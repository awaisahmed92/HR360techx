<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class LoanApplicationController extends Controller
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
                'statuses' => [
                    ['id' => 'pending', 'name' => 'Pending'],
                    ['id' => 'approved', 'name' => 'Approved'],
                    ['id' => 'rejected', 'name' => 'Rejected'],
                ],
            ],
        ]);
    }

    public function index(Request $request)
    {
        if (!Schema::hasTable('loan_application')) {
            return response()->json(['success' => false, 'message' => 'Run database/22_goals_termination_loan.sql'], 503);
        }
        $q = DB::table('loan_application as la')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'la.employee')
            ->orderByDesc('la.id')
            ->select('la.*', 'e.name as employee_name', 'e.employee_code');

        if ($request->filled('status')) {
            $q->where('la.status', $request->query('status'));
        }
        if ($request->filled('employee_id')) {
            $q->where('la.employee', (int) $request->query('employee_id'));
        }

        $rows = $q->limit(300)->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'employee_id' => (int) $r->employee,
            'employee_name' => (string) ($r->employee_name ?? ''),
            'employee_code' => (string) ($r->employee_code ?? ''),
            'loan_amount' => (float) $r->loan_amount,
            'purpose_of_loan' => (string) ($r->purpose_of_loan ?? ''),
            'start_date' => $r->start_date,
            'end_date' => $r->end_date,
            'status' => (string) ($r->status ?? 'pending'),
            'status_label' => ucfirst((string) ($r->status ?? 'pending')),
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
        DB::table('loan_application')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function setStatus(Request $request, int $id)
    {
        $data = $request->validate([
            'status' => 'required|in:pending,approved,rejected',
        ]);
        $row = DB::table('loan_application')->where('id', $id)->first();
        if (!$row) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }
        DB::table('loan_application')->where('id', $id)->update(['status' => $data['status']]);

        return response()->json(['success' => true]);
    }

    protected function upsert(Request $request, ?int $id)
    {
        if (!Schema::hasTable('loan_application')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }
        $data = $request->validate([
            'employee_id' => 'required|integer',
            'loan_amount' => 'required|numeric|min:0',
            'purpose_of_loan' => 'nullable|string',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'status' => 'nullable|in:pending,approved,rejected',
        ]);
        $claims = $request->attributes->get('hr_claims') ?? [];
        $payload = [
            'employee' => (int) $data['employee_id'],
            'loan_amount' => (float) $data['loan_amount'],
            'purpose_of_loan' => $data['purpose_of_loan'] ?? null,
            'start_date' => $data['start_date'],
            'end_date' => $data['end_date'],
            'status' => $data['status'] ?? 'pending',
        ];
        if ($id === null) {
            $payload['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
            $newId = (int) DB::table('loan_application')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('loan_application')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }
}
