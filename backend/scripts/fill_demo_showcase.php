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

$projectId = $projectId > 0 ? $projectId : (int) (Schema::hasTable('project') ? (DB::table('project')->orderBy('project_id')->value('project_id') ?? 0) : 0);
$stationId = Schema::hasTable('station') ? (int) (DB::table('station')->orderBy('station_id')->value('station_id') ?? 0) : 0;
$stationTo = Schema::hasTable('station') ? (int) (DB::table('station')->orderByDesc('station_id')->value('station_id') ?? 0) : 0;
$departmentId = Schema::hasTable('department') ? (int) (DB::table('department')->orderBy('department_id')->value('department_id') ?? 0) : 0;
$designationFrom = Schema::hasTable('designation') ? (int) (DB::table('designation')->orderBy('designation_id')->value('designation_id') ?? 0) : 0;
$designationTo = Schema::hasTable('designation') ? (int) (DB::table('designation')->orderByDesc('designation_id')->value('designation_id') ?? 0) : 0;

if (Schema::hasTable('hr_payroll_item')) {
    foreach ([
        'BASIC' => 'earning',
        'HRA' => 'allowance',
        'ARREARS' => 'allowance',
        'BONUS' => 'bonus',
        'COMM' => 'commission',
        'ADJ' => 'adjustment',
    ] as $code => $category) {
        $changed = DB::table('hr_payroll_item')->where('code', $code)->where('category', '!=', $category)->update([
            'category' => $category,
            'status' => 1,
        ]);
        $added += $changed;
    }
    foreach ([
        ['ALLOW_MEAL', 'Meal Allowance', 'allowance', 'fixed', 180],
        ['ALLOW_TRANS', 'Transport Allowance', 'allowance', 'fixed', 150],
        ['BONUS_SPOT', 'Spot Bonus', 'bonus', 'fixed', 500],
        ['BONUS_Q', 'Quarterly Bonus', 'bonus', 'percent', 8],
        ['COMM_NEW', 'New Business Commission', 'commission', 'percent', 5],
        ['EARN_SHIFT', 'Shift Differential', 'earning', 'fixed', 200],
        ['EARN_CTC', 'Employer Benefits', 'earning', 'fixed', 350],
        ['ADJ_ROUND', 'Payroll Adjustment', 'adjustment', 'fixed', 25],
    ] as [$code, $name, $category, $calc, $value]) {
        if (DB::table('hr_payroll_item')->where('code', $code)->exists()) {
            continue;
        }
        if (demoInsert('hr_payroll_item', [
            'code' => $code,
            'name' => $name,
            'category' => $category,
            'calc_type' => $calc,
            'default_value' => $value,
            'taxable' => 1,
            'status' => 1,
        ])) {
            $added++;
        }
    }
}

if (Schema::hasTable('hr_overtime_entry') && (int) DB::table('hr_overtime_entry')->count() === 0) {
    foreach ([2.5, 3, 1.5, 4] as $i => $hours) {
        if (demoInsert('hr_overtime_entry', [
            'employee_id' => $pick($i + 1),
            'work_date' => '2026-10-'.str_pad((string) (6 + $i * 4), 2, '0', STR_PAD_LEFT),
            'hours' => $hours,
            'rate_multiplier' => $i % 2 === 0 ? 1.5 : 2,
            'status' => $i === 3 ? 0 : 1,
        ])) {
            $added++;
        }
    }
}

if (!demoHas('hr_advance', 'remarks', $marker)) {
    foreach ([800, 1200, 500] as $i => $amount) {
        if (demoInsert('hr_advance', [
            'employee_id' => $pick($i + 2),
            'amount' => $amount,
            'request_date' => '2026-10-'.str_pad((string) (3 + $i), 2, '0', STR_PAD_LEFT),
            'recover_months' => 2 + $i,
            'status' => $i === 0 ? 0 : 1,
            'remarks' => $marker.' Salary advance for the month.',
        ])) {
            $added++;
        }
    }
}

