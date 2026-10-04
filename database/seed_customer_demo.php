<?php
/**
 * Customer-demo people for hr360_demo.
 * Eight employees, defined salaries, three active loans, September 2026 payslips.
 * Re-running replaces only rows tagged DEMO-101 … DEMO-108.
 */
declare(strict_types=1);

$pdo = new PDO('mysql:host=127.0.0.1;dbname=hr360_demo;charset=utf8mb4', 'root', '', [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
]);

$password = password_hash('Demo@360', PASSWORD_BCRYPT);

$dept = [
    'Human Resources' => idOf($pdo, 'department', 'name', 'Human Resources', 'department_id'),
    'Operations' => idOf($pdo, 'department', 'name', 'Operations', 'department_id'),
    'Finance' => ensure($pdo, 'department', 'name', 'Finance', 'department_id'),
    'Sales' => ensure($pdo, 'department', 'name', 'Sales', 'department_id'),
    'Technology' => ensure($pdo, 'department', 'name', 'Technology', 'department_id'),
];
$desig = [
    'HR Officer' => ensure($pdo, 'designation', 'name', 'HR Officer', 'designation_id'),
    'Accountant' => ensure($pdo, 'designation', 'name', 'Accountant', 'designation_id'),
    'Operations Lead' => ensure($pdo, 'designation', 'name', 'Operations Lead', 'designation_id'),
    'Sales Executive' => ensure($pdo, 'designation', 'name', 'Sales Executive', 'designation_id'),
    'Software Engineer' => ensure($pdo, 'designation', 'name', 'Software Engineer', 'designation_id'),
    'Support Officer' => ensure($pdo, 'designation', 'name', 'Support Officer', 'designation_id'),
    'Finance Manager' => ensure($pdo, 'designation', 'name', 'Finance Manager', 'designation_id'),
    'Recruiter' => ensure($pdo, 'designation', 'name', 'Recruiter', 'designation_id'),
];

$people = [
    ['DEMO-101', 'ayesha.khan', 'Ayesha Khan', 'ayesha.khan@hr360.demo', 'HR Officer', 'Human Resources', 95000, 0, 1],
    ['DEMO-102', 'bilal.ahmed', 'Bilal Ahmed', 'bilal.ahmed@hr360.demo', 'Accountant', 'Finance', 120000, 10000, 1],
    ['DEMO-103', 'sara.malik', 'Sara Malik', 'sara.malik@hr360.demo', 'Operations Lead', 'Operations', 150000, 0, 2],
    ['DEMO-104', 'omar.farooq', 'Omar Farooq', 'omar.farooq@hr360.demo', 'Sales Executive', 'Sales', 80000, 0, 1],
    ['DEMO-105', 'hina.raza', 'Hina Raza', 'hina.raza@hr360.demo', 'Software Engineer', 'Technology', 180000, 8000, 2],
    ['DEMO-106', 'usman.ali', 'Usman Ali', 'usman.ali@hr360.demo', 'Support Officer', 'Technology', 70000, 0, 1],
    ['DEMO-107', 'fatima.noor', 'Fatima Noor', 'fatima.noor@hr360.demo', 'Finance Manager', 'Finance', 220000, 12500, 2],
    ['DEMO-108', 'hassan.iqbal', 'Hassan Iqbal', 'hassan.iqbal@hr360.demo', 'Recruiter', 'Human Resources', 90000, 0, 1],
];

$codes = array_column($people, 0);
$in = implode(',', array_fill(0, count($codes), '?'));
$existing = $pdo->prepare("SELECT employee_id FROM employee WHERE employee_code IN ($in)");
$existing->execute($codes);
$ids = $existing->fetchAll(PDO::FETCH_COLUMN);
if ($ids) {
    $idIn = implode(',', array_map('intval', $ids));
    $pdo->exec("DELETE d FROM process_salary_details d INNER JOIN process_salary p ON p.id = d.process_salary_id WHERE p.employee_id IN ($idIn)");
    $pdo->exec("DELETE FROM process_salary WHERE employee_id IN ($idIn)");
    $pdo->exec("DELETE d FROM define_salary_details d INNER JOIN define_salary s ON s.id = d.define_salary_id WHERE s.employee_id IN ($idIn)");
    $pdo->exec("DELETE FROM define_salary WHERE employee_id IN ($idIn)");
    $pdo->exec("DELETE FROM hr_loan WHERE employee_id IN ($idIn)");
    $pdo->exec("DELETE FROM loan_application WHERE employee IN ($idIn)");
    $pdo->exec("DELETE FROM employee WHERE employee_id IN ($idIn)");
}

$item = [];
foreach ($pdo->query('SELECT id, code FROM hr_payroll_item') as $row) {
    $item[$row['code']] = (int) $row['id'];
}

