<?php

require_once __DIR__ . '/bootstrap.php';

function hr360_attendance_today(): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);
    if ($uid < 1) {
        hr360_error('Employees only.', 403);
    }

    $today = date('Y-m-d');
    $st = $pdo->prepare('SELECT * FROM attendance WHERE employee_id = ? AND `date` = ? LIMIT 1');
    $st->execute([$uid, $today]);
    $row = $st->fetch() ?: null;

    hr360_ok([
        'date' => $today,
        'record' => $row ? hr360_map_attendance($row) : null,
        'can_punch_in' => $row === null || empty($row['punch_in']),
        'can_punch_out' => $row !== null && !empty($row['punch_in']) && empty($row['punch_out']),
    ]);
}

function hr360_attendance_list(): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);
    if ($uid < 1) {
        hr360_error('Employees only.', 403);
    }

    $month = trim((string) ($_GET['month'] ?? date('Y-m')));
    if (!preg_match('/^\d{4}-\d{2}$/', $month)) {
        $month = date('Y-m');
    }

    $st = $pdo->prepare(
        'SELECT * FROM attendance
         WHERE employee_id = ?
           AND `date` LIKE ?
         ORDER BY `date` DESC'
    );
    $st->execute([$uid, $month . '%']);
    $rows = $st->fetchAll();

    hr360_ok([
        'month' => $month,
        'records' => array_map('hr360_map_attendance', $rows),
    ]);
}

function hr360_attendance_punch(): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);
    if ($uid < 1) {
        hr360_error('Employees only.', 403);
    }

    $body = hr360_body();
    $action = strtolower(trim((string) ($body['action'] ?? 'in')));
    $today = date('Y-m-d');
    $now = date('Y-m-d H:i:s');

    $st = $pdo->prepare('SELECT * FROM attendance WHERE employee_id = ? AND `date` = ? LIMIT 1');
    $st->execute([$uid, $today]);
    $row = $st->fetch();

    if ($action === 'in') {
        if ($row && !empty($row['punch_in'])) {
            hr360_error('Already punched in today.', 422);
        }
        if ($row) {
            $upd = $pdo->prepare('UPDATE attendance SET punch_in = ? WHERE id = ?');
            $upd->execute([$now, $row['id']]);
        } else {
            $ins = $pdo->prepare(
                'INSERT INTO attendance (employee_id, `date`, punch_in) VALUES (?, ?, ?)'
            );
            $ins->execute([$uid, $today, $now]);
        }
        hr360_ok(['message' => 'Punched in.', 'punch_in' => $now]);
    }

    if ($action === 'out') {
        if (!$row || empty($row['punch_in'])) {
            hr360_error('Punch in first.', 422);
        }
        if (!empty($row['punch_out'])) {
            hr360_error('Already punched out today.', 422);
        }
        $inTs = strtotime($row['punch_in']);
        $outTs = strtotime($now);
        $mins = max(0, (int) round(($outTs - $inTs) / 60));
        $upd = $pdo->prepare(
            'UPDATE attendance SET punch_out = ?, total_minutes = ? WHERE id = ?'
        );
        $upd->execute([$now, $mins, $row['id']]);
        hr360_ok([
            'message' => 'Punched out.',
            'punch_out' => $now,
            'total_minutes' => $mins,
        ]);
    }

    hr360_error('action must be "in" or "out".', 422);
}

function hr360_map_attendance(array $row): array
{
    return [
        'id' => (int) ($row['id'] ?? 0),
        'employee_id' => (int) ($row['employee_id'] ?? 0),
        'date' => (string) ($row['date'] ?? ''),
        'punch_in' => $row['punch_in'] ?? null,
        'punch_out' => $row['punch_out'] ?? null,
        'total_minutes' => isset($row['total_minutes']) ? (int) $row['total_minutes'] : null,
        'notes' => $row['notes'] ?? null,
    ];
}
