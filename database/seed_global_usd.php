<?php
/**
 * Global USD workforce for hr360_demo.
 * Fifty employees across nine stations, with salary, September 2026 payslips,
 * fifteen loans, two weeks of attendance, and one approved timesheet each.
 * Re-running replaces only SEED-001 … SEED-050.
 */
declare(strict_types=1);

$host = getenv('DB_HOST') ?: '127.0.0.1';
$port = getenv('DB_PORT') ?: '3306';
$name = getenv('DB_DATABASE') ?: 'hr360_demo';
$user = getenv('DB_USERNAME') ?: 'root';
$pass = getenv('DB_PASSWORD') !== false ? (string) getenv('DB_PASSWORD') : '';
$pdo = new PDO("mysql:host={$host};port={$port};dbname={$name};charset=utf8mb4", $user, $pass, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
]);
echo "Seeding {$name} on {$host}\n";

$password = password_hash('360tech', PASSWORD_BCRYPT);
$pdo->exec("UPDATE company SET currency = 'USD' WHERE id = 1");

$places = [
    'New York' => ['USA', '+1'],
    'Chicago' => ['USA', '+1'],
    'Toronto' => ['Canada', '+1'],
    'Vancouver' => ['Canada', '+1'],
    'Berlin' => ['Germany', '+49'],
    'Munich' => ['Germany', '+49'],
    'Amsterdam' => ['Netherlands', '+31'],
    'Paris' => ['France', '+33'],
    'Zurich' => ['Switzerland', '+41'],
];
$stationId = [];
foreach ($places as $city => [$country]) {
    $stationId[$city] = ensure($pdo, 'station', 'name', $city, 'station_id');
}
$projectId = (int) ($pdo->query('SELECT project_id FROM project ORDER BY project_id LIMIT 1')->fetchColumn() ?: 1);

$dept = [
    'Human Resources' => ensure($pdo, 'department', 'name', 'Human Resources', 'department_id'),
    'Operations' => ensure($pdo, 'department', 'name', 'Operations', 'department_id'),
    'Finance' => ensure($pdo, 'department', 'name', 'Finance', 'department_id'),
    'Sales' => ensure($pdo, 'department', 'name', 'Sales', 'department_id'),
    'Technology' => ensure($pdo, 'department', 'name', 'Technology', 'department_id'),
];
$roleDept = [
    'HR Officer' => 'Human Resources',
    'Recruiter' => 'Human Resources',
    'Operations Lead' => 'Operations',
    'Support Officer' => 'Operations',
    'Accountant' => 'Finance',
    'Finance Manager' => 'Finance',
    'Sales Executive' => 'Sales',
    'Software Engineer' => 'Technology',
];
$desig = [];
foreach (array_keys($roleDept) as $role) {
    $desig[$role] = ensure($pdo, 'designation', 'name', $role, 'designation_id');
}
$basePay = [
    'Support Officer' => 4200,
    'Sales Executive' => 5200,
    'HR Officer' => 5800,
    'Recruiter' => 6100,
    'Accountant' => 6800,
    'Software Engineer' => 9200,
    'Operations Lead' => 10500,
    'Finance Manager' => 12800,
];

