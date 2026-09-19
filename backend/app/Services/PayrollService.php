<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Phase 3 payroll: define salary (per employee+project), process monthly run,
 * PK tax slabs + EOBI.
 */
class PayrollService
{
    public function listDefines(?int $projectId = null): array
    {
        if (!Schema::hasTable('define_salary')) {
            return [];
        }
        $q = DB::table('define_salary as d')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'd.employee_id')
            ->leftJoin('project as p', 'p.project_id', '=', 'd.project_id')
            ->leftJoin('station as s', 's.station_id', '=', 'd.station_id')
            ->select(
                'd.*',
                'e.name as employee_name',
                'p.name as project_name',
                's.name as station_name'
            )
            ->orderByDesc('d.id');
        if ($projectId) {
            $q->where('d.project_id', $projectId);
        }

        return $q->get()->map(fn ($r) => $this->mapDefine($r))->all();
    }

    public function getDefine(int $id): ?array
    {
        $row = DB::table('define_salary as d')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'd.employee_id')
            ->leftJoin('project as p', 'p.project_id', '=', 'd.project_id')
            ->leftJoin('station as s', 's.station_id', '=', 'd.station_id')
            ->select('d.*', 'e.name as employee_name', 'p.name as project_name', 's.name as station_name')
            ->where('d.id', $id)
            ->first();
        if (!$row) {
            return null;
        }
        $out = $this->mapDefine($row);
        $out['items'] = DB::table('define_salary_details as dd')
            ->leftJoin('hr_payroll_item as i', 'i.id', '=', 'dd.payroll_item_id')
            ->where('dd.define_salary_id', $id)
            ->get(['dd.*', 'i.name as item_name', 'i.code as item_code', 'i.category'])
            ->map(fn ($d) => [
                'id' => (int) $d->id,
                'payroll_item_id' => (int) $d->payroll_item_id,
                'item_name' => (string) ($d->item_name ?? ''),
                'item_code' => (string) ($d->item_code ?? ''),
                'category' => (string) ($d->category ?? ''),
                'allowance' => (float) $d->allowance,
                'deduction' => (float) $d->deduction,
            ])
            ->all();

        return $out;
    }

    /**
     * @param array{employee_id:int,project_id:int,station_id?:int,basic_salary:float,items?:list<array>} $data
     */
    public function saveDefine(array $data, int $actorId, ?int $id = null): array
    {
        $employeeId = (int) $data['employee_id'];
        $projectId = (int) ($data['project_id'] ?? 1);
        $stationId = (int) ($data['station_id'] ?? 1);
        $basic = (float) ($data['basic_salary'] ?? 0);
        $items = $data['items'] ?? [];
        $applyFormulas = !array_key_exists('apply_formulas', $data) || !empty($data['apply_formulas']);
        if ($applyFormulas) {
            $items = $this->applySetupFormulas($basic, $items);
        }

        $allowTotal = 0.0;
        $deductTotal = 0.0;
        $normalized = [];
        foreach ($items as $it) {
            $a = (float) ($it['allowance'] ?? 0);
            $d = (float) ($it['deduction'] ?? 0);
            $pid = (int) ($it['payroll_item_id'] ?? 0);
            if ($pid < 1) {
                continue;
            }
            $allowTotal += $a;
            $deductTotal += $d;
            $normalized[] = ['payroll_item_id' => $pid, 'allowance' => $a, 'deduction' => $d];
        }

        // Basic counted in gross; if no BASIC line, treat basic as earning
        $gross = max($basic, $allowTotal);
        if ($allowTotal < $basic) {
            $allowTotal = $basic;
            $gross = $basic;
        }
        $net = $gross - $deductTotal;

        $payload = [
            'station_id' => $stationId,
            'project_id' => $projectId,
            'employee_id' => $employeeId,
            'basic_salary' => $basic,
            'total_allowance' => $allowTotal,
            'total_deduction' => $deductTotal,
            'net_salary' => $net,
            'created_by' => $actorId,
        ];

        if ($id) {
            unset($payload['created_by']);
            DB::table('define_salary')->where('id', $id)->update($payload);
            DB::table('define_salary_details')->where('define_salary_id', $id)->delete();
            $defineId = $id;
        } else {
            // Upsert by unique employee+project+station
            $existing = DB::table('define_salary')
                ->where('employee_id', $employeeId)
                ->where('project_id', $projectId)
                ->where('station_id', $stationId)
                ->value('id');
            if ($existing) {
                unset($payload['created_by']);
                DB::table('define_salary')->where('id', $existing)->update($payload);
                DB::table('define_salary_details')->where('define_salary_id', $existing)->delete();
                $defineId = (int) $existing;
            } else {
                $defineId = (int) DB::table('define_salary')->insertGetId($payload);
            }
        }

        foreach ($normalized as $n) {
            DB::table('define_salary_details')->insert([
                'define_salary_id' => $defineId,
                'payroll_item_id' => $n['payroll_item_id'],
                'allowance' => $n['allowance'],
                'deduction' => $n['deduction'],
            ]);
        }

        return $this->getDefine($defineId) ?? ['id' => $defineId];
    }

    public function deleteDefine(int $id): void
    {
        DB::table('define_salary_details')->where('define_salary_id', $id)->delete();
        DB::table('define_salary')->where('id', $id)->delete();
    }

    /**
     * Process salary for a project for a given month-end date.
     * @return array{count:int,runs:list}
     */
    public function processProject(int $projectId, string $date, int $days, int $actorId): array
    {
        $defines = DB::table('define_salary')->where('project_id', $projectId)->get();
        $runs = [];
        foreach ($defines as $def) {
            $runs[] = $this->processOne($def, $date, $days, $actorId);
        }

        return ['count' => count($runs), 'runs' => $runs];
    }

    protected function processOne(object $def, string $date, int $days, int $actorId): array
    {
        $setup = $this->getSetup();
        $employeeId = (int) $def->employee_id;
        $fullBasic = (float) $def->basic_salary;

        // Join/exit proration → effective payable days
        $effectiveDays = $this->effectiveDaysForEmployee($employeeId, $date, $days, $setup);
        $factor = max(0, min(31, $effectiveDays)) / 30.0;

        $basic = round($fullBasic * $factor, 2);
        $allow = round((float) $def->total_allowance * $factor, 2);
        $deductBase = round((float) $def->total_deduction * $factor, 2);

        $otAmount = !empty($setup['enable_auto_overtime'])
            ? $this->overtimeForEmployee($employeeId, $date, $fullBasic)
            : 0.0;

        $arrears = $this->arrearsForEmployee($employeeId, $date);
        $arrearsAmount = (float) ($arrears['amount'] ?? 0);

        $grossMonthly = ($allow > 0 ? $allow : $basic) + $otAmount + $arrearsAmount;
        $autoAdd = $this->autoAdditionsForEmployee($employeeId, $fullBasic, $grossMonthly);
        $grossMonthly += $autoAdd;
        // PHP calculateTaxMod: monthly → annual progressive → monthly tax
        $excludeTax = false;
        if (Schema::hasTable('hr_employee_pay')) {
            $excludeTax = (int) (DB::table('hr_employee_pay')->where('employee_id', $employeeId)->value('exclude_from_tax') ?? 0) === 1;
        }
        $taxMonthly = $excludeTax ? 0.0 : $this->taxOnMonthly($grossMonthly);
        $eobi = $this->eobiEmployeeAmount();

        $rates = $this->statutoryRates();
        $sessi = 0.0;
        if (!empty($setup['enable_sessi'])) {
            $pct = (float) ($rates['sessi_emp_percent'] ?? $setup['sessi_emp_percent'] ?? 1);
            $fixed = (float) ($rates['sessi_emp_amount'] ?? 0);
            $sessi = $fixed > 0 ? $fixed : round($grossMonthly * ($pct / 100), 2);
        }
        $pf = 0.0;
        if (!empty($setup['enable_pf'])) {
            $pct = (float) ($rates['pf_emp_percent'] ?? $setup['pf_emp_percent'] ?? 0);
            $fixed = (float) ($rates['pf_emp_amount'] ?? 0);
            $pf = $fixed > 0 ? $fixed : round($grossMonthly * ($pct / 100), 2);
        }

        $advance = $this->advanceRecoveryForEmployee($employeeId);
        $advanceAmount = (float) ($advance['amount'] ?? 0);

        $loan = $this->loanRecoveryForEmployee($employeeId);
        $loanAmount = (float) ($loan['amount'] ?? 0);

        $lateAmount = 0.0;
        if (!empty($setup['enable_auto_late'])) {
            $lateAmount = $this->lateDeductionForEmployee($employeeId, $date, $fullBasic);
        }

        $lwpAmount = $this->lwpDeductionForEmployee($employeeId, $date, $fullBasic, $days);

        $totalDeduct = $deductBase + $taxMonthly + $eobi + $sessi + $pf + $advanceAmount + $loanAmount + $lateAmount + $lwpAmount;
        $net = $grossMonthly - $totalDeduct;

        $payload = [
            'project_id' => (int) $def->project_id,
            'employee_id' => $employeeId,
            'days' => $effectiveDays,
            'basic_salary' => $basic,
            'total_allowance' => $grossMonthly,
            'total_deduction' => $totalDeduct,
            'net_salary' => $net,
            'tax_amount' => $taxMonthly,
            'eobi_amount' => $eobi,
            'date' => $date,
            'created_by' => $actorId,
            'created_at' => now(),
        ];
        foreach ([
            'sessi_amount' => $sessi,
            'pf_amount' => $pf,
            'overtime_amount' => $otAmount,
            'advance_amount' => $advanceAmount,
            'late_amount' => $lateAmount,
            'lwp_amount' => $lwpAmount,
            'loan_amount' => $loanAmount,
            'arrears_amount' => $arrearsAmount,
        ] as $col => $val) {
            if (Schema::hasColumn('process_salary', $col)) {
                $payload[$col] = $val;
            }
        }

        $id = (int) DB::table('process_salary')->insertGetId($payload);

        $details = DB::table('define_salary_details')->where('define_salary_id', $def->id)->get();
        foreach ($details as $d) {
            DB::table('process_salary_details')->insert([
                'process_salary_id' => $id,
                'payroll_item_id' => (int) $d->payroll_item_id,
                'allowance' => round((float) $d->allowance * $factor, 2),
                'deduction' => round((float) $d->deduction * $factor, 2),
            ]);
        }

        $this->appendProcessLine($id, 'TAX', 0, $taxMonthly);
        $this->appendProcessLine($id, 'EOBI_E', 0, $eobi);
        if ($sessi > 0) {
            $this->appendProcessLine($id, 'SESSI', 0, $sessi);
        }
        if ($pf > 0) {
            $this->appendProcessLine($id, 'PF', 0, $pf);
        }
        if ($otAmount > 0) {
            $this->appendProcessLine($id, 'OT', $otAmount, 0);
        }
        if ($autoAdd > 0) {
            $this->appendProcessLine($id, 'AUTO_ADD', $autoAdd, 0);
        }
        if ($arrearsAmount > 0) {
            $this->appendProcessLine($id, 'ARREARS', $arrearsAmount, 0);
            $this->markArrearsApplied($arrears['ids'] ?? []);
        }
        if ($advanceAmount > 0) {
            $this->appendProcessLine($id, 'ADV', 0, $advanceAmount);
            $this->applyAdvanceRecoveries($advance['ids'] ?? [], $advance['per_id'] ?? []);
        }
        if ($loanAmount > 0) {
            $this->appendProcessLine($id, 'LOAN', 0, $loanAmount);
            $this->applyLoanRecoveries($loan['ids'] ?? [], $loan['per_id'] ?? []);
        }
        if ($lateAmount > 0) {
            $this->appendProcessLine($id, 'LATE', 0, $lateAmount);
        }
        if ($lwpAmount > 0) {
            $this->appendProcessLine($id, 'LWP', 0, $lwpAmount);
        }

        return $this->mapProcess(DB::table('process_salary')->where('id', $id)->first());
    }

    /** Payable days in month considering joining/exit + setup proration mode. */
    protected function effectiveDaysForEmployee(int $employeeId, string $payDate, int $requestedDays, array $setup): int
    {
        $mode = (string) ($setup['exit_join_proration'] ?? 'Prorated Salary');
        if ($mode === 'Full Month' || $mode === 'No Proration') {
            return $requestedDays;
        }
        if (!Schema::hasColumn('employee', 'joining_date') && !Schema::hasColumn('employee', 'exit_date')) {
            return $requestedDays;
        }
        $emp = DB::table('employee')->where('employee_id', $employeeId)->first();
        if (!$emp) {
            return $requestedDays;
        }
        $ym = substr($payDate, 0, 7);
        $monthStart = $ym.'-01';
        $monthEnd = date('Y-m-t', strtotime($monthStart));
        $start = $monthStart;
        $end = $monthEnd;
        if (!empty($emp->joining_date) && $emp->joining_date > $start) {
            $start = (string) $emp->joining_date;
        }
        $exit = $emp->exit_date ?? null;
        if (!$exit && Schema::hasTable('hr_resignation')) {
            $exit = DB::table('hr_resignation')
                ->where('employee_id', $employeeId)
                ->where('status', 1)
                ->orderByDesc('id')
                ->value('last_working_day');
        }
        if ($exit && $exit < $end) {
            $end = (string) $exit;
        }
        if ($start > $end) {
            return 0;
        }
        $worked = (int) ((strtotime($end) - strtotime($start)) / 86400) + 1;
        $monthLen = (int) date('t', strtotime($monthStart));

        return (int) min($requestedDays, max(0, min($worked, $monthLen)));
    }

    /** Match each day's late_minutes to auto deduction bands. */
    protected function lateDeductionForEmployee(int $employeeId, string $payDate, float $basic): float
    {
        if (!Schema::hasTable('attendance') || !Schema::hasTable('hr_auto_deduction_rule')) {
            return 0.0;
        }
        $ym = substr($payDate, 0, 7);
        $rows = DB::table('attendance')
            ->where('employee_id', $employeeId)
            ->whereRaw("DATE_FORMAT(`date`, '%Y-%m') = ?", [$ym])
            ->get();
        $rules = DB::table('hr_auto_deduction_rule')->where('status', 1)->orderBy('minutes_from')->get();
        if ($rules->isEmpty()) {
            return 0.0;
        }
        $dailyRate = $basic / 30.0;
        $total = 0.0;
        foreach ($rows as $att) {
            $late = Schema::hasColumn('attendance', 'late_minutes')
                ? (int) ($att->late_minutes ?? 0)
                : $this->deriveLateMinutes($att, $payDate);
            if ($late <= 0) {
                continue;
            }
            foreach ($rules as $rule) {
                $from = (int) $rule->minutes_from;
                $to = (int) $rule->minutes_to;
                if ($late >= $from && ($to <= 0 || $late <= $to)) {
                    $amt = (float) $rule->amount;
                    $method = (string) ($rule->method ?? 'Fixed Amount');
                    if (stripos($method, 'Percent') !== false || stripos((string) $rule->amount_type, 'Percent') !== false) {
                        $total += round($dailyRate * ($amt / 100), 2);
                    } else {
                        $total += $amt;
                    }
                    break;
                }
            }
        }

        return round($total, 2);
    }

    protected function deriveLateMinutes(object $att, string $payDate): int
    {
        if (empty($att->punch_in)) {
            return 0;
        }
        $setup = $this->getSetup();
        $start = (string) ($setup['work_start_time'] ?? '09:00:00');
        $grace = (int) ($setup['late_grace_minutes'] ?? 15);
        $day = substr((string) $att->punch_in, 0, 10);
        $expected = strtotime($day.' '.$start) + ($grace * 60);
        $punch = strtotime((string) $att->punch_in);

        return max(0, (int) round(($punch - $expected) / 60));
    }

    /** LWP / absent days: status=0 or notes contain LWP. Deduct daily basic. */
    protected function lwpDeductionForEmployee(int $employeeId, string $payDate, float $basic, int $monthDays): float
    {
        if (!Schema::hasTable('attendance')) {
            return 0.0;
        }
        $ym = substr($payDate, 0, 7);
        $q = DB::table('attendance')
            ->where('employee_id', $employeeId)
            ->whereRaw("DATE_FORMAT(`date`, '%Y-%m') = ?", [$ym]);
        if (Schema::hasColumn('attendance', 'status')) {
            $q->where(function ($w) {
                $w->where('status', 0)->orWhere('notes', 'like', '%LWP%');
            });
        } else {
            $q->where('notes', 'like', '%LWP%');
        }
        $count = (int) $q->count();
        if ($count < 1) {
            return 0.0;
        }

        return round(($basic / max(1, $monthDays)) * $count, 2);
    }

    /** @return array{amount:float,ids:list<int>,per_id:array<int,float>} */
    protected function loanRecoveryForEmployee(int $employeeId): array
    {
        if (!Schema::hasTable('hr_loan') || $employeeId < 1) {
            return ['amount' => 0.0, 'ids' => [], 'per_id' => []];
        }
        $rows = DB::table('hr_loan')->where('employee_id', $employeeId)->where('status', 1)->get();
        $total = 0.0;
        $ids = [];
        $perId = [];
        foreach ($rows as $r) {
            $principal = (float) $r->principal;
            $recovered = (float) ($r->recovered_amount ?? 0);
            $remaining = max(0, $principal - $recovered);
            if ($remaining <= 0) {
                continue;
            }
            $inst = (float) ($r->installment ?? 0);
            if ($inst <= 0) {
                $inst = $remaining;
            }
            $take = min($remaining, $inst);
            $total += $take;
            $ids[] = (int) $r->id;
            $perId[(int) $r->id] = $take;
        }

        return ['amount' => round($total, 2), 'ids' => $ids, 'per_id' => $perId];
    }

    /** @param list<int> $ids @param array<int,float> $perId */
    protected function applyLoanRecoveries(array $ids, array $perId): void
    {
        foreach ($perId as $loanId => $take) {
            $row = DB::table('hr_loan')->where('id', $loanId)->first();
            if (!$row) {
                continue;
            }
            $new = round((float) ($row->recovered_amount ?? 0) + $take, 2);
            $upd = ['recovered_amount' => $new];
            if ($new >= (float) $row->principal) {
                $upd['status'] = 2;
            }
            DB::table('hr_loan')->where('id', $loanId)->update($upd);
        }
    }

    /** @return array{amount:float,ids:list<int>} */
    protected function arrearsForEmployee(int $employeeId, string $payDate): array
    {
        if (!Schema::hasTable('hr_arrears')) {
            return ['amount' => 0.0, 'ids' => []];
        }
        $ym = substr($payDate, 0, 7);
        $rows = DB::table('hr_arrears')
            ->where('employee_id', $employeeId)
            ->where('for_month', $ym)
            ->where('status', 1)
            ->get();
        $total = 0.0;
        $ids = [];
        foreach ($rows as $r) {
            $total += (float) $r->amount;
            $ids[] = (int) $r->id;
        }

        return ['amount' => round($total, 2), 'ids' => $ids];
    }

    /** @param list<int> $ids */
    protected function markArrearsApplied(array $ids): void
    {
        if ($ids === []) {
            return;
        }
        DB::table('hr_arrears')->whereIn('id', $ids)->update(['status' => 2]);
    }

    /**
     * Monthly installment = amount / recover_months, capped by remaining balance.
     * @return array{amount:float,ids:list<int>,per_id:array<int,float>}
     */
    protected function advanceRecoveryForEmployee(int $employeeId): array
    {
        if (!Schema::hasTable('hr_advance') || $employeeId < 1) {
            return ['amount' => 0.0, 'ids' => [], 'per_id' => []];
        }
        $hasRecovered = Schema::hasColumn('hr_advance', 'recovered_amount');
        $rows = DB::table('hr_advance')
            ->where('employee_id', $employeeId)
            ->where('status', 1)
            ->get();
        $total = 0.0;
        $ids = [];
        $perId = [];
        foreach ($rows as $r) {
            $amount = (float) ($r->amount ?? 0);
            $recovered = $hasRecovered ? (float) ($r->recovered_amount ?? 0) : 0.0;
            $remaining = max(0, $amount - $recovered);
            if ($remaining <= 0) {
                continue;
            }
            $months = max(1, (int) ($r->recover_months ?? 1));
            $installment = round($amount / $months, 2);
            $take = min($remaining, $installment);
            if ($take <= 0) {
                continue;
            }
            $total += $take;
            $ids[] = (int) $r->id;
            $perId[(int) $r->id] = $take;
        }

        return ['amount' => round($total, 2), 'ids' => $ids, 'per_id' => $perId];
    }

    /** @param list<int> $ids @param array<int,float> $perId */
    protected function applyAdvanceRecoveries(array $ids, array $perId): void
    {
        if ($ids === [] || !Schema::hasColumn('hr_advance', 'recovered_amount')) {
            return;
        }
        foreach ($perId as $advId => $take) {
            $row = DB::table('hr_advance')->where('id', $advId)->first();
            if (!$row) {
                continue;
            }
            $newRecovered = round((float) ($row->recovered_amount ?? 0) + $take, 2);
            $upd = ['recovered_amount' => $newRecovered];
            if ($newRecovered >= (float) $row->amount) {
                $upd['status'] = 3; // fully recovered
            }
            DB::table('hr_advance')->where('id', $advId)->update($upd);
        }
    }

    protected function appendProcessLine(int $processId, string $code, float $allow, float $deduct): void
    {
        if ($allow <= 0 && $deduct <= 0) {
            return;
        }
        $itemId = (int) (DB::table('hr_payroll_item')->where('code', $code)->value('id') ?? 0);
        if ($itemId < 1) {
            return;
        }
        DB::table('process_salary_details')->insert([
            'process_salary_id' => $processId,
            'payroll_item_id' => $itemId,
            'allowance' => $allow,
            'deduction' => $deduct,
        ]);
    }

    /** Approved OT hours in month of $date → amount using hourly = basic/30/8 * multiplier. */
    protected function overtimeForEmployee(int $employeeId, string $date, float $basic): float
    {
        if (!Schema::hasTable('hr_overtime_entry') || $employeeId < 1) {
            return 0.0;
        }
        $ym = substr($date, 0, 7);
        $rows = DB::table('hr_overtime_entry')
            ->where('employee_id', $employeeId)
            ->whereRaw("DATE_FORMAT(work_date, '%Y-%m') = ?", [$ym])
            ->where('status', '>=', 1)
            ->get();
        $hourly = $basic > 0 ? ($basic / 30.0 / 8.0) : 0.0;
        $total = 0.0;
        foreach ($rows as $r) {
            $hours = (float) ($r->hours ?? 0);
            $mult = (float) ($r->rate_multiplier ?? 1.5);
            $total += $hours * $hourly * $mult;
        }

        return round($total, 2);
    }

    public function listProcessed(?string $date = null, ?int $projectId = null): array
    {
        if (!Schema::hasTable('process_salary')) {
            return [];
        }
        $q = DB::table('process_salary as ps')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'ps.employee_id')
            ->leftJoin('project as p', 'p.project_id', '=', 'ps.project_id')
            ->select('ps.*', 'e.name as employee_name', 'p.name as project_name')
            ->orderByDesc('ps.id');
        if ($date) {
            $q->where('ps.date', $date);
        }
        if ($projectId) {
            $q->where('ps.project_id', $projectId);
        }

        return $q->limit(500)->get()->map(fn ($r) => $this->mapProcess($r))->all();
    }

    public function payslip(int $processId): ?array
    {
        $row = DB::table('process_salary as ps')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'ps.employee_id')
            ->leftJoin('project as p', 'p.project_id', '=', 'ps.project_id')
            ->leftJoin('designation as d', 'd.designation_id', '=', 'e.designation')
            ->select(
                'ps.*',
                'e.name as employee_name',
                'e.employee_code',
                'e.email',
                'p.name as project_name',
                'd.name as designation_name'
            )
            ->where('ps.id', $processId)
            ->first();
        if (!$row) {
            return null;
        }
        $company = DB::table('company')->first();
        $opts = $this->getPayslipOptions();
        $lines = DB::table('process_salary_details as pd')
            ->leftJoin('hr_payroll_item as i', 'i.id', '=', 'pd.payroll_item_id')
            ->where('pd.process_salary_id', $processId)
            ->get(['pd.*', 'i.name as item_name', 'i.code', 'i.category']);

        $logo = $company->hr_logo ?? $company->logo ?? null;

        return [
            'company' => [
                'name' => (string) ($company->hr_company_name ?? $company->name ?? 'Organization'),
                'currency' => (string) ($company->currency ?? 'PKR'),
                'logo' => $logo,
            ],
            'options' => $opts,
            'employee' => [
                'id' => (int) $row->employee_id,
                'name' => (string) ($row->employee_name ?? ''),
                'code' => (string) ($row->employee_code ?? ''),
                'email' => (string) ($row->email ?? ''),
                'designation' => (string) ($row->designation_name ?? ''),
            ],
            'project' => (string) ($row->project_name ?? ''),
            'period_date' => (string) ($row->date ?? ''),
            'days' => (int) $row->days,
            'basic_salary' => (float) $row->basic_salary,
            'total_allowance' => (float) $row->total_allowance,
            'total_deduction' => (float) $row->total_deduction,
            'tax_amount' => (float) ($row->tax_amount ?? 0),
            'eobi_amount' => (float) ($row->eobi_amount ?? 0),
            'sessi_amount' => (float) ($row->sessi_amount ?? 0),
            'pf_amount' => (float) ($row->pf_amount ?? 0),
            'overtime_amount' => (float) ($row->overtime_amount ?? 0),
            'advance_amount' => (float) ($row->advance_amount ?? 0),
            'late_amount' => (float) ($row->late_amount ?? 0),
            'lwp_amount' => (float) ($row->lwp_amount ?? 0),
            'loan_amount' => (float) ($row->loan_amount ?? 0),
            'arrears_amount' => (float) ($row->arrears_amount ?? 0),
            'net_salary' => (float) $row->net_salary,
            'lines' => $lines->map(fn ($l) => [
                'item' => (string) ($l->item_name ?? 'Item'),
                'code' => (string) ($l->code ?? ''),
                'allowance' => (float) $l->allowance,
                'deduction' => (float) $l->deduction,
            ])->all(),
        ];
    }

    public function dashboard(): array
    {
        $defines = Schema::hasTable('define_salary')
            ? (int) DB::table('define_salary')->count()
            : 0;
        $month = now()->format('Y-m');
        $processed = 0;
        $gross = 0.0;
        $net = 0.0;
        $tax = 0.0;
        if (Schema::hasTable('process_salary')) {
            $agg = DB::table('process_salary')
                ->whereRaw("DATE_FORMAT(`date`, '%Y-%m') = ?", [$month])
                ->selectRaw('COUNT(*) as c, COALESCE(SUM(total_allowance),0) as g, COALESCE(SUM(net_salary),0) as n, COALESCE(SUM(tax_amount),0) as t')
                ->first();
            $processed = (int) ($agg->c ?? 0);
            $gross = (float) ($agg->g ?? 0);
            $net = (float) ($agg->n ?? 0);
            $tax = (float) ($agg->t ?? 0);
        }

        return [
            'defined_structures' => $defines,
            'processed_this_month' => $processed,
            'month_gross' => $gross,
            'month_net' => $net,
            'month_tax' => $tax,
            'currency' => 'PKR',
        ];
    }

    public function taxSlabs(): array
    {
        if (!Schema::hasTable('tax')) {
            return [];
        }
        $fromCol = Schema::hasColumn('tax', 'from_amount') ? 'from_amount' : 'from';
        $toCol = Schema::hasColumn('tax', 'to_amount') ? 'to_amount' : 'to';
        $fixedCol = Schema::hasColumn('tax', 'fixed_amount') ? 'fixed_amount' : 'amount';

        return DB::table('tax')->orderBy($fromCol)->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'from' => (int) $r->{$fromCol},
            'to' => (int) ($r->{$toCol} ?? 0),
            'fixed' => (int) ($r->{$fixedCol} ?? 0),
            'percentage' => (int) ($r->percentage ?? 0),
            'year' => (string) ($r->year ?? ''),
        ])->all();
    }

    public function taxOnAnnual(float $annual): float
    {
        // Back-compat: treat as annual income, return annual tax (for reports).
        return round($this->taxOnMonthly($annual / 12) * 12, 2);
    }

    /**
     * PHP DefineSalaryModel::calculateTaxMod — progressive bands on annualized
     * monthly gross, returns monthly tax.
     */
    public function taxOnMonthly(float $monthlyGross): float
    {
        $slabs = $this->taxSlabs();
        if ($slabs === [] || $monthlyGross <= 0) {
            return 0.0;
        }
        $annual = $monthlyGross * 12;
        $tax = 0.0;
        foreach ($slabs as $s) {
            $min = (float) $s['from'];
            $max = (float) ($s['to'] ?: PHP_INT_MAX);
            if ($annual > $min) {
                $taxable = min($annual, $max) - $min;
                if ($taxable > 0) {
                    $tax += ($taxable * ((float) $s['percentage'])) / 100;
                }
            }
        }

        return round($tax / 12, 2);
    }

    public function eobiEmployeeAmount(): float
    {
        if (!Schema::hasTable('eobi')) {
            return 370.0;
        }
        $row = DB::table('eobi')->orderByDesc('id')->first();
        if (!$row) {
            return 370.0;
        }
        if (!empty($row->emp_percentage) && (float) $row->emp_percentage > 0) {
            // Percentage handled at call site when basic known; fixed amount is default.
        }

        return (float) ($row->emp_amount ?? 370);
    }

    /** @return array<string, float> */
    public function statutoryRates(): array
    {
        $out = [
            'sessi_emp_percent' => 1.0,
            'sessi_emp_amount' => 0.0,
            'pf_emp_percent' => 0.0,
            'pf_emp_amount' => 0.0,
        ];
        if (Schema::hasTable('sessi')) {
            $s = DB::table('sessi')->orderByDesc('id')->first();
            if ($s) {
                $out['sessi_emp_percent'] = (float) ($s->emp_percentage ?? 1);
                $out['sessi_emp_amount'] = (float) ($s->emp_amount ?? 0);
            }
        }
        if (Schema::hasTable('provident_fund')) {
            $p = DB::table('provident_fund')->orderByDesc('id')->first();
            if ($p) {
                $out['pf_emp_percent'] = (float) ($p->emp_percentage ?? 0);
                $out['pf_emp_amount'] = (float) ($p->emp_amount ?? 0);
            }
        }

        return $out;
    }

    /**
     * Merge PHP payroll_setup formulas into define lines (Fix / Percentage of basic).
     * @param list<array{payroll_item_id?:int,allowance?:float|int,deduction?:float|int}> $items
     * @return list<array{payroll_item_id:int,allowance:float,deduction:float}>
     */
    public function applySetupFormulas(float $basic, array $items): array
    {
        $byId = [];
        foreach ($items as $it) {
            $pid = (int) ($it['payroll_item_id'] ?? 0);
            if ($pid < 1) {
                continue;
            }
            $byId[$pid] = [
                'payroll_item_id' => $pid,
                'allowance' => (float) ($it['allowance'] ?? 0),
                'deduction' => (float) ($it['deduction'] ?? 0),
            ];
        }
        if (!Schema::hasTable('payroll_setup') || !Schema::hasTable('hr_payroll_item')) {
            return array_values($byId);
        }

        $formulas = DB::table('payroll_setup as p')
            ->leftJoin('hr_payroll_item as i', 'i.id', '=', 'p.target')
            ->select('p.target', 'p.condition', 'p.amount', 'p.category', 'i.category as item_category', 'i.code')
            ->get();

        foreach ($formulas as $f) {
            $tid = (int) $f->target;
            if ($tid < 1) {
                continue;
            }
            $cond = strtolower(trim((string) $f->condition));
            $isPct = in_array($cond, ['1', 'percentage', 'percentage of basic salary', '%'], true);
            $amt = $isPct
                ? round($basic * ((float) $f->amount / 100), 2)
                : round((float) $f->amount, 2);

            $itemCat = strtolower((string) ($f->item_category ?? ''));
            $setupCat = (string) ($f->category ?? 'General');
            $code = strtoupper((string) ($f->code ?? ''));
            $isDeduct = in_array($setupCat, ['EOBI', 'SESSI', 'Provident Fund'], true)
                || str_contains($itemCat, 'deduct')
                || in_array($code, ['EOBI', 'EOBI_E', 'SESSI', 'PF', 'TAX'], true);

            $row = $byId[$tid] ?? ['payroll_item_id' => $tid, 'allowance' => 0.0, 'deduction' => 0.0];
            // Formula fills when user left the line empty; otherwise keep user amount.
            if ($isDeduct) {
                if ((float) $row['deduction'] <= 0) {
                    $row['deduction'] = $amt;
                }
            } else {
                if ((float) $row['allowance'] <= 0) {
                    $row['allowance'] = $amt;
                }
            }
            $byId[$tid] = $row;
        }

        return array_values($byId);
    }

    public function autoAdditionsForEmployee(int $employeeId, float $basic, float $gross): float
    {
        if (!Schema::hasTable('hr_auto_addition_rule')) {
            return 0.0;
        }
        $total = 0.0;
        $rules = DB::table('hr_auto_addition_rule')->where('status', 1)->get();
        foreach ($rules as $r) {
            $method = strtolower((string) ($r->method ?? 'Fixed Amount'));
            $amt = (float) ($r->amount ?? 0);
            if (str_contains($method, 'percent')) {
                $total += round($basic * ($amt / 100), 2);
            } else {
                $total += $amt;
            }
        }

        return round($total, 2);
    }

    public function salaryCertificateHtml(int $employeeId, ?string $baseUrl = null): ?string
    {
        $emp = DB::table('employee as e')
            ->leftJoin('designation as d', 'd.designation_id', '=', 'e.designation')
            ->leftJoin('department as dep', 'dep.department_id', '=', 'e.department')
            ->where('e.employee_id', $employeeId)
            ->select('e.*', 'd.name as designation_name', 'dep.name as department_name')
            ->first();
        if (!$emp) {
            return null;
        }
        $def = DB::table('define_salary')->where('employee_id', $employeeId)->orderByDesc('id')->first();
        $basic = (float) ($def->basic_salary ?? 0);
        $gross = (float) ($def->total_allowance ?? $basic);
        $net = (float) ($def->net_salary ?? $gross);
        $name = htmlspecialchars((string) ($emp->name ?? ''));
        $code = htmlspecialchars((string) ($emp->employee_code ?? ''));
        $des = htmlspecialchars((string) ($emp->designation_name ?? ''));
        $dept = htmlspecialchars((string) ($emp->department_name ?? ''));
        $company = 'HR360 TechX';
        if (Schema::hasTable('company')) {
            $c = DB::table('company')->orderBy('id')->first();
            if ($c) {
                $company = htmlspecialchars((string) ($c->hr_company_name ?? $c->name ?? $company));
            }
        }
        $today = date('d M Y');

        return '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Salary Certificate</title>
<style>body{font-family:Georgia,serif;margin:48px;line-height:1.6;color:#222}
h1{font-size:22px;text-align:center;letter-spacing:2px}
.box{border:1px solid #ccc;padding:24px;margin-top:24px}
button{padding:8px 14px;background:#A67C5D;color:#fff;border:0;border-radius:6px;cursor:pointer}
@media print{button{display:none}}</style></head><body>
<button onclick="window.print()">Print / Save PDF</button>
<h1>SALARY CERTIFICATE</h1>
<p style="text-align:center">'.$company.'</p>
<div class="box">
<p>Date: <b>'.$today.'</b></p>
<p>This is to certify that <b>'.$name.'</b> (Employee Code: <b>'.$code.'</b>),
working as <b>'.$des.'</b> in the <b>'.$dept.'</b> department, is drawing the following salary:</p>
<ul>
<li>Basic Salary: <b>PKR '.number_format($basic, 2).'</b></li>
<li>Gross Salary: <b>PKR '.number_format($gross, 2).'</b></li>
<li>Net Salary: <b>PKR '.number_format($net, 2).'</b></li>
</ul>
<p>This certificate is issued upon request of the employee for whatever purpose it may serve.</p>
<p style="margin-top:48px">Authorized Signatory ______________________</p>
</div></body></html>';
    }

    public function salaryStatementHtml(int $employeeId, ?string $from = null, ?string $to = null): ?string
    {
        $emp = DB::table('employee')->where('employee_id', $employeeId)->first();
        if (!$emp) {
            return null;
        }
        $q = DB::table('process_salary')->where('employee_id', $employeeId)->orderBy('date');
        if ($from) {
            $q->where('date', '>=', $from);
        }
        if ($to) {
            $q->where('date', '<=', $to);
        }
        $rows = $q->limit(36)->get();
        $lines = '';
        foreach ($rows as $r) {
            $lines .= '<tr><td>'.htmlspecialchars((string) $r->date).'</td>'
                .'<td style="text-align:right">'.number_format((float) $r->basic_salary, 2).'</td>'
                .'<td style="text-align:right">'.number_format((float) $r->total_allowance, 2).'</td>'
                .'<td style="text-align:right">'.number_format((float) $r->total_deduction, 2).'</td>'
                .'<td style="text-align:right">'.number_format((float) $r->net_salary, 2).'</td></tr>';
        }
        if ($lines === '') {
            $lines = '<tr><td colspan="5">No processed salary found for this period.</td></tr>';
        }
        $name = htmlspecialchars((string) ($emp->name ?? ''));
        $code = htmlspecialchars((string) ($emp->employee_code ?? ''));

        return '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Salary Statement</title>
<style>body{font-family:Segoe UI,Arial,sans-serif;margin:32px;color:#222}
table{width:100%;border-collapse:collapse;margin-top:16px}
th,td{border-bottom:1px solid #ddd;padding:8px;font-size:13px}
th{background:#A67C5D;color:#fff;text-align:left}
button{padding:8px 14px;background:#A67C5D;color:#fff;border:0;border-radius:6px;cursor:pointer}
@media print{button{display:none}}</style></head><body>
<button onclick="window.print()">Print / Save PDF</button>
<h1>Salary Statement</h1>
<p><b>'.$name.'</b> ('.$code.')'
.($from || $to ? ' · Period: '.htmlspecialchars((string) ($from ?? '…')).' → '.htmlspecialchars((string) ($to ?? '…')) : '')
.'</p>
<table><thead><tr><th>Date</th><th style="text-align:right">Basic</th><th style="text-align:right">Gross</th><th style="text-align:right">Deductions</th><th style="text-align:right">Net</th></tr></thead>
<tbody>'.$lines.'</tbody></table>
</body></html>';
    }

    public function getSetup(): array
    {
        if (!Schema::hasTable('hr_payroll_setup')) {
            return $this->defaultSetup();
        }
        $row = DB::table('hr_payroll_setup')->orderBy('id')->first();
        if (!$row) {
            return $this->defaultSetup();
        }

        return [
            'id' => (int) $row->id,
            'name' => (string) $row->name,
            'payroll_type' => (string) $row->payroll_type,
            'pay_schedule' => (string) $row->pay_schedule,
            'salaries_per_year' => (int) $row->salaries_per_year,
            'fiscal_start_month' => (string) $row->fiscal_start_month,
            'divide_with_days' => (int) $row->divide_with_days === 1,
            'per_day_method' => (string) $row->per_day_method,
            'pro_rata_method' => (string) $row->pro_rata_method,
            'exit_join_proration' => (string) $row->exit_join_proration,
            'enable_basic_salary' => (int) ($row->enable_basic_salary ?? 1) === 1,
            'enable_auto_overtime' => (int) ($row->enable_auto_overtime ?? 1) === 1,
            'enable_auto_late' => (int) ($row->enable_auto_late ?? 1) === 1,
            'work_start_time' => (string) ($row->work_start_time ?? '09:00:00'),
            'late_grace_minutes' => (int) ($row->late_grace_minutes ?? 15),
            'sessi_emp_percent' => (float) ($row->sessi_emp_percent ?? 1),
            'sessi_org_percent' => (float) ($row->sessi_org_percent ?? 6),
            'pf_emp_percent' => (float) ($row->pf_emp_percent ?? 0),
            'pf_org_percent' => (float) ($row->pf_org_percent ?? 0),
            'enable_sessi' => (int) ($row->enable_sessi ?? 1) === 1,
            'enable_pf' => (int) ($row->enable_pf ?? 0) === 1,
        ];
    }

    public function saveSetup(array $data): array
    {
        $payload = [
            'name' => $data['name'] ?? 'General Payroll',
            'payroll_type' => $data['payroll_type'] ?? 'Payroll (Pakistan)',
            'pay_schedule' => $data['pay_schedule'] ?? 'Monthly (12)',
            'salaries_per_year' => (int) ($data['salaries_per_year'] ?? 12),
            'fiscal_start_month' => $data['fiscal_start_month'] ?? 'January',
            'divide_with_days' => !empty($data['divide_with_days']) ? 1 : 0,
            'per_day_method' => $data['per_day_method'] ?? 'Method 1 - Annual Gross Salary / 365',
            'pro_rata_method' => $data['pro_rata_method'] ?? 'Method 1 - Based on Annual Gross Salary',
            'exit_join_proration' => $data['exit_join_proration'] ?? 'Prorated Salary',
            'enable_basic_salary' => !empty($data['enable_basic_salary']) ? 1 : 0,
            'enable_auto_overtime' => !empty($data['enable_auto_overtime']) ? 1 : 0,
            'sessi_emp_percent' => (float) ($data['sessi_emp_percent'] ?? 1),
            'sessi_org_percent' => (float) ($data['sessi_org_percent'] ?? 6),
            'pf_emp_percent' => (float) ($data['pf_emp_percent'] ?? 0),
            'pf_org_percent' => (float) ($data['pf_org_percent'] ?? 0),
            'enable_sessi' => !empty($data['enable_sessi']) ? 1 : 0,
            'enable_pf' => !empty($data['enable_pf']) ? 1 : 0,
        ];
        if (Schema::hasColumn('hr_payroll_setup', 'enable_auto_late')) {
            $payload['enable_auto_late'] = !empty($data['enable_auto_late']) ? 1 : 0;
            $payload['work_start_time'] = $data['work_start_time'] ?? '09:00:00';
            $payload['late_grace_minutes'] = (int) ($data['late_grace_minutes'] ?? 15);
        }
        $existing = DB::table('hr_payroll_setup')->orderBy('id')->first();
        if ($existing) {
            DB::table('hr_payroll_setup')->where('id', $existing->id)->update($payload);
        } else {
            DB::table('hr_payroll_setup')->insert($payload);
        }

        return $this->getSetup();
    }

    public function getPayslipOptions(): array
    {
        if (!Schema::hasTable('hr_payslip_options')) {
            return $this->defaultPayslipOptions();
        }
        $row = DB::table('hr_payslip_options')->orderBy('id')->first();
        if (!$row) {
            return $this->defaultPayslipOptions();
        }

        return [
            'id' => (int) $row->id,
            'payslip_title' => (string) $row->payslip_title,
            'payslip_format' => (string) $row->payslip_format,
            'logo_alignment' => (string) $row->logo_alignment,
            'approval_levels' => (int) $row->approval_levels,
            'auto_email' => (int) $row->auto_email === 1,
            'add_signature' => (int) $row->add_signature === 1,
            'show_bank' => (int) $row->show_bank === 1,
            'show_ytd' => (int) $row->show_ytd === 1,
        ];
    }

    public function savePayslipOptions(array $data): array
    {
        $payload = [
            'payslip_title' => $data['payslip_title'] ?? 'Payslip',
            'payslip_format' => $data['payslip_format'] ?? 'Standard',
            'logo_alignment' => $data['logo_alignment'] ?? 'Left',
            'approval_levels' => (int) ($data['approval_levels'] ?? 0),
            'auto_email' => !empty($data['auto_email']) ? 1 : 0,
            'add_signature' => !empty($data['add_signature']) ? 1 : 0,
            'show_bank' => !empty($data['show_bank']) ? 1 : 0,
            'show_ytd' => !empty($data['show_ytd']) ? 1 : 0,
        ];
        $existing = DB::table('hr_payslip_options')->orderBy('id')->first();
        if ($existing) {
            DB::table('hr_payslip_options')->where('id', $existing->id)->update($payload);
        } else {
            $payload['setup_id'] = 1;
            DB::table('hr_payslip_options')->insert($payload);
        }

        return $this->getPayslipOptions();
    }

    public function listCalendars(): array
    {
        if (!Schema::hasTable('hr_payroll_calendar')) {
            return [];
        }

        return DB::table('hr_payroll_calendar')->orderByDesc('year')->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'year' => (int) $r->year,
            'start_date' => (string) $r->start_date,
            'end_date' => (string) $r->end_date,
            'pay_periods' => (int) $r->pay_periods,
            'label' => (string) ($r->label ?? ''),
        ])->all();
    }

    public function saveCalendar(array $data, ?int $id = null): array
    {
        $payload = [
            'year' => (int) $data['year'],
            'start_date' => $data['start_date'],
            'end_date' => $data['end_date'],
            'pay_periods' => (int) ($data['pay_periods'] ?? 12),
            'label' => $data['label'] ?? null,
        ];
        if ($id) {
            DB::table('hr_payroll_calendar')->where('id', $id)->update($payload);
        } else {
            $id = (int) DB::table('hr_payroll_calendar')->insertGetId($payload);
        }

        return collect($this->listCalendars())->firstWhere('id', $id) ?? $payload;
    }

    public function deleteCalendar(int $id): void
    {
        DB::table('hr_payroll_calendar')->where('id', $id)->delete();
    }

    public function listBanks(): array
    {
        if (!Schema::hasTable('hr_bank_account')) {
            return [];
        }

        return DB::table('hr_bank_account')->orderByDesc('is_primary')->orderBy('bank_name')->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'bank_name' => (string) $r->bank_name,
            'account_title' => (string) ($r->account_title ?? ''),
            'account_number' => (string) $r->account_number,
            'iban' => (string) ($r->iban ?? ''),
            'branch' => (string) ($r->branch ?? ''),
            'is_primary' => (int) $r->is_primary === 1,
            'status' => (int) $r->status,
        ])->all();
    }

    public function saveBank(array $data, ?int $id = null): array
    {
        $payload = [
            'bank_name' => $data['bank_name'],
            'account_title' => $data['account_title'] ?? null,
            'account_number' => $data['account_number'],
            'iban' => $data['iban'] ?? null,
            'branch' => $data['branch'] ?? null,
            'is_primary' => !empty($data['is_primary']) ? 1 : 0,
            'status' => (int) ($data['status'] ?? 1),
        ];
        if (!empty($payload['is_primary'])) {
            DB::table('hr_bank_account')->update(['is_primary' => 0]);
        }
        if ($id) {
            DB::table('hr_bank_account')->where('id', $id)->update($payload);
        } else {
            $id = (int) DB::table('hr_bank_account')->insertGetId($payload);
        }

        return collect($this->listBanks())->firstWhere('id', $id) ?? $payload;
    }

    public function deleteBank(int $id): void
    {
        DB::table('hr_bank_account')->where('id', $id)->delete();
    }

    public function listAutoRules(string $table): array
    {
        if (!Schema::hasTable($table)) {
            return [];
        }

        return DB::table($table)->orderBy('id')->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'minutes_from' => (int) $r->minutes_from,
            'minutes_to' => (int) $r->minutes_to,
            'amount_type' => (string) $r->amount_type,
            'method' => (string) $r->method,
            'amount' => (float) $r->amount,
            'status' => (int) $r->status,
        ])->all();
    }

    public function saveAutoRule(string $table, array $data, ?int $id = null): array
    {
        $payload = [
            'minutes_from' => (int) ($data['minutes_from'] ?? 0),
            'minutes_to' => (int) ($data['minutes_to'] ?? 0),
            'amount_type' => $data['amount_type'] ?? 'Specified Amount',
            'method' => $data['method'] ?? 'Fixed Amount',
            'amount' => (float) ($data['amount'] ?? 0),
            'status' => (int) ($data['status'] ?? 1),
        ];
        if ($id) {
            DB::table($table)->where('id', $id)->update($payload);
        } else {
            $id = (int) DB::table($table)->insertGetId($payload);
        }

        return collect($this->listAutoRules($table))->firstWhere('id', $id) ?? $payload;
    }

    public function deleteAutoRule(string $table, int $id): void
    {
        DB::table($table)->where('id', $id)->delete();
    }

    public function salarySheet(?string $date = null, ?int $projectId = null): array
    {
        $rows = $this->listProcessed($date, $projectId);
        $totals = [
            'gross' => 0.0,
            'deduction' => 0.0,
            'tax' => 0.0,
            'net' => 0.0,
            'count' => count($rows),
        ];
        foreach ($rows as $r) {
            $totals['gross'] += (float) ($r['total_allowance'] ?? 0);
            $totals['deduction'] += (float) ($r['total_deduction'] ?? 0);
            $totals['tax'] += (float) ($r['tax_amount'] ?? 0);
            $totals['net'] += (float) ($r['net_salary'] ?? 0);
        }

        return ['rows' => $rows, 'totals' => $totals, 'date' => $date, 'project_id' => $projectId];
    }

    public function payslipHtml(int $processId, ?string $publicBase = null): ?string
    {
        $slip = $this->payslip($processId);
        if (!$slip) {
            return null;
        }
        $c = $slip['company'];
        $e = $slip['employee'];
        $opts = $slip['options'] ?? [];
        $title = htmlspecialchars((string) ($opts['payslip_title'] ?? 'Payslip'));
        $company = htmlspecialchars((string) ($c['name'] ?? ''));
        $currency = htmlspecialchars((string) ($c['currency'] ?? 'PKR'));
        $ename = htmlspecialchars((string) ($e['name'] ?? ''));
        $ecode = htmlspecialchars((string) ($e['code'] ?? ''));
        $edes = htmlspecialchars((string) ($e['designation'] ?? ''));
        $period = htmlspecialchars((string) ($slip['period_date'] ?? ''));
        $logoPath = (string) ($c['logo'] ?? '');
        $logoHtml = '';
        if ($logoPath !== '' && $publicBase) {
            $url = rtrim($publicBase, '/').'/'.ltrim($logoPath, '/');
            $logoHtml = '<img src="'.htmlspecialchars($url).'" alt="logo" style="max-height:64px;margin-bottom:8px"/>';
        }
        $lines = '';
        foreach ($slip['lines'] as $l) {
            $lines .= '<tr><td>'.htmlspecialchars($l['item']).'</td>'
                .'<td style="text-align:right">'.number_format((float) $l['allowance'], 2).'</td>'
                .'<td style="text-align:right">'.number_format((float) $l['deduction'], 2).'</td></tr>';
        }
        $sig = !empty($opts['add_signature'])
            ? '<div style="margin-top:40px;display:flex;justify-content:space-between"><div>Employee _____________</div><div>Authorized _____________</div></div>'
            : '';

        return '<!DOCTYPE html><html><head><meta charset="utf-8"><title>'.$title.'</title>
<style>
body{font-family:Segoe UI,Arial,sans-serif;color:#222;margin:32px}
h1{font-size:20px;margin:0 0 4px}
table{width:100%;border-collapse:collapse;margin-top:16px}
th,td{border-bottom:1px solid #ddd;padding:8px;font-size:13px}
th{background:#A67C5D;color:#fff;text-align:left}
.meta{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:12px;font-size:13px}
.totals{margin-top:16px;font-size:14px}
@media print{button{display:none}}
</style></head><body>
<button onclick="window.print()" style="padding:8px 14px;background:#A67C5D;color:#fff;border:0;border-radius:6px;cursor:pointer">Print / Save PDF</button>
'.$logoHtml.'
<h1>'.$title.' — '.$company.'</h1>
<div class="meta">
<div><b>Employee:</b> '.$ename.' ('.$ecode.')</div>
<div><b>Period:</b> '.$period.'</div>
<div><b>Designation:</b> '.$edes.'</div>
<div><b>Project:</b> '.htmlspecialchars((string) ($slip['project'] ?? '')).'</div>
<div><b>Days:</b> '.(int) $slip['days'].'</div>
<div><b>Currency:</b> '.$currency.'</div>
</div>
<table><thead><tr><th>Item</th><th style="text-align:right">Allowance</th><th style="text-align:right">Deduction</th></tr></thead>
<tbody>'.$lines.'</tbody></table>
<div class="totals">
<div>Gross: <b>'.number_format((float) $slip['total_allowance'], 2).'</b></div>
<div>Tax: '.number_format((float) $slip['tax_amount'], 2)
.' · EOBI: '.number_format((float) $slip['eobi_amount'], 2)
.' · SESSI: '.number_format((float) ($slip['sessi_amount'] ?? 0), 2)
.' · PF: '.number_format((float) ($slip['pf_amount'] ?? 0), 2).'</div>
<div>Late: '.number_format((float) ($slip['late_amount'] ?? 0), 2)
.' · LWP: '.number_format((float) ($slip['lwp_amount'] ?? 0), 2)
.' · Loan: '.number_format((float) ($slip['loan_amount'] ?? 0), 2)
.' · Arrears: '.number_format((float) ($slip['arrears_amount'] ?? 0), 2).'</div>
<div>Total Deduction: '.number_format((float) $slip['total_deduction'], 2).'</div>
<div style="font-size:18px;margin-top:8px">Net Pay: <b>'.number_format((float) $slip['net_salary'], 2).' '.$currency.'</b></div>
</div>
'.$sig.'
</body></html>';
    }

    protected function defaultSetup(): array
    {
        return [
            'id' => 0,
            'name' => 'General Payroll',
            'payroll_type' => 'Payroll (Pakistan)',
            'pay_schedule' => 'Monthly (12)',
            'salaries_per_year' => 12,
            'fiscal_start_month' => 'January',
            'divide_with_days' => true,
            'per_day_method' => 'Method 1 - Annual Gross Salary / 365',
            'pro_rata_method' => 'Method 1 - Based on Annual Gross Salary',
            'exit_join_proration' => 'Prorated Salary',
            'enable_basic_salary' => true,
            'enable_auto_overtime' => true,
            'enable_auto_late' => true,
            'work_start_time' => '09:00:00',
            'late_grace_minutes' => 15,
            'sessi_emp_percent' => 1.0,
            'sessi_org_percent' => 6.0,
            'pf_emp_percent' => 0.0,
            'pf_org_percent' => 0.0,
            'enable_sessi' => true,
            'enable_pf' => false,
        ];
    }

    protected function defaultPayslipOptions(): array
    {
        return [
            'id' => 0,
            'payslip_title' => 'Payslip',
            'payslip_format' => 'Standard',
            'logo_alignment' => 'Left',
            'approval_levels' => 0,
            'auto_email' => false,
            'add_signature' => true,
            'show_bank' => true,
            'show_ytd' => false,
        ];
    }

    public function metaLookups(): array
    {
        return [
            'employees' => DB::table('employee')->orderBy('name')->limit(500)->get(['employee_id as id', 'name as label']),
            'projects' => Schema::hasTable('project')
                ? DB::table('project')->orderBy('name')->get(['project_id as id', 'name as label'])
                : [],
            'stations' => Schema::hasTable('station')
                ? DB::table('station')->orderBy('name')->get(['station_id as id', 'name as label'])
                : [],
            'items' => Schema::hasTable('hr_payroll_item')
                ? DB::table('hr_payroll_item')->where('status', 1)->orderBy('name')->get(['id', 'code', 'name', 'category', 'default_value'])
                : [],
            'tax_slabs' => $this->taxSlabs(),
            'eobi_employee' => $this->eobiEmployeeAmount(),
            'setup' => $this->getSetup(),
        ];
    }

    protected function mapDefine(object $r): array
    {
        return [
            'id' => (int) $r->id,
            'employee_id' => (int) $r->employee_id,
            'employee_name' => (string) ($r->employee_name ?? ''),
            'project_id' => (int) $r->project_id,
            'project_name' => (string) ($r->project_name ?? ''),
            'station_id' => (int) $r->station_id,
            'station_name' => (string) ($r->station_name ?? ''),
            'basic_salary' => (float) $r->basic_salary,
            'total_allowance' => (float) $r->total_allowance,
            'total_deduction' => (float) $r->total_deduction,
            'net_salary' => (float) $r->net_salary,
            'created_at' => (string) ($r->created_at ?? ''),
        ];
    }

    protected function mapProcess(?object $r): array
    {
        if (!$r) {
            return [];
        }

        return [
            'id' => (int) $r->id,
            'employee_id' => (int) $r->employee_id,
            'employee_name' => (string) ($r->employee_name ?? ''),
            'project_id' => (int) $r->project_id,
            'project_name' => (string) ($r->project_name ?? ''),
            'days' => (int) $r->days,
            'basic_salary' => (float) $r->basic_salary,
            'total_allowance' => (float) $r->total_allowance,
            'total_deduction' => (float) $r->total_deduction,
            'tax_amount' => (float) ($r->tax_amount ?? 0),
            'eobi_amount' => (float) ($r->eobi_amount ?? 0),
            'sessi_amount' => (float) ($r->sessi_amount ?? 0),
            'pf_amount' => (float) ($r->pf_amount ?? 0),
            'overtime_amount' => (float) ($r->overtime_amount ?? 0),
            'advance_amount' => (float) ($r->advance_amount ?? 0),
            'late_amount' => (float) ($r->late_amount ?? 0),
            'lwp_amount' => (float) ($r->lwp_amount ?? 0),
            'loan_amount' => (float) ($r->loan_amount ?? 0),
            'arrears_amount' => (float) ($r->arrears_amount ?? 0),
            'net_salary' => (float) $r->net_salary,
            'date' => (string) ($r->date ?? ''),
        ];
    }
}
