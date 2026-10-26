<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/** Filter-and-generate reports for people, attendance, leave, and pay. */
class ReportStudioController extends Controller
{
    public function meta()
    {
        return response()->json([
            'success' => true,
            'options' => [
                'stations' => $this->options('station', 'station_id'),
                'projects' => $this->options('project', 'project_id'),
                'divisions' => $this->options('hr_org_division', 'id'),
                'parent_departments' => $this->options('hr_parent_department', 'id'),
                'departments' => $this->options('department', 'department_id'),
                'designations' => $this->options('designation', 'designation_id'),
                'employees' => $this->employeeOptions(),
            ],
        ]);
    }

    public function run(Request $request)
    {
        $report = (string) $request->query('report', 'people');
        $built = match ($report) {
            'headcount' => $this->headcount($request),
            'new_hires' => $this->newHires($request),
            'attendance' => $this->attendance($request),
            'attendance_summary' => $this->attendanceSummary($request),
            'late_starts' => $this->lateStarts($request),
            'open_punches' => $this->openPunches($request),
            'absent_days' => $this->absentDays($request),
            'timesheet_detail' => $this->timesheetDetail($request),
            'timesheet_summary' => $this->timesheetSummary($request),
            'leave_activity' => $this->leaveActivity($request),
            'leave_summary' => $this->leaveSummary($request),
            'pay_profile' => $this->payProfile($request),
            'processed_pay' => $this->processedPay($request),
            'payroll_summary' => $this->payrollSummary($request),
            'additions' => $this->additions($request),
            'deductions' => $this->deductions($request),
            'overtime' => $this->overtime($request),
            'advances' => $this->advances($request),
            'settlements' => $this->settlements($request),
            default => $this->people($request),
        };

        return response()->json([
            'success' => true,
            'report' => $report,
            'columns' => $built['columns'],
            'rows' => $built['rows'],
            'totals' => $built['totals'] ?? new \stdClass(),
        ]);
    }

