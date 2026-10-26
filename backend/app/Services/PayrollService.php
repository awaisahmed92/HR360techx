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
        $seen = [];
        foreach ($defines as $def) {
            $employeeId = (int) ($def->employee_id ?? 0);
            if ($employeeId < 1 || isset($seen[$employeeId]) || $this->employeeAlreadyPaid($employeeId, $date)) {
                $seen[$employeeId] = true;
                continue;
            }
            $seen[$employeeId] = true;
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

        // App-saved salaries store the full gross in total_allowance.
        // The demo rows stored only the extra allowance (house rent) next to basic.
        $earnings = ($allow > 0 && $allow + 0.009 < $basic) ? ($basic + $allow) : ($allow > 0 ? $allow : $basic);
        $grossMonthly = $earnings + $otAmount + $arrearsAmount;
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

        // The defined salary already includes its tax and loan lines.
        // Adding those amounts again, on top of a gross that was only the allowance, produced a negative net.
        $totalDeduct = $deductBase + $advanceAmount + $lateAmount + $lwpAmount;
        if ($deductBase <= 0) {
            $totalDeduct += $taxMonthly + $eobi + $sessi + $pf + $loanAmount;
        } else {
            $totalDeduct += $eobi + $sessi + $pf;
        }
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

    public function listProcessed(?string $date = null, ?int $projectId = null, ?int $employeeId = null): array
    {
        if (!Schema::hasTable('process_salary')) {
            return [];
        }
        $this->ensureSlipStatus();
        $q = DB::table('process_salary as ps')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'ps.employee_id')
            ->leftJoin('project as p', 'p.project_id', '=', 'ps.project_id')
            ->select('ps.*', 'e.name as employee_name', 'e.employee_code', 'p.name as project_name')
            ->orderByDesc('ps.date')
            ->orderByDesc('ps.id');
        if ($date) {
            $q->where('ps.date', $date);
        }
        if ($projectId) {
            $q->where('ps.project_id', $projectId);
        }
        if ($employeeId !== null && $employeeId > 0) {
            $q->where('ps.employee_id', $employeeId);
        }

        $best = [];
        foreach ($q->limit(2000)->get() as $r) {
            $month = substr((string) ($r->date ?? ''), 0, 7);
            $key = ((int) $r->employee_id).'|'.$month;
            $open = !in_array((string) ($r->slip_status ?? 'processed'), ['cancelled', 'reversed'], true);
            if (!isset($best[$key])) {
                $best[$key] = $r;
                continue;
            }
            $keptOpen = !in_array((string) ($best[$key]->slip_status ?? 'processed'), ['cancelled', 'reversed'], true);
            if ($open && !$keptOpen) {
                $best[$key] = $r;
            }
        }

        return array_map(fn ($r) => $this->mapProcess($r), array_values($best));
    }

    public function payslip(int $processId): ?array
    {
        $this->ensureSlipStatus();
        $row = DB::table('process_salary as ps')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'ps.employee_id')
            ->leftJoin('project as p', 'p.project_id', '=', 'ps.project_id')
            ->leftJoin('designation as d', 'd.designation_id', '=', 'e.designation')
            ->leftJoin('department as dep', 'dep.department_id', '=', 'e.department')
            ->leftJoin('station as st', 'st.station_id', '=', 'e.station')
            ->leftJoin('employee as creator', 'creator.employee_id', '=', 'ps.created_by')
            ->select(
                'ps.*',
                'e.name as employee_name',
                'e.surname as employee_surname',
                'e.employee_code',
                'e.user_name',
                'e.email',
                'e.phone',
                'e.date_of_birth',
                'e.joining_date',
                'e.address',
                'e.bnk_title',
                'e.bnk_number',
                'e.bnk_code',
                'p.name as project_name',
                'd.name as designation_name',
                'dep.name as department_name',
                'st.name as station_name',
                'creator.name as created_by_name'
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
        $slipStatus = (string) ($row->slip_status ?? 'processed');

        return [
            'id' => (int) $row->id,
            'company' => [
                'name' => (string) ($company->hr_company_name ?? $company->name ?? 'Organization'),
                'email' => (string) ($company->email ?? ''),
                'currency' => (string) ($company->currency ?? 'USD'),
                'logo' => $logo,
            ],
            'options' => $opts,
            'employee' => [
                'id' => (int) $row->employee_id,
                'name' => trim((string) ($row->employee_name ?? '').' '.(string) ($row->employee_surname ?? '')),
                'code' => (string) ($row->employee_code ?? ''),
                'user_name' => (string) ($row->user_name ?? ''),
                'email' => (string) ($row->email ?? ''),
                'phone' => (string) ($row->phone ?? ''),
                'date_of_birth' => (string) ($row->date_of_birth ?? ''),
                'joining_date' => (string) ($row->joining_date ?? ''),
                'address' => (string) ($row->address ?? ''),
                'designation' => (string) ($row->designation_name ?? ''),
                'department' => (string) ($row->department_name ?? ''),
                'station' => (string) ($row->station_name ?? ''),
                'bank_title' => (string) ($row->bnk_title ?? ''),
                'bank_number' => (string) ($row->bnk_number ?? ''),
                'bank_code' => (string) ($row->bnk_code ?? ''),
            ],
            'project' => (string) ($row->project_name ?? ''),
            'period_date' => (string) ($row->date ?? ''),
            'period_start' => self::periodStart((string) ($row->date ?? '')),
            'period_end' => (string) ($row->date ?? ''),
            'slip_status' => $slipStatus,
            'status' => self::slipStatusLabel($slipStatus),
            'created_at' => (string) ($row->created_at ?? ''),
            'created_by_name' => (string) ($row->created_by_name ?? ''),
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
            'currency' => $this->companyCurrency(),
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
        $logos = $this->letterheadLogos($baseUrl);
        $basicTxt = htmlspecialchars($this->formatMoney($basic));
        $grossTxt = htmlspecialchars($this->formatMoney($gross));
        $netTxt = htmlspecialchars($this->formatMoney($net));

        return '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Salary Certificate</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Libre+Baskerville:wght@400;700&family=Source+Sans+3:wght@400;600;700&display=swap" rel="stylesheet">
<style>
body{margin:0;background:#eef2f6;color:#1f2937;font-family:"Source Sans 3",Segoe UI,sans-serif}
.page{max-width:820px;margin:28px auto;background:#fff;padding:36px 42px 48px;box-shadow:0 12px 40px rgba(15,23,42,.08)}
.logos{display:flex;justify-content:space-between;align-items:center;gap:16px}
.logos img{max-height:58px;max-width:160px;object-fit:contain}
h1{font-family:"Libre Baskerville",Georgia,serif;text-align:center;letter-spacing:2px;font-size:26px;margin:22px 0 4px}
.company{text-align:center;color:#0e3a4a;font-weight:700;margin:0}
.rule{height:3px;background:linear-gradient(90deg,#0e3a4a,#38bdf8);margin:16px 0 22px;border:0}
.meta{font-size:14px;color:#475569}
.lead{font-size:16px;line-height:1.7}
.amounts{width:100%;border-collapse:collapse;margin:18px 0}
.amounts td{padding:10px 12px;border-bottom:1px solid #e5e7eb}
.amounts td:last-child{text-align:right;font-weight:700;font-variant-numeric:tabular-nums}
.sign{margin-top:54px;display:flex;justify-content:flex-end}
.sign div{width:240px;text-align:center}
.sign .line{border-top:1px solid #111;margin-top:42px;padding-top:6px;font-size:13px}
button{padding:8px 14px;background:#0e3a4a;color:#fff;border:0;border-radius:6px;cursor:pointer}
@media print{body{background:#fff} .page{box-shadow:none;margin:0} button{display:none}}
</style></head><body>
<button onclick="window.print()">Print / Save PDF</button>
<div class="page">
<div class="logos">'.$logos.'</div>
<h1>SALARY CERTIFICATE</h1>
<p class="company">'.$company.'</p>
<hr class="rule">
<p class="meta">Date: <b>'.$today.'</b></p>
<p class="lead">This is to certify that <b>'.$name.'</b> (Employee Code: <b>'.$code.'</b>), working as <b>'.$des.'</b> in the <b>'.$dept.'</b> department, is drawing the following salary:</p>
<table class="amounts">
<tr><td>Basic salary</td><td>'.$basicTxt.'</td></tr>
<tr><td>Gross salary</td><td>'.$grossTxt.'</td></tr>
<tr><td>Net salary</td><td>'.$netTxt.'</td></tr>
</table>
<p>This certificate is issued upon request of the employee for whatever purpose it may serve.</p>
<div class="sign"><div><div class="line">Authorized signatory</div></div></div>
</div></body></html>';
    }

    /** HR360 mark plus the company logo for certificates and statements. */
    protected function letterheadLogos(?string $baseUrl): string
    {
        $hr = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="52" height="52" fill="none">'
            .'<defs><linearGradient id="g" x1="20" y1="24" x2="180" y2="180" gradientUnits="userSpaceOnUse">'
            .'<stop stop-color="#67e8f9"/><stop offset="0.45" stop-color="#2563eb"/><stop offset="1" stop-color="#1e3a8a"/>'
            .'</linearGradient></defs>'
            .'<path d="M58 46c-28 8-40 48-28 78 14 34 58 48 96 32 22-10 34-32 28-52" stroke="url(#g)" stroke-width="18" stroke-linecap="round"/>'
            .'<path d="M46 118c6-36 28-62 62-70 30-8 58 6 70 28" stroke="url(#g)" stroke-width="18" stroke-linecap="round"/>'
            .'</svg>';
        $client = '';
        if (Schema::hasTable('company') && $baseUrl) {
            $c = DB::table('company')->orderBy('id')->first();
            $path = $c ? (string) ($c->hr_logo ?? $c->logo ?? '') : '';
            if ($path !== '') {
                $url = htmlspecialchars(rtrim($baseUrl, '/').'/'.ltrim($path, '/'), ENT_QUOTES, 'UTF-8');
                $client = '<img src="'.$url.'" alt="Company logo"/>';
            }
        }

        return $hr.$client;
    }

    public function salaryStatementHtml(int $employeeId, ?string $from = null, ?string $to = null, ?string $baseUrl = null): ?string
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
                .'<td style="text-align:right">'.htmlspecialchars($this->formatMoney((float) $r->basic_salary)).'</td>'
                .'<td style="text-align:right">'.htmlspecialchars($this->formatMoney((float) $r->total_allowance)).'</td>'
                .'<td style="text-align:right">'.htmlspecialchars($this->formatMoney((float) $r->total_deduction)).'</td>'
                .'<td style="text-align:right">'.htmlspecialchars($this->formatMoney((float) $r->net_salary)).'</td></tr>';
        }
        if ($lines === '') {
            $lines = '<tr><td colspan="5">No processed salary found for this period.</td></tr>';
        }
        $name = htmlspecialchars((string) ($emp->name ?? ''));
        $code = htmlspecialchars((string) ($emp->employee_code ?? ''));

        $logos = $this->letterheadLogos($baseUrl);

        return '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Salary Statement</title>
<link href="https://fonts.googleapis.com/css2?family=Libre+Baskerville:wght@700&family=Source+Sans+3:wght@400;600;700&display=swap" rel="stylesheet">
<style>
body{margin:0;background:#eef2f6;color:#1f2937;font-family:"Source Sans 3",Segoe UI,sans-serif}
.page{max-width:860px;margin:28px auto;background:#fff;padding:32px 36px 40px}
h1{font-family:"Libre Baskerville",Georgia,serif;font-size:26px;margin:16px 0 4px}
table{width:100%;border-collapse:collapse;margin-top:16px}
th,td{border-bottom:1px solid #e5e7eb;padding:10px;font-size:14px}
th{background:#0e3a4a;color:#fff;text-align:left}
td:not(:first-child),th:not(:first-child){text-align:right;font-variant-numeric:tabular-nums}
.logos{display:flex;justify-content:space-between;align-items:center}
button{padding:8px 14px;background:#0e3a4a;color:#fff;border:0;border-radius:6px;cursor:pointer}
@media print{body{background:#fff}.page{margin:0}button{display:none}}
</style></head><body>
<button onclick="window.print()">Print / Save PDF</button>
<div class="page">
<div class="logos">'.$logos.'</div>
<h1>Salary Statement</h1>
<p><b>'.$name.'</b> · '.$code
.($from || $to ? ' · '.htmlspecialchars((string) ($from ?? '…')).' to '.htmlspecialchars((string) ($to ?? '…')) : '')
.'</p>
<table><thead><tr><th>Date</th><th>Basic</th><th>Gross</th><th>Deductions</th><th>Net</th></tr></thead>
<tbody>'.$lines.'</tbody></table>
</div></body></html>';
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
            'payroll_currencies' => $this->companyCurrency(),
            'cutoff_days' => '-',
            'merge_previous' => false,
            'salaried_hours_method' => 'Attendance',
            'hourly_salary_method' => 'Attendance',
            'decimal_places' => 0,
            'round_off_places' => 5,
            'hourly_decimal_places' => 5,
        ];
    }

    public function saveSetup(array $data): array
    {
        $payload = [
            'name' => $data['name'] ?? 'General Payroll',
            'payroll_type' => $data['payroll_type'] ?? 'Payroll (USA)',
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
        if (!empty($data['payroll_currencies']) && Schema::hasTable('company') && Schema::hasColumn('company', 'currency')) {
            DB::table('company')->orderBy('id')->limit(1)->update([
                'currency' => strtoupper((string) $data['payroll_currencies']),
            ]);
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
        $h = static fn ($v) => htmlspecialchars((string) $v, ENT_QUOTES, 'UTF-8');
        $money = fn ($v) => $this->formatMoney((float) $v, (string) ($c['currency'] ?? 'USD'));
        $title = $h($opts['payslip_title'] ?? 'Payslip');
        $company = $h($c['name'] ?? '');
        $start = $h($this->prettyDate((string) ($slip['period_start'] ?? '')));
        $end = $h($this->prettyDate((string) ($slip['period_end'] ?? $slip['period_date'] ?? '')));
        $logoPath = (string) ($c['logo'] ?? '');
        $clientLogo = '<div class="logo-fallback">'.$company.'</div>';
        if ($logoPath !== '' && $publicBase) {
            $url = rtrim($publicBase, '/').'/'.ltrim($logoPath, '/');
            $clientLogo = '<img src="'.$h($url).'" alt="Client logo"/>';
        }
        $hrLogo = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="52" height="52" fill="none">'
            .'<defs><linearGradient id="hr360g" x1="20" y1="24" x2="180" y2="180" gradientUnits="userSpaceOnUse">'
            .'<stop stop-color="#67e8f9"/><stop offset="0.45" stop-color="#2563eb"/><stop offset="1" stop-color="#1e3a8a"/>'
            .'</linearGradient></defs>'
            .'<path d="M58 46c-28 8-40 48-28 78 14 34 58 48 96 32 22-10 34-32 28-52" stroke="url(#hr360g)" stroke-width="18" stroke-linecap="round"/>'
            .'<path d="M46 118c6-36 28-62 62-70 30-8 58 6 70 28" stroke="url(#hr360g)" stroke-width="18" stroke-linecap="round"/>'
            .'<path d="M72 78c18 10 28 28 28 28s10 16 28 26" stroke="#1e40af" stroke-width="16" stroke-linecap="round"/>'
            .'<path d="M128 74c-16 8-28 22-28 22s-8 16-22 30" stroke="#38bdf8" stroke-width="16" stroke-linecap="round"/>'
            .'<path d="M34 96l-6-28 26 8z" fill="#22d3ee"/>'
            .'</svg>';

        $earn = '';
        $extra = '';
        $deduct = '';
        $earnTotal = 0.0;
        $extraTotal = 0.0;
        $deductTotal = 0.0;
        foreach ($slip['lines'] as $l) {
            $allow = (float) ($l['allowance'] ?? 0);
            $ded = (float) ($l['deduction'] ?? 0);
            $name = $h($l['item'] ?? 'Item');
            if ($ded > 0) {
                $deductTotal += $ded;
                $deduct .= '<tr><td>'.$name.'</td><td class="num">'.$money($ded).'</td></tr>';
            } elseif (strtoupper((string) ($l['code'] ?? '')) === 'BASIC') {
                $earnTotal += $allow;
                $earn .= '<tr><td>'.$name.'</td><td class="num">'.$money($allow).'</td></tr>';
            } elseif ($allow > 0) {
                $extraTotal += $allow;
                $extra .= '<tr><td>'.$name.'</td><td class="num">'.$money($allow).'</td></tr>';
            }
        }
        if ($earn === '') {
            $earnTotal = (float) $slip['basic_salary'];
            $earn = '<tr><td>Basic Salary</td><td class="num">'.$money($earnTotal).'</td></tr>';
        }
        if ($extra === '') {
            $extra = '<tr><td colspan="2" class="muted">—</td></tr>';
        }
        if ($deduct === '') {
            $deduct = '<tr><td colspan="2" class="muted">—</td></tr>';
        }

        $field = static function (string $label, string $value) use ($h): string {
            $shown = trim($value) === '' ? '—' : $value;

            return '<div class="k">'.$h($label).'</div><div class="v">'.$h($shown).'</div>';
        };
        $left = $field('User Name', (string) $e['name'])
            .$field('Username', (string) ($e['user_name'] ?? ''))
            .$field('Employee Id', (string) ($e['code'] ?? ''))
            .$field('Date of Birth', $this->prettyDate((string) ($e['date_of_birth'] ?? '')))
            .$field('Joining Date', $this->prettyDate((string) ($e['joining_date'] ?? '')))
            .$field('Station', (string) ($e['station'] ?? ''))
            .$field('Account Title', (string) ($e['bank_title'] ?? ''))
            .$field('Account Number', (string) ($e['bank_number'] ?? ''))
            .$field('Bank Code', (string) ($e['bank_code'] ?? ''));
        $right = $field('Job Title', (string) ($e['designation'] ?? ''))
            .$field('Department', (string) ($e['department'] ?? ''))
            .$field('Project', (string) ($slip['project'] ?? ''))
            .$field('Email', (string) ($e['email'] ?? ''))
            .$field('Phone', (string) ($e['phone'] ?? ''))
            .$field('Salary Days', (string) ($slip['days'] ?? ''))
            .$field('Monthly Gross Salary', $money($slip['total_allowance']))
            .$field('Status', (string) ($slip['status'] ?? 'Processed'))
            .$field('Address', (string) ($e['address'] ?? ''));

        $note = !empty($opts['add_signature'])
            ? '<p class="foot">This payslip is electronically generated and is valid without a signature or company stamp.</p>'
            : '';

        return '<!DOCTYPE html><html><head><meta charset="utf-8"><title>'.$title.'</title>
<style>
body{font-family:Segoe UI,Arial,sans-serif;color:#1f2937;margin:28px;background:#fff}
h1{text-align:center;font-size:22px;font-weight:600;margin:0}
.sub{text-align:center;color:#4b5563;margin:4px 0 18px;font-size:13px}
.logos{display:flex;justify-content:space-between;align-items:center;gap:24px;border:1px solid #d1d5db;padding:12px 16px;margin-bottom:16px}
.brand{display:flex;align-items:center;gap:10px;font-size:13px;line-height:1.35}
.brand img{max-height:56px;max-width:160px;object-fit:contain}
.logo-fallback{font-weight:700;font-size:15px}
.tag{color:#6b7280;font-size:11px;letter-spacing:.04em;text-transform:uppercase}
.grid{display:grid;grid-template-columns:1fr 1fr;border:1px solid #e5e7eb}
.col{display:grid;grid-template-columns:180px 1fr}
.k,.v{border-bottom:1px solid #e5e7eb;padding:6px 10px;font-size:12px}
.k{color:#6b7280}
.v{font-weight:600}
.cols{display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px;margin-top:18px}
table{width:100%;border-collapse:collapse}
th{text-align:left;font-size:12px;padding:6px 4px;border-bottom:2px solid #111}
td{font-size:12px;padding:5px 4px;border-bottom:1px solid #e5e7eb}
.num{text-align:right}
.muted{color:#9ca3af}
.net{margin-top:10px;display:flex;justify-content:space-between;font-size:15px;font-weight:700;border-top:2px solid #111;padding-top:8px}
.foot{margin-top:28px;font-size:11px;color:#6b7280;text-align:center}
button{margin-bottom:12px;padding:8px 14px;background:#8d6e63;color:#fff;border:0;border-radius:6px;cursor:pointer}
@media print{button{display:none} body{margin:12px}}
</style></head><body>
<button onclick="window.print()">Print / Save PDF</button>
<h1>'.$title.'</h1>
<div class="sub">Payslip for '.$start.' – '.$end.'</div>
<div class="logos">
<div class="brand">'.$hrLogo.'<div><b>HR360</b><br><span class="tag">Company</span></div></div>
<div class="brand">'.$clientLogo.'<div><b>'.$company.'</b><br><span class="tag">Client</span>'.($c['email'] ? '<br>'.$h($c['email']) : '').'</div></div>
</div>
<div class="grid"><div class="col">'.$left.'</div><div class="col">'.$right.'</div></div>
<div class="cols">
<table><thead><tr><th>GROSS EARNING</th><th class="num">AMOUNT</th></tr></thead><tbody>'.$earn.'
<tr><td><b>Gross Salary</b></td><td class="num"><b>'.$money($earnTotal).'</b></td></tr></tbody></table>
<table><thead><tr><th>ADDITIONAL</th><th class="num">AMOUNT</th></tr></thead><tbody>'.$extra.'
<tr><td><b>Total Additional</b></td><td class="num"><b>'.$money($extraTotal).'</b></td></tr></tbody></table>
<table><thead><tr><th>DEDUCTION</th><th class="num">AMOUNT</th></tr></thead><tbody>'.$deduct.'
<tr><td><b>Total Deductions</b></td><td class="num"><b>'.$money($deductTotal).'</b></td></tr></tbody></table>
</div>
<div class="net"><span>Net Salary</span><span>'.$money($slip['net_salary']).'</span></div>
'.$note.'
</body></html>';
    }

    protected function prettyDate(string $value): string
    {
        if (!preg_match('/^\d{4}-\d{2}-\d{2}/', $value)) {
            return $value;
        }
        $ts = strtotime(substr($value, 0, 10));

        return $ts ? date('F j, Y', $ts) : $value;
    }

    protected function defaultSetup(): array
    {
        return [
            'id' => 0,
            'name' => 'General Payroll',
            'payroll_type' => 'Payroll (Global)',
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

    public function companyCurrency(): string
    {
        if (!Schema::hasTable('company')) {
            return 'USD';
        }
        $code = strtoupper(trim((string) DB::table('company')->orderBy('id')->value('currency')));

        return $code !== '' ? $code : 'USD';
    }

    public function moneySymbol(?string $code = null): string
    {
        $iso = strtoupper(trim((string) ($code ?? $this->companyCurrency())));
        if ($iso === '') {
            $iso = 'USD';
        }
        if (class_exists(\NumberFormatter::class)) {
            $fmt = new \NumberFormatter('en_US', \NumberFormatter::CURRENCY);
            $sample = $fmt->formatCurrency(0, $iso);
            if (is_string($sample) && $sample !== '') {
                $symbol = trim(str_replace(['0', ',', '.', ' '], '', $sample));
                if ($symbol !== '') {
                    return $symbol;
                }
            }
        }

        return $iso.' ';
    }

    public function formatMoney(float $amount, ?string $code = null): string
    {
        $iso = strtoupper(trim((string) ($code ?? $this->companyCurrency())));
        if ($iso === '') {
            $iso = 'USD';
        }
        if (class_exists(\NumberFormatter::class)) {
            $fmt = new \NumberFormatter('en_US', \NumberFormatter::CURRENCY);
            $text = $fmt->formatCurrency($amount, $iso);
            if (is_string($text) && $text !== '') {
                return $text;
            }
        }

        return $this->moneySymbol($iso).number_format($amount, 2);
    }

    /** @return list<array{code:string,name:string}> */
    public function currencyCatalog(): array
    {
        return [
            ['code' => 'USD', 'name' => 'US Dollar'],
            ['code' => 'EUR', 'name' => 'Euro'],
            ['code' => 'GBP', 'name' => 'British Pound'],
            ['code' => 'AED', 'name' => 'UAE Dirham'],
            ['code' => 'SAR', 'name' => 'Saudi Riyal'],
            ['code' => 'CAD', 'name' => 'Canadian Dollar'],
            ['code' => 'AUD', 'name' => 'Australian Dollar'],
            ['code' => 'CHF', 'name' => 'Swiss Franc'],
            ['code' => 'JPY', 'name' => 'Japanese Yen'],
            ['code' => 'CNY', 'name' => 'Chinese Yuan'],
            ['code' => 'INR', 'name' => 'Indian Rupee'],
            ['code' => 'SGD', 'name' => 'Singapore Dollar'],
            ['code' => 'HKD', 'name' => 'Hong Kong Dollar'],
            ['code' => 'NZD', 'name' => 'New Zealand Dollar'],
            ['code' => 'QAR', 'name' => 'Qatari Riyal'],
            ['code' => 'KWD', 'name' => 'Kuwaiti Dinar'],
            ['code' => 'BHD', 'name' => 'Bahraini Dinar'],
            ['code' => 'OMR', 'name' => 'Omani Rial'],
            ['code' => 'ZAR', 'name' => 'South African Rand'],
            ['code' => 'SEK', 'name' => 'Swedish Krona'],
            ['code' => 'NOK', 'name' => 'Norwegian Krone'],
            ['code' => 'DKK', 'name' => 'Danish Krone'],
            ['code' => 'MXN', 'name' => 'Mexican Peso'],
            ['code' => 'BRL', 'name' => 'Brazilian Real'],
            ['code' => 'TRY', 'name' => 'Turkish Lira'],
            ['code' => 'PKR', 'name' => 'Pakistani Rupee'],
        ];
    }

    /** @return list<array{code:string,name:string,station_ids:list<int>}> */
    public function payrollCountries(): array
    {
        if (!Schema::hasTable('station')) {
            return [];
        }
        $by = [];
        foreach (DB::table('station')->orderBy('name')->get() as $station) {
            [$code, $name] = $this->countryForStation((string) $station->name);
            $by[$code]['code'] = $code;
            $by[$code]['name'] = $name;
            $by[$code]['station_ids'][] = (int) $station->station_id;
        }

        return array_values($by);
    }

    /** @return array{0:string,1:string} */
    protected function countryForStation(string $name): array
    {
        $key = strtolower(trim($name));
        $map = [
            'new york' => ['us', 'USA'],
            'chicago' => ['us', 'USA'],
            'toronto' => ['ca', 'Canada'],
            'vancouver' => ['ca', 'Canada'],
            'berlin' => ['de', 'Germany'],
            'munich' => ['de', 'Germany'],
            'amsterdam' => ['nl', 'Netherlands'],
            'paris' => ['fr', 'France'],
            'zurich' => ['ch', 'Switzerland'],
        ];
        if (isset($map[$key])) {
            return $map[$key];
        }
        $code = substr(preg_replace('/[^a-z]/', '', $key) ?: 'xx', 0, 8);

        return [$code, $name !== '' ? $name : 'Other'];
    }

    /**
     * @param array<string, mixed> $filters
     * @return list<object>
     */
    public function filteredDefines(array $filters): array
    {
        if (!Schema::hasTable('define_salary')) {
            return [];
        }
        $q = DB::table('define_salary as d')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'd.employee_id')
            ->leftJoin('department as dep', 'dep.department_id', '=', 'e.department')
            ->leftJoin('station as st', 'st.station_id', '=', 'e.station')
            ->leftJoin('designation as des', 'des.designation_id', '=', 'e.designation');
        $country = (string) ($filters['country'] ?? '');
        if ($country !== '') {
            $ids = [];
            foreach ($this->payrollCountries() as $c) {
                if ($c['code'] === $country) {
                    $ids = $c['station_ids'];
                }
            }
            if ($ids === []) {
                return [];
            }
            $q->whereIn('e.station', $ids);
        }
        $embassy = array_values(array_filter(array_map('strval', (array) ($filters['embassy_codes'] ?? []))));
        if ($embassy !== []) {
            $ids = [];
            foreach ($this->payrollCountries() as $c) {
                if (in_array($c['code'], $embassy, true)) {
                    $ids = array_merge($ids, $c['station_ids']);
                }
            }
            if ($ids === []) {
                return [];
            }
            $q->whereIn('e.station', $ids);
        }
        foreach ([
            'station_ids' => 'e.station',
            'department_ids' => 'e.department',
            'designation_ids' => 'e.designation',
            'employee_ids' => 'e.employee_id',
            'project_ids' => 'e.project',
        ] as $key => $col) {
            $vals = array_values(array_filter(array_map('intval', (array) ($filters[$key] ?? []))));
            if ($vals !== []) {
                $q->whereIn($col, $vals);
            }
        }
        $exclude = array_values(array_filter(array_map('intval', (array) ($filters['exclude_ids'] ?? []))));
        if ($exclude !== []) {
            $q->whereNotIn('e.employee_id', $exclude);
        }

        return $q->select(
            'd.*',
            'e.name as employee_name',
            'dep.name as department_name',
            'st.name as station_name',
            'des.name as designation_name'
        )
            ->orderBy('e.name')
            ->limit(500)
            ->get()
            ->all();
    }

    /** @param array<string, mixed> $filters */
    public function previewRun(array $filters): array
    {
        $rows = $this->filteredDefines($filters);
        $ids = array_map(fn ($r) => (int) $r->id, $rows);
        $items = [];
        if ($ids !== [] && Schema::hasTable('define_salary_details')) {
            $details = DB::table('define_salary_details as dd')
                ->leftJoin('hr_payroll_item as i', 'i.id', '=', 'dd.payroll_item_id')
                ->whereIn('dd.define_salary_id', $ids)
                ->get(['dd.*', 'i.name as item_name']);
            foreach ($details as $d) {
                $items[(int) $d->define_salary_id][] = [
                    'item' => (string) ($d->item_name ?? 'Item'),
                    'description' => (string) ($d->item_name ?? ''),
                    'hours' => 0,
                    'amount' => (float) $d->allowance - (float) $d->deduction,
                    'employer' => 0,
                    'allowance' => (float) $d->allowance,
                    'deduction' => (float) $d->deduction,
                ];
            }
        }
        $out = [];
        foreach ($rows as $r) {
            $basic = (float) $r->basic_salary;
            $gross = (float) ($r->total_allowance ?: $basic);
            $deduct = (float) $r->total_deduction;
            $out[] = [
                'id' => (int) $r->id,
                'employee_id' => (int) $r->employee_id,
                'employee_name' => (string) ($r->employee_name ?? ''),
                'department_name' => (string) ($r->department_name ?? ''),
                'station_name' => (string) ($r->station_name ?? ''),
                'designation_name' => (string) ($r->designation_name ?? ''),
                'salary_type' => 'Salary',
                'basic_salary' => $basic,
                'additions' => max(0, $gross - $basic),
                'deductions' => $deduct,
                'gross' => $gross,
                'tax' => 0,
                'net' => (float) $r->net_salary,
                'items' => $items[(int) $r->id] ?? [],
            ];
        }

        return $out;
    }

    /**
     * True when this month already has a processed payslip for the selection:
     * the chosen employees, the chosen stations, or the whole organization.
     *
     * @param array<string, mixed> $filters
     */
    public function selectionAlreadyPaid(array $filters, string $date): bool
    {
        if (!Schema::hasTable('process_salary')) {
            return false;
        }
        $stamp = strtotime($date);
        if ($stamp === false) {
            return false;
        }
        $start = date('Y-m-01', $stamp);
        $end = date('Y-m-t', $stamp);

        $paid = DB::table('process_salary as ps')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'ps.employee_id')
            ->whereBetween('ps.date', [$start, $end]);
        if (Schema::hasColumn('process_salary', 'slip_status')) {
            $paid->where(function ($w) {
                $w->whereNull('ps.slip_status')
                    ->orWhere('ps.slip_status', '')
                    ->orWhereNotIn('ps.slip_status', ['cancelled', 'reversed']);
            });
        }

        $employeeIds = array_values(array_filter(array_map('intval', (array) ($filters['employee_ids'] ?? []))));
        $stationIds = array_values(array_filter(array_map('intval', (array) ($filters['station_ids'] ?? []))));
        $hasNarrow = $employeeIds !== []
            || $stationIds !== []
            || array_filter((array) ($filters['department_ids'] ?? [])) !== []
            || array_filter((array) ($filters['designation_ids'] ?? [])) !== []
            || array_filter((array) ($filters['project_ids'] ?? [])) !== []
            || array_filter((array) ($filters['embassy_codes'] ?? [])) !== [];

        if ($employeeIds !== []) {
            return (clone $paid)->whereIn('ps.employee_id', $employeeIds)->exists();
        }
        if ($stationIds !== []) {
            return (clone $paid)->whereIn('e.station', $stationIds)->exists();
        }
        if ($hasNarrow) {
            $ids = [];
            foreach ($this->filteredDefines($filters) as $def) {
                $ids[] = (int) $def->employee_id;
            }
            if ($ids === []) {
                return false;
            }

            return (clone $paid)->whereIn('ps.employee_id', $ids)->exists();
        }

        $country = (string) ($filters['country'] ?? '');
        if ($country !== '') {
            $ids = [];
            foreach ($this->payrollCountries() as $c) {
                if ($c['code'] === $country) {
                    $ids = $c['station_ids'];
                }
            }
            if ($ids !== []) {
                $paid->whereIn('e.station', $ids);
            }
        }

        return $paid->exists();
    }

    /** @param array<string, mixed> $filters */
    public function processFiltered(array $filters, string $date, int $days, int $actorId): array
    {
        $runs = [];
        $seen = [];
        foreach ($this->filteredDefines($filters) as $def) {
            $employeeId = (int) ($def->employee_id ?? 0);
            if ($employeeId < 1 || isset($seen[$employeeId])) {
                continue;
            }
            if ($this->employeeAlreadyPaid($employeeId, $date)) {
                $seen[$employeeId] = true;
                continue;
            }
            $seen[$employeeId] = true;
            $runs[] = $this->processOne($def, $date, $days, $actorId);
        }

        return ['count' => count($runs), 'runs' => $runs];
    }

    public function metaLookups(): array
    {
        return [
            'employees' => DB::table('employee')->orderBy('name')->limit(500)->get(
                Schema::hasColumn('employee', 'employee_code')
                    ? ['employee_id as id', 'name as label', 'employee_code as code']
                    : ['employee_id as id', 'name as label']
            ),
            'projects' => Schema::hasTable('project')
                ? DB::table('project')->orderBy('name')->get(['project_id as id', 'name as label'])
                : [],
            'stations' => Schema::hasTable('station')
                ? DB::table('station')->orderBy('name')->get(['station_id as id', 'name as label'])
                : [],
            'departments' => Schema::hasTable('department')
                ? DB::table('department')->orderBy('name')->get(['department_id as id', 'name as label'])
                : [],
            'designations' => Schema::hasTable('designation')
                ? DB::table('designation')->orderBy('name')->get(['designation_id as id', 'name as label'])
                : [],
            'countries' => $this->payrollCountries(),
            'currency' => $this->companyCurrency(),
            'currencies' => $this->currencyCatalog(),
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
            'employee_code' => (string) ($r->employee_code ?? ''),
            'period_start' => self::periodStart((string) ($r->date ?? '')),
            'period_end' => (string) ($r->date ?? ''),
            'slip_status' => (string) ($r->slip_status ?? 'processed'),
            'status' => self::slipStatusLabel((string) ($r->slip_status ?? 'processed')),
        ];
    }

    public static function slipStatusLabel(string $status): string
    {
        return match ($status) {
            'cancelled' => 'Cancelled',
            'reversed' => 'Reversed',
            default => 'Processed',
        };
    }

    public function ensureSlipStatus(): void
    {
        if (!Schema::hasTable('process_salary') || Schema::hasColumn('process_salary', 'slip_status')) {
            return;
        }
        try {
            DB::statement("ALTER TABLE `process_salary` ADD COLUMN `slip_status` VARCHAR(20) NOT NULL DEFAULT 'processed'");
        } catch (\Throwable $e) {
            // Applied by database/31_payslip_status.sql on the next schema boot.
        }
    }

    /** @return array<string, mixed>|null */
    public function setSlipStatus(int $id, string $status): ?array
    {
        $this->ensureSlipStatus();
        $row = DB::table('process_salary')->where('id', $id)->first();
        if (!$row) {
            return null;
        }
        $current = (string) ($row->slip_status ?? 'processed');
        if (!in_array($current, ['processed', ''], true)) {
            return ['error' => 'Only a processed payslip can be updated.'];
        }
        DB::table('process_salary')->where('id', $id)->update(['slip_status' => $status]);

        return $this->mapProcess(DB::table('process_salary as ps')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'ps.employee_id')
            ->leftJoin('project as p', 'p.project_id', '=', 'ps.project_id')
            ->select('ps.*', 'e.name as employee_name', 'e.employee_code', 'p.name as project_name')
            ->where('ps.id', $id)
            ->first());
    }

    protected static function periodStart(string $date): string
    {
        if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            return substr($date, 0, 8).'01';
        }

        return $date;
    }

    protected function employeeAlreadyPaid(int $employeeId, string $date): bool
    {
        $stamp = strtotime($date);
        if ($stamp === false || !Schema::hasTable('process_salary')) {
            return false;
        }
        $q = DB::table('process_salary')
            ->where('employee_id', $employeeId)
            ->whereBetween('date', [date('Y-m-01', $stamp), date('Y-m-t', $stamp)]);
        if (Schema::hasColumn('process_salary', 'slip_status')) {
            $q->where(function ($w) {
                $w->whereNull('slip_status')
                    ->orWhere('slip_status', '')
                    ->orWhereNotIn('slip_status', ['cancelled', 'reversed']);
            });
        }

        return $q->exists();
    }
}
