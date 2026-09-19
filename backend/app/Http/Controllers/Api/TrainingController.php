<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class TrainingController extends Controller
{
    public function meta()
    {
        return response()->json([
            'success' => true,
            'options' => [
                'types' => $this->typeOptions(),
                'trainers' => $this->trainerOptions(),
                'employees' => $this->employeeOptions(),
                'statuses' => [
                    ['id' => 'Scheduled', 'name' => 'Scheduled'],
                    ['id' => 'In Progress', 'name' => 'In Progress'],
                    ['id' => 'Completed', 'name' => 'Completed'],
                    ['id' => 'Cancelled', 'name' => 'Cancelled'],
                ],
            ],
        ]);
    }

    public function index(Request $request)
    {
        if (!Schema::hasTable('training')) {
            return response()->json(['success' => false, 'message' => 'Run database/21_training_mvp.sql'], 503);
        }

        $q = DB::table('training as t')
            ->leftJoin('training_type as tt', 'tt.id', '=', 't.training_type_id')
            ->leftJoin('trainers as tr', 'tr.id', '=', 't.trainer_id')
            ->leftJoin('employee as e', 'e.employee_id', '=', 't.employee_id')
            ->select(
                't.*',
                'tt.name as training_type_name',
                'tt.is_mandatory',
                'tr.first_name as trainer_first_name',
                'tr.last_name as trainer_last_name',
                'e.name as lead_name',
                DB::raw('(SELECT COUNT(*) FROM training_participants tp WHERE tp.training_id = t.id) as attendee_count'),
                DB::raw('(SELECT COUNT(*) FROM training_participants tp WHERE tp.training_id = t.id AND tp.completed = 1) as completed_count')
            )
            ->orderByDesc('t.id');

        if ($request->filled('from')) {
            $q->whereDate('t.start_date', '>=', $request->query('from'));
        }
        if ($request->filled('to')) {
            $q->whereDate('t.start_date', '<=', $request->query('to'));
        }
        if ($request->filled('training_type_id')) {
            $q->where('t.training_type_id', (int) $request->query('training_type_id'));
        }
        if ($request->filled('training_status')) {
            $q->where('t.training_status', $request->query('training_status'));
        }

        $rows = $q->limit(300)->get()->map(fn ($r) => $this->mapTraining($r));

        return response()->json(['success' => true, 'trainings' => $rows]);
    }

    public function show(int $id)
    {
        if (!Schema::hasTable('training')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }
        $r = DB::table('training as t')
            ->leftJoin('training_type as tt', 'tt.id', '=', 't.training_type_id')
            ->leftJoin('trainers as tr', 'tr.id', '=', 't.trainer_id')
            ->leftJoin('employee as e', 'e.employee_id', '=', 't.employee_id')
            ->where('t.id', $id)
            ->first([
                't.*',
                'tt.name as training_type_name',
                'tt.is_mandatory',
                'tr.first_name as trainer_first_name',
                'tr.last_name as trainer_last_name',
                'e.name as lead_name',
            ]);
        if (!$r) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }
        $row = $this->mapTraining($r);
        $row['participants'] = $this->participantsFor($id);
        $row['participant_ids'] = array_map(fn ($p) => $p['employee_id'], $row['participants']);

        return response()->json(['success' => true, 'training' => $row]);
    }

    public function store(Request $request)
    {
        return $this->upsert($request, null);
    }

    public function update(Request $request, int $id)
    {
        return $this->upsert($request, $id);
    }

    public function destroy(int $id)
    {
        if (!Schema::hasTable('training')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }
        DB::transaction(function () use ($id) {
            if (Schema::hasTable('training_participants')) {
                DB::table('training_participants')->where('training_id', $id)->delete();
            }
            if (Schema::hasTable('training_attendance')) {
                DB::table('training_attendance')->where('training_id', $id)->delete();
            }
            DB::table('training')->where('id', $id)->delete();
        });

        return response()->json(['success' => true]);
    }

    public function calendar(Request $request)
    {
        if (!Schema::hasTable('training')) {
            return response()->json(['success' => false, 'message' => 'Run database/21_training_mvp.sql'], 503);
        }
        $from = $request->query('from', now()->startOfMonth()->toDateString());
        $to = $request->query('to', now()->endOfMonth()->toDateString());

        $rows = DB::table('training as t')
            ->leftJoin('training_type as tt', 'tt.id', '=', 't.training_type_id')
            ->leftJoin('trainers as tr', 'tr.id', '=', 't.trainer_id')
            ->whereDate('t.start_date', '>=', $from)
            ->whereDate('t.start_date', '<=', $to)
            ->where(function ($w) {
                $w->where('t.is_cancelled', 0)->orWhereNull('t.is_cancelled');
            })
            ->orderBy('t.start_date')
            ->get([
                't.id',
                't.start_date',
                't.end_date',
                't.batch_name',
                't.venue',
                't.training_status',
                'tt.name as training_type_name',
                'tr.first_name',
                'tr.last_name',
            ])
            ->map(function ($r) {
                $title = (string) ($r->training_type_name ?? 'Training');
                if (!empty($r->batch_name)) {
                    $title .= ' ('.$r->batch_name.')';
                }

                return [
                    'id' => (int) $r->id,
                    'title' => $title,
                    'start_date' => $r->start_date,
                    'end_date' => $r->end_date,
                    'venue' => (string) ($r->venue ?? ''),
                    'status' => (string) ($r->training_status ?? 'Scheduled'),
                    'trainer' => trim(($r->first_name ?? '').' '.($r->last_name ?? '')),
                ];
            });

        return response()->json(['success' => true, 'from' => $from, 'to' => $to, 'events' => $rows]);
    }

    public function typesIndex()
    {
        if (!Schema::hasTable('training_type')) {
            return response()->json(['success' => false, 'message' => 'Run database/21_training_mvp.sql'], 503);
        }
        $rows = DB::table('training_type')->orderBy('name')->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'name' => (string) $r->name,
            'category' => (string) ($r->category ?? ''),
            'renewal_months' => $r->renewal_months !== null ? (int) $r->renewal_months : null,
            'is_mandatory' => (int) ($r->is_mandatory ?? 0) === 1,
            'description' => (string) ($r->description ?? ''),
            'status' => (int) ($r->status ?? 1),
        ]);

        return response()->json(['success' => true, 'types' => $rows]);
    }

    public function typesStore(Request $request)
    {
        return $this->typeUpsert($request, null);
    }

    public function typesUpdate(Request $request, int $id)
    {
        return $this->typeUpsert($request, $id);
    }

    public function typesDelete(int $id)
    {
        DB::table('training_type')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function trainersIndex()
    {
        if (!Schema::hasTable('trainers')) {
            return response()->json(['success' => false, 'message' => 'Run database/21_training_mvp.sql'], 503);
        }
        $rows = DB::table('trainers')->orderByDesc('id')->get()->map(fn ($r) => $this->mapTrainer($r));

        return response()->json(['success' => true, 'trainers' => $rows]);
    }

    public function trainersStore(Request $request)
    {
        return $this->trainerUpsert($request, null);
    }

    public function trainersUpdate(Request $request, int $id)
    {
        return $this->trainerUpsert($request, $id);
    }

    public function trainersDelete(int $id)
    {
        DB::table('trainers')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function markComplete(Request $request, int $id)
    {
        $data = $request->validate([
            'employee_id' => 'required|integer',
            'completed' => 'nullable|boolean',
        ]);
        $completed = array_key_exists('completed', $data) ? (bool) $data['completed'] : true;
        $payload = [
            'completed' => $completed ? 1 : 0,
            'completion_date' => $completed ? now()->toDateString() : null,
        ];
        DB::table('training_participants')
            ->where('training_id', $id)
            ->where('employee_id', (int) $data['employee_id'])
            ->update($payload);

        return response()->json(['success' => true]);
    }

    protected function upsert(Request $request, ?int $id)
    {
        if (!Schema::hasTable('training')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }
        $data = $request->validate([
            'training_type_id' => 'nullable|integer',
            'trainer_id' => 'nullable|integer',
            'employee_id' => 'nullable|integer',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'cost' => 'nullable|numeric',
            'description' => 'nullable|string',
            'venue' => 'nullable|string|max:255',
            'training_status' => 'nullable|string|max:30',
            'batch_name' => 'nullable|string|max:255',
            'agenda' => 'nullable|string',
            'materials' => 'nullable|string',
            'fund_source' => 'nullable|string|max:255',
            'cost_travel' => 'nullable|numeric',
            'cost_venue' => 'nullable|numeric',
            'cost_materials' => 'nullable|numeric',
            'cost_trainer_fee' => 'nullable|numeric',
            'participant_ids' => 'nullable|array',
            'participant_ids.*' => 'integer',
        ]);

        $claims = $request->attributes->get('hr_claims') ?? [];
        $payload = [
            'training_type_id' => $data['training_type_id'] ?? null,
            'trainer_id' => $data['trainer_id'] ?? null,
            'employee_id' => $data['employee_id'] ?? null,
            'start_date' => $data['start_date'] ?? null,
            'end_date' => $data['end_date'] ?? null,
            'cost' => (float) ($data['cost'] ?? 0),
            'description' => $data['description'] ?? null,
            'venue' => $data['venue'] ?? null,
            'training_status' => $data['training_status'] ?? 'Scheduled',
            'batch_name' => $data['batch_name'] ?? null,
            'agenda' => $data['agenda'] ?? null,
            'materials' => $data['materials'] ?? null,
            'fund_source' => $data['fund_source'] ?? null,
            'cost_travel' => (float) ($data['cost_travel'] ?? 0),
            'cost_venue' => (float) ($data['cost_venue'] ?? 0),
            'cost_materials' => (float) ($data['cost_materials'] ?? 0),
            'cost_trainer_fee' => (float) ($data['cost_trainer_fee'] ?? 0),
            'is_cancelled' => ($data['training_status'] ?? '') === 'Cancelled' ? 1 : 0,
        ];

        $participantIds = array_values(array_unique(array_map('intval', $data['participant_ids'] ?? [])));

        $newId = DB::transaction(function () use ($id, $payload, $participantIds, $claims) {
            if ($id === null) {
                $payload['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
                $payload['status'] = 1;
                $tid = (int) DB::table('training')->insertGetId($payload);
            } else {
                DB::table('training')->where('id', $id)->update($payload);
                $tid = $id;
            }
            $this->syncParticipants($tid, $participantIds);

            return $tid;
        });

        return response()->json(['success' => true, 'id' => $newId]);
    }

    protected function typeUpsert(Request $request, ?int $id)
    {
        $data = $request->validate([
            'name' => 'required|string|max:191',
            'category' => 'nullable|string|max:100',
            'renewal_months' => 'nullable|integer',
            'is_mandatory' => 'nullable|boolean',
            'description' => 'nullable|string',
            'status' => 'nullable|integer',
        ]);
        $payload = [
            'name' => $data['name'],
            'category' => $data['category'] ?? null,
            'renewal_months' => $data['renewal_months'] ?? null,
            'is_mandatory' => !empty($data['is_mandatory']) ? 1 : 0,
            'description' => $data['description'] ?? null,
            'status' => (int) ($data['status'] ?? 1),
        ];
        if ($id === null) {
            $newId = (int) DB::table('training_type')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('training_type')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    protected function trainerUpsert(Request $request, ?int $id)
    {
        $data = $request->validate([
            'first_name' => 'required|string|max:100',
            'last_name' => 'nullable|string|max:100',
            'role' => 'nullable|string|max:100',
            'internal_external' => 'nullable|string|max:20',
            'department_id' => 'nullable|integer',
            'email' => 'nullable|email|max:191',
            'phone' => 'nullable|string|max:40',
            'description' => 'nullable|string',
            'status' => 'nullable|integer',
        ]);
        $payload = [
            'first_name' => $data['first_name'],
            'last_name' => $data['last_name'] ?? null,
            'role' => $data['role'] ?? null,
            'internal_external' => $data['internal_external'] ?? 'internal',
            'department_id' => $data['department_id'] ?? null,
            'email' => $data['email'] ?? null,
            'phone' => $data['phone'] ?? null,
            'description' => $data['description'] ?? null,
            'status' => (int) ($data['status'] ?? 1),
        ];
        if ($id === null) {
            $newId = (int) DB::table('trainers')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('trainers')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    protected function syncParticipants(int $trainingId, array $employeeIds): void
    {
        if (!Schema::hasTable('training_participants')) {
            return;
        }
        DB::table('training_participants')->where('training_id', $trainingId)->delete();
        $now = now()->toDateString();
        foreach ($employeeIds as $eid) {
            if ($eid <= 0) {
                continue;
            }
            DB::table('training_participants')->insert([
                'training_id' => $trainingId,
                'employee_id' => $eid,
                'enrollment_date' => $now,
                'completed' => 0,
            ]);
        }
    }

    protected function participantsFor(int $trainingId): array
    {
        if (!Schema::hasTable('training_participants')) {
            return [];
        }

        return DB::table('training_participants as tp')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'tp.employee_id')
            ->where('tp.training_id', $trainingId)
            ->orderBy('e.name')
            ->get(['tp.employee_id', 'e.name', 'tp.completed', 'tp.enrollment_date', 'tp.completion_date'])
            ->map(fn ($r) => [
                'employee_id' => (int) $r->employee_id,
                'name' => (string) ($r->name ?? ''),
                'completed' => (int) ($r->completed ?? 0) === 1,
                'enrollment_date' => $r->enrollment_date,
                'completion_date' => $r->completion_date,
            ])->all();
    }

    protected function mapTraining(object $r): array
    {
        $trainer = trim(($r->trainer_first_name ?? '').' '.($r->trainer_last_name ?? ''));

        return [
            'id' => (int) $r->id,
            'training_type_id' => $r->training_type_id ? (int) $r->training_type_id : null,
            'training_type_name' => (string) ($r->training_type_name ?? ''),
            'is_mandatory' => (int) ($r->is_mandatory ?? 0) === 1,
            'trainer_id' => $r->trainer_id ? (int) $r->trainer_id : null,
            'trainer_name' => $trainer,
            'employee_id' => $r->employee_id ? (int) $r->employee_id : null,
            'lead_name' => (string) ($r->lead_name ?? ''),
            'start_date' => $r->start_date,
            'end_date' => $r->end_date,
            'cost' => (float) ($r->cost ?? 0),
            'description' => (string) ($r->description ?? ''),
            'venue' => (string) ($r->venue ?? ''),
            'training_status' => (string) ($r->training_status ?? 'Scheduled'),
            'batch_name' => (string) ($r->batch_name ?? ''),
            'agenda' => (string) ($r->agenda ?? ''),
            'materials' => (string) ($r->materials ?? ''),
            'fund_source' => (string) ($r->fund_source ?? ''),
            'cost_travel' => (float) ($r->cost_travel ?? 0),
            'cost_venue' => (float) ($r->cost_venue ?? 0),
            'cost_materials' => (float) ($r->cost_materials ?? 0),
            'cost_trainer_fee' => (float) ($r->cost_trainer_fee ?? 0),
            'attendee_count' => (int) ($r->attendee_count ?? 0),
            'completed_count' => (int) ($r->completed_count ?? 0),
        ];
    }

    protected function mapTrainer(object $r): array
    {
        return [
            'id' => (int) $r->id,
            'first_name' => (string) $r->first_name,
            'last_name' => (string) ($r->last_name ?? ''),
            'name' => trim($r->first_name.' '.($r->last_name ?? '')),
            'role' => (string) ($r->role ?? ''),
            'internal_external' => (string) ($r->internal_external ?? 'internal'),
            'department_id' => $r->department_id ? (int) $r->department_id : null,
            'email' => (string) ($r->email ?? ''),
            'phone' => (string) ($r->phone ?? ''),
            'description' => (string) ($r->description ?? ''),
            'status' => (int) ($r->status ?? 1),
        ];
    }

    protected function typeOptions(): array
    {
        if (!Schema::hasTable('training_type')) {
            return [];
        }

        return DB::table('training_type')->where('status', 1)->orderBy('name')
            ->get(['id', 'name'])->map(fn ($r) => [
                'id' => (int) $r->id,
                'name' => (string) $r->name,
            ])->all();
    }

    protected function trainerOptions(): array
    {
        if (!Schema::hasTable('trainers')) {
            return [];
        }

        return DB::table('trainers')->where('status', 1)->orderBy('first_name')
            ->get(['id', 'first_name', 'last_name'])->map(fn ($r) => [
                'id' => (int) $r->id,
                'name' => trim($r->first_name.' '.($r->last_name ?? '')),
            ])->all();
    }

    protected function employeeOptions(): array
    {
        if (!Schema::hasTable('employee')) {
            return [];
        }

        return DB::table('employee')->where('status', '>', 0)->orderBy('name')
            ->get(['employee_id', 'name'])->map(fn ($r) => [
                'id' => (int) $r->employee_id,
                'name' => (string) $r->name,
            ])->all();
    }
}
