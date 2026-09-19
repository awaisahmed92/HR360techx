<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ApprovalService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Profile, attendance, leave, timesheet, approvals — Laravel API.
 */
class SelfServiceController extends Controller
{
    public function __construct(private ApprovalService $approvals)
    {
    }
    public function profile(Request $request)
    {
        $uid = (int) ($request->attributes->get('hr_claims')['employee_id'] ?? 0);
        $e = DB::table('employee as e')
            ->leftJoin('designation as d', 'd.designation_id', '=', 'e.designation')
            ->leftJoin('department as dep', 'dep.department_id', '=', 'e.department')
            ->leftJoin('station as s', 's.station_id', '=', 'e.station')
            ->leftJoin('project as p', 'p.project_id', '=', 'e.project')
            ->leftJoin('employee as lm', 'lm.employee_id', '=', 'e.line_manager')
            ->where('e.employee_id', $uid)
            ->select('e.*', 'd.name as designation_name', 'dep.name as department_name',
                's.name as station_name', 'p.name as project_name', 'lm.name as line_manager_name')
            ->first();

        if (!$e) {
            return response()->json(['success' => false, 'message' => 'Not found.'], 404);
        }

        return response()->json(['success' => true, 'profile' => [
            'employee_id' => (int) $e->employee_id,
            'name' => UiPrefsController::displayName($e),
            'first_name' => ltrim(trim((string) ($e->name ?? '')), " \t,"),
            'surname' => ltrim(trim((string) ($e->surname ?? '')), " \t,"),
            'user_name' => (string) ($e->user_name ?? ''),
            'email' => (string) ($e->email ?? ''),
            'phone' => (string) ($e->phone ?? $e->contact_number ?? ''),
            'contact_number' => (string) ($e->contact_number ?? ''),
            'cnic' => (string) ($e->cnic ?? ''),
            'employee_code' => (string) ($e->employee_code ?? ''),
            'designation_id' => (int) ($e->designation ?? 0),
            'designation_name' => (string) ($e->designation_name ?? ''),
            'department_name' => (string) ($e->department_name ?? ''),
            'station_name' => (string) ($e->station_name ?? ''),
            'project_name' => (string) ($e->project_name ?? ''),
            'line_manager_name' => (string) ($e->line_manager_name ?? ''),
            'profile_picture' => $e->profile_picture ?? null,
            'status' => (int) ($e->status ?? 0),
            'gender' => isset($e->gender) ? (int) $e->gender : null,
            'date_of_birth' => $e->date_of_birth ?? null,
            'joining_date' => $e->joining_date ?? null,
            'blood_group' => (string) ($e->blood_group ?? ''),
            'marital_status' => (string) ($e->marital_status ?? ''),
            'religion' => (string) ($e->religion ?? ''),
            'address' => (string) ($e->address ?? ''),
            'employee_type' => (int) ($e->employee_type ?? 0),
            'personal_email' => (string) ($e->personal_email ?? ''),
            'salutation' => (string) ($e->salutation ?? ''),
            'preferred_name' => (string) ($e->preferred_name ?? ''),
            'nickname' => (string) ($e->nickname ?? ''),
            'pronoun' => (string) ($e->pronoun ?? ''),
            'nationality' => (string) ($e->nationality ?? ''),
            'race' => (string) ($e->race ?? ''),
            'home_phone' => (string) ($e->home_phone ?? ''),
            'office_phone' => (string) ($e->office_phone ?? ''),
            'mobile_number' => (string) ($e->mobile_number ?? ''),
            'ssn' => (string) ($e->ssn ?? ''),
            'grade' => (string) ($e->grade ?? ''),
            'grade_step' => (string) ($e->grade_step ?? ''),
            'employee_category' => (string) ($e->employee_category ?? ''),
            'calculated_service_date' => $e->calculated_service_date ?? null,
        ]]);
    }

