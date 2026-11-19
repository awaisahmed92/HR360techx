<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ApprovalService;
use App\Services\Ats\GreenhouseConnector;
use App\Services\Ats\JazzHrConnector;
use App\Services\Ats\WorkableConnector;
use App\Services\ResumeParseService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class RecruitmentParityController extends Controller
{
    public function dashboard()
    {
        if (!Schema::hasTable('hr_recruit_applications')) {
            return response()->json(['success' => false, 'message' => 'Run database/36_recruitment_parity.sql'], 503);
        }

        $funnel = [];
        for ($i = 0; $i <= 4; $i++) {
            $funnel[] = [
                'stage' => $i,
                'label' => match ($i) {
                    1 => 'Screening',
                    2 => 'Interview',
                    3 => 'Offer',
                    4 => 'Hired',
                    default => 'Applied',
                },
                'count' => (int) DB::table('hr_recruit_applications')->where('stage', $i)->where('status', '>=', 0)->count(),
            ];
        }

        $openPosts = Schema::hasTable('hr_recruit_posts')
            ? (int) DB::table('hr_recruit_posts')->where('status', 1)->count()
            : 0;

        $aging = DB::table('hr_recruit_applications as a')
            ->leftJoin('hr_candidate as c', 'c.id', '=', 'a.candidate_id')
            ->leftJoin('hr_recruit_posts as p', 'p.id', '=', 'a.post_id')
            ->where('a.status', 0)
            ->where('a.created_at', '<', now()->subDays(7))
            ->orderBy('a.created_at')
            ->limit(20)
            ->get(['a.id', 'a.stage', 'a.created_at', 'c.name as candidate_name', 'p.title as post_title'])
            ->map(fn ($r) => [
                'id' => (int) $r->id,
                'stage' => (int) $r->stage,
                'created_at' => (string) $r->created_at,
                'candidate_name' => (string) ($r->candidate_name ?? ''),
                'post_title' => (string) ($r->post_title ?? ''),
                'days' => max(0, now()->diffInDays($r->created_at)),
            ]);

        $interviewsWeek = Schema::hasTable('hr_recruit_interviews')
            ? DB::table('hr_recruit_interviews as i')
                ->leftJoin('hr_recruit_applications as a', 'a.id', '=', 'i.application_id')
                ->leftJoin('hr_candidate as c', 'c.id', '=', 'a.candidate_id')
                ->whereBetween('i.scheduled_at', [now()->startOfWeek(), now()->endOfWeek()])
                ->orderBy('i.scheduled_at')
                ->get(['i.*', 'c.name as candidate_name'])
                ->map(fn ($r) => [
                    'id' => (int) $r->id,
                    'title' => (string) ($r->title ?? 'Interview'),
                    'scheduled_at' => (string) ($r->scheduled_at ?? ''),
                    'candidate_name' => (string) ($r->candidate_name ?? ''),
                    'status' => (int) ($r->status ?? 0),
                ])
            : [];

        return response()->json([
            'success' => true,
            'dashboard' => [
                'funnel' => $funnel,
                'open_posts' => $openPosts,
                'aging' => $aging,
                'interviews_week' => $interviewsWeek,
                'pending_requests' => Schema::hasTable('hr_recruit_requisitions')
                    ? (int) DB::table('hr_recruit_requisitions')->where('status', 1)->count()
                    : 0,
            ],
        ]);
    }

    public function requisitionsIndex()
    {
        if (!Schema::hasTable('hr_recruit_requisitions')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }
        $rows = DB::table('hr_recruit_requisitions as r')
            ->leftJoin('hr_recruit_requisition_types as t', 't.id', '=', 'r.type_id')
            ->leftJoin('department as d', 'd.department_id', '=', 'r.department_id')
            ->orderByDesc('r.id')
            ->get(['r.*', 't.title as type_title', 'd.name as department_name'])
            ->map(fn ($r) => $this->mapRequisition($r));

        return response()->json(['success' => true, 'requisitions' => $rows]);
    }

    public function requisitionsStore(Request $request)
    {
        return $this->requisitionUpsert($request, null);
    }

    public function requisitionsUpdate(Request $request, int $id)
    {
        return $this->requisitionUpsert($request, $id);
    }

    public function requisitionsSubmit(Request $request, int $id, ApprovalService $approvals)
    {
        $row = DB::table('hr_recruit_requisitions')->where('id', $id)->first();
        if (!$row) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }
        $claims = $request->attributes->get('hr_claims') ?? [];
        $uid = (int) ($claims['employee_id'] ?? 0);
        DB::table('hr_recruit_requisitions')->where('id', $id)->update([
            'status' => 1,
            'updated_at' => now(),
        ]);
        $row = DB::table('hr_recruit_requisitions')->where('id', $id)->first();
        $approvals->bootstrapRequest(
            'recruit_request',
            $uid,
            'recruit_request',
            $id,
            'Job request: '.$row->job_title,
            (array) $row
        );

        return response()->json(['success' => true, 'message' => 'Submitted for approval.']);
    }

    public function requisitionsDelete(int $id)
    {
        DB::table('hr_recruit_requisitions')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function postsIndex(Request $request)
    {
        if (!Schema::hasTable('hr_recruit_posts')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }
        $q = DB::table('hr_recruit_posts as p')
            ->leftJoin('department as d', 'd.department_id', '=', 'p.department_id')
            ->orderByDesc('p.id')
            ->select('p.*', 'd.name as department_name');
        if ($request->filled('status')) {
            $q->where('p.status', (int) $request->query('status'));
        }
        $rows = $q->get()->map(fn ($r) => $this->mapPost($r));

        return response()->json(['success' => true, 'posts' => $rows]);
    }

    public function postsStore(Request $request)
    {
        return $this->postUpsert($request, null);
    }

    public function postsUpdate(Request $request, int $id)
    {
        return $this->postUpsert($request, $id);
    }

    public function postsDelete(int $id)
    {
        DB::table('hr_recruit_posts')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function applicationsIndex(Request $request)
    {
        if (!Schema::hasTable('hr_recruit_applications')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }
        $q = DB::table('hr_recruit_applications as a')
            ->leftJoin('hr_candidate as c', 'c.id', '=', 'a.candidate_id')
            ->leftJoin('hr_recruit_posts as p', 'p.id', '=', 'a.post_id')
            ->orderByDesc('a.id')
            ->select('a.*', 'c.name as candidate_name', 'c.email as candidate_email', 'c.phone as candidate_phone', 'p.title as post_title');
        if ($request->filled('stage')) {
            $q->where('a.stage', (int) $request->query('stage'));
        }
        if ($request->filled('post_id')) {
            $q->where('a.post_id', (int) $request->query('post_id'));
        }
        if ($request->filled('q')) {
            $like = '%'.trim((string) $request->query('q')).'%';
            $q->where(function ($w) use ($like) {
                $w->where('c.name', 'like', $like)->orWhere('c.email', 'like', $like);
            });
        }
        $rows = $q->get()->map(fn ($r) => $this->mapApplication($r));

        return response()->json(['success' => true, 'applications' => $rows]);
    }

    public function applicationsUpdate(Request $request, int $id)
    {
        $row = DB::table('hr_recruit_applications')->where('id', $id)->first();
        if (!$row) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }
        $data = $request->validate([
            'stage' => 'nullable|integer|min:0|max:4',
            'application_stage' => 'nullable|integer|min:0|max:9',
            'is_favorite' => 'nullable|boolean',
            'status' => 'nullable|integer',
            'notes' => 'nullable|string',
            'activity_json' => 'nullable|array',
        ]);
        $update = ['updated_at' => now()];
        foreach (['stage', 'application_stage', 'status', 'notes'] as $col) {
            if (array_key_exists($col, $data)) {
                $update[$col] = $data[$col];
            }
        }
        if (array_key_exists('is_favorite', $data)) {
            $update['is_favorite'] = $data['is_favorite'] ? 1 : 0;
        }
        if (array_key_exists('activity_json', $data)) {
            $update['activity_json'] = json_encode($data['activity_json']);
        }
        if (isset($data['status']) && (int) $data['status'] === -1) {
            $update['rejected_at'] = now();
        }
        if (isset($data['status']) && (int) $data['status'] === 4) {
            $update['hired_at'] = now();
        }
        DB::table('hr_recruit_applications')->where('id', $id)->update($update);

        if (isset($data['stage']) && Schema::hasTable('hr_candidate')) {
            $candStatus = (int) $data['stage'];
            if (isset($data['status']) && (int) $data['status'] === -1) {
                $candStatus = -1;
            }
            DB::table('hr_candidate')->where('id', $row->candidate_id)->update(['status' => $candStatus]);
        }

        return response()->json(['success' => true]);
    }

    public function interviewsIndex()
    {
        if (!Schema::hasTable('hr_recruit_interviews')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }
        $rows = DB::table('hr_recruit_interviews as i')
            ->leftJoin('hr_recruit_applications as a', 'a.id', '=', 'i.application_id')
            ->leftJoin('hr_candidate as c', 'c.id', '=', 'a.candidate_id')
            ->orderByDesc('i.scheduled_at')
            ->get(['i.*', 'c.name as candidate_name'])
            ->map(fn ($r) => [
                'id' => (int) $r->id,
                'application_id' => (int) $r->application_id,
                'template_id' => $r->template_id ? (int) $r->template_id : null,
                'title' => (string) ($r->title ?? ''),
                'scheduled_at' => (string) ($r->scheduled_at ?? ''),
                'duration_min' => (int) ($r->duration_min ?? 60),
                'location' => (string) ($r->location ?? ''),
                'mode' => (string) ($r->mode ?? 'onsite'),
                'panel_ids' => json_decode((string) ($r->panel_ids ?? '[]'), true) ?: [],
                'feedback' => (string) ($r->feedback ?? ''),
                'score' => $r->score !== null ? (float) $r->score : null,
                'status' => (int) ($r->status ?? 0),
                'candidate_name' => (string) ($r->candidate_name ?? ''),
            ]);

        return response()->json(['success' => true, 'interviews' => $rows]);
    }

    public function interviewsStore(Request $request)
    {
        return $this->interviewUpsert($request, null);
    }

    public function interviewsUpdate(Request $request, int $id)
    {
        return $this->interviewUpsert($request, $id);
    }

    public function interviewsDelete(int $id)
    {
        DB::table('hr_recruit_interviews')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function interviewTemplatesIndex()
    {
        $rows = Schema::hasTable('hr_recruit_interview_templates')
            ? DB::table('hr_recruit_interview_templates')->orderBy('title')->get()->map(fn ($r) => [
                'id' => (int) $r->id,
                'title' => (string) $r->title,
                'questions' => json_decode((string) ($r->questions ?? '[]'), true) ?: [],
                'status' => (int) $r->status,
            ])
            : [];

        return response()->json(['success' => true, 'templates' => $rows]);
    }

    public function interviewTemplatesStore(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'questions' => 'nullable|array',
            'status' => 'nullable|integer',
        ]);
        $id = (int) DB::table('hr_recruit_interview_templates')->insertGetId([
            'title' => $data['title'],
            'questions' => json_encode($data['questions'] ?? []),
            'status' => (int) ($data['status'] ?? 1),
            'created_by' => (int) (($request->attributes->get('hr_claims') ?? [])['employee_id'] ?? 0) ?: null,
            'created_at' => now(),
        ]);

        return response()->json(['success' => true, 'id' => $id]);
    }

    public function testsIndex()
    {
        $tests = Schema::hasTable('hr_recruit_tests')
            ? DB::table('hr_recruit_tests')->orderByDesc('id')->get()->map(fn ($r) => [
                'id' => (int) $r->id,
                'title' => (string) $r->title,
                'description' => (string) ($r->description ?? ''),
                'pass_score' => (float) ($r->pass_score ?? 50),
                'status' => (int) $r->status,
                'questions' => Schema::hasTable('hr_recruit_test_questions')
                    ? DB::table('hr_recruit_test_questions')->where('test_id', $r->id)->orderBy('sort_order')->get()->map(fn ($q) => [
                        'id' => (int) $q->id,
                        'question' => (string) $q->question,
                        'options' => json_decode((string) ($q->options_json ?? '[]'), true) ?: [],
                        'correct_answer' => (string) ($q->correct_answer ?? ''),
                        'points' => (float) ($q->points ?? 1),
                    ])->all()
                    : [],
            ])
            : [];

        return response()->json(['success' => true, 'tests' => $tests]);
    }

    public function testsStore(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'pass_score' => 'nullable|numeric',
            'status' => 'nullable|integer',
            'questions' => 'nullable|array',
        ]);
        $id = (int) DB::table('hr_recruit_tests')->insertGetId([
            'title' => $data['title'],
            'description' => $data['description'] ?? null,
            'pass_score' => $data['pass_score'] ?? 50,
            'status' => (int) ($data['status'] ?? 1),
            'created_by' => (int) (($request->attributes->get('hr_claims') ?? [])['employee_id'] ?? 0) ?: null,
            'created_at' => now(),
        ]);
        $this->syncTestQuestions($id, $data['questions'] ?? []);

        return response()->json(['success' => true, 'id' => $id]);
    }

    public function testsUpdate(Request $request, int $id)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'pass_score' => 'nullable|numeric',
            'status' => 'nullable|integer',
            'questions' => 'nullable|array',
        ]);
        DB::table('hr_recruit_tests')->where('id', $id)->update([
            'title' => $data['title'],
            'description' => $data['description'] ?? null,
            'pass_score' => $data['pass_score'] ?? 50,
            'status' => (int) ($data['status'] ?? 1),
        ]);
        if (array_key_exists('questions', $data)) {
            $this->syncTestQuestions($id, $data['questions'] ?? []);
        }

        return response()->json(['success' => true, 'id' => $id]);
    }

    public function testResultsStore(Request $request)
    {
        $data = $request->validate([
            'test_id' => 'required|integer',
            'application_id' => 'required|integer',
            'score' => 'nullable|numeric',
            'answers_json' => 'nullable|array',
            'passed' => 'nullable|boolean',
        ]);
        $id = (int) DB::table('hr_recruit_test_results')->insertGetId([
            'test_id' => $data['test_id'],
            'application_id' => $data['application_id'],
            'score' => $data['score'] ?? null,
            'answers_json' => json_encode($data['answers_json'] ?? []),
            'passed' => isset($data['passed']) ? ($data['passed'] ? 1 : 0) : null,
            'taken_at' => now(),
            'created_by' => (int) (($request->attributes->get('hr_claims') ?? [])['employee_id'] ?? 0) ?: null,
            'created_at' => now(),
        ]);

        return response()->json(['success' => true, 'id' => $id]);
    }

    public function evaluationsIndex()
    {
        $evals = Schema::hasTable('hr_recruit_evaluations')
            ? DB::table('hr_recruit_evaluations')->orderByDesc('id')->get()->map(fn ($r) => [
                'id' => (int) $r->id,
                'title' => (string) $r->title,
                'criteria' => json_decode((string) ($r->criteria_json ?? '[]'), true) ?: [],
                'status' => (int) $r->status,
            ])
            : [];
        $results = Schema::hasTable('hr_recruit_evaluation_results')
            ? DB::table('hr_recruit_evaluation_results as er')
                ->leftJoin('hr_recruit_evaluations as e', 'e.id', '=', 'er.evaluation_id')
                ->leftJoin('hr_recruit_applications as a', 'a.id', '=', 'er.application_id')
                ->leftJoin('hr_candidate as c', 'c.id', '=', 'a.candidate_id')
                ->orderByDesc('er.id')
                ->get(['er.*', 'e.title as evaluation_title', 'c.name as candidate_name'])
                ->map(fn ($r) => [
                    'id' => (int) $r->id,
                    'evaluation_id' => (int) $r->evaluation_id,
                    'application_id' => (int) $r->application_id,
                    'scores' => json_decode((string) ($r->scores_json ?? '{}'), true) ?: [],
                    'total_score' => $r->total_score !== null ? (float) $r->total_score : null,
                    'comments' => (string) ($r->comments ?? ''),
                    'evaluation_title' => (string) ($r->evaluation_title ?? ''),
                    'candidate_name' => (string) ($r->candidate_name ?? ''),
                ])
            : [];

        return response()->json(['success' => true, 'evaluations' => $evals, 'results' => $results]);
    }

    public function evaluationsStore(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'criteria' => 'nullable|array',
            'status' => 'nullable|integer',
        ]);
        $id = (int) DB::table('hr_recruit_evaluations')->insertGetId([
            'title' => $data['title'],
            'criteria_json' => json_encode($data['criteria'] ?? []),
            'status' => (int) ($data['status'] ?? 1),
            'created_by' => (int) (($request->attributes->get('hr_claims') ?? [])['employee_id'] ?? 0) ?: null,
            'created_at' => now(),
        ]);

        return response()->json(['success' => true, 'id' => $id]);
    }

    public function evaluationResultsStore(Request $request)
    {
        $data = $request->validate([
            'evaluation_id' => 'required|integer',
            'application_id' => 'required|integer',
            'scores' => 'nullable|array',
            'total_score' => 'nullable|numeric',
            'comments' => 'nullable|string',
        ]);
        $id = (int) DB::table('hr_recruit_evaluation_results')->insertGetId([
            'evaluation_id' => $data['evaluation_id'],
            'application_id' => $data['application_id'],
            'scores_json' => json_encode($data['scores'] ?? []),
            'total_score' => $data['total_score'] ?? null,
            'comments' => $data['comments'] ?? null,
            'evaluator_id' => (int) (($request->attributes->get('hr_claims') ?? [])['employee_id'] ?? 0) ?: null,
            'created_at' => now(),
        ]);

        return response()->json(['success' => true, 'id' => $id]);
    }

    public function referralsIndex()
    {
        $rows = Schema::hasTable('hr_recruit_referrals')
            ? DB::table('hr_recruit_referrals as r')
                ->leftJoin('employee as e', 'e.employee_id', '=', 'r.employee_id')
                ->leftJoin('hr_recruit_posts as p', 'p.id', '=', 'r.post_id')
                ->orderByDesc('r.id')
                ->get(['r.*', 'e.name as employee_name', 'p.title as post_title'])
                ->map(fn ($r) => [
                    'id' => (int) $r->id,
                    'employee_id' => (int) $r->employee_id,
                    'employee_name' => (string) ($r->employee_name ?? ''),
                    'candidate_id' => $r->candidate_id ? (int) $r->candidate_id : null,
                    'post_id' => $r->post_id ? (int) $r->post_id : null,
                    'post_title' => (string) ($r->post_title ?? ''),
                    'candidate_name' => (string) $r->candidate_name,
                    'candidate_email' => (string) ($r->candidate_email ?? ''),
                    'candidate_phone' => (string) ($r->candidate_phone ?? ''),
                    'notes' => (string) ($r->notes ?? ''),
                    'status' => (int) $r->status,
                ])
            : [];

        return response()->json(['success' => true, 'referrals' => $rows]);
    }

    public function referralsStore(Request $request)
    {
        $data = $request->validate([
            'candidate_name' => 'required|string|max:191',
            'candidate_email' => 'nullable|email|max:191',
            'candidate_phone' => 'nullable|string|max:40',
            'post_id' => 'nullable|integer',
            'notes' => 'nullable|string',
            'employee_id' => 'nullable|integer',
        ]);
        $uid = (int) ($data['employee_id'] ?? (($request->attributes->get('hr_claims') ?? [])['employee_id'] ?? 0));
        $id = (int) DB::table('hr_recruit_referrals')->insertGetId([
            'employee_id' => $uid,
            'candidate_name' => $data['candidate_name'],
            'candidate_email' => $data['candidate_email'] ?? null,
            'candidate_phone' => $data['candidate_phone'] ?? null,
            'post_id' => $data['post_id'] ?? null,
            'notes' => $data['notes'] ?? null,
            'status' => 0,
            'created_at' => now(),
        ]);

        return response()->json(['success' => true, 'id' => $id]);
    }

    public function referralsUpdate(Request $request, int $id)
    {
        $data = $request->validate(['status' => 'required|integer']);
        DB::table('hr_recruit_referrals')->where('id', $id)->update(['status' => (int) $data['status']]);

        return response()->json(['success' => true]);
    }

    public function tasksIndex()
    {
        $rows = Schema::hasTable('hr_recruit_tasks')
            ? DB::table('hr_recruit_tasks as t')
                ->leftJoin('employee as e', 'e.employee_id', '=', 't.assignee_id')
                ->orderByDesc('t.id')
                ->get(['t.*', 'e.name as assignee_name'])
                ->map(fn ($r) => [
                    'id' => (int) $r->id,
                    'application_id' => $r->application_id ? (int) $r->application_id : null,
                    'post_id' => $r->post_id ? (int) $r->post_id : null,
                    'title' => (string) $r->title,
                    'assignee_id' => $r->assignee_id ? (int) $r->assignee_id : null,
                    'assignee_name' => (string) ($r->assignee_name ?? ''),
                    'due_date' => (string) ($r->due_date ?? ''),
                    'status' => (int) $r->status,
                    'notes' => (string) ($r->notes ?? ''),
                ])
            : [];

        return response()->json(['success' => true, 'tasks' => $rows]);
    }

    public function tasksStore(Request $request)
    {
        return $this->taskUpsert($request, null);
    }

    public function tasksUpdate(Request $request, int $id)
    {
        return $this->taskUpsert($request, $id);
    }

    public function tasksComplete(int $id)
    {
        DB::table('hr_recruit_tasks')->where('id', $id)->update([
            'status' => 1,
            'completed_at' => now(),
        ]);

        return response()->json(['success' => true]);
    }

    public function reports()
    {
        $byStage = [];
        if (Schema::hasTable('hr_recruit_applications')) {
            $byStage = DB::table('hr_recruit_applications')
                ->select('stage', DB::raw('COUNT(*) as cnt'))
                ->groupBy('stage')
                ->get()
                ->map(fn ($r) => ['stage' => (int) $r->stage, 'count' => (int) $r->cnt]);
        }
        $bySource = Schema::hasTable('hr_recruit_applications')
            ? DB::table('hr_recruit_applications')
                ->select('source', DB::raw('COUNT(*) as cnt'))
                ->groupBy('source')
                ->get()
                ->map(fn ($r) => ['source' => (string) ($r->source ?? 'manual'), 'count' => (int) $r->cnt])
            : [];

        $hired = Schema::hasTable('hr_recruit_applications')
            ? DB::table('hr_recruit_applications')->where('status', 4)->whereNotNull('hired_at')->get(['created_at', 'hired_at'])
            : collect();
        $avgDays = 0;
        if ($hired->count() > 0) {
            $avgDays = (int) round($hired->avg(fn ($r) => max(0, \Carbon\Carbon::parse($r->created_at)->diffInDays($r->hired_at))));
        }

        $interviewLoad = Schema::hasTable('hr_recruit_interviews')
            ? DB::table('hr_recruit_interviews')
                ->select(DB::raw('DATE(scheduled_at) as d'), DB::raw('COUNT(*) as cnt'))
                ->where('scheduled_at', '>=', now()->subDays(30))
                ->groupBy('d')
                ->orderBy('d')
                ->get()
                ->map(fn ($r) => ['date' => (string) $r->d, 'count' => (int) $r->cnt])
            : [];

        return response()->json([
            'success' => true,
            'reports' => [
                'pipeline' => $byStage,
                'source' => $bySource,
                'time_to_hire_days' => $avgDays,
                'interview_load' => $interviewLoad,
            ],
        ]);
    }

    public function portalSettings()
    {
        $row = Schema::hasTable('hr_recruit_portal_settings')
            ? DB::table('hr_recruit_portal_settings')->orderBy('id')->first()
            : null;

        return response()->json([
            'success' => true,
            'settings' => $row ? [
                'id' => (int) $row->id,
                'enabled' => (int) $row->enabled === 1,
                'brand_name' => (string) ($row->brand_name ?? 'Careers'),
                'welcome_text' => (string) ($row->welcome_text ?? ''),
                'fields' => json_decode((string) ($row->fields_json ?? '[]'), true) ?: [],
                'resume_parse_enabled' => (int) ($row->resume_parse_enabled ?? 0) === 1,
                'ai_base_url' => (string) ($row->ai_base_url ?? ''),
                'ai_api_key_set' => !empty($row->ai_api_key),
                'ats' => json_decode((string) ($row->ats_json ?? '{}'), true) ?: [],
            ] : [
                'enabled' => true,
                'brand_name' => 'Careers',
                'welcome_text' => '',
                'fields' => ['name', 'email', 'phone', 'resume'],
                'resume_parse_enabled' => false,
                'ai_base_url' => '',
                'ai_api_key_set' => false,
                'ats' => [],
            ],
        ]);
    }

    public function portalSettingsSave(Request $request)
    {
        if (!Schema::hasTable('hr_recruit_portal_settings')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }
        $data = $request->validate([
            'enabled' => 'nullable|boolean',
            'brand_name' => 'nullable|string|max:191',
            'welcome_text' => 'nullable|string',
            'fields' => 'nullable|array',
            'resume_parse_enabled' => 'nullable|boolean',
            'ai_base_url' => 'nullable|string|max:255',
            'ai_api_key' => 'nullable|string|max:255',
            'ats' => 'nullable|array',
        ]);
        $row = DB::table('hr_recruit_portal_settings')->orderBy('id')->first();
        $payload = [
            'enabled' => ($data['enabled'] ?? true) ? 1 : 0,
            'brand_name' => $data['brand_name'] ?? 'Careers',
            'welcome_text' => $data['welcome_text'] ?? null,
            'fields_json' => json_encode($data['fields'] ?? ['name', 'email', 'phone', 'resume']),
            'resume_parse_enabled' => ($data['resume_parse_enabled'] ?? false) ? 1 : 0,
            'ai_base_url' => $data['ai_base_url'] ?? null,
            'updated_at' => now(),
        ];
        if (!empty($data['ai_api_key'])) {
            $payload['ai_api_key'] = $data['ai_api_key'];
        }
        if (array_key_exists('ats', $data)) {
            $payload['ats_json'] = json_encode($data['ats']);
        }
        if ($row) {
            DB::table('hr_recruit_portal_settings')->where('id', $row->id)->update($payload);
            $id = (int) $row->id;
        } else {
            $id = (int) DB::table('hr_recruit_portal_settings')->insertGetId($payload);
        }

        return response()->json(['success' => true, 'id' => $id]);
    }

    public function resumeParse(Request $request, ResumeParseService $parser)
    {
        $data = $request->validate([
            'text' => 'nullable|string',
            'path' => 'nullable|string',
        ]);
        $result = $parser->parse($data['text'] ?? '', $data['path'] ?? null);

        return response()->json(['success' => true, 'parsed' => $result]);
    }

    public function atsSync(Request $request, string $provider)
    {
        $provider = strtolower($provider);
        $settings = DB::table('hr_recruit_portal_settings')->orderBy('id')->first();
        $ats = $settings ? (json_decode((string) ($settings->ats_json ?? '{}'), true) ?: []) : [];
        $imported = 0;
        $message = 'ok';
        $status = 'ok';
        try {
            $connector = match ($provider) {
                'workable' => new WorkableConnector(),
                'greenhouse' => new GreenhouseConnector(),
                'jazzhr' => new JazzHrConnector(),
                default => null,
            };
            if ($connector === null) {
                $status = 'error';
                $message = 'Unknown provider';
            } else {
                $result = $connector->pullJobsAndCandidates(is_array($ats[$provider] ?? null) ? $ats[$provider] : []);
                $imported = (int) ($result['imported'] ?? 0);
                $message = (string) ($result['message'] ?? 'ok');
                $status = (string) ($result['status'] ?? 'ok');
            }
        } catch (\Throwable $e) {
            $status = 'error';
            $message = $e->getMessage();
        }
        if (Schema::hasTable('hr_recruit_ats_log')) {
            DB::table('hr_recruit_ats_log')->insert([
                'provider' => $provider,
                'action' => 'sync',
                'payload' => json_encode(['imported' => $imported]),
                'status' => $status,
                'message' => $message,
                'created_at' => now(),
            ]);
        }

        return response()->json([
            'success' => $status !== 'error',
            'imported' => $imported,
            'message' => $message,
            'status' => $status,
        ]);
    }

    public function atsLog()
    {
        $rows = Schema::hasTable('hr_recruit_ats_log')
            ? DB::table('hr_recruit_ats_log')->orderByDesc('id')->limit(50)->get()
            : [];

        return response()->json(['success' => true, 'log' => $rows]);
    }

    public function inboxIndex(Request $request)
    {
        $q = DB::table('hr_recruit_inbox')->orderByDesc('id');
        if ($request->filled('candidate_id')) {
            $q->where('candidate_id', (int) $request->query('candidate_id'));
        }
        $rows = Schema::hasTable('hr_recruit_inbox') ? $q->limit(100)->get() : [];

        return response()->json(['success' => true, 'messages' => $rows]);
    }

    public function inboxSend(Request $request)
    {
        $data = $request->validate([
            'candidate_id' => 'nullable|integer',
            'application_id' => 'nullable|integer',
            'subject' => 'nullable|string|max:255',
            'body' => 'required|string',
        ]);
        $id = (int) DB::table('hr_recruit_inbox')->insertGetId([
            'candidate_id' => $data['candidate_id'] ?? null,
            'application_id' => $data['application_id'] ?? null,
            'subject' => $data['subject'] ?? null,
            'body' => $data['body'],
            'direction' => 'outbound',
            'is_read' => 1,
            'created_at' => now(),
        ]);

        return response()->json(['success' => true, 'id' => $id]);
    }

    protected function requisitionUpsert(Request $request, ?int $id)
    {
        $data = $request->validate([
            'type_id' => 'nullable|integer',
            'job_title' => 'required|string|max:200',
            'job_type' => 'nullable|string|max:40',
            'vacancies' => 'nullable|integer|min:1',
            'department_id' => 'nullable|integer',
            'designation_id' => 'nullable|integer',
            'qualification' => 'nullable|string',
            'experience' => 'nullable|string',
            'salary_min' => 'nullable|numeric',
            'salary_max' => 'nullable|numeric',
            'description' => 'nullable|string',
            'opening_date' => 'nullable|date',
            'closing_date' => 'nullable|date',
            'notes' => 'nullable|string',
            'status' => 'nullable|integer',
            'reference_number' => 'nullable|string|max:40',
            'details' => 'nullable|array',
        ]);
        $payload = [
            'type_id' => $data['type_id'] ?? null,
            'job_title' => $data['job_title'],
            'job_type' => $data['job_type'] ?? 'Permanent',
            'vacancies' => (int) ($data['vacancies'] ?? 1),
            'department_id' => $data['department_id'] ?? null,
            'designation_id' => $data['designation_id'] ?? null,
            'qualification' => $data['qualification'] ?? null,
            'experience' => $data['experience'] ?? null,
            'salary_min' => $data['salary_min'] ?? null,
            'salary_max' => $data['salary_max'] ?? null,
            'description' => $data['description'] ?? null,
            'opening_date' => $data['opening_date'] ?? null,
            'closing_date' => $data['closing_date'] ?? null,
            'notes' => $data['notes'] ?? null,
            'updated_at' => now(),
        ];
        if (Schema::hasColumn('hr_recruit_requisitions', 'reference_number')) {
            $payload['reference_number'] = $data['reference_number'] ?? null;
        }
        if (Schema::hasColumn('hr_recruit_requisitions', 'details_json') && array_key_exists('details', $data)) {
            $payload['details_json'] = json_encode($data['details'] ?? []);
        }
        if (array_key_exists('status', $data)) {
            $payload['status'] = (int) $data['status'];
        }
        $claims = $request->attributes->get('hr_claims') ?? [];
        if ($id === null) {
            $payload['status'] = (int) ($data['status'] ?? 0);
            $payload['requested_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
            $payload['created_by'] = $payload['requested_by'];
            $payload['created_at'] = now();
            $newId = (int) DB::table('hr_recruit_requisitions')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('hr_recruit_requisitions')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    protected function postUpsert(Request $request, ?int $id)
    {
        $data = $request->validate([
            'requisition_id' => 'nullable|integer',
            'title' => 'required|string|max:200',
            'job_type' => 'nullable|string|max:40',
            'job_for' => 'nullable|integer',
            'vacancies' => 'nullable|integer|min:1',
            'department_id' => 'nullable|integer',
            'designation_id' => 'nullable|integer',
            'qualification' => 'nullable|string',
            'experience' => 'nullable|string',
            'description' => 'nullable|string',
            'locations' => 'nullable|string|max:255',
            'publish_portal' => 'nullable|boolean',
            'opening_date' => 'nullable|date',
            'closing_date' => 'nullable|date',
            'status' => 'nullable|integer',
            'reference_number' => 'nullable|string|max:40',
            'hiring_manager_id' => 'nullable|integer',
            'details' => 'nullable|array',
        ]);
        $payload = [
            'requisition_id' => $data['requisition_id'] ?? null,
            'title' => $data['title'],
            'job_type' => $data['job_type'] ?? 'Permanent',
            'job_for' => (int) ($data['job_for'] ?? 0),
            'vacancies' => (int) ($data['vacancies'] ?? 1),
            'department_id' => $data['department_id'] ?? null,
            'designation_id' => $data['designation_id'] ?? null,
            'qualification' => $data['qualification'] ?? null,
            'experience' => $data['experience'] ?? null,
            'description' => $data['description'] ?? null,
            'locations' => $data['locations'] ?? null,
            'publish_portal' => ($data['publish_portal'] ?? true) ? 1 : 0,
            'opening_date' => $data['opening_date'] ?? null,
            'closing_date' => $data['closing_date'] ?? null,
            'status' => (int) ($data['status'] ?? 1),
            'updated_at' => now(),
        ];
        if (Schema::hasColumn('hr_recruit_posts', 'reference_number')) {
            $payload['reference_number'] = ($data['reference_number'] ?? '') !== ''
                ? $data['reference_number']
                : (string) random_int(100000, 999999);
        }
        if (Schema::hasColumn('hr_recruit_posts', 'hiring_manager_id') && !empty($data['hiring_manager_id'])) {
            $payload['hiring_manager_id'] = (int) $data['hiring_manager_id'];
        }
        if (Schema::hasColumn('hr_recruit_posts', 'details_json')) {
            $payload['details_json'] = json_encode($data['details'] ?? []);
        }
        $claims = $request->attributes->get('hr_claims') ?? [];
        $legacyId = null;
        if (Schema::hasTable('hr_job')) {
            $jobTypeMap = ['Full-time' => 1, 'Part-time' => 2, 'Contract' => 3, 'Intern' => 4, 'Temporary' => 5, 'Permanent' => 1];
            $legacyPayload = [
                'title' => $payload['title'],
                'department_id' => $payload['department_id'],
                'designation_id' => $payload['designation_id'],
                'vacancies' => $payload['vacancies'],
                'job_type' => $jobTypeMap[$payload['job_type']] ?? 1,
                'experience' => $payload['experience'],
                'qualification' => $payload['qualification'],
                'description' => $payload['description'],
                'start_date' => $payload['opening_date'],
                'end_date' => $payload['closing_date'],
                'status' => match ($payload['status']) {
                    2 => 2,
                    3 => 3,
                    default => 1,
                },
            ];
            if ($id !== null) {
                $existing = DB::table('hr_recruit_posts')->where('id', $id)->first();
                $legacyId = $existing->legacy_job_id ?? null;
            }
            if ($legacyId) {
                DB::table('hr_job')->where('id', $legacyId)->update($legacyPayload);
            } else {
                $legacyPayload['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
                $legacyId = (int) DB::table('hr_job')->insertGetId($legacyPayload);
            }
            $payload['legacy_job_id'] = $legacyId;
        }
        if ($id === null) {
            $payload['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
            $payload['created_at'] = now();
            $newId = (int) DB::table('hr_recruit_posts')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId, 'legacy_job_id' => $legacyId]);
        }
        DB::table('hr_recruit_posts')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id, 'legacy_job_id' => $legacyId]);
    }

    protected function interviewUpsert(Request $request, ?int $id)
    {
        $data = $request->validate([
            'application_id' => 'required|integer',
            'template_id' => 'nullable|integer',
            'title' => 'nullable|string|max:255',
            'scheduled_at' => 'nullable|date',
            'duration_min' => 'nullable|integer',
            'location' => 'nullable|string|max:255',
            'mode' => 'nullable|string|max:40',
            'panel_ids' => 'nullable|array',
            'feedback' => 'nullable|string',
            'score' => 'nullable|numeric',
            'status' => 'nullable|integer',
        ]);
        $payload = [
            'application_id' => $data['application_id'],
            'template_id' => $data['template_id'] ?? null,
            'title' => $data['title'] ?? null,
            'scheduled_at' => $data['scheduled_at'] ?? null,
            'duration_min' => (int) ($data['duration_min'] ?? 60),
            'location' => $data['location'] ?? null,
            'mode' => $data['mode'] ?? 'onsite',
            'panel_ids' => json_encode($data['panel_ids'] ?? []),
            'feedback' => $data['feedback'] ?? null,
            'score' => $data['score'] ?? null,
            'status' => (int) ($data['status'] ?? 0),
        ];
        if ($id === null) {
            $payload['created_by'] = (int) (($request->attributes->get('hr_claims') ?? [])['employee_id'] ?? 0) ?: null;
            $payload['created_at'] = now();
            $newId = (int) DB::table('hr_recruit_interviews')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('hr_recruit_interviews')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    protected function taskUpsert(Request $request, ?int $id)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'application_id' => 'nullable|integer',
            'post_id' => 'nullable|integer',
            'assignee_id' => 'nullable|integer',
            'due_date' => 'nullable|date',
            'status' => 'nullable|integer',
            'notes' => 'nullable|string',
        ]);
        $payload = [
            'title' => $data['title'],
            'application_id' => $data['application_id'] ?? null,
            'post_id' => $data['post_id'] ?? null,
            'assignee_id' => $data['assignee_id'] ?? null,
            'due_date' => $data['due_date'] ?? null,
            'status' => (int) ($data['status'] ?? 0),
            'notes' => $data['notes'] ?? null,
        ];
        if ($id === null) {
            $payload['created_by'] = (int) (($request->attributes->get('hr_claims') ?? [])['employee_id'] ?? 0) ?: null;
            $payload['created_at'] = now();
            $newId = (int) DB::table('hr_recruit_tasks')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        if ((int) ($payload['status'] ?? 0) === 1) {
            $payload['completed_at'] = now();
        }
        DB::table('hr_recruit_tasks')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    protected function syncTestQuestions(int $testId, array $questions): void
    {
        if (!Schema::hasTable('hr_recruit_test_questions')) {
            return;
        }
        DB::table('hr_recruit_test_questions')->where('test_id', $testId)->delete();
        $i = 0;
        foreach ($questions as $q) {
            if (!is_array($q) || empty($q['question'])) {
                continue;
            }
            DB::table('hr_recruit_test_questions')->insert([
                'test_id' => $testId,
                'question' => $q['question'],
                'options_json' => json_encode($q['options'] ?? []),
                'correct_answer' => $q['correct_answer'] ?? null,
                'points' => $q['points'] ?? 1,
                'sort_order' => $i++,
            ]);
        }
    }

    protected function mapRequisition(object $r): array
    {
        return [
            'id' => (int) $r->id,
            'type_id' => $r->type_id ? (int) $r->type_id : null,
            'type_title' => (string) ($r->type_title ?? ''),
            'job_title' => (string) $r->job_title,
            'job_type' => (string) ($r->job_type ?? ''),
            'vacancies' => (int) $r->vacancies,
            'department_id' => $r->department_id ? (int) $r->department_id : null,
            'department_name' => (string) ($r->department_name ?? ''),
            'designation_id' => $r->designation_id ? (int) $r->designation_id : null,
            'qualification' => (string) ($r->qualification ?? ''),
            'experience' => (string) ($r->experience ?? ''),
            'salary_min' => $r->salary_min !== null ? (float) $r->salary_min : null,
            'salary_max' => $r->salary_max !== null ? (float) $r->salary_max : null,
            'description' => (string) ($r->description ?? ''),
            'opening_date' => $r->opening_date,
            'closing_date' => $r->closing_date,
            'status' => (int) $r->status,
            'status_label' => match ((int) $r->status) {
                1 => 'Pending',
                2 => 'Approved',
                3 => 'Rejected',
                4 => 'Closed',
                default => 'Draft',
            },
            'notes' => (string) ($r->notes ?? ''),
            'reference_number' => property_exists($r, 'reference_number') ? (string) ($r->reference_number ?? '') : '',
            'details' => property_exists($r, 'details_json')
                ? (json_decode((string) ($r->details_json ?? '{}'), true) ?: [])
                : [],
        ];
    }

    protected function mapPost(object $r): array
    {
        return [
            'id' => (int) $r->id,
            'requisition_id' => $r->requisition_id ? (int) $r->requisition_id : null,
            'legacy_job_id' => $r->legacy_job_id ? (int) $r->legacy_job_id : null,
            'title' => (string) $r->title,
            'job_type' => (string) ($r->job_type ?? ''),
            'job_for' => (int) ($r->job_for ?? 0),
            'vacancies' => (int) $r->vacancies,
            'department_id' => $r->department_id ? (int) $r->department_id : null,
            'department_name' => (string) ($r->department_name ?? ''),
            'designation_id' => $r->designation_id ? (int) $r->designation_id : null,
            'qualification' => (string) ($r->qualification ?? ''),
            'experience' => (string) ($r->experience ?? ''),
            'description' => (string) ($r->description ?? ''),
            'locations' => (string) ($r->locations ?? ''),
            'publish_portal' => (int) ($r->publish_portal ?? 0) === 1,
            'opening_date' => $r->opening_date,
            'closing_date' => $r->closing_date,
            'status' => (int) $r->status,
            'status_label' => match ((int) $r->status) {
                2 => 'Closed',
                3 => 'Cancelled',
                default => 'Active',
            },
            'reference_number' => property_exists($r, 'reference_number') ? (string) ($r->reference_number ?? '') : '',
            'hiring_manager_id' => isset($r->hiring_manager_id) && $r->hiring_manager_id ? (int) $r->hiring_manager_id : null,
            'details' => property_exists($r, 'details_json')
                ? (json_decode((string) ($r->details_json ?? '{}'), true) ?: [])
                : [],
        ];
    }

    protected function mapApplication(object $r): array
    {
        return [
            'id' => (int) $r->id,
            'candidate_id' => (int) $r->candidate_id,
            'candidate_name' => (string) ($r->candidate_name ?? ''),
            'candidate_email' => (string) ($r->candidate_email ?? ''),
            'candidate_phone' => (string) ($r->candidate_phone ?? ''),
            'post_id' => $r->post_id ? (int) $r->post_id : null,
            'post_title' => (string) ($r->post_title ?? ''),
            'source' => (string) ($r->source ?? 'manual'),
            'stage' => (int) $r->stage,
            'application_stage' => (int) $r->application_stage,
            'is_favorite' => (int) ($r->is_favorite ?? 0) === 1,
            'status' => (int) $r->status,
            'notes' => (string) ($r->notes ?? ''),
            'checkr_status' => (string) ($r->checkr_status ?? ''),
            'created_at' => (string) ($r->created_at ?? ''),
        ];
    }
}