if (Schema::hasTable('employee_settlements') && (int) DB::table('employee_settlements')->count() === 0) {
        foreach ([[4200, 1800, 6000], [3100, 900, 4000]] as $i => [$pf, $gratuity, $net]) {
            if (demoInsert('employee_settlements', [
                'employee' => $pick($i + 10),
                'date_of_joining' => '2022-03-01',
                'last_working_date' => '2026-11-30',
                'employee_pf' => $pf / 2,
                'employer_pf' => $pf / 2,
                'total_pf' => $pf,
                'gratuity_eligibility' => 1,
                'gratuity_amount' => $gratuity,
                'outstanding_loan' => 0,
                'loan_deduction' => 0,
                'assets_returned' => $i === 0 ? 1 : 0,
                'clearance_status' => $i === 0 ? 'Cleared' : 'Pending',
                'total_payable' => $net,
                'net_payable' => $net,
            ])) {
                $added++;
            }
        }
}

if (!demoHas('hr_contract', 'notes', $marker)) {
    foreach (['Permanent', 'Contract', 'Consultant'] as $i => $type) {
        if (demoInsert('hr_contract', [
            'employee_id' => $pick($i + 1),
            'contract_no' => 'CTR-2026-'.str_pad((string) ($i + 1), 3, '0', STR_PAD_LEFT),
            'contract_type' => $type,
            'start_date' => '2026-01-01',
            'end_date' => $type === 'Permanent' ? null : '2026-12-31',
            'project_id' => $projectId > 0 ? $projectId : null,
            'station_id' => $stationId > 0 ? $stationId : null,
            'status' => 1,
            'notes' => $marker.' Active employment contract.',
        ])) {
            $added++;
        }
    }
}

if (!demoHas('hr_assignment', 'role_title', 'Client Lead') && Schema::hasTable('hr_assignment') && (int) DB::table('hr_assignment')->count() === 0) {
    foreach (['Client Lead', 'Payroll Analyst', 'People Partner'] as $i => $role) {
        if (demoInsert('hr_assignment', [
            'employee_id' => $pick($i + 2),
            'project_id' => $projectId > 0 ? $projectId : null,
            'station_id' => $stationId > 0 ? $stationId : null,
            'department_id' => $departmentId > 0 ? $departmentId : null,
            'role_title' => $role,
            'start_date' => '2026-02-01',
            'end_date' => '2026-12-31',
            'status' => 1,
        ])) {
            $added++;
        }
    }
}

if (!demoHas('hr_transfer', 'reason', $marker)) {
    foreach (['Office move for the account team.', 'Project handover to the new site.'] as $i => $reason) {
        if (demoInsert('hr_transfer', [
            'employee_id' => $pick($i + 4),
            'from_station_id' => $stationId > 0 ? $stationId : null,
            'to_station_id' => $stationTo > 0 ? $stationTo : null,
            'from_project_id' => $projectId > 0 ? $projectId : null,
            'to_project_id' => $projectId > 0 ? $projectId : null,
            'effective_date' => '2026-11-01',
            'reason' => $marker.' '.$reason,
            'status' => $i,
        ])) {
            $added++;
        }
    }
}

if (!demoHas('hr_promotion', 'remarks', $marker)) {
    foreach (['Annual review promotion.', 'Acting role made permanent.'] as $i => $remarks) {
        if (demoInsert('hr_promotion', [
            'employee_id' => $pick($i + 3),
            'from_designation_id' => $designationFrom > 0 ? $designationFrom : null,
            'to_designation_id' => $designationTo > 0 ? $designationTo : null,
            'effective_date' => '2026-12-01',
            'remarks' => $marker.' '.$remarks,
            'status' => 1,
        ])) {
            $added++;
        }
    }
}

if (!demoHas('hr_complaint', 'detail', $marker)) {
    foreach (['Workplace schedule dispute', 'Equipment request delay'] as $i => $subject) {
        if (demoInsert('hr_complaint', [
            'employee_id' => $pick($i + 5),
            'against_employee_id' => $pick($i + 8),
            'subject' => $subject,
            'detail' => $marker.' Logged for the demo review queue.',
            'status' => $i,
        ])) {
            $added++;
        }
    }
}

