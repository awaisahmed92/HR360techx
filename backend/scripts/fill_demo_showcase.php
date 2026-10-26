<?php

/**
 * Fills empty demo screens (Wall of Fame, pending approvals, holidays, announcements)
 * using employees already in the database.
 *
 * Does not delete employees, payslips, or SEED records.
 * Does not run on container start. Safe to run again.
 *
 * Local:
 *   php scripts/fill_demo_showcase.php
 * Production API container, once, after this file is in the image:
 *   php scripts/fill_demo_showcase.php
 */

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

if (!Schema::hasTable('employee')) {
    fwrite(STDERR, "No employee table in this database.\n");
    exit(1);
}

$people = DB::table('employee')->orderBy('employee_id')->limit(24)->get();
if ($people->isEmpty()) {
    fwrite(STDERR, "No employees to attach demo rows to.\n");
    exit(1);
}

$added = 0;

function demoHas(string $table, string $column, string $marker): bool
{
    if (!Schema::hasTable($table) || !Schema::hasColumn($table, $column)) {
        return false;
    }

    return DB::table($table)->where($column, 'like', '%'.$marker.'%')->exists();
}

function demoInsert(string $table, array $data): bool
{
    if (!Schema::hasTable($table)) {
        return false;
    }
    $row = [];
    foreach ($data as $column => $value) {
        if (Schema::hasColumn($table, $column)) {
            $row[$column] = $value;
        }
    }
    if ($row === []) {
        return false;
    }
    DB::table($table)->insert($row);

    return true;
}

$ids = [];
foreach ($people as $person) {
    $ids[] = (int) $person->employee_id;
}
$pick = function (int $index) use ($ids): int {
    return $ids[$index % count($ids)];
};
$nameOf = function (int $id) use ($people): string {
    foreach ($people as $person) {
        if ((int) $person->employee_id === $id) {
            $surname = isset($person->surname) ? trim((string) $person->surname) : '';

            return trim($person->name.' '.$surname);
        }
    }

    return 'Employee';
};

$marker = '[demo]';

if (Schema::hasTable('leave_type')) {
    foreach (['Annual Leave' => 20, 'Sick Leave' => 10, 'Unpaid Leave' => 0] as $label => $days) {
        if (!DB::table('leave_type')->where('name', $label)->exists()) {
            demoInsert('leave_type', ['name' => $label, 'days' => $days]);
            $added++;
        }
    }
}
$leaveTypeId = Schema::hasTable('leave_type')
    ? (int) (DB::table('leave_type')->orderBy('id')->value('id') ?? 0)
    : 0;

$projectId = Schema::hasTable('project')
    ? (int) (DB::table('project')->orderBy('project_id')->value('project_id') ?? 0)
    : 0;
if ($projectId < 1 && Schema::hasTable('project')) {
    demoInsert('project', ['name' => 'Client Delivery']);
    $projectId = (int) DB::table('project')->orderBy('project_id')->value('project_id');
    $added++;
}

if (!demoHas('hr_achievement', 'description', $marker)) {
    $fame = [
        ['Employee of the Quarter', '2026-09-30', 'Recognised for client delivery and mentoring new joiners.'],
        ['Customer Hero', '2026-08-15', 'Recovered a delayed rollout and kept the account.'],
        ['Innovation Award', '2026-07-01', 'Shipped the attendance self-service flow.'],
        ['Team Player', '2026-06-12', 'Covered two offices during the summer handover.'],
        ['Quality Champion', '2026-05-20', 'Closed the payroll exception queue for the quarter.'],
        ['Rising Star', '2026-04-08', 'First year, already leading a small project team.'],
    ];
    foreach ($fame as $i => [$title, $date, $text]) {
        if (demoInsert('hr_achievement', [
            'employee_id' => $pick($i + 1),
            'title' => $title,
            'achieved_on' => $date,
            'description' => $marker.' '.$text,
        ])) {
            $added++;
        }
    }
}

if ($leaveTypeId > 0 && !demoHas('leave', 'reason', $marker)) {
    $leaves = [
        ['2026-11-02', '2026-11-04', 3, 'Annual leave for a family visit.'],
        ['2026-11-10', '2026-11-11', 2, 'Sick leave, medical certificate attached.'],
        ['2026-11-16', '2026-11-20', 5, 'Annual leave around a public holiday.'],
        ['2026-11-24', '2026-11-24', 1, 'Personal day.'],
    ];
    foreach ($leaves as $i => [$from, $to, $days, $reason]) {
        if (demoInsert('leave', [
            'leave_type' => $leaveTypeId,
            'employee' => $pick($i + 2),
            'from' => $from,
            'to' => $to,
            'days' => $days,
            'reason' => $marker.' '.$reason,
            'status' => 0,
            'date' => date('Y-m-d H:i:s'),
            'approval_pending_level' => 1,
            'current_approval_level' => 1,
            'added_by' => $pick($i + 2),
        ])) {
            $added++;
        }
    }
}

if (!demoHas('travel_request', 'purpose', $marker)) {
    $trips = [
        ['DEMO-TRV-101', 'New York', 'Chicago', 'Client workshop'],
        ['DEMO-TRV-102', 'Berlin', 'Munich', 'Office handover'],
        ['DEMO-TRV-103', 'Toronto', 'New York', 'Quarterly review'],
    ];
    foreach ($trips as $i => [$no, $from, $to, $purpose]) {
        if (DB::table('travel_request')->where('request_no', $no)->exists()) {
            continue;
        }
        if (demoInsert('travel_request', [
            'request_no' => $no,
            'employee_id' => $pick($i + 3),
            'project_id' => $projectId > 0 ? $projectId : null,
            'start_date' => '2026-11-0'.(3 + $i),
            'end_date' => '2026-11-0'.(5 + $i),
            'from_location' => $from,
            'to_location' => $to,
            'mode_of_travel' => 'Flight',
            'purpose' => $marker.' '.$purpose,
            'advance_amount' => 450 + ($i * 120),
            'status' => 0,
            'approval_pending_level' => 1,
            'current_approval_level' => 1,
        ])) {
            $added++;
        }
    }
}