$people = [
    ['James', 'Carter', 'Software Engineer', 'New York', 1],
    ['Emily', 'Brooks', 'HR Officer', 'New York', 2],
    ['Daniel', 'Hayes', 'Accountant', 'New York', 1],
    ['Olivia', 'Bennett', 'Sales Executive', 'New York', 2],
    ['Noah', 'Parker', 'Support Officer', 'New York', 1],
    ['Sophia', 'Reed', 'Finance Manager', 'New York', 2],
    ['Liam', 'Foster', 'Operations Lead', 'Chicago', 1],
    ['Ava', 'Collins', 'Software Engineer', 'Chicago', 2],
    ['Ethan', 'Murphy', 'Recruiter', 'Chicago', 1],
    ['Mia', 'Stewart', 'Accountant', 'Chicago', 2],
    ['Lucas', 'Ward', 'Sales Executive', 'Chicago', 1],
    ['Grace', 'Powell', 'HR Officer', 'Chicago', 2],
    ['Henry', 'Campbell', 'Software Engineer', 'Toronto', 1],
    ['Chloe', 'Mitchell', 'Finance Manager', 'Toronto', 2],
    ['Owen', 'Russell', 'Support Officer', 'Toronto', 1],
    ['Emma', 'Hughes', 'Operations Lead', 'Toronto', 2],
    ['Jack', 'Sullivan', 'Accountant', 'Toronto', 1],
    ['Lily', 'Barnes', 'Sales Executive', 'Toronto', 2],
    ['Benjamin', 'Cooper', 'Software Engineer', 'Vancouver', 1],
    ['Hannah', 'Price', 'HR Officer', 'Vancouver', 2],
    ['Samuel', 'Long', 'Recruiter', 'Vancouver', 1],
    ['Natalie', 'Gray', 'Accountant', 'Vancouver', 2],
    ['Andrew', 'Watson', 'Operations Lead', 'Vancouver', 1],
    ['Victoria', 'Ross', 'Finance Manager', 'Vancouver', 2],
    ['Alexander', 'Schmidt', 'Software Engineer', 'Berlin', 1],
    ['Clara', 'Hoffman', 'HR Officer', 'Berlin', 2],
    ['Felix', 'Weber', 'Accountant', 'Berlin', 1],
    ['Anna', 'Keller', 'Sales Executive', 'Berlin', 2],
    ['Jonas', 'Bauer', 'Support Officer', 'Berlin', 1],
    ['Laura', 'Fischer', 'Operations Lead', 'Berlin', 2],
    ['Max', 'Wagner', 'Software Engineer', 'Munich', 1],
    ['Sophie', 'Richter', 'Finance Manager', 'Munich', 2],
    ['Leon', 'Kruger', 'Recruiter', 'Munich', 1],
    ['Marie', 'Neumann', 'Accountant', 'Munich', 2],
    ['Paul', 'Schwarz', 'Sales Executive', 'Munich', 1],
    ['Eva', 'Wolf', 'HR Officer', 'Munich', 2],
    ['Thomas', 'de Vries', 'Software Engineer', 'Amsterdam', 1],
    ['Sophie', 'Bakker', 'Operations Lead', 'Amsterdam', 2],
    ['Julian', 'Visser', 'Accountant', 'Amsterdam', 1],
    ['Emma', 'Jansen', 'Sales Executive', 'Amsterdam', 2],
    ['Hugo', 'Moreau', 'Software Engineer', 'Paris', 1],
    ['Camille', 'Laurent', 'HR Officer', 'Paris', 2],
    ['Antoine', 'Bernard', 'Finance Manager', 'Paris', 1],
    ['Elise', 'Martin', 'Accountant', 'Paris', 2],
    ['Louis', 'Petit', 'Support Officer', 'Paris', 1],
    ['Nina', 'Keller', 'Software Engineer', 'Zurich', 2],
    ['David', 'Meier', 'Finance Manager', 'Zurich', 1],
    ['Lena', 'Brunner', 'HR Officer', 'Zurich', 2],
    ['Marco', 'Steiner', 'Operations Lead', 'Zurich', 1],
    ['Sara', 'Frei', 'Accountant', 'Zurich', 2],
];

