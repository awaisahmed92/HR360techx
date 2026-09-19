<?php

require_once __DIR__ . '/bootstrap.php';

function hr360_status_label(int $st): string
{
    return match ($st) {
        1 => 'Approved',
        2 => 'Rejected',
        default => 'Pending',
    };
}

function hr360_travel_list(): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);
    $isAdmin = (int) ($auth['claims']['user_status'] ?? 0) === 2;

    if ($isAdmin) {
        $rows = $pdo->query(
            'SELECT t.*, e.name AS employee_name, p.name AS project_name
             FROM travel_request t
             LEFT JOIN employee e ON e.employee_id = t.employee_id
             LEFT JOIN project p ON p.project_id = t.project_id
             ORDER BY t.id DESC'
        )->fetchAll();
    } else {
        $st = $pdo->prepare(
            'SELECT t.*, e.name AS employee_name, p.name AS project_name
             FROM travel_request t
             LEFT JOIN employee e ON e.employee_id = t.employee_id
             LEFT JOIN project p ON p.project_id = t.project_id
             WHERE t.employee_id = ?
                OR e.line_manager = ?
             ORDER BY t.id DESC'
        );
        $st->execute([$uid, $uid]);
        $rows = $st->fetchAll();
    }

    $out = [];
    foreach ($rows as $r) {
        $owner = (int) $r['employee_id'];
        $canApprove = ((int) $r['status'] === 0) && ($isAdmin || $owner !== $uid);
        $out[] = [
            'id' => (int) $r['id'],
            'request_no' => (string) $r['request_no'],
            'employee_id' => $owner,
            'employee_name' => (string) ($r['employee_name'] ?? ''),
            'project_id' => (int) ($r['project_id'] ?? 0),
            'project_name' => (string) ($r['project_name'] ?? ''),
            'start_date' => (string) $r['start_date'],
            'end_date' => (string) $r['end_date'],
            'from_location' => (string) $r['from_location'],
            'to_location' => (string) $r['to_location'],
            'mode_of_travel' => (string) ($r['mode_of_travel'] ?? ''),
            'purpose' => (string) ($r['purpose'] ?? ''),
            'advance_amount' => (float) ($r['advance_amount'] ?? 0),
            'status' => (int) $r['status'],
            'status_label' => hr360_status_label((int) $r['status']),
            'can_approve' => $canApprove,
            'created_at' => (string) ($r['created_at'] ?? ''),
        ];
    }

    hr360_ok(['travels' => $out]);
}

function hr360_travel_apply(): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);
    if ($uid < 1) {
        hr360_error('Employees only.', 403);
    }

    $b = hr360_body();
    $from = trim((string) ($b['from_location'] ?? ''));
    $to = trim((string) ($b['to_location'] ?? ''));
    $start = trim((string) ($b['start_date'] ?? ''));
    $end = trim((string) ($b['end_date'] ?? ''));
    $purpose = trim((string) ($b['purpose'] ?? ''));
    $mode = trim((string) ($b['mode_of_travel'] ?? 'Road'));
    $projectId = (int) ($b['project_id'] ?? 1);
    $advance = (float) ($b['advance_amount'] ?? 0);

    if ($from === '' || $to === '' || $start === '' || $end === '') {
        hr360_error('from_location, to_location, start_date, end_date are required.', 422);
    }

    $startDt = DateTime::createFromFormat('Y-m-d', $start) ?: DateTime::createFromFormat('d-m-Y', $start);
    $endDt = DateTime::createFromFormat('Y-m-d', $end) ?: DateTime::createFromFormat('d-m-Y', $end);
    if (!$startDt || !$endDt) {
        hr360_error('Invalid dates.', 422);
    }

    $no = 'TR' . str_pad((string) (time() % 1000000), 6, '0', STR_PAD_LEFT);
    $st = $pdo->prepare(
        'INSERT INTO travel_request
         (request_no, employee_id, project_id, start_date, end_date, from_location, to_location, mode_of_travel, purpose, advance_amount, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)'
    );
    $st->execute([
        $no,
        $uid,
        $projectId > 0 ? $projectId : null,
        $startDt->format('Y-m-d'),
        $endDt->format('Y-m-d'),
        $from,
        $to,
        $mode,
        $purpose,
        $advance,
    ]);

    hr360_ok(['message' => 'Travel request submitted.', 'request_no' => $no]);
}