    public function updateProfile(Request $request)
    {
        $uid = (int) ($request->attributes->get('hr_claims')['employee_id'] ?? 0);
        $data = $request->validate([
            'email' => 'nullable|email|max:191',
            'phone' => 'nullable|string|max:50',
            'personal_email' => 'nullable|email|max:191',
            'preferred_name' => 'nullable|string|max:120',
            'nickname' => 'nullable|string|max:80',
            'salutation' => 'nullable|string|max:40',
            'pronoun' => 'nullable|string|max:40',
            'date_of_birth' => 'nullable|date',
            'gender' => 'nullable|integer',
            'nationality' => 'nullable|string|max:80',
            'blood_group' => 'nullable|string|max:10',
            'religion' => 'nullable|string|max:80',
            'race' => 'nullable|string|max:80',
            'marital_status' => 'nullable|string|max:40',
            'mobile_number' => 'nullable|string|max:50',
            'home_phone' => 'nullable|string|max:50',
            'office_phone' => 'nullable|string|max:50',
            'address' => 'nullable|string|max:255',
            'ssn' => 'nullable|string|max:80',
        ]);

        $update = [];
        foreach ($data as $key => $value) {
            if (!Schema::hasColumn('employee', $key)) {
                continue;
            }
            if ($key === 'phone' && Schema::hasColumn('employee', 'phone')) {
                $update['phone'] = $value;
                if (Schema::hasColumn('employee', 'contact_number')) {
                    $update['contact_number'] = $value;
                }
                continue;
            }
            $update[$key] = $value;
        }
        if (!empty($update)) {
            DB::table('employee')->where('employee_id', $uid)->update($update);
        }

        return response()->json(['success' => true, 'message' => 'Profile updated.']);
    }

    public function attendanceToday(Request $request)
    {
        $uid = (int) ($request->attributes->get('hr_claims')['employee_id'] ?? 0);
        $today = now()->toDateString();
        $row = DB::table('attendance')->where('employee_id', $uid)->where('date', $today)->first();

        return response()->json([
            'success' => true,
            'date' => $today,
            'record' => $row ? $this->mapAttendance($row) : null,
            'can_punch_in' => !$row || empty($row->punch_in),
            'can_punch_out' => $row && !empty($row->punch_in) && empty($row->punch_out),
        ]);
    }

    public function attendanceList(Request $request)
    {
        $uid = (int) ($request->attributes->get('hr_claims')['employee_id'] ?? 0);
        $month = preg_match('/^\d{4}-\d{2}$/', (string) $request->query('month', ''))
            ? $request->query('month')
            : now()->format('Y-m');
        $rows = DB::table('attendance')
            ->where('employee_id', $uid)
            ->where('date', 'like', $month.'%')
            ->orderByDesc('date')
            ->get()
            ->map(fn ($r) => $this->mapAttendance($r));

        return response()->json(['success' => true, 'month' => $month, 'records' => $rows]);
    }

    public function punch(Request $request)
    {
        $uid = (int) ($request->attributes->get('hr_claims')['employee_id'] ?? 0);
        $action = strtolower((string) $request->input('action', 'in'));
        $today = now()->toDateString();
        $now = now()->toDateTimeString();
        $row = DB::table('attendance')->where('employee_id', $uid)->where('date', $today)->first();

        if ($action === 'in') {
            if ($row && !empty($row->punch_in)) {
                return response()->json(['success' => false, 'message' => 'Already punched in today.'], 422);
            }
            $late = 0;
            if (Schema::hasColumn('attendance', 'late_minutes')) {
                $start = '09:00:00';
                $grace = 15;
                if (Schema::hasTable('hr_payroll_setup')) {
                    $su = DB::table('hr_payroll_setup')->orderBy('id')->first();
                    if ($su) {
                        $start = (string) ($su->work_start_time ?? '09:00:00');
                        $grace = (int) ($su->late_grace_minutes ?? 15);
                    }
                }
                $punchTs = strtotime($now);
                $expected = strtotime($today.' '.$start) + ($grace * 60);
                $late = max(0, (int) round(($punchTs - $expected) / 60));
            }
            $payload = ['punch_in' => $now];
            if (Schema::hasColumn('attendance', 'late_minutes')) {
                $payload['late_minutes'] = $late;
            }
            if (Schema::hasColumn('attendance', 'status')) {
                $payload['status'] = 1;
            }
            if ($row) {
                DB::table('attendance')->where('id', $row->id)->update($payload);
            } else {
                $payload['employee_id'] = $uid;
                $payload['date'] = $today;
                DB::table('attendance')->insert($payload);
            }

            return response()->json(['success' => true, 'message' => 'Punched in.', 'punch_in' => $now, 'late_minutes' => $late]);
        }

        if ($action === 'out') {
            if (!$row || empty($row->punch_in)) {
                return response()->json(['success' => false, 'message' => 'Punch in first.'], 422);
            }
            if (!empty($row->punch_out)) {
                return response()->json(['success' => false, 'message' => 'Already punched out today.'], 422);
            }
            $mins = max(0, (int) round((strtotime($now) - strtotime($row->punch_in)) / 60));
            DB::table('attendance')->where('id', $row->id)->update([
                'punch_out' => $now,
                'total_minutes' => $mins,
            ]);

            return response()->json(['success' => true, 'message' => 'Punched out.', 'punch_out' => $now, 'total_minutes' => $mins]);
        }

        return response()->json(['success' => false, 'message' => 'action must be in or out.'], 422);
    }