if ($projectId > 0 && !demoHas('timesheet', 'description', $marker)) {
    foreach ([32, 40, 24] as $i => $hours) {
        if (demoInsert('timesheet', [
            'employee_id' => $pick($i + 4),
            'project_id' => $projectId,
            'from_date' => '2026-10-0'.(6 + $i),
            'to_date' => '2026-10-1'.(0 + $i),
            'hours' => $hours,
            'description' => $marker.' Week of client delivery work.',
            'status' => 0,
            'approval_pending_level' => 1,
            'current_approval_level' => 1,
        ])) {
            $added++;
        }
    }
}

if (!demoHas('loan_application', 'purpose_of_loan', $marker)) {
    foreach ([2500, 1800] as $i => $amount) {
        if (demoInsert('loan_application', [
            'employee' => $pick($i + 5),
            'loan_amount' => $amount,
            'purpose_of_loan' => $marker.' Home relocation support.',
            'start_date' => '2026-11-01',
            'end_date' => '2027-04-30',
            'status' => 'pending',
            'created_by' => $pick($i + 5),
        ])) {
            $added++;
        }
    }
}

if (!demoHas('hr_resignation', 'reason', $marker)) {
    if (demoInsert('hr_resignation', [
        'employee_id' => $pick(8),
        'resign_date' => '2026-11-15',
        'last_working_day' => '2026-12-15',
        'reason' => $marker.' Relocating with family. Notice period served.',
        'status' => 0,
    ])) {
        $added++;
    }
}

if (!demoHas('hr_employment_change', 'remarks', $marker)) {
    foreach ([['Station', 'Chicago', 'New York'], ['Department', 'Operations', 'Technology']] as $i => [$type, $old, $new]) {
        if (demoInsert('hr_employment_change', [
            'employee_id' => $pick($i + 6),
            'change_type' => $type,
            'effective_date' => '2026-12-01',
            'old_value' => $old,
            'new_value' => $new,
            'remarks' => $marker.' Requested by the employee.',
            'status' => 0,
        ])) {
            $added++;
        }
    }
}

if (Schema::hasTable('hr_holiday') && (int) DB::table('hr_holiday')->count() < 3) {
    foreach ([
        ['New Year\'s Day', '2026-01-01'],
        ['Good Friday', '2026-04-03'],
        ['Labour Day', '2026-05-01'],
        ['Christmas Day', '2026-12-25'],
    ] as [$name, $date]) {
        if (!DB::table('hr_holiday')->where('holiday_date', $date)->exists()) {
            demoInsert('hr_holiday', [
                'name' => $name,
                'holiday_date' => $date,
                'holiday_type' => 'Public',
                'status' => 1,
            ]);
            $added++;
        }
    }
}

if (!demoHas('hr_announcement', 'body', $marker)) {
    foreach ([
        ['Open enrollment is open', 'Benefits choices close on 30 November. Review your cover in My Info.'],
        ['November town hall', 'Join the all-hands on 12 November at 10:00. The recording will be posted here.'],
    ] as [$title, $body]) {
        if (demoInsert('hr_announcement', [
            'title' => $title,
            'body' => $marker.' '.$body,
            'audience' => 'all',
            'starts_on' => '2026-10-01',
            'ends_on' => '2026-12-31',
            'status' => 1,
            'created_by' => $pick(0),
        ])) {
            $added++;
        }
    }
}

if (!demoHas('status_posts', 'body', $marker)) {
    $posts = [
        ['Welcome to the November cycle', 'status'],
        ['Payroll for October is published. Review your payslip under My Info.', 'announcement'],
        ['Office closed 25 December.', 'holiday'],
    ];
    foreach ($posts as $i => [$body, $type]) {
        $authorId = $pick($i);
        if (demoInsert('status_posts', [
            'employee_id' => $authorId,
            'author' => $nameOf($authorId),
            'body' => $marker.' '.$body,
            'type' => $type,
            'created_at' => date('Y-m-d H:i:s', strtotime('-'.($i + 1).' days')),
        ])) {
            $added++;
        }
    }
}

if (Schema::hasTable('attendance')) {
    $days = 0;
    $cursor = new DateTimeImmutable('today');
    for ($n = 0; $n < 14 && $days < 8; $n++) {
        $cursor = $cursor->modify('-1 day');
        if ((int) $cursor->format('N') >= 6) {
            continue;
        }
        $days++;
        foreach (array_slice($ids, 0, 8) as $offset => $employeeId) {
            $exists = DB::table('attendance')
                ->where('employee_id', $employeeId)
                ->where('date', $cursor->format('Y-m-d'))
                ->exists();
            if ($exists) {
                continue;
            }
            $in = $cursor->setTime(9, ($offset % 3) * 5);
            $out = $cursor->setTime(17, 30);
            if (demoInsert('attendance', [
                'employee_id' => $employeeId,
                'date' => $cursor->format('Y-m-d'),
                'punch_in' => $in->format('Y-m-d H:i:s'),
                'punch_out' => $out->format('Y-m-d H:i:s'),
                'total_minutes' => 510,
                'notes' => $marker,
            ])) {
                $added++;
            }
        }
    }
}

echo "Demo showcase rows added: {$added}\n";
echo "Employees used: ".count($ids)."\n";
echo "Existing employees, salaries, and payslips were left as they are.\n";