function hr360_travel_act(string $action): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);
    $isAdmin = (int) ($auth['claims']['user_status'] ?? 0) === 2;

    $id = (int) (hr360_body()['id'] ?? 0);
    if ($id < 1) {
        hr360_error('Invalid id.', 422);
    }

    $st = $pdo->prepare(
        'SELECT t.*, e.line_manager FROM travel_request t
         LEFT JOIN employee e ON e.employee_id = t.employee_id
         WHERE t.id = ? LIMIT 1'
    );
    $st->execute([$id]);
    $row = $st->fetch();
    if (!$row) {
        hr360_error('Not found.', 404);
    }
    if ((int) $row['status'] !== 0) {
        hr360_error('Already finalized.', 422);
    }

    $owner = (int) $row['employee_id'];
    $lm = (int) ($row['line_manager'] ?? 0);
    if (!$isAdmin && !($lm === $uid && $owner !== $uid)) {
        hr360_error('Not allowed.', 403);
    }

    $status = $action === 'reject' ? 2 : 1;
    $pdo->prepare('UPDATE travel_request SET status = ? WHERE id = ?')->execute([$status, $id]);
    hr360_ok(['message' => 'Travel ' . ($action === 'reject' ? 'rejected' : 'approved') . '.']);
}

function hr360_timesheet_list(): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);
    $isAdmin = (int) ($auth['claims']['user_status'] ?? 0) === 2;

    if ($isAdmin) {
        $rows = $pdo->query(
            'SELECT t.*, e.name AS employee_name, p.name AS project_name
             FROM timesheet t
             LEFT JOIN employee e ON e.employee_id = t.employee_id
             LEFT JOIN project p ON p.project_id = t.project_id
             ORDER BY t.id DESC'
        )->fetchAll();
    } else {
        $st = $pdo->prepare(
            'SELECT t.*, e.name AS employee_name, p.name AS project_name
             FROM timesheet t
             LEFT JOIN employee e ON e.employee_id = t.employee_id
             LEFT JOIN project p ON p.project_id = t.project_id
             WHERE t.employee_id = ? OR e.line_manager = ?
             ORDER BY t.id DESC'
        );
        $st->execute([$uid, $uid]);
        $rows = $st->fetchAll();
    }

    $out = [];
    foreach ($rows as $r) {
        $owner = (int) $r['employee_id'];
        $out[] = [
            'id' => (int) $r['id'],
            'employee_id' => $owner,
            'employee_name' => (string) ($r['employee_name'] ?? ''),
            'project_id' => (int) $r['project_id'],
            'project_name' => (string) ($r['project_name'] ?? ''),
            'from_date' => (string) $r['from_date'],
            'to_date' => (string) $r['to_date'],
            'hours' => (float) $r['hours'],
            'description' => (string) ($r['description'] ?? ''),
            'status' => (int) $r['status'],
            'status_label' => hr360_status_label((int) $r['status']),
            'can_approve' => ((int) $r['status'] === 0) && ($isAdmin || $owner !== $uid),
        ];
    }
    hr360_ok(['timesheets' => $out]);
}

function hr360_timesheet_apply(): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);
    if ($uid < 1) {
        hr360_error('Employees only.', 403);
    }

    $b = hr360_body();
    $projectId = (int) ($b['project_id'] ?? 1);
    $from = trim((string) ($b['from_date'] ?? ''));
    $to = trim((string) ($b['to_date'] ?? ''));
    $hours = (float) ($b['hours'] ?? 0);
    $desc = trim((string) ($b['description'] ?? ''));

    $fromDt = DateTime::createFromFormat('Y-m-d', $from) ?: DateTime::createFromFormat('d-m-Y', $from);
    $toDt = DateTime::createFromFormat('Y-m-d', $to) ?: DateTime::createFromFormat('d-m-Y', $to);
    if (!$fromDt || !$toDt || $hours <= 0) {
        hr360_error('from_date, to_date and hours (>0) are required.', 422);
    }

    $st = $pdo->prepare(
        'INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status)
         VALUES (?, ?, ?, ?, ?, ?, 0)'
    );
    $st->execute([
        $uid,
        $projectId > 0 ? $projectId : 1,
        $fromDt->format('Y-m-d'),
        $toDt->format('Y-m-d'),
        $hours,
        $desc,
    ]);

    hr360_ok(['message' => 'Timesheet submitted.']);
}

