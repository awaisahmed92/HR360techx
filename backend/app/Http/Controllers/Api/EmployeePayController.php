<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class EmployeePayController extends Controller
{
    public function show(int $id)
    {
        $emp = DB::table('employee as e')
            ->leftJoin('designation as d', 'd.designation_id', '=', 'e.designation')
            ->where('e.employee_id', $id)
            ->first(['e.employee_id', 'e.name', 'e.user_name', 'd.name as job_title']);
        if (!$emp) {
            return response()->json(['success' => false, 'message' => 'Not found.'], 404);
        }

        $pay = Schema::hasTable('hr_employee_pay')
            ? DB::table('hr_employee_pay')->where('employee_id', $id)->first()
            : null;

        $banks = Schema::hasTable('hr_employee_bank')
            ? DB::table('hr_employee_bank')->where('employee_id', $id)->orderByDesc('is_primary')->get()
            : collect();

        $define = Schema::hasTable('define_salary')
            ? DB::table('define_salary')->where('employee_id', $id)->orderByDesc('id')->first()
            : null;

        return response()->json([
            'success' => true,
            'employee' => [
                'employee_id' => (int) $emp->employee_id,
                'name' => (string) $emp->name,
                'user_name' => (string) ($emp->user_name ?? ''),
                'job_title' => (string) ($emp->job_title ?? ''),
            ],
            'pay' => $this->mapPay($pay, $id),
            'banks' => $banks->map(fn ($b) => [
                'id' => (int) $b->id,
                'bank_name' => (string) $b->bank_name,
                'account_number' => (string) $b->account_number,
                'iban' => (string) ($b->iban ?? ''),
                'is_primary' => (int) $b->is_primary === 1,
            ])->values()->all(),
            'define_salary' => $define ? [
                'id' => (int) $define->id,
                'basic_salary' => (float) $define->basic_salary,
                'net_salary' => (float) $define->net_salary,
                'project_id' => (int) $define->project_id,
            ] : null,
        ]);
    }

    public function save(Request $request, int $id)
    {
        if (!DB::table('employee')->where('employee_id', $id)->exists()) {
            return response()->json(['success' => false, 'message' => 'Not found.'], 404);
        }
        if (!Schema::hasTable('hr_employee_pay')) {
            return response()->json(['success' => false, 'message' => 'Run database/14_remaining_phase3.sql'], 503);
        }

        $data = $request->validate([
            'payroll_setup' => 'nullable|string|max:80',
            'salary_type' => 'nullable|string|max:40',
            'currency' => 'nullable|string|max:10',
            'hours_per_week' => 'nullable|numeric',
            'annual_salary' => 'nullable|numeric',
            'gross_salary' => 'nullable|numeric',
            'hourly_salary' => 'nullable|numeric',
            'ot_hourly_salary' => 'nullable|numeric',
            'bonus_entitlement' => 'nullable|numeric',
            'residency_status' => 'nullable|string|max:40',
            'exclude_from_tax' => 'nullable|boolean',
            'prev_months' => 'nullable|integer',
            'prev_taxable' => 'nullable|numeric',
            'prev_tax' => 'nullable|numeric',
            'payment_method' => 'nullable|string|max:40',
            'salary_allocation_by' => 'nullable|string|max:40',
        ]);

        $payload = [
            'employee_id' => $id,
            'payroll_setup' => $data['payroll_setup'] ?? 'General Payroll',
            'salary_type' => $data['salary_type'] ?? 'Salary',
            'currency' => $data['currency'] ?? 'PKR',
            'hours_per_week' => (float) ($data['hours_per_week'] ?? 0),
            'annual_salary' => (float) ($data['annual_salary'] ?? 0),
            'gross_salary' => (float) ($data['gross_salary'] ?? 0),
            'hourly_salary' => (float) ($data['hourly_salary'] ?? 0),
            'ot_hourly_salary' => (float) ($data['ot_hourly_salary'] ?? 0),
            'bonus_entitlement' => (float) ($data['bonus_entitlement'] ?? 0),
            'residency_status' => $data['residency_status'] ?? 'Resident',
            'exclude_from_tax' => !empty($data['exclude_from_tax']) ? 1 : 0,
            'prev_months' => (int) ($data['prev_months'] ?? 0),
            'prev_taxable' => (float) ($data['prev_taxable'] ?? 0),
            'prev_tax' => (float) ($data['prev_tax'] ?? 0),
            'payment_method' => $data['payment_method'] ?? 'Manual',
            'salary_allocation_by' => $data['salary_allocation_by'] ?? null,
        ];

        $exists = DB::table('hr_employee_pay')->where('employee_id', $id)->exists();
        if ($exists) {
            unset($payload['employee_id']);
            DB::table('hr_employee_pay')->where('employee_id', $id)->update($payload);
        } else {
            DB::table('hr_employee_pay')->insert($payload);
        }

        // Sync gross/annual into latest define_salary basic when present
        if (Schema::hasTable('define_salary')) {
            $gross = (float) ($payload['gross_salary'] ?? $data['gross_salary'] ?? 0);
            $annual = (float) ($payload['annual_salary'] ?? $data['annual_salary'] ?? 0);
            $basic = $gross > 0 ? $gross : ($annual > 0 ? round($annual / 12, 2) : 0);
            if ($basic > 0) {
                $def = DB::table('define_salary')->where('employee_id', $id)->orderByDesc('id')->first();
                if ($def) {
                    $allow = (float) $def->total_allowance;
                    $deduct = (float) $def->total_deduction;
                    // Keep allowances; rebase basic & net
                    $netAllow = max($allow, $basic);
                    DB::table('define_salary')->where('id', $def->id)->update([
                        'basic_salary' => $basic,
                        'total_allowance' => $netAllow,
                        'net_salary' => $netAllow - $deduct,
                    ]);
                }
            }
        }

        return response()->json(['success' => true, 'message' => 'Saved.', 'pay' => $this->mapPay(
            DB::table('hr_employee_pay')->where('employee_id', $id)->first(),
            $id
        )]);
    }

    public function saveBank(Request $request, int $id)
    {
        $data = $request->validate([
            'bank_name' => 'required|string|max:120',
            'account_number' => 'required|string|max:60',
            'iban' => 'nullable|string|max:40',
            'is_primary' => 'nullable|boolean',
        ]);
        if (!empty($data['is_primary'])) {
            DB::table('hr_employee_bank')->where('employee_id', $id)->update(['is_primary' => 0]);
        }
        $newId = DB::table('hr_employee_bank')->insertGetId([
            'employee_id' => $id,
            'bank_name' => $data['bank_name'],
            'account_number' => $data['account_number'],
            'iban' => $data['iban'] ?? null,
            'is_primary' => !empty($data['is_primary']) ? 1 : 0,
        ]);

        return response()->json(['success' => true, 'id' => $newId]);
    }

    public function deleteBank(int $id, int $bankId)
    {
        DB::table('hr_employee_bank')->where('employee_id', $id)->where('id', $bankId)->delete();

        return response()->json(['success' => true]);
    }

    protected function mapPay(?object $pay, int $employeeId): array
    {
        if (!$pay) {
            return [
                'employee_id' => $employeeId,
                'payroll_setup' => 'General Payroll',
                'salary_type' => 'Salary',
                'currency' => 'PKR',
                'hours_per_week' => 0,
                'annual_salary' => 0,
                'gross_salary' => 0,
                'hourly_salary' => 0,
                'ot_hourly_salary' => 0,
                'bonus_entitlement' => 0,
                'residency_status' => 'Resident',
                'exclude_from_tax' => false,
                'prev_months' => 0,
                'prev_taxable' => 0,
                'prev_tax' => 0,
                'payment_method' => 'Manual',
                'salary_allocation_by' => null,
            ];
        }

        return [
            'employee_id' => $employeeId,
            'payroll_setup' => (string) ($pay->payroll_setup ?? 'General Payroll'),
            'salary_type' => (string) ($pay->salary_type ?? 'Salary'),
            'currency' => (string) ($pay->currency ?? 'PKR'),
            'hours_per_week' => (float) ($pay->hours_per_week ?? 0),
            'annual_salary' => (float) ($pay->annual_salary ?? 0),
            'gross_salary' => (float) ($pay->gross_salary ?? 0),
            'hourly_salary' => (float) ($pay->hourly_salary ?? 0),
            'ot_hourly_salary' => (float) ($pay->ot_hourly_salary ?? 0),
            'bonus_entitlement' => (float) ($pay->bonus_entitlement ?? 0),
            'residency_status' => (string) ($pay->residency_status ?? 'Resident'),
            'exclude_from_tax' => (int) ($pay->exclude_from_tax ?? 0) === 1,
            'prev_months' => (int) ($pay->prev_months ?? 0),
            'prev_taxable' => (float) ($pay->prev_taxable ?? 0),
            'prev_tax' => (float) ($pay->prev_tax ?? 0),
            'payment_method' => (string) ($pay->payment_method ?? 'Manual'),
            'salary_allocation_by' => $pay->salary_allocation_by,
        ];
    }
}
