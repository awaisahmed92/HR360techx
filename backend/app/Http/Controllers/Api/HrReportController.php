<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/** Non-payroll HR reports (leave, attendance summary/log, employee list). */
class HrReportController extends Controller
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
        $departments = [];
        if (Schema::hasTable('department')) {
            $departments = DB::table('department')->orderBy('name')
                ->get(['department_id', 'name'])->map(fn ($r) => [
                    'id' => (int) $r->department_id,
                    'name' => (string) $r->name,
                ])->all();
        }
        $leaveTypes = [];
        if (Schema::hasTable('leave_type')) {
            $leaveTypes = DB::table('leave_type')->orderBy('name')
                ->get(['id', 'name'])->map(fn ($r) => [
                    'id' => (int) $r->id,
                    'name' => (string) $r->name,
                ])->all();
        }

        return response()->json([
            'success' => true,
            'options' => [
                'employees' => $employees,
                'departments' => $departments,
                'leave_types' => $leaveTypes,
                'leave_statuses' => [
                    ['id' => 0, 'name' => 'Pending'],
                    ['id' => 1, 'name' => 'Approved'],
                    ['id' => 2, 'name' => 'Rejected'],
                ],
                'employee_report_types' => [
                    ['id' => 'active', 'name' => 'Active'],
                    ['id' => 'joiner', 'name' => 'Joiners'],
                    ['id' => 'leaver', 'name' => 'Leavers'],
                ],
            ],
        ]);
    }

    /** Leave applications report. */
    public function leave(Request $request)
    {
        if (!Schema::hasTable('leave')) {
            return response()->json(['success' => false, 'message' => 'Leave table missing'], 503);
        }

        $q = DB::table('leave as l')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'l.employee')
            ->leftJoin('leave_type as lt', 'lt.id', '=', 'l.leave_type')
            ->leftJoin('department as d', 'd.department_id', '=', 'e.department')
            ->select(
                'l.id',
                'l.employee',
                'l.leave_type',
                'l.from',
                'l.to',
                'l.days',
                'l.status',
                'l.reason',
                'l.date',
                'e.name as employee_name',
                'e.employee_code',
                'lt.name as leave_type_name',
                'd.name as department_name'
            )
            ->orderByDesc('l.from');

        if ($request->filled('employee_id')) {
            $q->where('l.employee', (int) $request->query('employee_id'));
        }
        if ($request->filled('status') && $request->query('status') !== '') {
            $q->where('l.status', (int) $request->query('status'));
        }
        if ($request->filled('leave_type_id')) {
            $q->where('l.leave_type', (int) $request->query('leave_type_id'));
        }
        if ($request->filled('department_id') && Schema::hasColumn('employee', 'department')) {
            $q->where('e.department', (int) $request->query('department_id'));
        }
        if ($request->filled('month') && $request->filled('year')) {
            $m = (int) $request->query('month');
            $y = (int) $request->query('year');
            $q->where(function ($w) use ($m, $y) {
                $w->whereMonth('l.from', $m)->whereYear('l.from', $y);
            });
        } else {
            if ($request->filled('from')) {
                $q->whereDate('l.from', '>=', $request->query('from'));
            }
            if ($request->filled('to')) {
                $q->whereDate('l.to', '<=', $request->query('to'));
            }
        }

        // Exclude assignment-only rows
        if (Schema::hasColumn('leave', 'assigned')) {
            $q->where(function ($w) {
                $w->whereNull('l.assigned')->orWhere('l.assigned', '<=', 0);
            });
        }

        $rows = $q->limit(500)->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'employee_id' => (int) $r->employee,
            'employee_name' => (string) ($r->employee_name ?? ''),
            'employee_code' => (string) ($r->employee_code ?? ''),
            'department_name' => (string) ($r->department_name ?? ''),
            'leave_type_id' => (int) $r->leave_type,
            'leave_type' => (string) ($r->leave_type_name ?? ''),
            'from' => (string) ($r->from ?? ''),
            'to' => (string) ($r->to ?? ''),
            'days' => (float) ($r->days ?? 0),
            'status' => (int) $r->status,
            'status_label' => match ((int) $r->status) {
                1 => 'Approved',
                2 => 'Rejected',
                default => 'Pending',
            },
            'reason' => (string) ($r->reason ?? ''),
            'applied_on' => (string) ($r->date ?? ''),
        ]);

        return response()->json(['success' => true, 'rows' => $rows]);
    }

    /** Leave balance by employee × type. */
    public function leaveBalance(Request $request)
    {
        if (!Schema::hasTable('leave') || !Schema::hasTable('leave_type')) {
            return response()->json(['success' => false, 'message' => 'Leave tables missing'], 503);
        }

        $empQ = DB::table('employee as e')->where('e.status', '>', 0)->orderBy('e.name');
        if ($request->filled('employee_id')) {
            $empQ->where('e.employee_id', (int) $request->query('employee_id'));
        }
        if ($request->filled('department_id') && Schema::hasColumn('employee', 'department')) {
            $empQ->where('e.department', (int) $request->query('department_id'));
        }
        $employees = $empQ->limit(300)->get(['e.employee_id', 'e.name', 'e.employee_code', 'e.department']);

        $types = DB::table('leave_type')->orderBy('name')->get(['id', 'name', 'days']);
        if ($request->filled('leave_type_id')) {
            $types = $types->where('id', (int) $request->query('leave_type_id'))->values();
        }

        $hasAssigned = Schema::hasColumn('leave', 'assigned');
        $rows = [];

        foreach ($employees as $emp) {
            $uid = (int) $emp->employee_id;
            foreach ($types as $t) {
                $typeId = (int) $t->id;
                $quota = (float) $t->days;
                if ($hasAssigned) {
                    $assigned = (float) DB::table('leave')
                        ->where('employee', $uid)
                        ->where('leave_type', $typeId)
                        ->where('assigned', '>', 0)
                        ->sum('assigned');
                    if ($assigned > 0) {
                        $quota = $assigned;
                    }
                }

                $usedQ = DB::table('leave')
                    ->where('employee', $uid)
                    ->where('leave_type', $typeId)
                    ->where('status', '!=', 2);
                if ($hasAssigned) {
                    $usedQ->where(function ($w) {
                        $w->whereNull('assigned')->orWhere('assigned', '<=', 0);
                    });
                }
                $used = (float) $usedQ->sum('days');

                $rows[] = [
                    'employee_id' => $uid,
                    'employee_name' => (string) $emp->name,
                    'employee_code' => (string) ($emp->employee_code ?? ''),
                    'leave_type_id' => $typeId,
                    'leave_type' => (string) $t->name,
                    'entitled' => $quota,
                    'used' => $used,
                    'remaining' => max(0, $quota - $used),
                ];
            }
        }

        return response()->json(['success' => true, 'rows' => $rows]);
    }

    /** Leave usage grouped by employee or department. */
    public function leaveUsage(Request $request)
    {
        if (!Schema::hasTable('leave')) {
            return response()->json(['success' => false, 'message' => 'Leave table missing'], 503);
        }

        $groupBy = $request->query('group_by', 'employee');
        $from = $request->query('from', now()->startOfYear()->toDateString());
        $to = $request->query('to', now()->toDateString());

        $q = DB::table('leave as l')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'l.employee')
            ->leftJoin('department as d', 'd.department_id', '=', 'e.department')
            ->leftJoin('leave_type as lt', 'lt.id', '=', 'l.leave_type')
            ->where('l.status', 1)
            ->whereDate('l.from', '>=', $from)
            ->whereDate('l.from', '<=', $to);

        if (Schema::hasColumn('leave', 'assigned')) {
            $q->where(function ($w) {
                $w->whereNull('l.assigned')->orWhere('l.assigned', '<=', 0);
            });
        }

        if ($groupBy === 'department') {
            $rows = $q->select(
                DB::raw("COALESCE(d.name, 'Unassigned') as group_name"),
                DB::raw('COUNT(DISTINCT l.employee) as headcount'),
                DB::raw('SUM(l.days) as days_used'),
                DB::raw('COUNT(l.id) as applications')
            )->groupBy('d.department_id', 'd.name')->orderByDesc('days_used')->get();
        } else {
            $rows = $q->select(
                'e.name as group_name',
                'e.employee_code',
                DB::raw('1 as headcount'),
                DB::raw('SUM(l.days) as days_used'),
                DB::raw('COUNT(l.id) as applications')
            )->groupBy('l.employee', 'e.name', 'e.employee_code')->orderByDesc('days_used')->limit(200)->get();
        }

        $mapped = $rows->map(fn ($r) => [
            'group_name' => (string) ($r->group_name ?? ''),
            'employee_code' => (string) ($r->employee_code ?? ''),
            'headcount' => (int) ($r->headcount ?? 0),
            'days_used' => (float) ($r->days_used ?? 0),
            'applications' => (int) ($r->applications ?? 0),
        ]);

        return response()->json([
            'success' => true,
            'from' => $from,
            'to' => $to,
            'group_by' => $groupBy,
            'rows' => $mapped,
        ]);
    }

    /** Active / joiners / leavers. */
    public function employees(Request $request)
    {
        if (!Schema::hasTable('employee')) {
            return response()->json(['success' => false, 'message' => 'Employee table missing'], 503);
        }

        $type = strtolower((string) $request->query('report_type', 'active'));
        $from = $request->query('from', now()->startOfYear()->toDateString());
        $to = $request->query('to', now()->toDateString());

        $q = DB::table('employee as e')
            ->leftJoin('department as d', 'd.department_id', '=', 'e.department')
            ->leftJoin('designation as des', 'des.designation_id', '=', 'e.designation')
            ->select(
                'e.employee_id',
                'e.employee_code',
                'e.name',
                'e.status',
                'e.joining_date',
                'e.leaving_date',
                'e.exit_date',
                'd.name as department_name',
                'des.name as designation_name'
            )
            ->orderBy('e.name');

        if ($request->filled('department_id')) {
            $q->where('e.department', (int) $request->query('department_id'));
        }

        if ($type === 'joiner' && Schema::hasColumn('employee', 'joining_date')) {
            $q->whereNotNull('e.joining_date')
                ->whereDate('e.joining_date', '>=', $from)
                ->whereDate('e.joining_date', '<=', $to);
        } elseif ($type === 'leaver') {
            $leaveCol = Schema::hasColumn('employee', 'leaving_date') ? 'leaving_date'
                : (Schema::hasColumn('employee', 'exit_date') ? 'exit_date' : null);
            if ($leaveCol) {
                $q->whereNotNull("e.$leaveCol")
                    ->whereDate("e.$leaveCol", '>=', $from)
                    ->whereDate("e.$leaveCol", '<=', $to);
            } else {
                $q->where('e.status', 0);
            }
        } else {
            $q->where('e.status', '>', 0);
        }

        $rows = $q->limit(500)->get()->map(function ($r) {
            $exit = $r->leaving_date ?? $r->exit_date ?? null;

            return [
                'id' => (int) $r->employee_id,
                'employee_code' => (string) ($r->employee_code ?? ''),
                'name' => (string) $r->name,
                'department' => (string) ($r->department_name ?? ''),
                'designation' => (string) ($r->designation_name ?? ''),
                'status' => (int) ($r->status ?? 0),
                'status_label' => ((int) ($r->status ?? 0)) > 0 ? 'Active' : 'Inactive',
                'joining_date' => $r->joining_date,
                'leaving_date' => $exit,
            ];
        });

        return response()->json([
            'success' => true,
            'report_type' => $type,
            'from' => $from,
            'to' => $to,
            'rows' => $rows,
        ]);
    }

    /** Monthly attendance rollup per employee. */
    public function attendanceMonthly(Request $request)
    {
        if (!Schema::hasTable('attendance')) {
            return response()->json(['success' => false, 'message' => 'Attendance table missing'], 503);
        }

        $month = (int) $request->query('month', now()->month);
        $year = (int) $request->query('year', now()->year);
        $from = sprintf('%04d-%02d-01', $year, $month);
        $to = date('Y-m-t', strtotime($from));

        $empQ = DB::table('employee as e')->where('e.status', '>', 0)->orderBy('e.name');
        if ($request->filled('employee_id')) {
            $empQ->where('e.employee_id', (int) $request->query('employee_id'));
        }
        if ($request->filled('department_id') && Schema::hasColumn('employee', 'department')) {
            $empQ->where('e.department', (int) $request->query('department_id'));
        }
        $employees = $empQ->limit(300)->get(['e.employee_id', 'e.name', 'e.employee_code']);

        $attRows = DB::table('attendance')
            ->whereBetween('date', [$from, $to])
            ->get();

        $byEmp = [];
        foreach ($attRows as $a) {
            $eid = (int) $a->employee_id;
            if (!isset($byEmp[$eid])) {
                $byEmp[$eid] = ['present' => 0, 'absent' => 0, 'leave' => 0, 'late' => 0];
            }
            $st = isset($a->status) ? (int) $a->status : (!empty($a->punch_in) ? 1 : 0);
            if ($st === 1 || !empty($a->punch_in)) {
                $byEmp[$eid]['present']++;
            } elseif ($st === 2) {
                $byEmp[$eid]['leave']++;
            } else {
                $byEmp[$eid]['absent']++;
            }
            if (!empty($a->late_minutes) && (int) $a->late_minutes > 0) {
                $byEmp[$eid]['late']++;
            }
        }

        // Leave days overlapping month
        if (Schema::hasTable('leave')) {
            $leaves = DB::table('leave')
                ->where('status', 1)
                ->whereDate('from', '<=', $to)
                ->whereDate('to', '>=', $from)
                ->get(['employee', 'from', 'to', 'days']);
            foreach ($leaves as $lv) {
                $eid = (int) $lv->employee;
                if (!isset($byEmp[$eid])) {
                    $byEmp[$eid] = ['present' => 0, 'absent' => 0, 'leave' => 0, 'late' => 0];
                }
                // Prefer days field when present
                $byEmp[$eid]['leave'] += max(1, (int) ($lv->days ?? 1));
            }
        }

        $rows = [];
        foreach ($employees as $e) {
            $eid = (int) $e->employee_id;
            $stats = $byEmp[$eid] ?? ['present' => 0, 'absent' => 0, 'leave' => 0, 'late' => 0];
            $rows[] = [
                'employee_id' => $eid,
                'employee_name' => (string) $e->name,
                'employee_code' => (string) ($e->employee_code ?? ''),
                'present' => (int) $stats['present'],
                'absent' => (int) $stats['absent'],
                'leave' => (int) $stats['leave'],
                'late' => (int) $stats['late'],
            ];
        }

        return response()->json([
            'success' => true,
            'month' => $month,
            'year' => $year,
            'from' => $from,
            'to' => $to,
            'rows' => $rows,
        ]);
    }

    /** Punch log over a date range. */
    public function attendanceLog(Request $request)
    {
        if (!Schema::hasTable('attendance')) {
            return response()->json(['success' => false, 'message' => 'Attendance table missing'], 503);
        }

        $from = $request->query('from', now()->startOfMonth()->toDateString());
        $to = $request->query('to', now()->toDateString());

        $q = DB::table('attendance as a')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'a.employee_id')
            ->leftJoin('department as d', 'd.department_id', '=', 'e.department')
            ->whereBetween('a.date', [$from, $to])
            ->orderByDesc('a.date')
            ->orderBy('e.name')
            ->select(
                'a.id',
                'a.employee_id',
                'a.date',
                'a.punch_in',
                'a.punch_out',
                'a.total_minutes',
                'a.status',
                'a.late_minutes',
                'e.name as employee_name',
                'e.employee_code',
                'd.name as department_name'
            );

        if ($request->filled('employee_id')) {
            $q->where('a.employee_id', (int) $request->query('employee_id'));
        }
        if ($request->filled('department_id') && Schema::hasColumn('employee', 'department')) {
            $q->where('e.department', (int) $request->query('department_id'));
        }
        if ($request->filled('status') && $request->query('status') !== '') {
            $q->where('a.status', (int) $request->query('status'));
        }

        $rows = $q->limit(1000)->get()->map(function ($r) {
            $st = isset($r->status) ? (int) $r->status : (!empty($r->punch_in) ? 1 : 0);

            return [
                'id' => (int) $r->id,
                'employee_id' => (int) $r->employee_id,
                'employee_name' => (string) ($r->employee_name ?? ''),
                'employee_code' => (string) ($r->employee_code ?? ''),
                'department' => (string) ($r->department_name ?? ''),
                'date' => (string) $r->date,
                'punch_in' => (string) ($r->punch_in ?? ''),
                'punch_out' => (string) ($r->punch_out ?? ''),
                'total_minutes' => (int) ($r->total_minutes ?? 0),
                'late_minutes' => (int) ($r->late_minutes ?? 0),
                'status' => $st,
                'status_label' => match ($st) {
                    1 => 'Present',
                    2 => 'Leave',
                    default => 'Absent',
                },
            ];
        });

        return response()->json([
            'success' => true,
            'from' => $from,
            'to' => $to,
            'rows' => $rows,
        ]);
    }
}