if (!demoHas('hr_discipline', 'detail', $marker)) {
    foreach (['Warning', 'Written Warning'] as $i => $action) {
        if (demoInsert('hr_discipline', [
            'employee_id' => $pick($i + 7),
            'action_type' => $action,
            'action_date' => '2026-09-'.str_pad((string) (12 + $i), 2, '0', STR_PAD_LEFT),
            'detail' => $marker.' Recorded after a manager discussion. The employee remains active.',
            'status' => 1,
        ])) {
            $added++;
        }
    }
}

if (Schema::hasTable('termination') && (int) DB::table('termination')->count() === 0) {
    if (demoInsert('termination', [
        'employee' => $pick(12),
        'termination_type' => 'Contract End',
        'termination_date' => '2026-11-30',
        'notice_date' => '2026-10-31',
        'reason' => $marker.' Sample final-settlement case. The employee record is not removed.',
    ])) {
        $added++;
    }
}

if (Schema::hasTable('training_type')) {
    foreach ([
        ['Leadership Workshop', 'Development', 0],
        ['Payroll Close', 'Finance', 1],
        ['Customer Handling', 'Development', 0],
    ] as [$name, $category, $mandatory]) {
        if (DB::table('training_type')->where('name', $name)->exists()) {
            continue;
        }
        if (demoInsert('training_type', [
            'name' => $name,
            'category' => $category,
            'renewal_months' => 12,
            'is_mandatory' => $mandatory,
            'description' => $marker.' '.$name,
            'status' => 1,
        ])) {
            $added++;
        }
    }
}

if (Schema::hasTable('trainers')) {
    foreach ([
        ['Noah', 'Bennett', 'Facilitator', 'noah.bennett@demo.local'],
        ['Maya', 'Chen', 'External Coach', 'maya.chen@demo.local'],
    ] as [$first, $last, $role, $email]) {
        if (DB::table('trainers')->where('email', $email)->exists()) {
            continue;
        }
        if (demoInsert('trainers', [
            'first_name' => $first,
            'last_name' => $last,
            'role' => $role,
            'internal_external' => $role === 'External Coach' ? 'external' : 'internal',
            'email' => $email,
            'phone' => '+1 202 555 0148',
            'description' => $marker,
            'status' => 1,
        ])) {
            $added++;
        }
    }
}

if (Schema::hasTable('training') && !demoHas('training', 'description', $marker)) {
    $typeId = (int) (DB::table('training_type')->orderBy('id')->value('id') ?? 0);
    $trainerId = (int) (DB::table('trainers')->orderBy('id')->value('id') ?? 0);
    $sessions = [
        ['October Leadership', '2026-10-08', '2026-10-09', 'Board room', 'Scheduled'],
        ['Payroll Close Lab', '2026-10-15', '2026-10-15', 'Training room B', 'Completed'],
        ['Customer Handling', '2026-10-22', '2026-10-23', 'Online', 'In Progress'],
        ['November Safety', '2026-11-05', '2026-11-06', 'Main hall', 'Scheduled'],
    ];
    foreach ($sessions as $i => [$batch, $start, $end, $venue, $status]) {
        if (!demoInsert('training', [
            'training_type_id' => $typeId > 0 ? $typeId : null,
            'trainer_id' => $trainerId > 0 ? $trainerId : null,
            'employee_id' => $pick($i + 1),
            'start_date' => $start,
            'end_date' => $end,
            'cost' => 750 + ($i * 120),
            'description' => $marker.' '.$batch,
            'status' => 1,
            'venue' => $venue,
            'training_status' => $status,
            'batch_name' => $batch,
            'agenda' => 'Welcome, practice, and close.',
            'is_cancelled' => 0,
        ])) {
            continue;
        }
        $added++;
        $trainingId = (int) DB::table('training')->where('batch_name', $batch)->value('id');
        if ($trainingId > 0 && Schema::hasTable('training_participants')) {
            foreach ([$pick($i + 2), $pick($i + 3), $pick($i + 4)] as $employeeId) {
                $exists = DB::table('training_participants')
                    ->where('training_id', $trainingId)
                    ->where('employee_id', $employeeId)
                    ->exists();
                if ($exists) {
                    continue;
                }
                demoInsert('training_participants', [
                    'training_id' => $trainingId,
                    'employee_id' => $employeeId,
                    'enrollment_date' => $start,
                    'completed' => $status === 'Completed' ? 1 : 0,
                ]);
            }
        }
    }
}

