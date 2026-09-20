<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ApprovalService
{
    public const MODULES = ['travel', 'leave', 'timesheet'];

    public function __construct(private HrApprovalResolver $resolver)
    {
    }

    public function settings(string $module): array
    {
        // Prefer live SCF designation setup when present
        $levelMap = $this->resolver->levelMap($module);
        if ($levelMap !== []) {
            $levels = [];
            foreach ($levelMap as $lvl => $rules) {
                $primary = $this->resolver->primaryRule($rules);
                $label = $primary === HrApprovalResolver::LINE_MANAGER
                    ? 'Line Manager'
                    : (string) (DB::table('designation')->where('designation_id', $primary)->value('name') ?? 'Designation #'.$primary);
                $levels[(int) $lvl] = [
                    'level' => (int) $lvl,
                    'employee_id' => 0,
                    'employee_name' => $label,
                    'designation_id' => $primary,
                    'designation_ids' => $rules,
                ];
            }

            return [
                'module' => $module,
                'approval_method' => 'designation_setup',
                'approval_levels' => count($levelMap),
                'restart_on_edit' => false,
                'skip_specific' => false,
                'hide_rejected' => false,
                'do_not_notify_employee' => false,
                'sms_on_submission' => false,
                'source' => 'hr_approval_setup',
                'level_assignees' => empty($levels) ? new \stdClass() : $levels,
            ];
        }

        $this->ensureTables();
        $row = DB::table('approval_settings')->where('module', $module)->first();
        if (!$row) {
            DB::table('approval_settings')->insert([
                'module' => $module,
                'approval_method' => 'multi_level',
                'approval_levels' => 1,
            ]);
            $row = DB::table('approval_settings')->where('module', $module)->first();
        }

        $assignees = DB::table('approval_level_assignee as a')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'a.employee_id')
            ->where('a.module', $module)
            ->orderBy('a.level')
            ->get(['a.level', 'a.employee_id', 'e.name as employee_name']);

        $levels = [];
        foreach ($assignees as $a) {
            $levels[(int) $a->level] = [
                'level' => (int) $a->level,
                'employee_id' => (int) $a->employee_id,
                'employee_name' => (string) ($a->employee_name ?? ''),
            ];
        }

        return [
            'module' => $module,
            'approval_method' => (string) ($row->approval_method ?? 'multi_level'),
            'approval_levels' => (int) ($row->approval_levels ?? 1),
            'restart_on_edit' => (bool) ($row->restart_on_edit ?? false),
            'skip_specific' => (bool) ($row->skip_specific ?? false),
            'hide_rejected' => (bool) ($row->hide_rejected ?? false),
            'do_not_notify_employee' => (bool) ($row->do_not_notify_employee ?? false),
            'sms_on_submission' => (bool) ($row->sms_on_submission ?? false),
            'source' => 'approval_settings',
            // Always JSON object {} — empty PHP [] becomes [] and breaks Flutter Map casts.
            'level_assignees' => empty($levels) ? new \stdClass() : $levels,
        ];
    }

    public function saveSettings(string $module, array $data): array
    {
        if ($this->resolver->levelMap($module) !== []) {
            // Live SCF setup is managed via hr_approval_setup — don't overwrite with employee assignees.
            return $this->settings($module);
        }

        $this->ensureTables();
        $levels = max(0, min(5, (int) ($data['approval_levels'] ?? 1)));

        DB::table('approval_settings')->updateOrInsert(
            ['module' => $module],
            [
                'approval_method' => $data['approval_method'] ?? 'multi_level',
                'approval_levels' => $levels,
                'restart_on_edit' => !empty($data['restart_on_edit']) ? 1 : 0,
                'skip_specific' => !empty($data['skip_specific']) ? 1 : 0,
                'hide_rejected' => !empty($data['hide_rejected']) ? 1 : 0,
                'do_not_notify_employee' => !empty($data['do_not_notify_employee']) ? 1 : 0,
                'sms_on_submission' => !empty($data['sms_on_submission']) ? 1 : 0,
            ]
        );

        DB::table('approval_level_assignee')->where('module', $module)->delete();
        $assignees = $data['level_assignees'] ?? [];
        if (is_array($assignees)) {
            foreach ($assignees as $level => $employeeId) {
                $lvl = (int) $level;
                $eid = (int) $employeeId;
                if ($lvl < 1 || $lvl > 5 || $eid < 1) {
                    continue;
                }
                if ($levels > 0 && $lvl > $levels) {
                    continue;
                }
                DB::table('approval_level_assignee')->insert([
                    'module' => $module,
                    'level' => $lvl,
                    'employee_id' => $eid,
                ]);
            }
        }

        return $this->settings($module);
    }

    public function notificationSettings(string $module): array
    {
        $approval = $this->settings($module);
        if (!Schema::hasTable('notification_settings')) {
            return [
                'module' => $module,
                'do_not_notify_employee' => $approval['do_not_notify_employee'],
                'sms_on_submission' => $approval['sms_on_submission'],
                'notify_on_submission' => [],
                'notify_on_approval' => [],
                'notify_on_reassignment' => [],
            ];
        }
        $row = DB::table('notification_settings')->where('module', $module)->first();
        if (!$row) {
            try {
                DB::table('notification_settings')->insert(['module' => $module]);
                $row = DB::table('notification_settings')->where('module', $module)->first();
            } catch (\Throwable $e) {
                $row = null;
            }
        }

        return [
            'module' => $module,
            'do_not_notify_employee' => $approval['do_not_notify_employee'],
            'sms_on_submission' => $approval['sms_on_submission'],
            'notify_on_submission' => $this->parseIds($row->notify_on_submission ?? ''),
            'notify_on_approval' => $this->parseIds($row->notify_on_approval ?? ''),
            'notify_on_reassignment' => $this->parseIds($row->notify_on_reassignment ?? ''),
        ];
    }

    public function saveNotificationSettings(string $module, array $data): array
    {
        $this->ensureTables();
        DB::table('notification_settings')->updateOrInsert(
            ['module' => $module],
            [
                'notify_on_submission' => $this->idsToCsv($data['notify_on_submission'] ?? []),
                'notify_on_approval' => $this->idsToCsv($data['notify_on_approval'] ?? []),
                'notify_on_reassignment' => $this->idsToCsv($data['notify_on_reassignment'] ?? []),
            ]
        );

        if (isset($data['do_not_notify_employee']) || isset($data['sms_on_submission'])) {
            $cur = $this->settings($module);
            $this->saveSettings($module, array_merge($cur, [
                'do_not_notify_employee' => $data['do_not_notify_employee'] ?? $cur['do_not_notify_employee'],
                'sms_on_submission' => $data['sms_on_submission'] ?? $cur['sms_on_submission'],
                'level_assignees' => collect($cur['level_assignees'])
                    ->mapWithKeys(fn ($v, $k) => [$k => $v['employee_id']])
                    ->all(),
            ]));
        }

        return $this->notificationSettings($module);
    }

    /** Snapshot approvers onto a new request; returns [levels, current, l1, l2, l3, status]. */
    public function bootstrapRequest(string $module, int $requesterId, string $refType, int $refId, string $title, array $requestRow = []): array
    {
        $requestRow = array_merge($requestRow, [
            'employee_id' => $requesterId,
            'employee' => $requesterId,
            'added_by' => $requesterId,
            'status' => 0,
        ]);

        $levelMap = $this->resolver->levelMap($module);
        if ($levelMap !== []) {
            return $this->bootstrapFromSetup($module, $requesterId, $refType, $refId, $title, $requestRow, $levelMap);
        }

        $cfg = $this->settings($module);
        $levels = (int) $cfg['approval_levels'];
        $assignees = $cfg['level_assignees'];
        if ($assignees instanceof \stdClass) {
            $assignees = (array) $assignees;
        }

        $l1 = (int) ($assignees[1]['employee_id'] ?? 0);
        $l2 = (int) ($assignees[2]['employee_id'] ?? 0);
        $l3 = (int) ($assignees[3]['employee_id'] ?? 0);

        // Fallback: line manager as level 1 if not configured
        if ($levels >= 1 && $l1 < 1) {
            $lm = DB::table('employee')->where('employee_id', $requesterId)->value('line_manager');
            $l1 = (int) ($lm ?? 0);
        }

        if ($levels === 0) {
            $this->notifyList(
                $this->notificationSettings($module)['notify_on_approval'],
                'Auto-approved: '.$title,
                'Request was auto-approved by workflow settings.',
                'approval',
                $refType,
                $refId,
                null
            );
            if (!$cfg['do_not_notify_employee']) {
                $this->notify($requesterId, 'Approved: '.$title, 'Your request was auto-approved.', 'approval', $refType, $refId, null);
            }

            return [
                'approval_levels' => 0,
                'current_approval_level' => 0,
                'level1_approver_id' => null,
                'level2_approver_id' => null,
                'level3_approver_id' => null,
                'status' => 1,
            ];
        }

        $payload = [
            'approval_levels' => $levels,
            'current_approval_level' => 1,
            'level1_approver_id' => $l1 > 0 ? $l1 : null,
            'level2_approver_id' => $levels >= 2 && $l2 > 0 ? $l2 : null,
            'level3_approver_id' => $levels >= 3 && $l3 > 0 ? $l3 : null,
            'status' => 0,
        ];

        // Notify level-1 approver
        if ($l1 > 0) {
            $this->notify(
                $l1,
                $this->acknowledgementTitle($module),
                $title,
                'approval',
                $refType,
                $refId,
                1
            );
        }

        try {
            $extra = $this->notificationSettings($module)['notify_on_submission'];
            $this->notifyList($extra, 'Submitted: '.$title, 'A new '.$module.' request was submitted.', 'info', $refType, $refId, 1);
        } catch (\Throwable $e) {
            // optional tables
        }

        return $payload;
    }

    protected function bootstrapFromSetup(
        string $module,
        int $requesterId,
        string $refType,
        int $refId,
        string $title,
        array $requestRow,
        array $levelMap
    ): array {
        $first = $this->resolver->getFirstApprovalLevel($levelMap, $requestRow);
        if ($first === null) {
            return [
                'approval_levels' => 0,
                'current_approval_level' => 0,
                'level1_approver_id' => null,
                'level2_approver_id' => null,
                'level3_approver_id' => null,
                'status' => 1,
            ];
        }

        $keys = array_map('intval', array_keys($levelMap));
        sort($keys, SORT_NUMERIC);
        $l1 = $l2 = $l3 = null;
        $i = 0;
        foreach ($keys as $lvl) {
            $primary = $this->resolver->primaryRule($levelMap[$lvl] ?? null);
            if ($primary === null) {
                continue;
            }
            $ids = $this->resolver->employeeIdsWhoCanApproveLevel($requesterId, $primary, $requestRow);
            $eid = $ids[0] ?? null;
            $i++;
            if ($i === 1) {
                $l1 = $eid;
            } elseif ($i === 2) {
                $l2 = $eid;
            } elseif ($i === 3) {
                $l3 = $eid;
            }
        }

        $approvers = $this->resolver->pendingApproverIds(
            array_merge($requestRow, ['approval_pending_level' => $first, 'status' => 0]),
            $levelMap
        );
        foreach ($approvers as $aid) {
            $this->notify(
                $aid,
                $this->acknowledgementTitle($module),
                $title,
                'approval',
                $refType,
                $refId,
                $first === HrApprovalResolver::ED_FALLBACK_LEVEL ? 1 : $first
            );
        }

        return [
            'approval_levels' => count($levelMap),
            'current_approval_level' => $first === HrApprovalResolver::ED_FALLBACK_LEVEL ? count($levelMap) : $first,
            'level1_approver_id' => $l1,
            'level2_approver_id' => $l2,
            'level3_approver_id' => $l3,
            'status' => 0,
            'approval_pending_level' => $first,
        ];
    }

    /**
     * Approve/reject current level. Returns message + new status.
     * @return array{ok:bool,message:string,status?:int,level?:int}
     */
    public function act(
        string $module,
        object $row,
        int $actorId,
        bool $isAdmin,
        bool $approve,
        string $refType,
        string $title,
        ?string $remarks = null
    ): array {
        $status = (int) ($row->status ?? 0);
        if ($status !== 0) {
            return ['ok' => false, 'message' => 'Already finalized.'];
        }

        $owner = (int) ($row->employee_id ?? $row->employee ?? 0);
        if (!$isAdmin && $owner === $actorId) {
            return ['ok' => false, 'message' => 'Cannot approve your own request.'];
        }

        $levelMap = $this->resolver->levelMap($module);
        if ($levelMap !== []) {
            return $this->actFromSetup($module, $row, $actorId, $isAdmin, $approve, $refType, $title, $remarks, $levelMap);
        }

        $levels = (int) ($row->approval_levels ?? 1);
        $current = (int) ($row->current_approval_level ?? 1);
        if ($levels < 1) {
            $levels = 1;
        }

        $approverCol = 'level'.$current.'_approver_id';
        $expected = (int) ($row->{$approverCol} ?? 0);

        // Fallback LM check for level 1 when assignee missing
        if ($expected < 1 && $current === 1) {
            $expected = (int) ($row->line_manager ?? 0);
        }

        if (!$isAdmin && !($expected > 0 && $expected === $actorId)) {
            return ['ok' => false, 'message' => 'Not allowed for level '.$current.' approval.'];
        }

        $refId = $this->rowPk($module, $row);

        if (!$approve) {
            $this->writeApprovalLog($module, $refId, $current, 'reject', $actorId, $remarks, null);
            $this->persistRequest($module, $refId, ['status' => 2, 'approval_pending_level' => null]);

            if (!$this->settings($module)['do_not_notify_employee'] && $owner > 0) {
                $this->notify($owner, 'Rejected: '.$title, 'Level '.$current.' rejected your request.', 'approval', $refType, $refId, $current);
            }

            return ['ok' => true, 'message' => ucfirst($module).' rejected at level '.$current.'.', 'status' => 2, 'level' => $current];
        }

        $this->writeApprovalLog($module, $refId, $current, 'approve', $actorId, $remarks, null);

        try {
            $extra = $this->notificationSettings($module)['notify_on_approval'];
            $this->notifyList($extra, 'Level '.$current.' approved: '.$title, 'Approved by level '.$current.'.', 'approval', $refType, $refId, $current);
        } catch (\Throwable $e) {
        }

        if ($current >= $levels) {
            $this->persistRequest($module, $refId, [
                'status' => 1,
                'approval_pending_level' => null,
            ]);
            if (!$this->settings($module)['do_not_notify_employee'] && $owner > 0) {
                $this->notify($owner, 'Approved: '.$title, 'All approval levels completed.', 'approval', $refType, $refId, $current);
            }

            return ['ok' => true, 'message' => ucfirst($module).' fully approved.', 'status' => 1, 'level' => $current];
        }

        $next = $current + 1;
        $this->persistRequest($module, $refId, [
            'current_approval_level' => $next,
            'approval_pending_level' => $next,
            'status' => 0,
        ]);

        $nextCol = 'level'.$next.'_approver_id';
        $nextApprover = (int) ($row->{$nextCol} ?? 0);
        if ($nextApprover > 0) {
            $this->notify(
                $nextApprover,
                $this->acknowledgementTitle($module),
                $title.' — Level '.$next.' approval pending',
                'approval',
                $refType,
                $refId,
                $next
            );
        }

        return [
            'ok' => true,
            'message' => 'Level '.$current.' approved. Forwarded to level '.$next.'.',
            'status' => 0,
            'level' => $next,
        ];
    }

    protected function actFromSetup(
        string $module,
        object $row,
        int $actorId,
        bool $isAdmin,
        bool $approve,
        string $refType,
        string $title,
        ?string $remarks,
        array $levelMap
    ): array {
        if (!$this->resolver->canUserApprovePendingRow($actorId, $row, $levelMap, $isAdmin)) {
            return ['ok' => false, 'message' => 'Not allowed for this approval step.'];
        }

        $pending = $this->resolver->effectivePendingLevel($row, $levelMap);
        $ruleId = $this->resolver->resolveRuleForPending($row, $levelMap);
        $refId = $this->rowPk($module, $row);
        $owner = (int) ($row->employee_id ?? $row->employee ?? 0);

        if (!$approve) {
            $this->writeApprovalLog($module, $refId, $pending, 'reject', $actorId, $remarks, $ruleId);
            $this->persistRequest($module, $refId, ['status' => 2, 'approval_pending_level' => null]);
            if ($owner > 0) {
                $this->notify($owner, 'Rejected: '.$title, 'Your request was rejected.', 'approval', $refType, $refId, $pending);
            }

            return ['ok' => true, 'message' => ucfirst($module).' rejected.', 'status' => 2, 'level' => $pending];
        }

        $this->writeApprovalLog($module, $refId, $pending, 'approve', $actorId, $remarks, $ruleId);

        $next = $this->resolver->nextApprovalLevelAfter($pending, $levelMap, $row);
        if ($next === null) {
            $this->persistRequest($module, $refId, [
                'status' => 1,
                'approval_pending_level' => null,
            ]);
            if ($owner > 0) {
                $this->notify($owner, 'Approved: '.$title, 'All approval levels completed.', 'approval', $refType, $refId, $pending);
            }

            return ['ok' => true, 'message' => ucfirst($module).' fully approved.', 'status' => 1, 'level' => $pending];
        }

        $this->persistRequest($module, $refId, [
            'status' => 0,
            'approval_pending_level' => $next,
            'current_approval_level' => $next === HrApprovalResolver::ED_FALLBACK_LEVEL
                ? count($levelMap)
                : $next,
        ]);

        $nextRow = (object) array_merge((array) $row, [
            'approval_pending_level' => $next,
            'status' => 0,
        ]);
        foreach ($this->resolver->pendingApproverIds($nextRow, $levelMap) as $aid) {
            $this->notify(
                $aid,
                $this->acknowledgementTitle($module),
                $title.' — next approval pending',
                'approval',
                $refType,
                $refId,
                $next === HrApprovalResolver::ED_FALLBACK_LEVEL ? count($levelMap) : $next
            );
        }

        return [
            'ok' => true,
            'message' => 'Level '.$pending.' approved. Forwarded to next level.',
            'status' => 0,
            'level' => $next,
        ];
    }

    protected function rowPk(string $module, object $row): int
    {
        if ($module === 'timesheet') {
            return (int) ($row->timesheet_id ?? $row->id ?? 0);
        }
        if ($module === 'travel') {
            return (int) ($row->travel_request_id ?? $row->id ?? 0);
        }

        return (int) ($row->id ?? 0);
    }

    protected function writeApprovalLog(
        string $module,
        int $refId,
        int $level,
        string $action,
        int $actorId,
        ?string $remarks,
        ?int $designationRuleId = null
    ): void {
        $rule = $designationRuleId ?? 0;
        if ($module === 'travel') {
            if (Schema::hasTable('travel_approval_log')) {
                DB::table('travel_approval_log')->insert([
                    'travel_id' => $refId,
                    'level' => $level,
                    'action' => $action,
                    'approver_id' => $actorId,
                    'remarks' => $remarks,
                    'created_at' => now(),
                ]);
            }

            return;
        }
        if ($module === 'leave' && Schema::hasTable('leave_approval')) {
            $cols = ['leave_id' => $refId, 'level' => $level, 'approver_employee_id' => $actorId, 'action' => $action, 'remarks' => $remarks, 'acted_on' => now()];
            if (Schema::hasColumn('leave_approval', 'designation_rule_id')) {
                $cols['designation_rule_id'] = $rule;
            }
            DB::table('leave_approval')->insert($cols);

            return;
        }
        if ($module === 'timesheet' && Schema::hasTable('timesheet_approval')) {
            $cols = [
                'timesheet_id' => $refId,
                'level' => $level,
                'approver_employee_id' => $actorId,
                'action' => $action,
                'remarks' => $remarks,
                'acted_on' => now(),
            ];
            if (Schema::hasColumn('timesheet_approval', 'designation_rule_id')) {
                $cols['designation_rule_id'] = $rule;
            }
            DB::table('timesheet_approval')->insert($cols);
        }
    }

    protected function persistRequest(string $module, int $id, array $data): void
    {
        if ($module === 'travel') {
            $table = Schema::hasColumn('travel_request', 'travel_request_id') ? 'travel_request' : 'travel_request';
            $pk = Schema::hasColumn('travel_request', 'travel_request_id') ? 'travel_request_id' : 'id';
            $allowed = array_intersect_key($data, array_flip([
                'status', 'approval_levels', 'current_approval_level',
                'level1_approver_id', 'level2_approver_id', 'level3_approver_id',
                'approval_pending_level',
            ]));
            // Some travel tables lack approval_pending_level
            if (!Schema::hasColumn('travel_request', 'approval_pending_level')) {
                unset($allowed['approval_pending_level']);
            }
            DB::table($table)->where($pk, $id)->update($allowed);

            return;
        }
        if ($module === 'leave') {
            $allowed = array_intersect_key($data, array_flip([
                'status', 'approval_levels', 'current_approval_level',
                'level1_approver_id', 'level2_approver_id', 'level3_approver_id',
                'approval_pending_level', 'approve_date',
            ]));
            if (isset($allowed['status']) && (int) $allowed['status'] === 1 && Schema::hasColumn('leave', 'approve_date')) {
                $allowed['approve_date'] = now();
            }
            foreach (array_keys($allowed) as $col) {
                if ($col !== 'status' && !Schema::hasColumn('leave', $col)) {
                    unset($allowed[$col]);
                }
            }
            DB::table('leave')->where('id', $id)->update($allowed);

            return;
        }
        if ($module === 'timesheet') {
            $pk = Schema::hasColumn('timesheet', 'timesheet_id') ? 'timesheet_id' : 'id';
            $allowed = array_intersect_key($data, array_flip([
                'status', 'approval_levels', 'current_approval_level',
                'level1_approver_id', 'level2_approver_id', 'level3_approver_id',
                'approval_pending_level',
            ]));
            foreach (array_keys($allowed) as $col) {
                if ($col !== 'status' && !Schema::hasColumn('timesheet', $col)) {
                    unset($allowed[$col]);
                }
            }
            DB::table('timesheet')->where($pk, $id)->update($allowed);
        }
    }

    public function canActOnLeave(object $row, int $uid, bool $isAdmin): bool
    {
        if (!isset($row->employee_id) && isset($row->employee)) {
            $row->employee_id = $row->employee;
        }

        return $this->canActOnTravel($row, $uid, $isAdmin, 'leave');
    }

    public function canActOnTimesheet(object $row, int $uid, bool $isAdmin): bool
    {
        return $this->canActOnTravel($row, $uid, $isAdmin, 'timesheet');
    }

    public function canActOnTravel(object $row, int $uid, bool $isAdmin, string $module = 'travel'): bool
    {
        if ((int) ($row->status ?? -1) !== 0) {
            return false;
        }
        $owner = (int) ($row->employee_id ?? $row->employee ?? 0);
        if ($owner === $uid) {
            return false;
        }

        $levelMap = $this->resolver->levelMap($module);
        if ($levelMap !== []) {
            return $this->resolver->canUserApprovePendingRow($uid, $row, $levelMap, $isAdmin);
        }

        if ($isAdmin) {
            return true;
        }
        $current = (int) ($row->current_approval_level ?? $row->approval_pending_level ?? 1);
        $col = 'level'.$current.'_approver_id';
        $expected = (int) ($row->{$col} ?? 0);
        if ($expected < 1 && $current === 1) {
            $expected = (int) ($row->line_manager ?? 0);
        }

        return $expected > 0 && $expected === $uid;
    }

    public function inboxEligible(object $row, int $uid, bool $isAdmin, string $module): bool
    {
        $levelMap = $this->resolver->levelMap($module);
        if ($levelMap !== []) {
            return $this->resolver->canUserViewPendingRow($uid, $row, $levelMap, $isAdmin);
        }

        return $this->canActOnTravel($row, $uid, $isAdmin, $module);
    }

    public function notify(int $employeeId, string $title, string $body, string $kind, ?string $refType, ?int $refId, ?int $level): void
    {
        if ($employeeId < 1 || !Schema::hasTable('notifications')) {
            return;
        }
        DB::table('notifications')->insert([
            'employee_id' => $employeeId,
            'title' => $title,
            'body' => $body,
            'kind' => $kind,
            'ref_type' => $refType,
            'ref_id' => $refId,
            'level' => $level,
            'is_read' => 0,
            'created_at' => now(),
        ]);
    }

    /** Human label for bell / acknowledgement lines (Leave → Leaves, etc.). */
    public static function moduleLabel(string $module): string
    {
        return match (strtolower(trim($module))) {
            'leave', 'leaves' => 'Leaves',
            'travel' => 'Travel',
            'timesheet' => 'Timesheet',
            'resignation', 'resignations' => 'Resignations',
            'termination', 'terminations' => 'Termination',
            'loan', 'loan_application' => 'Loan Applications',
            'employment_change' => 'Employment Change',
            'contract', 'contracts' => 'Contracts',
            'assignment', 'assignments' => 'Assignments',
            'transfer', 'transfers' => 'Transfers',
            default => ucfirst(str_replace('_', ' ', $module)),
        };
    }

    public function acknowledgementTitle(string $module): string
    {
        return 'Your acknowledgement is required for: ('.$this->moduleLabel($module).')';
    }

    public function notifyList(array $ids, string $title, string $body, string $kind, ?string $refType, ?int $refId, ?int $level): void
    {
        foreach (array_unique(array_map('intval', $ids)) as $id) {
            $this->notify($id, $title, $body, $kind, $refType, $refId, $level);
        }
    }

    public function listNotifications(int $employeeId, int $limit = 50): array
    {
        if (!Schema::hasTable('notifications')) {
            return [];
        }

        return DB::table('notifications')
            ->where('employee_id', $employeeId)
            ->orderByDesc('id')
            ->limit($limit)
            ->get()
            ->map(fn ($n) => [
                'id' => (int) $n->id,
                'title' => (string) $n->title,
                'body' => (string) ($n->body ?? ''),
                'kind' => (string) $n->kind,
                'ref_type' => $n->ref_type,
                'ref_id' => $n->ref_id !== null ? (int) $n->ref_id : null,
                'level' => $n->level !== null ? (int) $n->level : null,
                'is_read' => (bool) $n->is_read,
                'created_at' => (string) $n->created_at,
            ])
            ->all();
    }

    public function markRead(int $employeeId, ?int $id = null): void
    {
        if (!Schema::hasTable('notifications')) {
            return;
        }
        $q = DB::table('notifications')->where('employee_id', $employeeId);
        if ($id !== null) {
            $q->where('id', $id);
        }
        $q->update(['is_read' => 1]);
    }

    public function unreadCount(int $employeeId): int
    {
        if (!Schema::hasTable('notifications')) {
            return 0;
        }

        return (int) DB::table('notifications')
            ->where('employee_id', $employeeId)
            ->where('is_read', 0)
            ->count();
    }

    public function statusLabel(object $row): string
    {
        $st = (int) ($row->status ?? 0);
        if ($st === 1) {
            return 'Approved';
        }
        if ($st === 2) {
            return 'Rejected';
        }
        $levels = (int) ($row->approval_levels ?? 1);
        $cur = (int) ($row->current_approval_level ?? 1);
        if ($levels <= 1) {
            return 'Level 1 Approval Pending';
        }

        return 'Level '.$cur.' of '.$levels.' Approval Pending';
    }

    protected function parseIds(?string $csv): array
    {
        if ($csv === null || trim($csv) === '') {
            return [];
        }

        return array_values(array_filter(array_map('intval', explode(',', $csv)), fn ($v) => $v > 0));
    }

    protected function idsToCsv($ids): string
    {
        if (!is_array($ids)) {
            return '';
        }

        return implode(',', array_values(array_filter(array_map('intval', $ids), fn ($v) => $v > 0)));
    }

    protected function ensureTables(): void
    {
        // Soft guard — SQL script 06 should create tables; avoid hard crash if missing.
        if (!Schema::hasTable('approval_settings')) {
            throw new \RuntimeException('Run database/06_approvals_notifications.sql on the tenant DB.');
        }
    }
}