    private function people(Request $request): array
    {
        $rows = $this->peopleBase($request)
            ->orderBy('e.name')
            ->limit(400)
            ->get([
                'e.employee_id',
                'e.name',
                'e.employee_code',
                'e.status',
                's.name as station_name',
                'p.name as project_name',
                'd.name as department_name',
                'dg.name as designation_name',
            ])
            ->map(fn ($r) => [
                'name' => (string) $r->name,
                'code' => (string) ($r->employee_code ?? ''),
                'station' => (string) ($r->station_name ?? ''),
                'project' => (string) ($r->project_name ?? ''),
                'department' => (string) ($r->department_name ?? ''),
                'designation' => (string) ($r->designation_name ?? ''),
                'status' => (int) $r->status === 2 ? 'Admin' : ((int) $r->status > 0 ? 'Active' : 'Inactive'),
            ])->all();

        return [
            'columns' => [
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'station', 'label' => 'Station'],
                ['key' => 'project', 'label' => 'Project'],
                ['key' => 'department', 'label' => 'Department'],
                ['key' => 'designation', 'label' => 'Designation'],
                ['key' => 'status', 'label' => 'Status'],
            ],
            'rows' => $this->numbered($rows),
        ];
    }

    private function headcount(Request $request): array
    {
        $rows = $this->peopleBase($request)
            ->selectRaw("COALESCE(d.name, 'Unassigned') as group_name")
            ->selectRaw('COUNT(DISTINCT e.employee_id) as headcount')
            ->groupBy('d.name')
            ->orderByDesc('headcount')
            ->get()
            ->map(fn ($r) => [
                'department' => (string) $r->group_name,
                'headcount' => (int) $r->headcount,
            ])->all();

        return [
            'columns' => [
                ['key' => 'department', 'label' => 'Department'],
                ['key' => 'headcount', 'label' => 'People', 'numeric' => true],
            ],
            'rows' => $this->numbered($rows),
            'totals' => ['headcount' => array_sum(array_column($rows, 'headcount'))],
        ];
    }

    private function newHires(Request $request): array
    {
        if (!Schema::hasColumn('employee', 'joining_date')) {
            return $this->emptyGrid(['Name', 'Code', 'Joining date', 'Department', 'Designation']);
        }
        [$from, $to] = $this->range($request);
        $rows = $this->peopleBase($request)
            ->whereBetween('e.joining_date', [$from, $to])
            ->orderByDesc('e.joining_date')
            ->get([
                'e.name', 'e.employee_code', 'e.joining_date',
                'd.name as department_name', 'dg.name as designation_name',
            ])->map(fn ($r) => [
                'name' => (string) $r->name,
                'code' => (string) ($r->employee_code ?? ''),
                'joining_date' => (string) ($r->joining_date ?? ''),
                'department' => (string) ($r->department_name ?? ''),
                'designation' => (string) ($r->designation_name ?? ''),
            ])->all();

        return [
            'columns' => [
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'joining_date', 'label' => 'Joining date'],
                ['key' => 'department', 'label' => 'Department'],
                ['key' => 'designation', 'label' => 'Designation'],
            ],
            'rows' => $this->numbered($rows),
        ];
    }

    private function attendance(Request $request): array
    {
        if (!Schema::hasTable('attendance')) {
            return $this->emptyGrid(['Name', 'Code', 'Date', 'Start', 'End', 'Hours']);
        }
        [$from, $to] = $this->range($request);
        $rows = DB::table('attendance as a')
            ->join('employee as e', 'e.employee_id', '=', 'a.employee_id')
            ->whereIn('a.employee_id', $this->scopedIds($request))
            ->whereBetween('a.date', [$from, $to])
            ->orderByDesc('a.date')
            ->limit(500)
            ->get(['e.name', 'e.employee_code', 'a.date', 'a.punch_in', 'a.punch_out', 'a.total_minutes']);
        $out = [];
        $hours = 0.0;
        foreach ($rows as $r) {
            $h = round(((int) ($r->total_minutes ?? 0)) / 60, 2);
            $hours += $h;
            $out[] = [
                'name' => (string) $r->name,
                'code' => (string) ($r->employee_code ?? ''),
                'date' => (string) $r->date,
                'start' => $this->clock($r->punch_in),
                'end' => $this->clock($r->punch_out),
                'hours' => $h,
            ];
        }

        return [
            'columns' => [
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'date', 'label' => 'Date'],
                ['key' => 'start', 'label' => 'Start'],
                ['key' => 'end', 'label' => 'End'],
                ['key' => 'hours', 'label' => 'Hours', 'numeric' => true],
            ],
            'rows' => $this->numbered($out),
            'totals' => ['hours' => round($hours, 2)],
        ];
    }

    private function attendanceSummary(Request $request): array
    {
        if (!Schema::hasTable('attendance')) {
            return $this->emptyGrid(['Date', 'Present', 'Absent', 'Leave', 'Hours']);
        }
        [$from, $to] = $this->range($request);
        $hasStatus = Schema::hasColumn('attendance', 'status');
        $rows = DB::table('attendance as a')
            ->whereIn('a.employee_id', $this->scopedIds($request))
            ->whereBetween('a.date', [$from, $to])
            ->selectRaw('a.date, COUNT(*) as records')
            ->selectRaw($hasStatus ? 'SUM(a.status = 1) as present' : 'SUM(a.punch_in IS NOT NULL) as present')
            ->selectRaw($hasStatus ? 'SUM(a.status = 0) as absent' : '0 as absent')
            ->selectRaw($hasStatus ? 'SUM(a.status = 2) as leave_count' : '0 as leave_count')
            ->selectRaw('ROUND(COALESCE(SUM(a.total_minutes), 0) / 60, 2) as hours')
            ->groupBy('a.date')
            ->orderByDesc('a.date')
            ->get()
            ->map(fn ($r) => [
                'date' => (string) $r->date,
                'present' => (int) $r->present,
                'absent' => (int) $r->absent,
                'leave' => (int) $r->leave_count,
                'hours' => (float) $r->hours,
            ])->all();

        return [
            'columns' => [
                ['key' => 'date', 'label' => 'Date'],
                ['key' => 'present', 'label' => 'Present', 'numeric' => true],
                ['key' => 'absent', 'label' => 'Absent', 'numeric' => true],
                ['key' => 'leave', 'label' => 'Leave', 'numeric' => true],
                ['key' => 'hours', 'label' => 'Hours', 'numeric' => true],
            ],
            'rows' => $this->numbered($rows),
        ];
    }

    private function lateStarts(Request $request): array
    {
        if (!Schema::hasTable('attendance')) {
            return $this->emptyGrid(['Name', 'Code', 'Date', 'Start', 'Minutes late']);
        }
        [$from, $to] = $this->range($request);
        $rows = DB::table('attendance as a')
            ->join('employee as e', 'e.employee_id', '=', 'a.employee_id')
            ->whereIn('a.employee_id', $this->scopedIds($request))
            ->whereBetween('a.date', [$from, $to])
            ->whereNotNull('a.punch_in')
            ->whereRaw('TIME(a.punch_in) > ?', ['09:05:00'])
            ->orderByDesc('a.date')
            ->limit(500)
            ->get(['e.name', 'e.employee_code', 'a.date', 'a.punch_in']);
        $out = [];
        $late = 0;
        foreach ($rows as $r) {
            $minutes = $this->minutesAfter($r->punch_in, '09:05:00');
            $late += $minutes;
            $out[] = [
                'name' => (string) $r->name,
                'code' => (string) ($r->employee_code ?? ''),
                'date' => (string) $r->date,
                'start' => $this->clock($r->punch_in),
                'late_minutes' => $minutes,
            ];
        }

        return [
            'columns' => [
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'date', 'label' => 'Date'],
                ['key' => 'start', 'label' => 'Start'],
                ['key' => 'late_minutes', 'label' => 'Minutes late', 'numeric' => true],
            ],
            'rows' => $this->numbered($out),
            'totals' => ['late_minutes' => $late],
        ];
    }

    private function openPunches(Request $request): array
    {
        if (!Schema::hasTable('attendance')) {
            return $this->emptyGrid(['Name', 'Code', 'Date', 'Start']);
        }
        [$from, $to] = $this->range($request);
        $rows = DB::table('attendance as a')
            ->join('employee as e', 'e.employee_id', '=', 'a.employee_id')
            ->whereIn('a.employee_id', $this->scopedIds($request))
            ->whereBetween('a.date', [$from, $to])
            ->whereNotNull('a.punch_in')
            ->whereNull('a.punch_out')
            ->orderByDesc('a.date')
            ->limit(500)
            ->get(['e.name', 'e.employee_code', 'a.date', 'a.punch_in'])
            ->map(fn ($r) => [
                'name' => (string) $r->name,
                'code' => (string) ($r->employee_code ?? ''),
                'date' => (string) $r->date,
                'start' => $this->clock($r->punch_in),
            ])->all();

        return [
            'columns' => [
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'date', 'label' => 'Date'],
                ['key' => 'start', 'label' => 'Start'],
            ],
            'rows' => $this->numbered($rows),
        ];
    }

    private function absentDays(Request $request): array
    {
        if (!Schema::hasTable('attendance') || !Schema::hasColumn('attendance', 'status')) {
            return $this->emptyGrid(['Name', 'Code', 'Date', 'Notes']);
        }
        [$from, $to] = $this->range($request);
        $rows = DB::table('attendance as a')
            ->join('employee as e', 'e.employee_id', '=', 'a.employee_id')
            ->whereIn('a.employee_id', $this->scopedIds($request))
            ->whereBetween('a.date', [$from, $to])
            ->where('a.status', 0)
            ->orderByDesc('a.date')
            ->get(['e.name', 'e.employee_code', 'a.date', 'a.notes'])
            ->map(fn ($r) => [
                'name' => (string) $r->name,
                'code' => (string) ($r->employee_code ?? ''),
                'date' => (string) $r->date,
                'notes' => (string) ($r->notes ?? ''),
            ])->all();

        return [
            'columns' => [
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'date', 'label' => 'Date'],
                ['key' => 'notes', 'label' => 'Notes'],
            ],
            'rows' => $this->numbered($rows),
        ];
    }

    private function timesheetDetail(Request $request): array
    {
        if (!Schema::hasTable('timesheet')) {
            return $this->emptyGrid(['Name', 'Project', 'From', 'To', 'Hours', 'Status']);
        }
        [$from, $to] = $this->range($request);
        $rows = DB::table('timesheet as t')
            ->join('employee as e', 'e.employee_id', '=', 't.employee_id')
            ->leftJoin('project as p', 'p.project_id', '=', 't.project_id')
            ->whereIn('t.employee_id', $this->scopedIds($request))
            ->whereDate('t.from_date', '<=', $to)
            ->whereDate('t.to_date', '>=', $from)
            ->orderByDesc('t.from_date')
            ->get(['e.name', 'e.employee_code', 'p.name as project_name', 't.from_date', 't.to_date', 't.hours', 't.status'])
            ->map(fn ($r) => [
                'name' => (string) $r->name,
                'code' => (string) ($r->employee_code ?? ''),
                'project' => (string) ($r->project_name ?? ''),
                'from' => (string) $r->from_date,
                'to' => (string) $r->to_date,
                'hours' => (float) $r->hours,
                'status' => $this->approvalLabel($r->status),
            ])->all();

        return [
            'columns' => [
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'project', 'label' => 'Project'],
                ['key' => 'from', 'label' => 'From'],
                ['key' => 'to', 'label' => 'To'],
                ['key' => 'hours', 'label' => 'Hours', 'numeric' => true],
                ['key' => 'status', 'label' => 'Status'],
            ],
            'rows' => $this->numbered($rows),
            'totals' => ['hours' => round(array_sum(array_column($rows, 'hours')), 2)],
        ];
    }

    private function timesheetSummary(Request $request): array
    {
        if (!Schema::hasTable('timesheet')) {
            return $this->emptyGrid(['Name', 'Code', 'Entries', 'Hours']);
        }
        [$from, $to] = $this->range($request);
        $rows = DB::table('timesheet as t')
            ->join('employee as e', 'e.employee_id', '=', 't.employee_id')
            ->whereIn('t.employee_id', $this->scopedIds($request))
            ->whereDate('t.from_date', '<=', $to)
            ->whereDate('t.to_date', '>=', $from)
            ->groupBy('t.employee_id', 'e.name', 'e.employee_code')
            ->orderBy('e.name')
            ->get([
                'e.name', 'e.employee_code',
                DB::raw('COUNT(*) as entries'),
                DB::raw('ROUND(SUM(t.hours), 2) as hours'),
            ])->map(fn ($r) => [
                'name' => (string) $r->name,
                'code' => (string) ($r->employee_code ?? ''),
                'entries' => (int) $r->entries,
                'hours' => (float) $r->hours,
            ])->all();

        return [
            'columns' => [
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'entries', 'label' => 'Entries', 'numeric' => true],
                ['key' => 'hours', 'label' => 'Hours', 'numeric' => true],
            ],
            'rows' => $this->numbered($rows),
            'totals' => ['hours' => round(array_sum(array_column($rows, 'hours')), 2)],
        ];
    }

    private function leaveActivity(Request $request): array
    {
        if (!Schema::hasTable('leave')) {
            return $this->emptyGrid(['Name', 'Type', 'From', 'To', 'Days', 'Status']);
        }
        [$from, $to] = $this->range($request);
        $q = DB::table('leave as l')
            ->join('employee as e', 'e.employee_id', '=', 'l.employee')
            ->leftJoin('leave_type as lt', 'lt.id', '=', 'l.leave_type')
            ->whereIn('l.employee', $this->scopedIds($request))
            ->whereDate('l.from', '<=', $to)
            ->whereDate('l.to', '>=', $from)
            ->orderByDesc('l.from')
            ->limit(500);
        $rows = $q->get(['e.name', 'e.employee_code', 'lt.name as type_name', 'l.from', 'l.to', 'l.days', 'l.status']);
        $out = [];
        $days = 0.0;
        foreach ($rows as $r) {
            $days += (float) $r->days;
            $out[] = [
                'name' => (string) $r->name,
                'code' => (string) ($r->employee_code ?? ''),
                'type' => (string) ($r->type_name ?? ''),
                'from' => (string) $r->from,
                'to' => (string) $r->to,
                'days' => (float) $r->days,
                'status' => match ((int) $r->status) {
                    1 => 'Approved',
                    2 => 'Rejected',
                    default => 'Pending',
                },
            ];
        }

        return [
            'columns' => [
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'type', 'label' => 'Leave type'],
                ['key' => 'from', 'label' => 'From'],
                ['key' => 'to', 'label' => 'To'],
                ['key' => 'days', 'label' => 'Days', 'numeric' => true],
                ['key' => 'status', 'label' => 'Status'],
            ],
            'rows' => $this->numbered($out),
            'totals' => ['days' => $days],
        ];
    }

    private function leaveSummary(Request $request): array
    {
        if (!Schema::hasTable('leave')) {
            return $this->emptyGrid(['Leave type', 'Requests', 'Days']);
        }
        [$from, $to] = $this->range($request);
        $rows = DB::table('leave as l')
            ->leftJoin('leave_type as lt', 'lt.id', '=', 'l.leave_type')
            ->whereIn('l.employee', $this->scopedIds($request))
            ->whereDate('l.from', '<=', $to)
            ->whereDate('l.to', '>=', $from)
            ->groupBy('lt.name')
            ->orderByDesc('days')
            ->get([
                DB::raw("COALESCE(lt.name, 'Unspecified') as type_name"),
                DB::raw('COUNT(*) as requests'),
                DB::raw('ROUND(SUM(l.days), 2) as days'),
            ])->map(fn ($r) => [
                'type' => (string) $r->type_name,
                'requests' => (int) $r->requests,
                'days' => (float) $r->days,
            ])->all();

        return [
            'columns' => [
                ['key' => 'type', 'label' => 'Leave type'],
                ['key' => 'requests', 'label' => 'Requests', 'numeric' => true],
                ['key' => 'days', 'label' => 'Days', 'numeric' => true],
            ],
            'rows' => $this->numbered($rows),
            'totals' => ['days' => round(array_sum(array_column($rows, 'days')), 2)],
        ];
    }

    private function payProfile(Request $request): array
    {
        $q = $this->peopleBase($request)->orderBy('e.name')->limit(400);
        if (Schema::hasTable('hr_employee_pay')) {
            $q->leftJoin('hr_employee_pay as pay', 'pay.employee_id', '=', 'e.employee_id');
        }
        if (Schema::hasTable('define_salary')) {
            $basic = DB::table('define_salary')
                ->select('employee_id', DB::raw('MAX(basic_salary) as basic_salary'))
                ->groupBy('employee_id');
            $q->leftJoinSub($basic, 'ds', 'ds.employee_id', '=', 'e.employee_id');
        }
        $select = ['e.name', 'e.employee_code'];
        if (Schema::hasTable('hr_employee_pay')) {
            $select = array_merge($select, [
                'pay.salary_type', 'pay.annual_salary', 'pay.gross_salary', 'pay.hourly_salary', 'pay.ot_hourly_salary', 'pay.hours_per_week',
            ]);
        }
        if (Schema::hasTable('define_salary')) {
            $select[] = 'ds.basic_salary';
        }
        $rows = $q->get($select);
        $out = [];
        $totals = ['annual' => 0.0, 'monthly' => 0.0, 'basic' => 0.0];
        foreach ($rows as $r) {
            $annual = round((float) ($r->annual_salary ?? 0), 2);
            $monthly = round((float) ($r->gross_salary ?? 0), 2);
            $basic = round((float) ($r->basic_salary ?? 0), 2);
            $totals['annual'] += $annual;
            $totals['monthly'] += $monthly;
            $totals['basic'] += $basic;
            $out[] = [
                'name' => (string) $r->name,
                'code' => (string) ($r->employee_code ?? ''),
                'pay_type' => (string) ($r->salary_type ?? 'Salary'),
                'annual' => $annual,
                'monthly' => $monthly,
                'basic' => $basic,
                'hourly' => round((float) ($r->hourly_salary ?? 0), 2),
                'ot_hourly' => round((float) ($r->ot_hourly_salary ?? 0), 2),
                'hours_week' => round((float) ($r->hours_per_week ?? 0), 2),
            ];
        }
        foreach ($totals as $k => $v) {
            $totals[$k] = round($v, 2);
        }

        return [
            'columns' => [
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'pay_type', 'label' => 'Pay type'],
                ['key' => 'annual', 'label' => 'Annual pay', 'numeric' => true],
                ['key' => 'monthly', 'label' => 'Monthly pay', 'numeric' => true],
                ['key' => 'basic', 'label' => 'Basic', 'numeric' => true],
                ['key' => 'hourly', 'label' => 'Hourly', 'numeric' => true],
                ['key' => 'ot_hourly', 'label' => 'Overtime hourly', 'numeric' => true],
                ['key' => 'hours_week', 'label' => 'Hours / week', 'numeric' => true],
            ],
            'rows' => $this->numbered($out),
            'totals' => $totals,
        ];
    }

    private function processedPay(Request $request): array
    {
        if (!Schema::hasTable('process_salary')) {
            return $this->emptyGrid(['Name', 'Pay date', 'Basic', 'Allowances', 'Deductions', 'Net']);
        }
        [$from, $to] = $this->range($request);
        $select = [
            'ps.employee_id', 'e.name', 'e.employee_code', 'ps.date', 'ps.basic_salary', 'ps.total_allowance',
            'ps.total_deduction', 'ps.tax_amount', 'ps.net_salary',
        ];
        if (Schema::hasColumn('process_salary', 'slip_status')) {
            $select[] = 'ps.slip_status';
        }
        $rows = DB::table('process_salary as ps')
            ->join('employee as e', 'e.employee_id', '=', 'ps.employee_id')
            ->whereIn('ps.employee_id', $this->scopedIds($request))
            ->whereBetween('ps.date', [$from, $to])
            ->orderByDesc('ps.date')
            ->orderByDesc('ps.id')
            ->limit(2000)
            ->get($select);
        $kept = [];
        foreach ($rows as $r) {
            $month = substr((string) ($r->date ?? ''), 0, 7);
            $key = ((int) $r->employee_id).'|'.$month;
            $open = !in_array((string) ($r->slip_status ?? 'processed'), ['cancelled', 'reversed'], true);
            if (!isset($kept[$key])) {
                $kept[$key] = $r;
                continue;
            }
            $keptOpen = !in_array((string) ($kept[$key]->slip_status ?? 'processed'), ['cancelled', 'reversed'], true);
            if ($open && !$keptOpen) {
                $kept[$key] = $r;
            }
        }
        $out = [];
        $totals = ['basic' => 0.0, 'allowances' => 0.0, 'deductions' => 0.0, 'net' => 0.0];
        foreach ($kept as $r) {
            $basic = round((float) $r->basic_salary, 2);
            $allow = round((float) $r->total_allowance, 2);
            $ded = round((float) $r->total_deduction, 2);
            $net = round((float) $r->net_salary, 2);
            $totals['basic'] += $basic;
            $totals['allowances'] += $allow;
            $totals['deductions'] += $ded;
            $totals['net'] += $net;
            $out[] = [
                'name' => (string) $r->name,
                'code' => (string) ($r->employee_code ?? ''),
                'pay_date' => (string) ($r->date ?? ''),
                'basic' => $basic,
                'allowances' => $allow,
                'deductions' => $ded,
                'tax' => round((float) ($r->tax_amount ?? 0), 2),
                'net' => $net,
            ];
        }
        foreach ($totals as $k => $v) {
            $totals[$k] = round($v, 2);
        }

        return [
            'columns' => [
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'pay_date', 'label' => 'Pay date'],
                ['key' => 'basic', 'label' => 'Basic', 'numeric' => true],
                ['key' => 'allowances', 'label' => 'Allowances', 'numeric' => true],
                ['key' => 'deductions', 'label' => 'Deductions', 'numeric' => true],
                ['key' => 'tax', 'label' => 'Tax', 'numeric' => true],
                ['key' => 'net', 'label' => 'Net', 'numeric' => true],
            ],
            'rows' => $this->numbered($out),
            'totals' => $totals,
        ];
    }

    private function payrollSummary(Request $request): array
    {
        $detail = $this->processedPay($request);
        $months = [];
        foreach ($detail['rows'] as $row) {
            $month = substr((string) ($row['pay_date'] ?? ''), 0, 7);
            $months[$month] ??= ['month' => $month, 'people' => 0, 'gross' => 0.0, 'deductions' => 0.0, 'net' => 0.0];
            $months[$month]['people']++;
            $months[$month]['gross'] += (float) ($row['allowances'] ?? 0);
            $months[$month]['deductions'] += (float) ($row['deductions'] ?? 0);
            $months[$month]['net'] += (float) ($row['net'] ?? 0);
        }
        krsort($months);
        $rows = array_values($months);
        foreach ($rows as &$row) {
            $row['gross'] = round($row['gross'], 2);
            $row['deductions'] = round($row['deductions'], 2);
            $row['net'] = round($row['net'], 2);
        }

        return [
            'columns' => [
                ['key' => 'month', 'label' => 'Pay month'],
                ['key' => 'people', 'label' => 'People', 'numeric' => true],
                ['key' => 'gross', 'label' => 'Gross', 'numeric' => true],
                ['key' => 'deductions', 'label' => 'Deductions', 'numeric' => true],
                ['key' => 'net', 'label' => 'Net', 'numeric' => true],
            ],
            'rows' => $this->numbered($rows),
        ];
    }

    private function additions(Request $request): array
    {
        return $this->payLines($request, 'allowance', 'Addition');
    }

    private function deductions(Request $request): array
    {
        return $this->payLines($request, 'deduction', 'Deduction');
    }

    private function payLines(Request $request, string $side, string $label): array
    {
        if (!Schema::hasTable('define_salary_details') || !Schema::hasTable('define_salary')) {
            return $this->emptyGrid(['Name', 'Item', $label]);
        }
        $ids = $this->scopedIds($request);
        $amountCol = $side === 'allowance' ? 'dd.allowance' : 'dd.deduction';
        $rows = DB::table('define_salary_details as dd')
            ->join('define_salary as ds', 'ds.id', '=', 'dd.define_salary_id')
            ->join('employee as e', 'e.employee_id', '=', 'ds.employee_id')
            ->leftJoin('hr_payroll_item as i', 'i.id', '=', 'dd.payroll_item_id')
            ->whereIn('ds.employee_id', $ids)
            ->where($side === 'allowance' ? 'dd.allowance' : 'dd.deduction', '>', 0)
            ->orderBy('e.name')
            ->limit(500)
            ->get(['e.name', 'e.employee_code', 'i.name as item_name', 'i.category', DB::raw($amountCol.' as amount')]);
        $out = [];
        $total = 0.0;
        foreach ($rows as $r) {
            $amount = round((float) $r->amount, 2);
            $total += $amount;
            $out[] = [
                'name' => (string) $r->name,
                'code' => (string) ($r->employee_code ?? ''),
                'item' => (string) ($r->item_name ?? $label),
                'category' => (string) ($r->category ?? ''),
                'amount' => $amount,
            ];
        }

        return [
            'columns' => [
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'item', 'label' => 'Item'],
                ['key' => 'category', 'label' => 'Category'],
                ['key' => 'amount', 'label' => $label, 'numeric' => true],
            ],
            'rows' => $this->numbered($out),
            'totals' => ['amount' => round($total, 2)],
        ];
    }

    private function overtime(Request $request): array
    {
        if (!Schema::hasTable('hr_overtime_entry')) {
            return $this->emptyGrid(['Name', 'Date', 'Hours']);
        }
        [$from, $to] = $this->range($request);
        $rows = DB::table('hr_overtime_entry as o')
            ->join('employee as e', 'e.employee_id', '=', 'o.employee_id')
            ->whereIn('o.employee_id', $this->scopedIds($request))
            ->whereBetween('o.work_date', [$from, $to])
            ->orderByDesc('o.work_date')
            ->limit(500)
            ->get(['e.name', 'e.employee_code', 'o.work_date', 'o.hours', 'o.rate_multiplier', 'o.status']);
        $out = [];
        $hours = 0.0;
        foreach ($rows as $r) {
            $h = round((float) $r->hours, 2);
            $hours += $h;
            $out[] = [
                'name' => (string) $r->name,
                'code' => (string) ($r->employee_code ?? ''),
                'date' => (string) $r->work_date,
                'hours' => $h,
                'multiplier' => (float) $r->rate_multiplier,
                'status' => match ((int) $r->status) {
                    1 => 'Approved',
                    2 => 'Rejected',
                    default => 'Pending',
                },
            ];
        }

        return [
            'columns' => [
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'date', 'label' => 'Date'],
                ['key' => 'hours', 'label' => 'Hours', 'numeric' => true],
                ['key' => 'multiplier', 'label' => 'Multiplier', 'numeric' => true],
                ['key' => 'status', 'label' => 'Status'],
            ],
            'rows' => $this->numbered($out),
            'totals' => ['hours' => round($hours, 2)],
        ];
    }

    private function advances(Request $request): array
    {
        if (!Schema::hasTable('hr_advance')) {
            return $this->emptyGrid(['Name', 'Code', 'Request date', 'Amount', 'Recovery months', 'Status']);
        }
        [$from, $to] = $this->range($request);
        $rows = DB::table('hr_advance as a')
            ->join('employee as e', 'e.employee_id', '=', 'a.employee_id')
            ->whereIn('a.employee_id', $this->scopedIds($request))
            ->whereBetween('a.request_date', [$from, $to])
            ->orderByDesc('a.request_date')
            ->get(['e.name', 'e.employee_code', 'a.request_date', 'a.amount', 'a.recover_months', 'a.status'])
            ->map(fn ($r) => [
                'name' => (string) $r->name,
                'code' => (string) ($r->employee_code ?? ''),
                'date' => (string) ($r->request_date ?? ''),
                'amount' => round((float) $r->amount, 2),
                'months' => (int) $r->recover_months,
                'status' => $this->approvalLabel($r->status),
            ])->all();

        return [
            'columns' => [
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'date', 'label' => 'Request date'],
                ['key' => 'amount', 'label' => 'Amount', 'numeric' => true],
                ['key' => 'months', 'label' => 'Recovery months', 'numeric' => true],
                ['key' => 'status', 'label' => 'Status'],
            ],
            'rows' => $this->numbered($rows),
            'totals' => ['amount' => round(array_sum(array_column($rows, 'amount')), 2)],
        ];
    }

    private function settlements(Request $request): array
    {
        if (!Schema::hasTable('employee_settlements')) {
            return $this->emptyGrid(['Name', 'Last working date', 'Clearance', 'Total payable', 'Net payable']);
        }
        [$from, $to] = $this->range($request);
        $rows = DB::table('employee_settlements as s')
            ->join('employee as e', 'e.employee_id', '=', 's.employee')
            ->whereIn('s.employee', $this->scopedIds($request))
            ->whereBetween('s.last_working_date', [$from, $to])
            ->orderByDesc('s.last_working_date')
            ->get(['e.name', 'e.employee_code', 's.last_working_date', 's.clearance_status', 's.total_payable', 's.net_payable'])
            ->map(fn ($r) => [
                'name' => (string) $r->name,
                'code' => (string) ($r->employee_code ?? ''),
                'last_day' => (string) ($r->last_working_date ?? ''),
                'clearance' => (string) ($r->clearance_status ?? ''),
                'total' => round((float) $r->total_payable, 2),
                'net' => round((float) $r->net_payable, 2),
            ])->all();

        return [
            'columns' => [
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'last_day', 'label' => 'Last working date'],
                ['key' => 'clearance', 'label' => 'Clearance'],
                ['key' => 'total', 'label' => 'Total payable', 'numeric' => true],
                ['key' => 'net', 'label' => 'Net payable', 'numeric' => true],
            ],
            'rows' => $this->numbered($rows),
            'totals' => ['net' => round(array_sum(array_column($rows, 'net')), 2)],
        ];
    }

    private function peopleBase(Request $request)
    {
        $q = DB::table('employee as e')
            ->leftJoin('department as d', 'd.department_id', '=', 'e.department')
            ->leftJoin('designation as dg', 'dg.designation_id', '=', 'e.designation')
            ->leftJoin('station as s', 's.station_id', '=', 'e.station')
            ->leftJoin('project as p', 'p.project_id', '=', 'e.project');
        $this->applyFilters($q, $request);

        return $q;
    }

    /** @return array<int, int> */
    private function scopedIds(Request $request): array
    {
        $ids = $this->peopleBase($request)->limit(500)->pluck('e.employee_id')->map(fn ($id) => (int) $id)->all();

        return $ids === [] ? [0] : $ids;
    }

    private function applyFilters($q, Request $request): void
    {
        if ($request->query('status', 'active') !== 'all') {
            $q->where('e.status', '>', 0);
        }
        if ($request->filled('employee_id')) {
            $q->where('e.employee_id', (int) $request->query('employee_id'));
        }
        if ($request->filled('station_id')) {
            $q->where('e.station', (int) $request->query('station_id'));
        }
        if ($request->filled('project_id')) {
            $q->where('e.project', (int) $request->query('project_id'));
        }
        if ($request->filled('department_id')) {
            $q->where('e.department', (int) $request->query('department_id'));
        }
        if ($request->filled('designation_id')) {
            $q->where('e.designation', (int) $request->query('designation_id'));
        }
        if ($request->filled('division_id') && Schema::hasColumn('department', 'division_id')) {
            $q->where('d.division_id', (int) $request->query('division_id'));
        }
        if ($request->filled('parent_department_id') && Schema::hasColumn('department', 'parent_department_id')) {
            $q->where('d.parent_department_id', (int) $request->query('parent_department_id'));
        }
    }

    /** @return array{0: string, 1: string} */
    private function range(Request $request): array
    {
        $from = (string) $request->query('from', now()->startOfMonth()->toDateString());
        $to = (string) $request->query('to', now()->toDateString());
        if ($to < $from) {
            [$from, $to] = [$to, $from];
        }

        return [$from, $to];
    }

    private function options(string $table, string $idColumn): array
    {
        if (!Schema::hasTable($table) || !Schema::hasColumn($table, 'name')) {
            return [];
        }

        return DB::table($table)->orderBy('name')->limit(200)->get([$idColumn, 'name'])->map(fn ($r) => [
            'id' => (int) $r->{$idColumn},
            'name' => (string) $r->name,
        ])->all();
    }

    private function employeeOptions(): array
    {
        if (!Schema::hasTable('employee')) {
            return [];
        }

        return DB::table('employee')->where('status', '>', 0)->orderBy('name')->limit(400)
            ->get(['employee_id', 'name', 'employee_code'])->map(fn ($r) => [
                'id' => (int) $r->employee_id,
                'name' => trim((string) $r->name.($r->employee_code ? ' ('.$r->employee_code.')' : '')),
            ])->all();
    }

    private function numbered(array $rows): array
    {
        $n = 1;
        foreach ($rows as &$row) {
            $row = ['n' => $n++] + $row;
        }

        return $rows;
    }

    private function emptyGrid(array $labels): array
    {
        $columns = [['key' => 'n', 'label' => '#']];
        foreach ($labels as $i => $label) {
            $columns[] = ['key' => 'c'.$i, 'label' => $label];
        }

        return ['columns' => $columns, 'rows' => []];
    }

    private function clock(mixed $value): string
    {
        $text = (string) ($value ?? '');
        if (strlen($text) >= 16) {
            return substr($text, 11, 5);
        }

        return $text;
    }

    private function approvalLabel(mixed $status): string
    {
        return match ((int) $status) {
            1 => 'Approved',
            2 => 'Rejected',
            3 => 'Closed',
            default => 'Pending',
        };
    }

    private function minutesAfter(mixed $punch, string $start): int
    {
        $clock = $this->clock($punch);
        if ($clock === '') {
            return 0;
        }
        $a = strtotime('2000-01-01 '.$clock);
        $b = strtotime('2000-01-01 '.substr($start, 0, 5));
        if ($a === false || $b === false || $a <= $b) {
            return 0;
        }

        return (int) round(($a - $b) / 60);
    }
}