if (Schema::hasTable('performance_review') && !demoHas('performance_review', 'comments', $marker)) {
    $indicatorId = (int) (DB::table('performance_indicator')->orderBy('id')->value('id') ?? 0);
    foreach ([4.5, 4.0, 3.8, 4.2] as $i => $rating) {
        if (demoInsert('performance_review', [
            'employee_id' => $pick($i + 1),
            'indicator_id' => $indicatorId > 0 ? $indicatorId : null,
            'review_date' => '2026-10-'.str_pad((string) (2 + $i), 2, '0', STR_PAD_LEFT),
            'rating' => $rating,
            'comments' => $marker.' Mid-year review note.',
            'reviewer_id' => $pick(0),
            'status' => 1,
        ])) {
            $added++;
        }
    }
}

if (Schema::hasTable('performance_appraisal') && !demoHas('performance_appraisal', 'manager_comments', $marker)) {
    $cycleId = Schema::hasTable('performance_cycle') ? (int) (DB::table('performance_cycle')->orderBy('id')->value('id') ?? 0) : 0;
    foreach (['Exceeds', 'Meets', 'Exceeds'] as $i => $rating) {
        if (demoInsert('performance_appraisal', [
            'employee_id' => $pick($i + 2),
            'manager_id' => $pick(0),
            'cycle_id' => $cycleId > 0 ? $cycleId : null,
            'period' => '2026 H1',
            'overall_score' => 80 + ($i * 5),
            'final_rating' => $rating,
            'self_comments' => $marker.' Self review.',
            'manager_comments' => $marker.' Manager review for the demo cycle.',
            'status' => $i === 2 ? 1 : 2,
        ])) {
            $added++;
        }
    }
}

if (Schema::hasTable('performance_goal') && !demoHas('performance_goal', 'employee_comment', $marker)) {
    $goalTypeId = (int) (DB::table('performance_goal_types')->orderBy('id')->value('id') ?? 0);
    foreach (['Close the quarter with no payroll exceptions', 'Lift client satisfaction', 'Complete the leadership workshop'] as $i => $title) {
        if (demoInsert('performance_goal', [
            'employee_id' => $pick($i + 1),
            'goal_type_id' => $goalTypeId > 0 ? $goalTypeId : null,
            'title' => $title,
            'metric' => 'Percent complete',
            'weight' => 30,
            'target_value' => '100',
            'achievement_value' => (string) (70 + ($i * 10)),
            'score' => 70 + ($i * 10),
            'period' => '2026 H2',
            'status' => 0,
            'employee_comment' => $marker,
            'manager_comment' => $marker.' On track.',
        ])) {
            $added++;
        }
    }
}

$companyId = 0;
if (Schema::hasTable('company')) {
    $companyPk = Schema::hasColumn('company', 'id') ? 'id' : (Schema::hasColumn('company', 'company_id') ? 'company_id' : null);
    if ($companyPk !== null) {
        $companyId = (int) (DB::table('company')->orderBy($companyPk)->value($companyPk) ?? 0);
    }
}

if (Schema::hasTable('hr_org_division')) {
    foreach ([
        ['DIV-OPS', 'Operations'],
        ['DIV-TECH', 'Technology'],
        ['DIV-PEOPLE', 'People and Culture'],
    ] as [$code, $name]) {
        if (DB::table('hr_org_division')->where('code', $code)->exists()) {
            continue;
        }
        if (demoInsert('hr_org_division', [
            'code' => $code,
            'name' => $name,
            'company_id' => $companyId > 0 ? $companyId : null,
            'status' => 1,
        ])) {
            $added++;
        }
    }
}

$divisionId = Schema::hasTable('hr_org_division')
    ? (int) (DB::table('hr_org_division')->where('code', 'DIV-OPS')->value('id') ?? DB::table('hr_org_division')->orderBy('id')->value('id') ?? 0)
    : 0;
