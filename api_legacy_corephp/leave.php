<?php

require_once __DIR__ . '/bootstrap.php';

function hr360_map_leave(array $row, int $viewerId): array
{
    $st = (int) ($row['status'] ?? 0);
    $statusLabel = match ($st) {
        1 => 'Approved',
        2 => 'Rejected',
        default => 'Pending',
    };
    $ownerId = (int) ($row['employee'] ?? 0);
    $canApprove = $st === 0 && $ownerId !== $viewerId && (
        // Line manager of requester
        (isset($row['line_manager']) && (int) $row['line_manager'] === $viewerId)
        // Or admin
        || !empty($row['_viewer_is_admin'])
    );

    return [
        'id' => (int) ($row['id'] ?? 0),
        'employee_id' => $ownerId,
        'employee_name' => (string) ($row['employeeName'] ?? ''),
        'employee_code' => (string) ($row['employeeCode'] ?? ''),
        'leave_type_id' => (int) ($row['leave_type'] ?? 0),
        'leave_type' => (string) ($row['leaveType'] ?? ''),
        'from' => (string) ($row['from'] ?? ''),
        'to' => (string) ($row['to'] ?? ''),
        'days' => (int) ($row['days'] ?? 0),
        'reason' => (string) ($row['reason'] ?? ''),
        'status' => $st,
        'status_label' => $statusLabel,
        'process_status' => strtolower($statusLabel),
        'approval_step_label' => $st === 0 ? 'Pending approval' : '',
        'approval_approver_names' => [],
        'can_approve' => $canApprove,
        'date' => (string) ($row['date'] ?? ''),
    ];
}

function hr360_leave_types(): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);

    $types = $pdo->query('SELECT id, name, days FROM leave_type ORDER BY name ASC')->fetchAll();
    $balances = [];
    if ($uid > 0) {
        $st = $pdo->prepare(
            'SELECT leave_type.name AS name,
                    leave_type.days AS total_days,
                    COUNT(`leave`.id) AS used_leaves
             FROM leave_type
             LEFT JOIN `leave`
               ON leave_type.id = `leave`.leave_type
              AND `leave`.employee = ?
             GROUP BY leave_type.id, leave_type.name, leave_type.days
             ORDER BY leave_type.name'
        );
        $st->execute([$uid]);
        $balances = $st->fetchAll();
    }

    hr360_ok([
        'types' => array_map(static fn ($r) => [
            'id' => (int) $r['id'],
            'name' => (string) $r['name'],
            'days' => (int) ($r['days'] ?? 0),
        ], $types),
        'balances' => array_map(static fn ($r) => [
            'name' => (string) $r['name'],
            'total_days' => (int) ($r['total_days'] ?? 0),
            'used_leaves' => (int) ($r['used_leaves'] ?? 0),
        ], $balances),
    ]);
}

function hr360_leave_index(): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);
    $isAdmin = (int) ($auth['claims']['user_status'] ?? 0) === 2
        || !empty($auth['claims']['is_superuser']);

    $sql = 'SELECT `leave`.*,
                   employee.name AS employeeName,
                   employee.employee_code AS employeeCode,
                   employee.line_manager AS line_manager,
                   leave_type.name AS leaveType
            FROM `leave`
            LEFT JOIN employee ON employee.employee_id = `leave`.employee
            LEFT JOIN leave_type ON leave_type.id = `leave`.leave_type';

    if ($isAdmin) {
        $rows = $pdo->query($sql . ' ORDER BY `leave`.id DESC')->fetchAll();
    } else {
        $st = $pdo->prepare(
            $sql . ' WHERE `leave`.employee = ?
                      OR employee.line_manager = ?
                    ORDER BY `leave`.id DESC'
        );
        $st->execute([$uid, $uid]);
        $rows = $st->fetchAll();
    }

    $out = [];
    foreach ($rows as $row) {
        if ($isAdmin) {
            $row['_viewer_is_admin'] = true;
        }
        $out[] = hr360_map_leave($row, $uid);
    }

    hr360_ok(['leaves' => $out]);
}

function hr360_leave_apply(): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);
    if ($uid < 1) {
        hr360_error('Only employees can apply for leave.', 403);
    }

    $payload = hr360_body();
    $typeId = (int) ($payload['leave_type_id'] ?? $payload['leaveType'] ?? 0);
    $from = trim((string) ($payload['from'] ?? ''));
    $to = trim((string) ($payload['to'] ?? ''));
    $days = (int) ($payload['days'] ?? 0);
    $reason = trim((string) ($payload['reason'] ?? ''));

    if ($typeId < 1) {
        hr360_error('Leave type is required.', 422);
    }
    if ($from === '' || $to === '') {
        hr360_error('From and To dates are required.', 422);
    }

    $fromDt = DateTime::createFromFormat('d-m-Y', $from) ?: DateTime::createFromFormat('Y-m-d', $from);
    $toDt = DateTime::createFromFormat('d-m-Y', $to) ?: DateTime::createFromFormat('Y-m-d', $to);
    if (!$fromDt || !$toDt) {
        hr360_error('Invalid leave dates. Use Y-m-d or d-m-Y.', 422);
    }

    $st = $pdo->prepare(
        'INSERT INTO `leave`
         (leave_type, employee, `from`, `to`, days, reason, status, date, added_by, approval_pending_level)
         VALUES (?, ?, ?, ?, ?, ?, 0, NOW(), ?, 1)'
    );
    $st->execute([
        $typeId,
        $uid,
        $fromDt->format('Y-m-d'),
        $toDt->format('Y-m-d'),
        $days > 0 ? $days : 1,
        $reason,
        $uid,
    ]);

    hr360_ok(['message' => 'Leave submitted successfully.']);
}

function hr360_leave_act(string $action): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);
    $isAdmin = (int) ($auth['claims']['user_status'] ?? 0) === 2
        || !empty($auth['claims']['is_superuser']);

    $payload = hr360_body();
    $id = (int) ($payload['id'] ?? 0);
    if ($id < 1) {
        hr360_error('Invalid leave ID.', 422);
    }

    $st = $pdo->prepare(
        'SELECT `leave`.*, employee.line_manager
         FROM `leave`
         LEFT JOIN employee ON employee.employee_id = `leave`.employee
         WHERE `leave`.id = ? LIMIT 1'
    );
    $st->execute([$id]);
    $row = $st->fetch();
    if (!$row) {
        hr360_error('Leave not found.', 404);
    }
    if ((int) ($row['status'] ?? 0) !== 0) {
        hr360_error('Leave is already finalized.', 422);
    }

    $ownerId = (int) ($row['employee'] ?? 0);
    $lineManager = (int) ($row['line_manager'] ?? 0);
    $allowed = $isAdmin || ($lineManager === $uid && $ownerId !== $uid);
    if (!$allowed) {
        hr360_error('You are not allowed to ' . $action . ' this leave.', 403);
    }

    $newStatus = $action === 'reject' ? 2 : 1;
    $upd = $pdo->prepare(
        'UPDATE `leave` SET status = ?, approval_pending_level = NULL WHERE id = ?'
    );
    $upd->execute([$newStatus, $id]);

    hr360_ok(['message' => 'Leave ' . ($action === 'reject' ? 'rejected' : 'approved') . '.']);
}
