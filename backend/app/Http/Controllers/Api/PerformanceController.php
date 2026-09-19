<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class PerformanceController extends Controller
{
    public function indicatorsIndex()
    {
        if (!Schema::hasTable('performance_indicator')) {
            return response()->json(['success' => false, 'message' => 'Run database/20_hiring_performance_mvp.sql'], 503);
        }
        $rows = DB::table('performance_indicator')->orderBy('name')->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'name' => (string) $r->name,
            'designation_id' => $r->designation_id ? (int) $r->designation_id : null,
            'department_id' => $r->department_id ? (int) $r->department_id : null,
            'description' => (string) ($r->description ?? ''),
            'status' => (int) ($r->status ?? 1),
        ]);

        return response()->json(['success' => true, 'indicators' => $rows]);
    }

    public function indicatorsStore(Request $request)
    {
        return $this->indicatorUpsert($request, null);
    }

    public function indicatorsUpdate(Request $request, int $id)
    {
        return $this->indicatorUpsert($request, $id);
    }

    public function indicatorsDelete(int $id)
    {
        DB::table('performance_indicator')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function reviewsIndex(Request $request)
    {
        if (!Schema::hasTable('performance_review')) {
            return response()->json(['success' => false, 'message' => 'Run database/20_hiring_performance_mvp.sql'], 503);
        }
        $q = DB::table('performance_review as r')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'r.employee_id')
            ->leftJoin('performance_indicator as i', 'i.id', '=', 'r.indicator_id')
            ->leftJoin('employee as rev', 'rev.employee_id', '=', 'r.reviewer_id')
            ->orderByDesc('r.id')
            ->select('r.*', 'e.name as employee_name', 'i.name as indicator_name', 'rev.name as reviewer_name');

        if ($request->filled('employee_id')) {
            $q->where('r.employee_id', (int) $request->query('employee_id'));
        }

        $rows = $q->limit(200)->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'employee_id' => (int) $r->employee_id,
            'employee_name' => (string) ($r->employee_name ?? ''),
            'indicator_id' => $r->indicator_id ? (int) $r->indicator_id : null,
            'indicator_name' => (string) ($r->indicator_name ?? ''),
            'review_date' => $r->review_date,
            'rating' => (float) $r->rating,
            'comments' => (string) ($r->comments ?? ''),
            'reviewer_id' => $r->reviewer_id ? (int) $r->reviewer_id : null,
            'reviewer_name' => (string) ($r->reviewer_name ?? ''),
            'status' => (int) ($r->status ?? 1),
        ]);

        return response()->json(['success' => true, 'reviews' => $rows]);
    }

    public function reviewsStore(Request $request)
    {
        return $this->reviewUpsert($request, null);
    }

    public function reviewsUpdate(Request $request, int $id)
    {
        return $this->reviewUpsert($request, $id);
    }

    public function reviewsDelete(int $id)
    {
        DB::table('performance_review')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function appraisalsIndex()
    {
        if (!Schema::hasTable('performance_appraisal')) {
            return response()->json(['success' => false, 'message' => 'Run database/20_hiring_performance_mvp.sql'], 503);
        }
        $rows = DB::table('performance_appraisal as a')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'a.employee_id')
            ->leftJoin('employee as m', 'm.employee_id', '=', 'a.manager_id')
            ->leftJoin('performance_cycle as cy', 'cy.id', '=', 'a.cycle_id')
            ->orderByDesc('a.id')
            ->get(['a.*', 'e.name as employee_name', 'm.name as manager_name', 'cy.name as cycle_name'])
            ->map(fn ($r) => [
                'id' => (int) $r->id,
                'employee_id' => (int) $r->employee_id,
                'employee_name' => (string) ($r->employee_name ?? ''),
                'manager_id' => $r->manager_id ? (int) $r->manager_id : null,
                'manager_name' => (string) ($r->manager_name ?? ''),
                'cycle_id' => isset($r->cycle_id) && $r->cycle_id ? (int) $r->cycle_id : null,
                'cycle_name' => (string) ($r->cycle_name ?? ''),
                'period' => (string) ($r->period ?? ''),
                'overall_score' => $r->overall_score !== null ? (float) $r->overall_score : null,
                'final_rating' => (string) ($r->final_rating ?? ''),
                'self_comments' => (string) ($r->self_comments ?? ''),
                'manager_comments' => (string) ($r->manager_comments ?? ''),
                'status' => (int) ($r->status ?? 0),
                'status_label' => match ((int) ($r->status ?? 0)) {
                    1 => 'In Progress',
                    2 => 'Completed',
                    default => 'Draft',
                },
                'current_stage' => (string) ($r->current_stage ?? 'goal_setting'),
                'stage_label' => $this->appraisalStageLabel((string) ($r->current_stage ?? 'goal_setting')),
                'finalized_at' => $r->finalized_at ?? null,
                'acknowledged_at' => $r->acknowledged_at ?? null,
            ]);

        return response()->json(['success' => true, 'appraisals' => $rows]);
    }

    public function appraisalsAdvance(Request $request, int $id)
    {
        $row = DB::table('performance_appraisal')->where('id', $id)->first();
        if (!$row) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }

        $stages = ['goal_setting', 'self_review', 'manager_review', 'finalization', 'acknowledged'];
        $current = (string) ($row->current_stage ?? 'goal_setting');
        $idx = array_search($current, $stages, true);
        if ($idx === false) {
            $idx = 0;
        }
        if ($idx >= count($stages) - 1) {
            return response()->json(['success' => true, 'message' => 'Already acknowledged.', 'current_stage' => $current]);
        }

        $next = $stages[$idx + 1];
        $update = [];
        if (Schema::hasColumn('performance_appraisal', 'current_stage')) {
            $update['current_stage'] = $next;
        }
        // Map stage → coarse status
        $update['status'] = match ($next) {
            'goal_setting' => 0,
            'acknowledged' => 2,
            default => 1,
        };
        if ($next === 'finalization' && Schema::hasColumn('performance_appraisal', 'finalized_at')) {
            $update['finalized_at'] = now();
        }
        if ($next === 'acknowledged' && Schema::hasColumn('performance_appraisal', 'acknowledged_at')) {
            $update['acknowledged_at'] = now();
            $update['status'] = 2;
        }
        DB::table('performance_appraisal')->where('id', $id)->update($update);

        return response()->json([
            'success' => true,
            'message' => 'Advanced to '.$this->appraisalStageLabel($next),
            'current_stage' => $next,
            'stage_label' => $this->appraisalStageLabel($next),
        ]);
    }

    protected function appraisalStageLabel(string $stage): string
    {
        return match ($stage) {
            'self_review' => 'Self Review',
            'manager_review' => 'Manager Review',
            'finalization' => 'Finalization',
            'acknowledged' => 'Acknowledged',
            default => 'Goal Setting',
        };
    }

    public function appraisalsStore(Request $request)
    {
        return $this->appraisalUpsert($request, null);
    }

    public function appraisalsUpdate(Request $request, int $id)
    {
        return $this->appraisalUpsert($request, $id);
    }

    public function appraisalsDelete(int $id)
    {
        DB::table('performance_appraisal')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function meta()
    {
        $employees = [];
        if (Schema::hasTable('employee')) {
            $employees = DB::table('employee')->where('status', '>', 0)->orderBy('name')
                ->get(['employee_id', 'name'])->map(fn ($r) => [
                    'id' => (int) $r->employee_id,
                    'name' => (string) $r->name,
                ])->all();
        }
        $indicators = [];
        if (Schema::hasTable('performance_indicator')) {
            $indicators = DB::table('performance_indicator')->where('status', 1)->orderBy('name')
                ->get(['id', 'name'])->map(fn ($r) => [
                    'id' => (int) $r->id,
                    'name' => (string) $r->name,
                ])->all();
        }

        $goalTypes = [];
        if (Schema::hasTable('performance_goal_types')) {
            $goalTypes = DB::table('performance_goal_types')->where('status', 1)->orderBy('name')
                ->get(['id', 'name'])->map(fn ($r) => [
                    'id' => (int) $r->id,
                    'name' => (string) $r->name,
                ])->all();
        }

        return response()->json([
            'success' => true,
            'options' => [
                'employees' => $employees,
                'indicators' => $indicators,
                'goal_types' => $goalTypes,
                'goal_statuses' => [
                    ['id' => 0, 'name' => 'Active'],
                    ['id' => 1, 'name' => 'Completed'],
                    ['id' => 2, 'name' => 'Cancelled'],
                ],
                'appraisal_stages' => [
                    ['id' => 'goal_setting', 'name' => 'Goal Setting'],
                    ['id' => 'self_review', 'name' => 'Self Review'],
                    ['id' => 'manager_review', 'name' => 'Manager Review'],
                    ['id' => 'finalization', 'name' => 'Finalization'],
                    ['id' => 'acknowledged', 'name' => 'Acknowledged'],
                ],
                'cycles' => Schema::hasTable('performance_cycle')
                    ? DB::table('performance_cycle')->where('status', 1)->orderByDesc('id')->get(['id', 'name'])->map(fn ($r) => [
                        'id' => (int) $r->id,
                        'name' => (string) $r->name,
                    ])->all()
                    : [],
            ],
        ]);
    }

    public function cyclesIndex()
    {
        if (!Schema::hasTable('performance_cycle')) {
            return response()->json(['success' => false, 'message' => 'Run database/27_phase4_depth.sql'], 503);
        }
        $rows = DB::table('performance_cycle')->orderByDesc('id')->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'name' => (string) $r->name,
            'period_start' => $r->period_start,
            'period_end' => $r->period_end,
            'status' => (int) ($r->status ?? 1),
            'status_label' => (int) ($r->status ?? 1) === 1 ? 'Open' : 'Closed',
            'description' => (string) ($r->description ?? ''),
        ]);

        return response()->json(['success' => true, 'cycles' => $rows]);
    }

    public function cyclesStore(Request $request)
    {
        return $this->cycleUpsert($request, null);
    }

    public function cyclesUpdate(Request $request, int $id)
    {
        return $this->cycleUpsert($request, $id);
    }

    public function cyclesDelete(int $id)
    {
        DB::table('performance_cycle')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    protected function cycleUpsert(Request $request, ?int $id)
    {
        if (!Schema::hasTable('performance_cycle')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }
        $data = $request->validate([
            'name' => 'required|string|max:150',
            'period_start' => 'nullable|date',
            'period_end' => 'nullable|date',
            'status' => 'nullable|integer',
            'description' => 'nullable|string',
        ]);
        $claims = $request->attributes->get('hr_claims') ?? [];
        $payload = [
            'name' => $data['name'],
            'period_start' => $data['period_start'] ?? null,
            'period_end' => $data['period_end'] ?? null,
            'status' => (int) ($data['status'] ?? 1),
            'description' => $data['description'] ?? null,
        ];
        if ($id === null) {
            $payload['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
            $newId = (int) DB::table('performance_cycle')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('performance_cycle')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    public function goalsIndex(Request $request)
    {
        if (!Schema::hasTable('performance_goal')) {
            return response()->json(['success' => false, 'message' => 'Run database/22_goals_termination_loan.sql'], 503);
        }
        $q = DB::table('performance_goal as g')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'g.employee_id')
            ->leftJoin('performance_goal_types as gt', 'gt.id', '=', 'g.goal_type_id')
            ->orderByDesc('g.id')
            ->select('g.*', 'e.name as employee_name', 'gt.name as goal_type_name');

        if ($request->filled('employee_id')) {
            $q->where('g.employee_id', (int) $request->query('employee_id'));
        }
        if ($request->filled('appraisal_id')) {
            $q->where('g.appraisal_id', (int) $request->query('appraisal_id'));
        }

        $rows = $q->limit(300)->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'employee_id' => (int) $r->employee_id,
            'employee_name' => (string) ($r->employee_name ?? ''),
            'goal_type_id' => $r->goal_type_id ? (int) $r->goal_type_id : null,
            'goal_type_name' => (string) ($r->goal_type_name ?? ''),
            'appraisal_id' => $r->appraisal_id ? (int) $r->appraisal_id : null,
            'title' => (string) $r->title,
            'metric' => (string) ($r->metric ?? ''),
            'weight' => (float) ($r->weight ?? 0),
            'target_value' => (string) ($r->target_value ?? ''),
            'achievement_value' => (string) ($r->achievement_value ?? ''),
            'score' => (float) ($r->score ?? 0),
            'period' => (string) ($r->period ?? ''),
            'status' => (int) ($r->status ?? 0),
            'status_label' => match ((int) ($r->status ?? 0)) {
                1 => 'Completed',
                2 => 'Cancelled',
                default => 'Active',
            },
            'employee_comment' => (string) ($r->employee_comment ?? ''),
            'manager_comment' => (string) ($r->manager_comment ?? ''),
        ]);

        return response()->json(['success' => true, 'goals' => $rows]);
    }

    public function goalsStore(Request $request)
    {
        return $this->goalUpsert($request, null);
    }

    public function goalsUpdate(Request $request, int $id)
    {
        return $this->goalUpsert($request, $id);
    }

    public function goalsDelete(int $id)
    {
        DB::table('performance_goal')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function goalTypesIndex()
    {
        if (!Schema::hasTable('performance_goal_types')) {
            return response()->json(['success' => false, 'message' => 'Run database/22_goals_termination_loan.sql'], 503);
        }
        $rows = DB::table('performance_goal_types')->orderBy('name')->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'name' => (string) $r->name,
            'description' => (string) ($r->description ?? ''),
            'status' => (int) ($r->status ?? 1),
        ]);

        return response()->json(['success' => true, 'types' => $rows]);
    }

    public function goalTypesStore(Request $request)
    {
        return $this->goalTypeUpsert($request, null);
    }

    public function goalTypesUpdate(Request $request, int $id)
    {
        return $this->goalTypeUpsert($request, $id);
    }

    public function goalTypesDelete(int $id)
    {
        DB::table('performance_goal_types')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    protected function goalUpsert(Request $request, ?int $id)
    {
        $data = $request->validate([
            'employee_id' => 'required|integer',
            'goal_type_id' => 'nullable|integer',
            'appraisal_id' => 'nullable|integer',
            'title' => 'required|string|max:255',
            'metric' => 'nullable|string|max:255',
            'weight' => 'nullable|numeric',
            'target_value' => 'nullable|string|max:255',
            'achievement_value' => 'nullable|string|max:255',
            'score' => 'nullable|numeric',
            'period' => 'nullable|string|max:80',
            'status' => 'nullable|integer',
            'employee_comment' => 'nullable|string',
            'manager_comment' => 'nullable|string',
        ]);
        $claims = $request->attributes->get('hr_claims') ?? [];
        $payload = [
            'employee_id' => (int) $data['employee_id'],
            'goal_type_id' => $data['goal_type_id'] ?? null,
            'appraisal_id' => $data['appraisal_id'] ?? null,
            'title' => $data['title'],
            'metric' => $data['metric'] ?? null,
            'weight' => (float) ($data['weight'] ?? 0),
            'target_value' => $data['target_value'] ?? null,
            'achievement_value' => $data['achievement_value'] ?? null,
            'score' => (float) ($data['score'] ?? 0),
            'period' => $data['period'] ?? null,
            'status' => (int) ($data['status'] ?? 0),
            'employee_comment' => $data['employee_comment'] ?? null,
            'manager_comment' => $data['manager_comment'] ?? null,
        ];
        if ($id === null) {
            $payload['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
            $newId = (int) DB::table('performance_goal')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('performance_goal')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    protected function goalTypeUpsert(Request $request, ?int $id)
    {
        $data = $request->validate([
            'name' => 'required|string|max:150',
            'description' => 'nullable|string',
            'status' => 'nullable|integer',
        ]);
        $claims = $request->attributes->get('hr_claims') ?? [];
        $payload = [
            'name' => $data['name'],
            'description' => $data['description'] ?? null,
            'status' => (int) ($data['status'] ?? 1),
        ];
        if ($id === null) {
            $payload['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
            $newId = (int) DB::table('performance_goal_types')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('performance_goal_types')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    protected function indicatorUpsert(Request $request, ?int $id)
    {
        $data = $request->validate([
            'name' => 'required|string|max:191',
            'designation_id' => 'nullable|integer',
            'department_id' => 'nullable|integer',
            'description' => 'nullable|string',
            'status' => 'nullable|integer',
        ]);
        $payload = [
            'name' => $data['name'],
            'designation_id' => $data['designation_id'] ?? null,
            'department_id' => $data['department_id'] ?? null,
            'description' => $data['description'] ?? null,
            'status' => (int) ($data['status'] ?? 1),
        ];
        if ($id === null) {
            $claims = $request->attributes->get('hr_claims') ?? [];
            $payload['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
            $newId = (int) DB::table('performance_indicator')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('performance_indicator')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    protected function reviewUpsert(Request $request, ?int $id)
    {
        $data = $request->validate([
            'employee_id' => 'required|integer',
            'indicator_id' => 'nullable|integer',
            'review_date' => 'nullable|date',
            'rating' => 'required|numeric|min:0|max:10',
            'comments' => 'nullable|string',
            'status' => 'nullable|integer',
        ]);
        $claims = $request->attributes->get('hr_claims') ?? [];
        $payload = [
            'employee_id' => (int) $data['employee_id'],
            'indicator_id' => $data['indicator_id'] ?? null,
            'review_date' => $data['review_date'] ?? now()->toDateString(),
            'rating' => (float) $data['rating'],
            'comments' => $data['comments'] ?? null,
            'reviewer_id' => (int) ($claims['employee_id'] ?? 0) ?: null,
            'status' => (int) ($data['status'] ?? 1),
        ];
        if ($id === null) {
            $newId = (int) DB::table('performance_review')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('performance_review')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    protected function appraisalUpsert(Request $request, ?int $id)
    {
        $data = $request->validate([
            'employee_id' => 'required|integer',
            'manager_id' => 'nullable|integer',
            'cycle_id' => 'nullable|integer',
            'period' => 'nullable|string|max:80',
            'overall_score' => 'nullable|numeric',
            'final_rating' => 'nullable|string|max:40',
            'self_comments' => 'nullable|string',
            'manager_comments' => 'nullable|string',
            'status' => 'nullable|integer',
        ]);
        $claims = $request->attributes->get('hr_claims') ?? [];
        $payload = [
            'employee_id' => (int) $data['employee_id'],
            'manager_id' => $data['manager_id'] ?? null,
            'period' => $data['period'] ?? null,
            'overall_score' => $data['overall_score'] ?? null,
            'final_rating' => $data['final_rating'] ?? null,
            'self_comments' => $data['self_comments'] ?? null,
            'manager_comments' => $data['manager_comments'] ?? null,
            'status' => (int) ($data['status'] ?? 0),
        ];
        if (Schema::hasColumn('performance_appraisal', 'cycle_id') && array_key_exists('cycle_id', $data)) {
            $payload['cycle_id'] = $data['cycle_id'];
        }
        if (Schema::hasColumn('performance_appraisal', 'current_stage')) {
            $payload['current_stage'] = $request->input('current_stage', $id === null ? 'goal_setting' : null);
            if ($payload['current_stage'] === null) {
                unset($payload['current_stage']);
            }
        }
        if ($id === null) {
            $payload['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
            if (Schema::hasColumn('performance_appraisal', 'current_stage') && empty($payload['current_stage'])) {
                $payload['current_stage'] = 'goal_setting';
            }
            $newId = (int) DB::table('performance_appraisal')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('performance_appraisal')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }
}