function hr360_timesheet_act(string $action): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);
    $isAdmin = (int) ($auth['claims']['user_status'] ?? 0) === 2;

    $id = (int) (hr360_body()['id'] ?? 0);
    if ($id < 1) {
        hr360_error('Invalid id.', 422);
    }

    $st = $pdo->prepare(
        'SELECT t.*, e.line_manager FROM timesheet t
         LEFT JOIN employee e ON e.employee_id = t.employee_id
         WHERE t.id = ? LIMIT 1'
    );
    $st->execute([$id]);
    $row = $st->fetch();
    if (!$row) {
        hr360_error('Not found.', 404);
    }
    if ((int) $row['status'] !== 0) {
        hr360_error('Already finalized.', 422);
    }

    $owner = (int) $row['employee_id'];
    $lm = (int) ($row['line_manager'] ?? 0);
    if (!$isAdmin && !($lm === $uid && $owner !== $uid)) {
        hr360_error('Not allowed.', 403);
    }

    $status = $action === 'reject' ? 2 : 1;
    $pdo->prepare('UPDATE timesheet SET status = ? WHERE id = ?')->execute([$status, $id]);
    hr360_ok(['message' => 'Timesheet ' . ($action === 'reject' ? 'rejected' : 'approved') . '.']);
}

function hr360_approvals_inbox(): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);
    $isAdmin = (int) ($auth['claims']['user_status'] ?? 0) === 2;
    $items = [];

    $leaves = $pdo->query(
        'SELECT l.id, l.employee, l.days, l.`from`, l.`to`,
                e.name AS employee_name, e.line_manager, lt.name AS type_name
         FROM `leave` l
         LEFT JOIN employee e ON e.employee_id = l.employee
         LEFT JOIN leave_type lt ON lt.id = l.leave_type
         WHERE l.status = 0
         ORDER BY l.id DESC'
    )->fetchAll();
    foreach ($leaves as $r) {
        $owner = (int) $r['employee'];
        $lm = (int) ($r['line_manager'] ?? 0);
        if ($isAdmin || ($lm === $uid && $owner !== $uid)) {
            $items[] = [
                'kind' => 'leave',
                'id' => (int) $r['id'],
                'title' => (string) ($r['type_name'] ?? 'Leave'),
                'employee_name' => (string) ($r['employee_name'] ?? ''),
                'summary' => ($r['from'] ?? '') . ' → ' . ($r['to'] ?? '') . ' (' . (int) $r['days'] . 'd)',
            ];
        }
    }

    $travels = $pdo->query(
        'SELECT t.id, t.request_no, t.from_location, t.to_location, t.employee_id,
                e.name AS employee_name, e.line_manager
         FROM travel_request t
         LEFT JOIN employee e ON e.employee_id = t.employee_id
         WHERE t.status = 0
         ORDER BY t.id DESC'
    )->fetchAll();
    foreach ($travels as $r) {
        $owner = (int) $r['employee_id'];
        $lm = (int) ($r['line_manager'] ?? 0);
        if ($isAdmin || ($lm === $uid && $owner !== $uid)) {
            $items[] = [
                'kind' => 'travel',
                'id' => (int) $r['id'],
                'title' => (string) $r['request_no'],
                'employee_name' => (string) ($r['employee_name'] ?? ''),
                'summary' => ($r['from_location'] ?? '') . ' → ' . ($r['to_location'] ?? ''),
            ];
        }
    }

    $sheets = $pdo->query(
        'SELECT t.id, t.hours, t.from_date, t.to_date, t.employee_id,
                e.name AS employee_name, e.line_manager, p.name AS project_name
         FROM timesheet t
         LEFT JOIN employee e ON e.employee_id = t.employee_id
         LEFT JOIN project p ON p.project_id = t.project_id
         WHERE t.status = 0
         ORDER BY t.id DESC'
    )->fetchAll();
    foreach ($sheets as $r) {
        $owner = (int) $r['employee_id'];
        $lm = (int) ($r['line_manager'] ?? 0);
        if ($isAdmin || ($lm === $uid && $owner !== $uid)) {
            $items[] = [
                'kind' => 'timesheet',
                'id' => (int) $r['id'],
                'title' => (string) ($r['project_name'] ?? 'Timesheet'),
                'employee_name' => (string) ($r['employee_name'] ?? ''),
                'summary' => ($r['from_date'] ?? '') . ' → ' . ($r['to_date'] ?? '') . ' · ' . $r['hours'] . 'h',
            ];
        }
    }

    hr360_ok(['items' => $items, 'count' => count($items)]);
}