    public function leaveTypes(Request $request)
    {
        $uid = (int) ($request->attributes->get('hr_claims')['employee_id'] ?? 0);
        $types = DB::table('leave_type')->orderBy('name')->get(['id', 'name', 'days']);
        $hasAssigned = Schema::hasColumn('leave', 'assigned');
        $balances = [];

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
            $usedDays = (float) $usedQ->sum('days');

            $balances[] = [
                'name' => (string) $t->name,
                'leave_type_id' => $typeId,
                'total_days' => $quota,
                'used_leaves' => $usedDays,
            ];
        }

        return response()->json([
            'success' => true,
            'types' => $types,
            'balances' => $balances,
        ]);
    }

    public function leaveIndex(Request $request)
    {
        $claims = $request->attributes->get('hr_claims');
        $uid = (int) ($claims['employee_id'] ?? 0);
        $isAdmin = (int) ($claims['user_status'] ?? 0) === 2;

        $q = DB::table('leave as l')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'l.employee')
            ->leftJoin('leave_type as lt', 'lt.id', '=', 'l.leave_type')
            ->select('l.*', 'e.name as employeeName', 'e.employee_code as employeeCode', 'e.line_manager', 'lt.name as leaveType')
            ->orderByDesc('l.id');

        if (!$isAdmin) {
            $q->where(function ($w) use ($uid) {
                $w->where('l.employee', $uid)->orWhere('e.line_manager', $uid);
            });
        }

        $leaves = $q->get()->map(function ($r) use ($uid, $isAdmin) {
            $st = (int) $r->status;
            $owner = (int) $r->employee;
            $can = false;
            $label = match ($st) {
                1 => 'Approved',
                2 => 'Rejected',
                default => 'Pending',
            };
            try {
                $can = $this->approvals->canActOnLeave($r, $uid, $isAdmin);
                $label = $this->approvals->statusLabel($r);
            } catch (\Throwable $e) {
                $can = $st === 0 && ($isAdmin || $owner !== $uid);
                if ($st === 0) {
                    $label = 'Level 1 Approval Pending';
                }
            }

            return [
                'id' => (int) $r->id,
                'employee_id' => $owner,
                'employee_name' => (string) ($r->employeeName ?? ''),
                'employee_code' => (string) ($r->employeeCode ?? ''),
                'leave_type_id' => (int) $r->leave_type,
                'leave_type' => (string) ($r->leaveType ?? ''),
                'from' => (string) $r->from,
                'to' => (string) $r->to,
                'days' => (int) $r->days,
                'reason' => (string) ($r->reason ?? ''),
                'status' => $st,
                'status_label' => $label,
                'process_status' => match ($st) { 1 => 'approved', 2 => 'rejected', default => 'pending' },
                'approval_step_label' => $st === 0 ? $label : '',
                'approval_approver_names' => [],
                'approval_levels' => (int) ($r->approval_levels ?? 1),
                'current_approval_level' => (int) ($r->current_approval_level ?? 1),
                'can_approve' => $can,
                'date' => (string) ($r->date ?? ''),
            ];
        });

        return response()->json(['success' => true, 'leaves' => $leaves]);
    }

    public function leaveApply(Request $request)
    {
        $uid = (int) ($request->attributes->get('hr_claims')['employee_id'] ?? 0);
        $data = $request->validate([
            'leave_type_id' => 'required|integer',
            'from' => 'required|date',
            'to' => 'required|date|after_or_equal:from',
            'days' => 'nullable|integer|min:1',
            'reason' => 'nullable|string',
        ]);

        $days = (int) ($data['days'] ?? 1);
        $block = $this->thresholdBlockMessage($uid, (int) $data['leave_type_id'], $days);
        if ($block !== null) {
            return response()->json(['success' => false, 'message' => $block], 422);
        }

        $typeName = (string) (DB::table('leave_type')->where('id', $data['leave_type_id'])->value('name') ?? 'Leave');
        $empName = (string) (DB::table('employee')->where('employee_id', $uid)->value('name') ?? 'Employee');

        $payload = [
            'leave_type' => $data['leave_type_id'],
            'employee' => $uid,
            'from' => $data['from'],
            'to' => $data['to'],
            'days' => $days,
            'reason' => $data['reason'] ?? '',
            'status' => 0,
            'date' => now(),
            'added_by' => $uid,
            'approval_pending_level' => 1,
        ];
        if (Schema::hasColumn('leave', 'assigned')) {
            $payload['assigned'] = 0;
        }

        $id = DB::table('leave')->insertGetId($payload);

        $title = 'Leave #'.$id.' — '.$empName.': '.$typeName;
        try {
            $boot = $this->approvals->bootstrapRequest('leave', $uid, 'leave', $id, $title);
            $update = [
                'status' => $boot['status'],
                'approval_pending_level' => $boot['current_approval_level'] ?: null,
            ];
            if (Schema::hasColumn('leave', 'approval_levels')) {
                $update['approval_levels'] = $boot['approval_levels'];
                $update['current_approval_level'] = $boot['current_approval_level'];
                $update['level1_approver_id'] = $boot['level1_approver_id'];
                $update['level2_approver_id'] = $boot['level2_approver_id'];
                $update['level3_approver_id'] = $boot['level3_approver_id'];
            }
            DB::table('leave')->where('id', $id)->update($update);
        } catch (\Throwable $e) {
            // keep pending
        }

        return response()->json(['success' => true, 'message' => 'Leave submitted successfully.', 'id' => $id]);
    }

    public function leaveApprove(Request $request)
    {
        return $this->leaveAct($request, 1, 'approved');
    }

    public function leaveReject(Request $request)
    {
        return $this->leaveAct($request, 2, 'rejected');
    }

    public function timesheetIndex(Request $request)
    {
        $claims = $request->attributes->get('hr_claims');
        $uid = (int) ($claims['employee_id'] ?? 0);
        $isAdmin = (int) ($claims['user_status'] ?? 0) === 2 || !empty($claims['is_superuser']);
        $pk = Schema::hasColumn('timesheet', 'timesheet_id') ? 'timesheet_id' : 'id';
        $hasFrom = Schema::hasColumn('timesheet', 'from_date');

        $q = DB::table('timesheet as t')
            ->leftJoin('employee as e', 'e.employee_id', '=', 't.employee_id')
            ->leftJoin('project as p', 'p.project_id', '=', 't.project_id')
            ->select('t.*', 'e.name as employee_name', 'e.line_manager', 'p.name as project_name')
            ->orderByDesc('t.'.$pk);
        if (!$isAdmin) {
            $q->where(function ($w) use ($uid) {
                $w->where('t.employee_id', $uid)->orWhere('e.line_manager', $uid);
            });
        }

        $rows = $q->get()->map(function ($r) use ($uid, $isAdmin, $pk, $hasFrom) {
            $st = (int) $r->status;
            $owner = (int) $r->employee_id;
            $can = $this->approvals->canActOnTimesheet($r, $uid, $isAdmin);
            $from = $hasFrom ? (string) ($r->from_date ?? '') : (string) ($r->date ?? '');
            $to = $hasFrom ? (string) ($r->to_date ?? '') : (string) ($r->date ?? '');

            return [
                'id' => (int) ($r->{$pk} ?? $r->id ?? 0),
                'employee_id' => $owner,
                'employee_name' => (string) ($r->employee_name ?? ''),
                'project_id' => (int) $r->project_id,
                'project_name' => (string) ($r->project_name ?? ''),
                'from_date' => $from,
                'to_date' => $to,
                'hours' => (float) $r->hours,
                'description' => (string) ($r->description ?? ''),
                'status' => $st,
                'status_label' => $this->approvals->statusLabel($r),
                'approval_pending_level' => isset($r->approval_pending_level) ? (int) $r->approval_pending_level : null,
                'can_approve' => $can,
            ];
        });

        return response()->json(['success' => true, 'timesheets' => $rows]);
    }

    public function timesheetApply(Request $request)
    {
        $uid = (int) ($request->attributes->get('hr_claims')['employee_id'] ?? 0);
        $data = $request->validate([
            'project_id' => 'nullable|integer',
            'from_date' => 'required|date',
            'to_date' => 'nullable|date',
            'hours' => 'required|numeric|min:0.5',
            'description' => 'nullable|string',
        ]);

        $projectId = (int) ($data['project_id'] ?? 1);
        $hasFrom = Schema::hasColumn('timesheet', 'from_date');
        $pk = Schema::hasColumn('timesheet', 'timesheet_id') ? 'timesheet_id' : 'id';

        $insert = [
            'employee_id' => $uid,
            'project_id' => $projectId,
            'hours' => $data['hours'],
            'description' => $data['description'] ?? '',
            'status' => 0,
        ];
        if ($hasFrom) {
            $insert['from_date'] = $data['from_date'];
            $insert['to_date'] = $data['to_date'] ?? $data['from_date'];
            if (Schema::hasColumn('timesheet', 'created_at')) {
                $insert['created_at'] = now();
            }
        } else {
            $insert['date'] = $data['from_date'];
            if (Schema::hasColumn('timesheet', 'added_by')) {
                $insert['added_by'] = $uid;
            }
            if (Schema::hasColumn('timesheet', 'added_on')) {
                $insert['added_on'] = now();
            }
        }
        if (Schema::hasColumn('timesheet', 'approval_pending_level')) {
            $insert['approval_pending_level'] = 1;
        }

        $id = DB::table('timesheet')->insertGetId($insert);
        // insertGetId may return wrong pk name on some drivers — re-read
        if ($pk === 'timesheet_id' && $id < 1) {
            $id = (int) DB::table('timesheet')->where('employee_id', $uid)->orderByDesc($pk)->value($pk);
        }

        $empName = (string) (DB::table('employee')->where('employee_id', $uid)->value('name') ?? 'Employee');
        $title = 'Timesheet #'.$id.' — '.$empName;
        try {
            $boot = $this->approvals->bootstrapRequest('timesheet', $uid, 'timesheet', $id, $title, [
                'project_id' => $projectId,
                'employee_id' => $uid,
                'added_by' => $uid,
            ]);
            $update = ['status' => $boot['status']];
            if (Schema::hasColumn('timesheet', 'approval_pending_level')) {
                $update['approval_pending_level'] = $boot['approval_pending_level']
                    ?? ($boot['current_approval_level'] ?: null);
            }
            foreach (['approval_levels', 'current_approval_level', 'level1_approver_id', 'level2_approver_id', 'level3_approver_id'] as $col) {
                if (isset($boot[$col]) && Schema::hasColumn('timesheet', $col)) {
                    $update[$col] = $boot[$col];
                }
            }
            DB::table('timesheet')->where($pk, $id)->update($update);
        } catch (\Throwable $e) {
            // keep pending
        }

        return response()->json(['success' => true, 'message' => 'Timesheet submitted.', 'id' => $id]);
    }

    public function timesheetApprove(Request $request)
    {
        return $this->timesheetAct($request, 1, 'approved');
    }

    public function timesheetReject(Request $request)
    {
        return $this->timesheetAct($request, 2, 'rejected');
    }

    public function approvalsInbox(Request $request)
    {
        $claims = $request->attributes->get('hr_claims');
        $uid = (int) ($claims['employee_id'] ?? 0);
        $isAdmin = (int) ($claims['user_status'] ?? 0) === 2 || !empty($claims['is_superuser']);
        $items = [];

        foreach (DB::table('leave as l')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'l.employee')
            ->leftJoin('leave_type as lt', 'lt.id', '=', 'l.leave_type')
            ->where('l.status', 0)
            ->select('l.*', 'e.name as employee_name', 'e.line_manager', 'lt.name as type_name')
            ->orderByDesc('l.id')->get() as $r) {
            if (!isset($r->employee_id)) {
                $r->employee_id = $r->employee;
            }
            if ($this->approvals->inboxEligible($r, $uid, $isAdmin, 'leave')) {
                $items[] = [
                    'kind' => 'leave',
                    'id' => (int) $r->id,
                    'title' => (string) ($r->type_name ?? 'Leave'),
                    'employee_name' => (string) ($r->employee_name ?? ''),
                    'summary' => $r->from.' → '.$r->to.' ('.(int) $r->days.'d)',
                ];
            }
        }

        $travelPk = Schema::hasColumn('travel_request', 'travel_request_id') ? 'travel_request_id' : 'id';
        foreach (DB::table('travel_request as t')
            ->leftJoin('employee as e', 'e.employee_id', '=', 't.employee_id')
            ->where('t.status', 0)
            ->select('t.*', 'e.name as employee_name', 'e.line_manager')
            ->orderByDesc('t.'.$travelPk)->get() as $r) {
            if ($this->approvals->inboxEligible($r, $uid, $isAdmin, 'travel')) {
                $items[] = [
                    'kind' => 'travel',
                    'id' => (int) ($r->{$travelPk} ?? $r->id ?? 0),
                    'title' => (string) ($r->request_no ?? 'Travel'),
                    'employee_name' => (string) ($r->employee_name ?? ''),
                    'summary' => ($r->from_location ?? '').' → '.($r->to_location ?? ''),
                ];
            }
        }

        $tsPk = Schema::hasColumn('timesheet', 'timesheet_id') ? 'timesheet_id' : 'id';
        foreach (DB::table('timesheet as t')
            ->leftJoin('employee as e', 'e.employee_id', '=', 't.employee_id')
            ->leftJoin('project as p', 'p.project_id', '=', 't.project_id')
            ->where('t.status', 0)
            ->select('t.*', 'e.name as employee_name', 'e.line_manager', 'p.name as project_name')
            ->orderByDesc('t.'.$tsPk)->get() as $r) {
            if ($this->approvals->inboxEligible($r, $uid, $isAdmin, 'timesheet')) {
                $from = Schema::hasColumn('timesheet', 'from_date')
                    ? ($r->from_date ?? '').' → '.($r->to_date ?? '')
                    : (string) ($r->date ?? '');
                $items[] = [
                    'kind' => 'timesheet',
                    'id' => (int) ($r->{$tsPk} ?? $r->id ?? 0),
                    'title' => (string) ($r->project_name ?? 'Timesheet'),
                    'employee_name' => (string) ($r->employee_name ?? ''),
                    'summary' => $from.' · '.$r->hours.'h',
                ];
            }
        }

        return response()->json(['success' => true, 'items' => $items, 'count' => count($items)]);
    }

    protected function leaveAct(Request $request, int $status, string $label)
    {
        $claims = $request->attributes->get('hr_claims');
        $uid = (int) ($claims['employee_id'] ?? 0);
        $isAdmin = (int) ($claims['user_status'] ?? 0) === 2;
        $id = (int) $request->input('id');
        $row = DB::table('leave as l')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'l.employee')
            ->leftJoin('leave_type as lt', 'lt.id', '=', 'l.leave_type')
            ->select('l.*', 'e.line_manager', 'e.name as employee_name', 'lt.name as leave_type_name')
            ->where('l.id', $id)->first();
        if (!$row) {
            return response()->json(['success' => false, 'message' => 'Not found.'], 404);
        }

        $title = 'Leave #'.$id.' — '.($row->employee_name ?? '').': '.($row->leave_type_name ?? 'Leave');
        try {
            $result = $this->approvals->act(
                'leave',
                $row,
                $uid,
                $isAdmin,
                $status === 1,
                'leave',
                $title,
                $request->input('remarks')
            );
            if (!$result['ok']) {
                $code = str_contains($result['message'], 'Not allowed') ? 403 : 422;

                return response()->json(['success' => false, 'message' => $result['message']], $code);
            }

            return response()->json(['success' => true, 'message' => $result['message']]);
        } catch (\Throwable $e) {
            $owner = (int) $row->employee;
            $lm = (int) ($row->line_manager ?? 0);
            if (!$isAdmin && !($lm === $uid && $owner !== $uid)) {
                return response()->json(['success' => false, 'message' => 'Not allowed.'], 403);
            }
            DB::table('leave')->where('id', $id)->update(['status' => $status, 'approval_pending_level' => null]);

            return response()->json(['success' => true, 'message' => 'Leave '.$label.'.']);
        }
    }

    protected function timesheetAct(Request $request, int $status, string $label)
    {
        $claims = $request->attributes->get('hr_claims');
        $uid = (int) ($claims['employee_id'] ?? 0);
        $isAdmin = (int) ($claims['user_status'] ?? 0) === 2 || !empty($claims['is_superuser']);
        $id = (int) $request->input('id');
        $pk = Schema::hasColumn('timesheet', 'timesheet_id') ? 'timesheet_id' : 'id';
        $row = DB::table('timesheet as t')
            ->leftJoin('employee as e', 'e.employee_id', '=', 't.employee_id')
            ->select('t.*', 'e.line_manager', 'e.name as employee_name')
            ->where('t.'.$pk, $id)->first();
        if (!$row) {
            return response()->json(['success' => false, 'message' => 'Not found.'], 404);
        }

        $title = 'Timesheet #'.$id.' — '.($row->employee_name ?? '');
        try {
            $result = $this->approvals->act(
                'timesheet',
                $row,
                $uid,
                $isAdmin,
                $status === 1,
                'timesheet',
                $title,
                $request->input('remarks')
            );
            if (!$result['ok']) {
                $code = str_contains($result['message'], 'Not allowed') ? 403 : 422;

                return response()->json(['success' => false, 'message' => $result['message']], $code);
            }

            return response()->json(['success' => true, 'message' => $result['message']]);
        } catch (\Throwable $e) {
            if (!$this->approvals->canActOnTimesheet($row, $uid, $isAdmin)) {
                return response()->json(['success' => false, 'message' => 'Not allowed.'], 403);
            }
            DB::table('timesheet')->where($pk, $id)->update(['status' => $status]);

            return response()->json(['success' => true, 'message' => 'Timesheet '.$label.'.']);
        }
    }

    /**
     * If designation has an active threshold for this leave type and requested days
     * exceed threshold_to, block the application (PHP leave_threshold max band).
     */
    protected function thresholdBlockMessage(int $employeeId, int $leaveTypeId, int $days): ?string
    {
        if (!Schema::hasTable('leave_threshold')) {
            return null;
        }
        $designation = (int) (DB::table('employee')->where('employee_id', $employeeId)->value('designation') ?? 0);
        if ($designation < 1) {
            return null;
        }
        $rows = DB::table('leave_threshold')
            ->where('designation_id', $designation)
            ->where('status', 1)
            ->get();
        foreach ($rows as $r) {
            $ids = array_map('intval', explode(',', (string) $r->leave_type_id));
            if (!in_array($leaveTypeId, $ids, true)) {
                continue;
            }
            $max = (int) $r->threshold_to;
            if ($max > 0 && $days > $max) {
                return "Leave exceeds threshold: max {$max} day(s) for your designation.";
            }
        }

        return null;
    }

    protected function mapAttendance(object $row): array
    {
        return [
            'id' => (int) $row->id,
            'employee_id' => (int) $row->employee_id,
            'date' => (string) $row->date,
            'punch_in' => $row->punch_in,
            'punch_out' => $row->punch_out,
            'total_minutes' => isset($row->total_minutes) ? (int) $row->total_minutes : null,
            'notes' => $row->notes ?? null,
        ];
    }
}