$codes = [];
foreach ($people as $i => $_) {
    $codes[] = sprintf('SEED-%03d', $i + 1);
}
$in = implode(',', array_fill(0, count($codes), '?'));
$existing = $pdo->prepare("SELECT employee_id FROM employee WHERE employee_code IN ($in)");
$existing->execute($codes);
$ids = $existing->fetchAll(PDO::FETCH_COLUMN);
if ($ids) {
    $idIn = implode(',', array_map('intval', $ids));
    $pdo->exec("DELETE FROM attendance WHERE employee_id IN ($idIn)");
    $pdo->exec("DELETE FROM timesheet WHERE employee_id IN ($idIn)");
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
foreach (['BASIC', 'HRA', 'TAX', 'LOAN'] as $code) {
    if (empty($item[$code])) {
        fwrite(STDERR, "Missing payroll item $code\n");
        exit(1);
    }
}

$insEmp = $pdo->prepare(
    'INSERT INTO employee
      (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
     VALUES (?,?,?,?,?,?,1,?,?,?,?,?,?,?, ?,0, ?,?,?,?,0,0,?,?,?)'
);
$insDef = $pdo->prepare(
    'INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by)
     VALUES (?,?,?,?,?,?,?,1)'
);
$insDet = $pdo->prepare(
    'INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) VALUES (?,?,?,?)'
);
$insProc = $pdo->prepare(
    'INSERT INTO process_salary
      (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by)
     VALUES (?,?,30,?,?,?,?,?,0,0,0,0,0,0,0,?,0,?,1)'
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
$insAtt = $pdo->prepare(
    'INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes)
     VALUES (?,?,?,?,510,?,1,?)'
);
$insTime = $pdo->prepare(
    'INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status)
     VALUES (?,?,?,?,72,?,1)'
);

$payrollCol = $pdo->query("SHOW COLUMNS FROM employee LIKE 'payroll_type'")->fetch(PDO::FETCH_ASSOC);
$payrollType = (isset($payrollCol['Type']) && stripos((string) $payrollCol['Type'], 'int') !== false) ? 1 : 'Monthly';
$workdays = ['2026-09-01', '2026-09-02', '2026-09-03', '2026-09-04', '2026-09-07', '2026-09-08', '2026-09-09', '2026-09-10', '2026-09-11'];
$managers = [];
$byStation = [];
$loanCount = 0;
$inserted = 0;

$pdo->beginTransaction();
foreach ($people as $i => [$first, $last, $role, $city, $gender]) {
    $n = $i + 1;
    $code = sprintf('SEED-%03d', $n);
    [$country, $dial] = $places[$city];
    $name = "$first $last";
    $user = strtolower($first . '.' . $last . $n);
    $user = preg_replace('/[^a-z0-9.]/', '', $user);
    $email = $user . '@hr360.demo';
    $basic = $basePay[$role] + (($n % 5) * 150);
    $allowance = round($basic * 0.15, 2);
    $gross = $basic + $allowance;
    $tax = taxMonthlyUsd($gross);
    $loanTake = 0.0;
    if ($n % 3 === 0 && $loanCount < 15) {
        $loanTake = $n % 2 === 0 ? 400.0 : 250.0;
        $loanCount++;
    }
    $deduct = round($tax + $loanTake, 2);
    $net = round($gross - $deduct, 2);
    $phone = $dial . '55501' . str_pad((string) $n, 4, '0', STR_PAD_LEFT);

    $insEmp->execute([
        $name, $user, $email, $phone, 'P-' . $code, $password,
        $gender, $desig[$role], $dept[$roleDept[$role]], $stationId[$city], $projectId, 1, $code, '2024-03-01',
        sprintf('199%d-0%d-15', $n % 8, ($n % 9) + 1),
        $n % 4 === 0 ? 'Married' : 'Single',
        "$city, $country",
        $payrollType,
        $name,
        'USD' . str_pad((string) (100000 + $n), 8, '0', STR_PAD_LEFT),
        'SEED',
    ]);
    $empId = (int) $pdo->lastInsertId();
    $byStation[$city][] = $empId;
    if (!isset($managers[$city])) {
        $managers[$city] = $empId;
    }

    $insDef->execute([$stationId[$city], $projectId, $empId, $basic, $allowance, $deduct, $net]);
    $defId = (int) $pdo->lastInsertId();
    $insDet->execute([$defId, $item['BASIC'], $basic, 0]);
    $insDet->execute([$defId, $item['HRA'], $allowance, 0]);
    $insDet->execute([$defId, $item['TAX'], 0, $tax]);

    $insProc->execute([$projectId, $empId, $basic, $allowance, $deduct, $net, $tax, $loanTake, '2026-09-30']);
    $procId = (int) $pdo->lastInsertId();
    $insProcDet->execute([$procId, $item['BASIC'], $basic, 0]);
    $insProcDet->execute([$procId, $item['HRA'], $allowance, 0]);
    $insProcDet->execute([$procId, $item['TAX'], 0, $tax]);
    if ($loanTake > 0) {
        $principal = $loanTake * 12;
        $insProcDet->execute([$procId, $item['LOAN'], 0, $loanTake]);
        $insDet->execute([$defId, $item['LOAN'], 0, $loanTake]);
        $insLoan->execute([$empId, $principal, $loanTake, $loanTake, '2026-09-01', 'USD staff loan recovered on the September payslip']);
        $insApp->execute([$empId, $principal, 'Personal loan', '2026-09-01', '2027-08-31', 'approved']);
    }

    foreach ($workdays as $day) {
        $late = $day === '2026-09-03' && $n % 7 === 0 ? 20 : 0;
        $in = $late > 0 ? "$day 09:20:00" : "$day 09:00:00";
        $insAtt->execute([$empId, $day, $in, "$day 17:30:00", $late, 'USD seed attendance']);
    }
    $insTime->execute([$empId, $projectId, '2026-09-01', '2026-09-11', "September timesheet for $city"]);
    $inserted++;
}

$updMgr = $pdo->prepare('UPDATE employee SET line_manager = ? WHERE employee_id = ? AND employee_id <> ?');
foreach ($byStation as $city => $empIds) {
    $manager = $managers[$city];
    foreach ($empIds as $empId) {
        if ($empId !== $manager) {
            $updMgr->execute([$manager, $empId, $manager]);
        }
    }
}
$pdo->commit();

echo "Inserted $inserted employees, $loanCount loans, currency USD\n";
echo "Stations: " . implode(', ', array_keys($places)) . "\n";
echo "Login any SEED user with password 360tech\n";

function ensure(PDO $pdo, string $table, string $col, string $value, string $idCol): int
{
    $st = $pdo->prepare("SELECT `$idCol` FROM `$table` WHERE `$col` = ? LIMIT 1");
    $st->execute([$value]);
    $found = (int) ($st->fetchColumn() ?: 0);
    if ($found > 0) {
        return $found;
    }
    $pdo->prepare("INSERT INTO `$table` (`$col`) VALUES (?)")->execute([$value]);
    return (int) $pdo->lastInsertId();
}

/** Illustrative monthly USD withholding from simplified annual brackets. */
function taxMonthlyUsd(float $monthlyGross): float
{
    $annual = $monthlyGross * 12;
    $bands = [
        [0, 11600, 0.10],
        [11600, 47150, 0.12],
        [47150, 100525, 0.22],
        [100525, PHP_INT_MAX, 0.24],
    ];
    $tax = 0.0;
    foreach ($bands as [$from, $to, $rate]) {
        if ($annual > $from) {
            $slice = min($annual, $to) - $from;
            if ($slice > 0) {
                $tax += $slice * $rate;
            }
        }
    }
    return round($tax / 12, 2);
}
