<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class TerminationController extends Controller
{
    public function meta()
    {
        $employees = [];
        if (Schema::hasTable('employee')) {
            $employees = DB::table('employee')->where('status', '>', 0)->orderBy('name')
                ->get(['employee_id', 'name', 'employee_code'])->map(fn ($r) => [
                    'id' => (int) $r->employee_id,
                    'name' => (string) $r->name,
                    'code' => (string) ($r->employee_code ?? ''),
                ])->all();
        }

        return response()->json([
            'success' => true,
            'options' => [
                'employees' => $employees,
                'types' => [
                    ['id' => 'Misconduct', 'name' => 'Misconduct'],
                    ['id' => 'Others', 'name' => 'Others'],
                    ['id' => 'Performance', 'name' => 'Performance'],
                    ['id' => 'Redundancy', 'name' => 'Redundancy'],
                    ['id' => 'End of Contract', 'name' => 'End of Contract'],
                ],
            ],
        ]);
    }

    public function index()
    {
        if (!Schema::hasTable('termination')) {
            return response()->json(['success' => false, 'message' => 'Run database/22_goals_termination_loan.sql'], 503);
        }
        $rows = DB::table('termination as t')
            ->leftJoin('employee as e', 'e.employee_id', '=', 't.employee')
            ->leftJoin('department as d', 'd.department_id', '=', 'e.department')
            ->orderByDesc('t.id')
            ->get([
                't.*',
                'e.name as employee_name',
                'e.employee_code',
                'd.name as department_name',
            ])
            ->map(fn ($r) => [
                'id' => (int) $r->id,
                'employee_id' => (int) $r->employee,
                'employee_name' => (string) ($r->employee_name ?? ''),
                'employee_code' => (string) ($r->employee_code ?? ''),
                'department_name' => (string) ($r->department_name ?? ''),
                'termination_type' => (string) ($r->termination_type ?? ''),
                'termination_date' => $r->termination_date,
                'notice_date' => $r->notice_date,
                'reason' => (string) ($r->reason ?? ''),
            ]);

        return response()->json(['success' => true, 'rows' => $rows]);
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
        DB::table('termination')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    protected function upsert(Request $request, ?int $id)
    {
        if (!Schema::hasTable('termination')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }
        $data = $request->validate([
            'employee_id' => 'required|integer',
            'termination_type' => 'nullable|string|max:100',
            'termination_date' => 'required|date',
            'notice_date' => 'nullable|date',
            'reason' => 'nullable|string',
            'deactivate_employee' => 'nullable|boolean',
        ]);
        $claims = $request->attributes->get('hr_claims') ?? [];
        $payload = [
            'employee' => (int) $data['employee_id'],
            'termination_type' => $data['termination_type'] ?? 'Others',
            'termination_date' => $data['termination_date'],
            'notice_date' => $data['notice_date'] ?? null,
            'reason' => $data['reason'] ?? null,
        ];

        $newId = DB::transaction(function () use ($id, $payload, $claims, $data) {
            if ($id === null) {
                $payload['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
                $tid = (int) DB::table('termination')->insertGetId($payload);
            } else {
                DB::table('termination')->where('id', $id)->update($payload);
                $tid = $id;
            }

            $deactivate = array_key_exists('deactivate_employee', $data)
                ? (bool) $data['deactivate_employee']
                : ($id === null);
            if ($deactivate && Schema::hasTable('employee')) {
                $upd = ['status' => 0];
                if (Schema::hasColumn('employee', 'leaving_date')) {
                    $upd['leaving_date'] = $payload['termination_date'];
                } elseif (Schema::hasColumn('employee', 'exit_date')) {
                    $upd['exit_date'] = $payload['termination_date'];
                }
                DB::table('employee')->where('employee_id', $payload['employee'])->update($upd);
            }

            return $tid;
        });

        return response()->json(['success' => true, 'id' => $newId]);
    }
}