$divisionTech = Schema::hasTable('hr_org_division')
    ? (int) (DB::table('hr_org_division')->where('code', 'DIV-TECH')->value('id') ?? $divisionId)
    : 0;

if (Schema::hasTable('hr_cost_center')) {
    foreach ([
        ['CC-OPS', 'Operations', $divisionId],
        ['CC-TECH', 'Technology', $divisionTech],
        ['CC-ADMIN', 'Administration', $divisionId],
    ] as [$code, $name, $div]) {
        if (DB::table('hr_cost_center')->where('code', $code)->exists()) {
            continue;
        }
        if (demoInsert('hr_cost_center', [
            'code' => $code,
            'name' => $name,
            'division_id' => $div > 0 ? $div : null,
            'status' => 1,
        ])) {
            $added++;
        }
    }
}

if (Schema::hasTable('hr_parent_department')) {
    foreach ([
        ['PD-OPS', 'Operations', $divisionId],
        ['PD-TECH', 'Technology', $divisionTech],
        ['PD-CORP', 'Corporate', $divisionId],
    ] as [$code, $name, $div]) {
        if (DB::table('hr_parent_department')->where('code', $code)->exists()) {
            continue;
        }
        if (demoInsert('hr_parent_department', [
            'code' => $code,
            'name' => $name,
            'division_id' => $div > 0 ? $div : null,
            'status' => 1,
        ])) {
            $added++;
        }
    }
}

$costCenterId = Schema::hasTable('hr_cost_center')
    ? (int) (DB::table('hr_cost_center')->where('code', 'CC-OPS')->value('id') ?? 0)
    : 0;
$parentDepartmentId = Schema::hasTable('hr_parent_department')
    ? (int) (DB::table('hr_parent_department')->where('code', 'PD-OPS')->value('id') ?? 0)
    : 0;

if (Schema::hasTable('department') && $divisionId > 0 && Schema::hasColumn('department', 'division_id')) {
    $link = ['division_id' => $divisionId];
    if ($costCenterId > 0 && Schema::hasColumn('department', 'cost_center_id')) {
        $link['cost_center_id'] = $costCenterId;
    }
    if ($parentDepartmentId > 0 && Schema::hasColumn('department', 'parent_department_id')) {
        $link['parent_department_id'] = $parentDepartmentId;
    }
    $added += DB::table('department')->whereNull('division_id')->update($link);
}

if (Schema::hasTable('hr_team') && Schema::hasTable('department')) {
    $deptIds = DB::table('department')->orderBy('department_id')->limit(4)->pluck('department_id')->map(fn ($id) => (int) $id)->all();
    foreach ([
        ['TEAM-DEL', 'Client Delivery'],
        ['TEAM-PAY', 'Payroll'],
        ['TEAM-HR', 'People Operations'],
        ['TEAM-SUP', 'Support'],
    ] as $i => [$code, $name]) {
        if (DB::table('hr_team')->where('code', $code)->exists()) {
            continue;
        }
        if (demoInsert('hr_team', [
            'code' => $code,
            'name' => $name,
            'department_id' => $deptIds[$i % max(1, count($deptIds))] ?? null,
            'lead_employee_id' => $pick($i + 1),
            'status' => 1,
        ])) {
            $added++;
        }
    }
}

if (Schema::hasTable('hr_policy')) {
    foreach ([
        ['Code of Conduct', 'Code of Conduct', '1.0'],
        ['Leave Policy', 'Leave', '2.1'],
        ['Attendance Policy', 'Attendance', '1.4'],
        ['Workplace Safety', 'Safety', '1.0'],
        ['Employee Handbook', 'HR', '3.0'],
    ] as [$title, $category, $version]) {
        if (DB::table('hr_policy')->where('title', $title)->exists()) {
            continue;
        }
        if (demoInsert('hr_policy', [
            'title' => $title,
            'category' => $category,
            'version' => $version,
            'status' => 1,
        ])) {
            $added++;
        }
    }
}