$insEmp = $pdo->prepare(
    'INSERT INTO employee
      (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, father_name, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
     VALUES (?,?,?,?,?,?,1,?,?,?,1,1,1,?, ?,0, ?,?,?,?,?,1,1,?,?,?)'
);
$insDef = $pdo->prepare(
    'INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by)
     VALUES (1,1,?,?,?,0,?,1)'
);
$insDet = $pdo->prepare(
    'INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) VALUES (?,?,?,?)'
);
$insProc = $pdo->prepare(
    'INSERT INTO process_salary
      (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by)
     VALUES (1,?,30,?,?,?,?,?,370,0,0,0,0,0,0,?,0,?,1)'
);
$insProcDet = $pdo->prepare(
    'INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) VALUES (?,?,?,?)'
);
$insLoan = $pdo->prepare(
    'INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks)
     VALUES (?,?,?,?,?,1,?)'
);
$insApp = $pdo->prepare(
    'INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by)
     VALUES (?,?,?,?,?,?,1)'
);

$payDate = '2026-09-30';
$n = 1;
foreach ($people as [$code, $user, $name, $email, $role, $department, $basic, $loanInst, $gender]) {
    $hra = round($basic * 0.40, 2);
    $gross = $basic + $hra;
    $tax = taxMonthly($gross);
    $loanTake = (float) $loanInst;
    $deduct = round($tax + 370 + $loanTake, 2);
    $net = round($gross - $deduct, 2);
    $cnic = sprintf('42101-%07d-1', 1000000 + $n);

    $insEmp->execute([
        $name, $user, $email, '0300' . str_pad((string) (1000000 + $n), 7, '0', STR_PAD_LEFT), $cnic, $password,
        $gender, $desig[$role], $dept[$department], $code, '2024-03-01',
        'Demo', '1992-0' . (($n % 9) + 1) . '-15', 'Single', 'Lahore, Pakistan', 'Monthly',
        $name, '01000000' . $n, 'HABB',
    ]);
    $empId = (int) $pdo->lastInsertId();

    $insDef->execute([$empId, $basic, $gross, $net]);
    $defId = (int) $pdo->lastInsertId();
    $insDet->execute([$defId, $item['BASIC'], $basic, 0]);
    $insDet->execute([$defId, $item['HRA'], $hra, 0]);

    $insProc->execute([$empId, $basic, $gross, $deduct, $net, $tax, $loanTake, $payDate]);
    $procId = (int) $pdo->lastInsertId();
    $insProcDet->execute([$procId, $item['BASIC'], $basic, 0]);
    $insProcDet->execute([$procId, $item['HRA'], $hra, 0]);
    $insProcDet->execute([$procId, $item['TAX'], 0, $tax]);
    $insProcDet->execute([$procId, $item['EOBI_E'], 0, 370]);
    if ($loanTake > 0) {
        $principal = $loanTake * 12;
        $insProcDet->execute([$procId, $item['LOAN'], 0, $loanTake]);
        $insLoan->execute([$empId, $principal, $loanTake, $loanTake, '2026-09-01', 'Demo staff loan, recovered on the September payslip']);
        $insApp->execute([$empId, $principal, 'Personal loan for the customer demo', '2026-09-01', '2027-08-31', 'approved']);
    }
    echo "$code $name  basic $basic  net $net  loan $loanTake  payslip $procId\n";
    $n++;
}

$hassan = (int) $pdo->query("SELECT employee_id FROM employee WHERE employee_code='DEMO-108'")->fetchColumn();
$insApp->execute([$hassan, 50000, 'Pending laptop advance — not yet approved', '2026-10-01', '2027-03-31', 'pending']);
echo "Pending loan application for DEMO-108\n";
echo "Done. Login any demo employee with password Demo@360\n";

function ensure(PDO $pdo, string $table, string $col, string $value, string $idCol): int
{
    $found = idOf($pdo, $table, $col, $value, $idCol);
    if ($found > 0) {
        return $found;
    }
    $pdo->prepare("INSERT INTO `$table` (`$col`) VALUES (?)")->execute([$value]);
    return (int) $pdo->lastInsertId();
}

function idOf(PDO $pdo, string $table, string $col, string $value, string $idCol): int
{
    $st = $pdo->prepare("SELECT `$idCol` FROM `$table` WHERE `$col` = ? LIMIT 1");
    $st->execute([$value]);
    return (int) ($st->fetchColumn() ?: 0);
}

function taxMonthly(float $monthlyGross): float
{
    $annual = $monthlyGross * 12;
    $slabs = [
        [1, 600000, 0],
        [600001, 1200000, 1],
        [1200001, 2200000, 11],
        [2200001, 3200000, 23],
        [3200001, 4100000, 30],
        [4100001, PHP_INT_MAX, 35],
    ];
    $tax = 0.0;
    foreach ($slabs as [$min, $max, $pct]) {
        if ($annual > $min) {
            $taxable = min($annual, $max) - $min;
            if ($taxable > 0) {
                $tax += $taxable * $pct / 100;
            }
        }
    }
    return round($tax / 12, 2);
}