if (Schema::hasTable('attendance')) {
    foreach ([0, 1] as $i) {
        $employeeId = $pick($i + 1);
        $date = '2026-11-0'.(2 + $i);
        $exists = DB::table('attendance')->where('employee_id', $employeeId)->where('date', $date)->exists();
        if ($exists) {
            continue;
        }
        if (demoInsert('attendance', [
            'employee_id' => $employeeId,
            'date' => $date,
            'punch_in' => $date.' 09:20:00',
            'punch_out' => null,
            'total_minutes' => 0,
            'notes' => $marker.' open punch',
        ])) {
            $added++;
        }
    }
}

if (Schema::hasTable('hr_employee_pay')) {
    $payPeople = DB::table('employee')->where('status', '>', 0)->orderBy('employee_id')->limit(16)->get();
    $n = 0;
    foreach ($payPeople as $person) {
        $employeeId = (int) $person->employee_id;
        if (DB::table('hr_employee_pay')->where('employee_id', $employeeId)->exists()) {
            continue;
        }
        $annual = 42000 + ($n * 6500);
        $monthly = round($annual / 12, 2);
        $hourly = round($annual / 52 / 40, 2);
        demoInsert('hr_employee_pay', [
            'employee_id' => $employeeId,
            'payroll_setup' => 'General Payroll',
            'salary_type' => $n % 5 === 0 ? 'Hourly' : 'Salary',
            'currency' => 'USD',
            'hours_per_week' => 40,
            'annual_salary' => $annual,
            'gross_salary' => $monthly,
            'hourly_salary' => $hourly,
            'ot_hourly_salary' => round($hourly * 1.5, 2),
            'bonus_entitlement' => 500 + ($n * 75),
        ]);
        $station = (int) ($person->station ?? 0);
        $project = (int) ($person->project ?? 0);
        if (Schema::hasTable('define_salary') && !DB::table('define_salary')->where('employee_id', $employeeId)->exists()) {
            $basic = round($monthly * 0.7, 2);
            $allowance = round($monthly * 0.15, 2);
            $deduction = round($monthly * 0.08, 2);
            $defineId = DB::table('define_salary')->insertGetId([
                'station_id' => $station > 0 ? $station : 1,
                'project_id' => $project > 0 ? $project : 1,
                'employee_id' => $employeeId,
                'basic_salary' => $basic,
                'total_allowance' => $allowance,
                'total_deduction' => $deduction,
                'net_salary' => round($basic + $allowance - $deduction, 2),
            ]);
            if (Schema::hasTable('define_salary_details') && Schema::hasTable('hr_payroll_item')) {
                $allowItem = (int) (DB::table('hr_payroll_item')->where('category', 'allowance')->orderBy('id')->value('id') ?? 0);
                $deductItem = (int) (DB::table('hr_payroll_item')->where('category', 'deduction')->orderBy('id')->value('id') ?? 0);
                if ($allowItem > 0) {
                    DB::table('define_salary_details')->insert([
                        'define_salary_id' => $defineId,
                        'payroll_item_id' => $allowItem,
                        'allowance' => $allowance,
                        'deduction' => 0,
                    ]);
                }
                if ($deductItem > 0) {
                    DB::table('define_salary_details')->insert([
                        'define_salary_id' => $defineId,
                        'payroll_item_id' => $deductItem,
                        'allowance' => 0,
                        'deduction' => $deduction,
                    ]);
                }
            }
            $added++;
        }
        if (Schema::hasTable('process_salary') && !DB::table('process_salary')->where('employee_id', $employeeId)->where('date', '2026-10-31')->exists()) {
            $basic = round($monthly * 0.7, 2);
            $allowance = round($monthly * 0.15, 2);
            $deduction = round($monthly * 0.08, 2);
            demoInsert('process_salary', [
                'project_id' => $project > 0 ? $project : 1,
                'employee_id' => $employeeId,
                'days' => 22,
                'basic_salary' => $basic,
                'total_allowance' => $allowance,
                'total_deduction' => $deduction,
                'tax_amount' => round($monthly * 0.05, 2),
                'net_salary' => round($basic + $allowance - $deduction, 2),
                'date' => '2026-10-31',
            ]);
        }
        $added++;
        $n++;
    }
}

echo "Demo showcase rows added: {$added}\n";
echo "Employees used: ".count($ids)."\n";
echo "Existing employees, salaries, and payslips were left as they are.\n";
