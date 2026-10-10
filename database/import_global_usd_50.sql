-- HR360 global USD demo import. Select the company database first, then run this file.
-- Replaces only employee codes SEED-001 through SEED-050. Amounts are USD.
START TRANSACTION;
UPDATE company SET currency = 'USD' WHERE id = 1;
INSERT INTO station (name, office_type) SELECT 'New York', 'Branch' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM station WHERE name = 'New York');
INSERT INTO station (name, office_type) SELECT 'Chicago', 'Branch' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM station WHERE name = 'Chicago');
INSERT INTO station (name, office_type) SELECT 'Toronto', 'Branch' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM station WHERE name = 'Toronto');
INSERT INTO station (name, office_type) SELECT 'Vancouver', 'Branch' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM station WHERE name = 'Vancouver');
INSERT INTO station (name, office_type) SELECT 'Berlin', 'Branch' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM station WHERE name = 'Berlin');
INSERT INTO station (name, office_type) SELECT 'Munich', 'Branch' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM station WHERE name = 'Munich');
INSERT INTO station (name, office_type) SELECT 'Amsterdam', 'Branch' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM station WHERE name = 'Amsterdam');
INSERT INTO station (name, office_type) SELECT 'Paris', 'Branch' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM station WHERE name = 'Paris');
INSERT INTO station (name, office_type) SELECT 'Zurich', 'Branch' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM station WHERE name = 'Zurich');
INSERT INTO department (name) SELECT 'Human Resources' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM department WHERE name = 'Human Resources');
INSERT INTO department (name) SELECT 'Operations' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM department WHERE name = 'Operations');
INSERT INTO department (name) SELECT 'Finance' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM department WHERE name = 'Finance');
INSERT INTO department (name) SELECT 'Sales' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM department WHERE name = 'Sales');
INSERT INTO department (name) SELECT 'Technology' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM department WHERE name = 'Technology');
INSERT INTO designation (name) SELECT 'HR Officer' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM designation WHERE name = 'HR Officer');
INSERT INTO designation (name) SELECT 'Recruiter' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM designation WHERE name = 'Recruiter');
INSERT INTO designation (name) SELECT 'Operations Lead' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM designation WHERE name = 'Operations Lead');
INSERT INTO designation (name) SELECT 'Support Officer' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM designation WHERE name = 'Support Officer');
INSERT INTO designation (name) SELECT 'Accountant' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM designation WHERE name = 'Accountant');
INSERT INTO designation (name) SELECT 'Finance Manager' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM designation WHERE name = 'Finance Manager');
INSERT INTO designation (name) SELECT 'Sales Executive' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM designation WHERE name = 'Sales Executive');
INSERT INTO designation (name) SELECT 'Software Engineer' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM designation WHERE name = 'Software Engineer');
DELETE a FROM attendance a INNER JOIN employee e ON e.employee_id = a.employee_id WHERE e.employee_code LIKE 'SEED-%';
DELETE t FROM timesheet t INNER JOIN employee e ON e.employee_id = t.employee_id WHERE e.employee_code LIKE 'SEED-%';
DELETE d FROM process_salary_details d INNER JOIN process_salary p ON p.id = d.process_salary_id INNER JOIN employee e ON e.employee_id = p.employee_id WHERE e.employee_code LIKE 'SEED-%';
DELETE p FROM process_salary p INNER JOIN employee e ON e.employee_id = p.employee_id WHERE e.employee_code LIKE 'SEED-%';
DELETE d FROM define_salary_details d INNER JOIN define_salary s ON s.id = d.define_salary_id INNER JOIN employee e ON e.employee_id = s.employee_id WHERE e.employee_code LIKE 'SEED-%';
DELETE s FROM define_salary s INNER JOIN employee e ON e.employee_id = s.employee_id WHERE e.employee_code LIKE 'SEED-%';
DELETE l FROM hr_loan l INNER JOIN employee e ON e.employee_id = l.employee_id WHERE e.employee_code LIKE 'SEED-%';
DELETE a FROM loan_application a INNER JOIN employee e ON e.employee_id = a.employee WHERE e.employee_code LIKE 'SEED-%';
DELETE FROM employee WHERE employee_code LIKE 'SEED-%';
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'James Carter', 'james.carter1', 'james.carter1@hr360.demo', '+1555010001', 'P-SEED-001', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Software Engineer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Technology' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'New York' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-001', '2024-03-01', 0, '1991-02-15', 'Single', 'New York, USA', 'Monthly', 0, 0, 'James Carter', 'USD00100001', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-001');
SET @st := (SELECT station_id FROM station WHERE name = 'New York' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 9350.00, 1402.50, 2000.81, 8751.69, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 9350.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1402.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 2000.81 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 9350.00, 1402.50, 2000.81, 8751.69, 2000.81, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 9350.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1402.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 2000.81 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for New York', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Emily Brooks', 'emily.brooks2', 'emily.brooks2@hr360.demo', '+1555010002', 'P-SEED-002', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'HR Officer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Human Resources' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'New York' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-002', '2024-03-01', 0, '1992-03-15', 'Single', 'New York, USA', 'Monthly', 0, 0, 'Emily Brooks', 'USD00100002', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-002');
SET @st := (SELECT station_id FROM station WHERE name = 'New York' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 6100.00, 915.00, 1131.05, 5883.95, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 6100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 915.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1131.05 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 6100.00, 915.00, 1131.05, 5883.95, 1131.05, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 6100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 915.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1131.05 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for New York', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Daniel Hayes', 'daniel.hayes3', 'daniel.hayes3@hr360.demo', '+1555010003', 'P-SEED-003', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Accountant' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Finance' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'New York' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-003', '2024-03-01', 0, '1993-04-15', 'Single', 'New York, USA', 'Monthly', 0, 0, 'Daniel Hayes', 'USD00100003', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-003');
SET @st := (SELECT station_id FROM station WHERE name = 'New York' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 7250.00, 1087.50, 1672.00, 6665.50, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 7250.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1087.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1422.00 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 7250.00, 1087.50, 1672.00, 6665.50, 1422.00, 0, 0, 0, 0, 0, 0, 0, 250.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 7250.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1087.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1422.00 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks) VALUES (@emp, 3000.00, 250.00, 250.00, '2026-09-01', 1, 'USD staff loan recovered on the September payslip');
INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by) VALUES (@emp, 3000.00, 'Personal loan', '2026-09-01', '2027-08-31', 'approved', 1);
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for New York', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Olivia Bennett', 'olivia.bennett4', 'olivia.bennett4@hr360.demo', '+1555010004', 'P-SEED-004', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Sales Executive' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Sales' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'New York' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-004', '2024-03-01', 0, '1994-05-15', 'Married', 'New York, USA', 'Monthly', 0, 0, 'Olivia Bennett', 'USD00100004', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-004');
SET @st := (SELECT station_id FROM station WHERE name = 'New York' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 5800.00, 870.00, 1055.15, 5614.85, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 5800.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 870.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1055.15 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 5800.00, 870.00, 1055.15, 5614.85, 1055.15, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 5800.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 870.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1055.15 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for New York', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Noah Parker', 'noah.parker5', 'noah.parker5@hr360.demo', '+1555010005', 'P-SEED-005', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Support Officer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Operations' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'New York' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-005', '2024-03-01', 0, '1995-06-15', 'Single', 'New York, USA', 'Monthly', 0, 0, 'Noah Parker', 'USD00100005', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-005');
SET @st := (SELECT station_id FROM station WHERE name = 'New York' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 4200.00, 630.00, 650.35, 4179.65, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 4200.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 630.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 650.35 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 4200.00, 630.00, 650.35, 4179.65, 650.35, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 4200.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 630.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 650.35 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for New York', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Sophia Reed', 'sophia.reed6', 'sophia.reed6@hr360.demo', '+1555010006', 'P-SEED-006', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Finance Manager' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Finance' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'New York' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-006', '2024-03-01', 0, '1996-07-15', 'Single', 'New York, USA', 'Monthly', 0, 0, 'Sophia Reed', 'USD00100006', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-006');
SET @st := (SELECT station_id FROM station WHERE name = 'New York' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 12950.00, 1942.50, 3394.41, 11498.09, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 12950.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1942.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 2994.41 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 12950.00, 1942.50, 3394.41, 11498.09, 2994.41, 0, 0, 0, 0, 0, 0, 0, 400.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 12950.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1942.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 2994.41 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 400.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 400.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks) VALUES (@emp, 4800.00, 400.00, 400.00, '2026-09-01', 1, 'USD staff loan recovered on the September payslip');
INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by) VALUES (@emp, 4800.00, 'Personal loan', '2026-09-01', '2027-08-31', 'approved', 1);
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for New York', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Liam Foster', 'liam.foster7', 'liam.foster7@hr360.demo', '+1555010007', 'P-SEED-007', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Operations Lead' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Operations' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Chicago' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-007', '2024-03-01', 0, '1997-08-15', 'Single', 'Chicago, USA', 'Monthly', 0, 0, 'Liam Foster', 'USD00100007', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-007');
SET @st := (SELECT station_id FROM station WHERE name = 'Chicago' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 10800.00, 1620.00, 2401.01, 10018.99, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 10800.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1620.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 2401.01 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 10800.00, 1620.00, 2401.01, 10018.99, 2401.01, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 10800.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1620.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 2401.01 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:20:00', '2026-09-03 17:30:00', 510, 20, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Chicago', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Ava Collins', 'ava.collins8', 'ava.collins8@hr360.demo', '+1555010008', 'P-SEED-008', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Software Engineer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Technology' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Chicago' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-008', '2024-03-01', 0, '1990-09-15', 'Married', 'Chicago, USA', 'Monthly', 0, 0, 'Ava Collins', 'USD00100008', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-008');
SET @st := (SELECT station_id FROM station WHERE name = 'Chicago' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 9650.00, 1447.50, 2083.61, 9013.89, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 9650.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1447.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 2083.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 9650.00, 1447.50, 2083.61, 9013.89, 2083.61, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 9650.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1447.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 2083.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Chicago', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Ethan Murphy', 'ethan.murphy9', 'ethan.murphy9@hr360.demo', '+1555010009', 'P-SEED-009', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Recruiter' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Human Resources' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Chicago' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-009', '2024-03-01', 0, '1991-01-15', 'Single', 'Chicago, USA', 'Monthly', 0, 0, 'Ethan Murphy', 'USD00100009', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-009');
SET @st := (SELECT station_id FROM station WHERE name = 'Chicago' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 6700.00, 1005.00, 1532.85, 6172.15, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 6700.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1005.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1282.85 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 6700.00, 1005.00, 1532.85, 6172.15, 1282.85, 0, 0, 0, 0, 0, 0, 0, 250.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 6700.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1005.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1282.85 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks) VALUES (@emp, 3000.00, 250.00, 250.00, '2026-09-01', 1, 'USD staff loan recovered on the September payslip');
INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by) VALUES (@emp, 3000.00, 'Personal loan', '2026-09-01', '2027-08-31', 'approved', 1);
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Chicago', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Mia Stewart', 'mia.stewart10', 'mia.stewart10@hr360.demo', '+1555010010', 'P-SEED-010', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Accountant' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Finance' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Chicago' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-010', '2024-03-01', 0, '1992-02-15', 'Single', 'Chicago, USA', 'Monthly', 0, 0, 'Mia Stewart', 'USD00100010', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-010');
SET @st := (SELECT station_id FROM station WHERE name = 'Chicago' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 6800.00, 1020.00, 1308.15, 6511.85, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 6800.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1020.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1308.15 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 6800.00, 1020.00, 1308.15, 6511.85, 1308.15, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 6800.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1020.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1308.15 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Chicago', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Lucas Ward', 'lucas.ward11', 'lucas.ward11@hr360.demo', '+1555010011', 'P-SEED-011', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Sales Executive' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Sales' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Chicago' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-011', '2024-03-01', 0, '1993-03-15', 'Single', 'Chicago, USA', 'Monthly', 0, 0, 'Lucas Ward', 'USD00100011', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-011');
SET @st := (SELECT station_id FROM station WHERE name = 'Chicago' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 5350.00, 802.50, 941.30, 5211.20, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 5350.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 802.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 941.30 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 5350.00, 802.50, 941.30, 5211.20, 941.30, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 5350.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 802.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 941.30 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Chicago', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Grace Powell', 'grace.powell12', 'grace.powell12@hr360.demo', '+1555010012', 'P-SEED-012', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'HR Officer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Human Resources' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Chicago' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-012', '2024-03-01', 0, '1994-04-15', 'Married', 'Chicago, USA', 'Monthly', 0, 0, 'Grace Powell', 'USD00100012', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-012');
SET @st := (SELECT station_id FROM station WHERE name = 'Chicago' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 6100.00, 915.00, 1531.05, 5483.95, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 6100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 915.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1131.05 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 6100.00, 915.00, 1531.05, 5483.95, 1131.05, 0, 0, 0, 0, 0, 0, 0, 400.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 6100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 915.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1131.05 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 400.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 400.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks) VALUES (@emp, 4800.00, 400.00, 400.00, '2026-09-01', 1, 'USD staff loan recovered on the September payslip');
INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by) VALUES (@emp, 4800.00, 'Personal loan', '2026-09-01', '2027-08-31', 'approved', 1);
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Chicago', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Henry Campbell', 'henry.campbell13', 'henry.campbell13@hr360.demo', '+1555010013', 'P-SEED-013', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Software Engineer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Technology' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Toronto' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-013', '2024-03-01', 0, '1995-05-15', 'Single', 'Toronto, Canada', 'Monthly', 0, 0, 'Henry Campbell', 'USD00100013', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-013');
SET @st := (SELECT station_id FROM station WHERE name = 'Toronto' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 9650.00, 1447.50, 2083.61, 9013.89, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 9650.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1447.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 2083.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 9650.00, 1447.50, 2083.61, 9013.89, 2083.61, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 9650.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1447.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 2083.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Toronto', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Chloe Mitchell', 'chloe.mitchell14', 'chloe.mitchell14@hr360.demo', '+1555010014', 'P-SEED-014', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Finance Manager' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Finance' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Toronto' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-014', '2024-03-01', 0, '1996-06-15', 'Single', 'Toronto, Canada', 'Monthly', 0, 0, 'Chloe Mitchell', 'USD00100014', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-014');
SET @st := (SELECT station_id FROM station WHERE name = 'Toronto' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 13400.00, 2010.00, 3118.61, 12291.39, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 13400.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 2010.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 3118.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 13400.00, 2010.00, 3118.61, 12291.39, 3118.61, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 13400.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 2010.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 3118.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:20:00', '2026-09-03 17:30:00', 510, 20, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Toronto', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Owen Russell', 'owen.russell15', 'owen.russell15@hr360.demo', '+1555010015', 'P-SEED-015', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Support Officer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Operations' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Toronto' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-015', '2024-03-01', 0, '1997-07-15', 'Single', 'Toronto, Canada', 'Monthly', 0, 0, 'Owen Russell', 'USD00100015', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-015');
SET @st := (SELECT station_id FROM station WHERE name = 'Toronto' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 4200.00, 630.00, 900.35, 3929.65, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 4200.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 630.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 650.35 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 4200.00, 630.00, 900.35, 3929.65, 650.35, 0, 0, 0, 0, 0, 0, 0, 250.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 4200.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 630.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 650.35 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks) VALUES (@emp, 3000.00, 250.00, 250.00, '2026-09-01', 1, 'USD staff loan recovered on the September payslip');
INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by) VALUES (@emp, 3000.00, 'Personal loan', '2026-09-01', '2027-08-31', 'approved', 1);
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Toronto', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Emma Hughes', 'emma.hughes16', 'emma.hughes16@hr360.demo', '+1555010016', 'P-SEED-016', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Operations Lead' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Operations' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Toronto' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-016', '2024-03-01', 0, '1990-08-15', 'Married', 'Toronto, Canada', 'Monthly', 0, 0, 'Emma Hughes', 'USD00100016', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-016');
SET @st := (SELECT station_id FROM station WHERE name = 'Toronto' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 10650.00, 1597.50, 2359.61, 9887.89, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 10650.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1597.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 2359.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 10650.00, 1597.50, 2359.61, 9887.89, 2359.61, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 10650.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1597.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 2359.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Toronto', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Jack Sullivan', 'jack.sullivan17', 'jack.sullivan17@hr360.demo', '+1555010017', 'P-SEED-017', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Accountant' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Finance' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Toronto' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-017', '2024-03-01', 0, '1991-09-15', 'Single', 'Toronto, Canada', 'Monthly', 0, 0, 'Jack Sullivan', 'USD00100017', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-017');
SET @st := (SELECT station_id FROM station WHERE name = 'Toronto' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 7100.00, 1065.00, 1384.05, 6780.95, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 7100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1065.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1384.05 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 7100.00, 1065.00, 1384.05, 6780.95, 1384.05, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 7100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1065.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1384.05 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Toronto', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Lily Barnes', 'lily.barnes18', 'lily.barnes18@hr360.demo', '+1555010018', 'P-SEED-018', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Sales Executive' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Sales' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Toronto' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-018', '2024-03-01', 0, '1992-01-15', 'Single', 'Toronto, Canada', 'Monthly', 0, 0, 'Lily Barnes', 'USD00100018', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-018');
SET @st := (SELECT station_id FROM station WHERE name = 'Toronto' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 5650.00, 847.50, 1417.20, 5080.30, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 5650.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 847.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1017.20 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 5650.00, 847.50, 1417.20, 5080.30, 1017.20, 0, 0, 0, 0, 0, 0, 0, 400.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 5650.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 847.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1017.20 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 400.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 400.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks) VALUES (@emp, 4800.00, 400.00, 400.00, '2026-09-01', 1, 'USD staff loan recovered on the September payslip');
INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by) VALUES (@emp, 4800.00, 'Personal loan', '2026-09-01', '2027-08-31', 'approved', 1);
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Toronto', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Benjamin Cooper', 'benjamin.cooper19', 'benjamin.cooper19@hr360.demo', '+1555010019', 'P-SEED-019', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Software Engineer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Technology' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Vancouver' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-019', '2024-03-01', 0, '1993-02-15', 'Single', 'Vancouver, Canada', 'Monthly', 0, 0, 'Benjamin Cooper', 'USD00100019', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-019');
SET @st := (SELECT station_id FROM station WHERE name = 'Vancouver' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 9800.00, 1470.00, 2125.01, 9144.99, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 9800.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1470.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 2125.01 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 9800.00, 1470.00, 2125.01, 9144.99, 2125.01, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 9800.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1470.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 2125.01 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Vancouver', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Hannah Price', 'hannah.price20', 'hannah.price20@hr360.demo', '+1555010020', 'P-SEED-020', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'HR Officer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Human Resources' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Vancouver' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-020', '2024-03-01', 0, '1994-03-15', 'Married', 'Vancouver, Canada', 'Monthly', 0, 0, 'Hannah Price', 'USD00100020', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-020');
SET @st := (SELECT station_id FROM station WHERE name = 'Vancouver' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 5800.00, 870.00, 1055.15, 5614.85, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 5800.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 870.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1055.15 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 5800.00, 870.00, 1055.15, 5614.85, 1055.15, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 5800.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 870.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1055.15 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Vancouver', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Samuel Long', 'samuel.long21', 'samuel.long21@hr360.demo', '+1555010021', 'P-SEED-021', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Recruiter' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Human Resources' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Vancouver' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-021', '2024-03-01', 0, '1995-04-15', 'Single', 'Vancouver, Canada', 'Monthly', 0, 0, 'Samuel Long', 'USD00100021', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-021');
SET @st := (SELECT station_id FROM station WHERE name = 'Vancouver' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 6250.00, 937.50, 1419.00, 5768.50, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 6250.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 937.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1169.00 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 6250.00, 937.50, 1419.00, 5768.50, 1169.00, 0, 0, 0, 0, 0, 0, 0, 250.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 6250.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 937.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1169.00 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks) VALUES (@emp, 3000.00, 250.00, 250.00, '2026-09-01', 1, 'USD staff loan recovered on the September payslip');
INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by) VALUES (@emp, 3000.00, 'Personal loan', '2026-09-01', '2027-08-31', 'approved', 1);
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:20:00', '2026-09-03 17:30:00', 510, 20, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Vancouver', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Natalie Gray', 'natalie.gray22', 'natalie.gray22@hr360.demo', '+1555010022', 'P-SEED-022', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Accountant' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Finance' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Vancouver' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-022', '2024-03-01', 0, '1996-05-15', 'Single', 'Vancouver, Canada', 'Monthly', 0, 0, 'Natalie Gray', 'USD00100022', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-022');
SET @st := (SELECT station_id FROM station WHERE name = 'Vancouver' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 7100.00, 1065.00, 1384.05, 6780.95, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 7100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1065.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1384.05 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 7100.00, 1065.00, 1384.05, 6780.95, 1384.05, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 7100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1065.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1384.05 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Vancouver', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Andrew Watson', 'andrew.watson23', 'andrew.watson23@hr360.demo', '+1555010023', 'P-SEED-023', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Operations Lead' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Operations' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Vancouver' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-023', '2024-03-01', 0, '1997-06-15', 'Single', 'Vancouver, Canada', 'Monthly', 0, 0, 'Andrew Watson', 'USD00100023', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-023');
SET @st := (SELECT station_id FROM station WHERE name = 'Vancouver' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 10950.00, 1642.50, 2442.41, 10150.09, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 10950.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1642.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 2442.41 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 10950.00, 1642.50, 2442.41, 10150.09, 2442.41, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 10950.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1642.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 2442.41 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Vancouver', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Victoria Ross', 'victoria.ross24', 'victoria.ross24@hr360.demo', '+1555010024', 'P-SEED-024', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Finance Manager' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Finance' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Vancouver' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-024', '2024-03-01', 0, '1990-07-15', 'Married', 'Vancouver, Canada', 'Monthly', 0, 0, 'Victoria Ross', 'USD00100024', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-024');
SET @st := (SELECT station_id FROM station WHERE name = 'Vancouver' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 13400.00, 2010.00, 3518.61, 11891.39, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 13400.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 2010.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 3118.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 13400.00, 2010.00, 3518.61, 11891.39, 3118.61, 0, 0, 0, 0, 0, 0, 0, 400.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 13400.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 2010.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 3118.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 400.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 400.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks) VALUES (@emp, 4800.00, 400.00, 400.00, '2026-09-01', 1, 'USD staff loan recovered on the September payslip');
INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by) VALUES (@emp, 4800.00, 'Personal loan', '2026-09-01', '2027-08-31', 'approved', 1);
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Vancouver', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Alexander Schmidt', 'alexander.schmidt25', 'alexander.schmidt25@hr360.demo', '+49555010025', 'P-SEED-025', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Software Engineer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Technology' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Berlin' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-025', '2024-03-01', 0, '1991-08-15', 'Single', 'Berlin, Germany', 'Monthly', 0, 0, 'Alexander Schmidt', 'USD00100025', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-025');
SET @st := (SELECT station_id FROM station WHERE name = 'Berlin' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 9200.00, 1380.00, 1959.41, 8620.59, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 9200.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1380.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1959.41 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 9200.00, 1380.00, 1959.41, 8620.59, 1959.41, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 9200.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1380.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1959.41 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Berlin', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Clara Hoffman', 'clara.hoffman26', 'clara.hoffman26@hr360.demo', '+49555010026', 'P-SEED-026', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'HR Officer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Human Resources' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Berlin' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-026', '2024-03-01', 0, '1992-09-15', 'Single', 'Berlin, Germany', 'Monthly', 0, 0, 'Clara Hoffman', 'USD00100026', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-026');
SET @st := (SELECT station_id FROM station WHERE name = 'Berlin' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 5950.00, 892.50, 1093.10, 5749.40, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 5950.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 892.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1093.10 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 5950.00, 892.50, 1093.10, 5749.40, 1093.10, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 5950.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 892.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1093.10 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Berlin', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Felix Weber', 'felix.weber27', 'felix.weber27@hr360.demo', '+49555010027', 'P-SEED-027', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Accountant' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Finance' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Berlin' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-027', '2024-03-01', 0, '1993-01-15', 'Single', 'Berlin, Germany', 'Monthly', 0, 0, 'Felix Weber', 'USD00100027', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-027');
SET @st := (SELECT station_id FROM station WHERE name = 'Berlin' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 7100.00, 1065.00, 1634.05, 6530.95, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 7100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1065.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1384.05 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 7100.00, 1065.00, 1634.05, 6530.95, 1384.05, 0, 0, 0, 0, 0, 0, 0, 250.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 7100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1065.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1384.05 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks) VALUES (@emp, 3000.00, 250.00, 250.00, '2026-09-01', 1, 'USD staff loan recovered on the September payslip');
INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by) VALUES (@emp, 3000.00, 'Personal loan', '2026-09-01', '2027-08-31', 'approved', 1);
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Berlin', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Anna Keller', 'anna.keller28', 'anna.keller28@hr360.demo', '+49555010028', 'P-SEED-028', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Sales Executive' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Sales' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Berlin' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-028', '2024-03-01', 0, '1994-02-15', 'Married', 'Berlin, Germany', 'Monthly', 0, 0, 'Anna Keller', 'USD00100028', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-028');
SET @st := (SELECT station_id FROM station WHERE name = 'Berlin' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 5650.00, 847.50, 1017.20, 5480.30, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 5650.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 847.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1017.20 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 5650.00, 847.50, 1017.20, 5480.30, 1017.20, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 5650.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 847.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1017.20 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:20:00', '2026-09-03 17:30:00', 510, 20, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Berlin', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Jonas Bauer', 'jonas.bauer29', 'jonas.bauer29@hr360.demo', '+49555010029', 'P-SEED-029', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Support Officer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Operations' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Berlin' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-029', '2024-03-01', 0, '1995-03-15', 'Single', 'Berlin, Germany', 'Monthly', 0, 0, 'Jonas Bauer', 'USD00100029', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-029');
SET @st := (SELECT station_id FROM station WHERE name = 'Berlin' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 4800.00, 720.00, 802.15, 4717.85, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 4800.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 720.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 802.15 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 4800.00, 720.00, 802.15, 4717.85, 802.15, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 4800.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 720.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 802.15 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Berlin', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Laura Fischer', 'laura.fischer30', 'laura.fischer30@hr360.demo', '+49555010030', 'P-SEED-030', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Operations Lead' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Operations' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Berlin' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-030', '2024-03-01', 0, '1996-04-15', 'Single', 'Berlin, Germany', 'Monthly', 0, 0, 'Laura Fischer', 'USD00100030', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-030');
SET @st := (SELECT station_id FROM station WHERE name = 'Berlin' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 10500.00, 1575.00, 2718.21, 9356.79, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 10500.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1575.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 2318.21 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 10500.00, 1575.00, 2718.21, 9356.79, 2318.21, 0, 0, 0, 0, 0, 0, 0, 400.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 10500.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1575.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 2318.21 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 400.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 400.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks) VALUES (@emp, 4800.00, 400.00, 400.00, '2026-09-01', 1, 'USD staff loan recovered on the September payslip');
INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by) VALUES (@emp, 4800.00, 'Personal loan', '2026-09-01', '2027-08-31', 'approved', 1);
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Berlin', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Max Wagner', 'max.wagner31', 'max.wagner31@hr360.demo', '+49555010031', 'P-SEED-031', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Software Engineer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Technology' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Munich' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-031', '2024-03-01', 0, '1997-05-15', 'Single', 'Munich, Germany', 'Monthly', 0, 0, 'Max Wagner', 'USD00100031', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-031');
SET @st := (SELECT station_id FROM station WHERE name = 'Munich' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 9350.00, 1402.50, 2000.81, 8751.69, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 9350.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1402.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 2000.81 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 9350.00, 1402.50, 2000.81, 8751.69, 2000.81, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 9350.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1402.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 2000.81 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Munich', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Sophie Richter', 'sophie.richter32', 'sophie.richter32@hr360.demo', '+49555010032', 'P-SEED-032', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Finance Manager' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Finance' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Munich' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-032', '2024-03-01', 0, '1990-06-15', 'Married', 'Munich, Germany', 'Monthly', 0, 0, 'Sophie Richter', 'USD00100032', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-032');
SET @st := (SELECT station_id FROM station WHERE name = 'Munich' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 13100.00, 1965.00, 3035.81, 12029.19, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 13100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1965.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 3035.81 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 13100.00, 1965.00, 3035.81, 12029.19, 3035.81, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 13100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1965.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 3035.81 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Munich', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Leon Kruger', 'leon.kruger33', 'leon.kruger33@hr360.demo', '+49555010033', 'P-SEED-033', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Recruiter' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Human Resources' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Munich' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-033', '2024-03-01', 0, '1991-07-15', 'Single', 'Munich, Germany', 'Monthly', 0, 0, 'Leon Kruger', 'USD00100033', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-033');
SET @st := (SELECT station_id FROM station WHERE name = 'Munich' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 6550.00, 982.50, 1494.90, 6037.60, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 6550.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 982.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1244.90 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 6550.00, 982.50, 1494.90, 6037.60, 1244.90, 0, 0, 0, 0, 0, 0, 0, 250.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 6550.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 982.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1244.90 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks) VALUES (@emp, 3000.00, 250.00, 250.00, '2026-09-01', 1, 'USD staff loan recovered on the September payslip');
INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by) VALUES (@emp, 3000.00, 'Personal loan', '2026-09-01', '2027-08-31', 'approved', 1);
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Munich', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Marie Neumann', 'marie.neumann34', 'marie.neumann34@hr360.demo', '+49555010034', 'P-SEED-034', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Accountant' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Finance' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Munich' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-034', '2024-03-01', 0, '1992-08-15', 'Single', 'Munich, Germany', 'Monthly', 0, 0, 'Marie Neumann', 'USD00100034', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-034');
SET @st := (SELECT station_id FROM station WHERE name = 'Munich' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 7400.00, 1110.00, 1462.61, 7047.39, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 7400.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1110.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1462.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 7400.00, 1110.00, 1462.61, 7047.39, 1462.61, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 7400.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1110.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1462.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Munich', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Paul Schwarz', 'paul.schwarz35', 'paul.schwarz35@hr360.demo', '+49555010035', 'P-SEED-035', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Sales Executive' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Sales' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Munich' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-035', '2024-03-01', 0, '1993-09-15', 'Single', 'Munich, Germany', 'Monthly', 0, 0, 'Paul Schwarz', 'USD00100035', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-035');
SET @st := (SELECT station_id FROM station WHERE name = 'Munich' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 5200.00, 780.00, 903.35, 5076.65, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 5200.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 780.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 903.35 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 5200.00, 780.00, 903.35, 5076.65, 903.35, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 5200.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 780.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 903.35 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:20:00', '2026-09-03 17:30:00', 510, 20, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Munich', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Eva Wolf', 'eva.wolf36', 'eva.wolf36@hr360.demo', '+49555010036', 'P-SEED-036', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'HR Officer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Human Resources' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Munich' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-036', '2024-03-01', 0, '1994-01-15', 'Married', 'Munich, Germany', 'Monthly', 0, 0, 'Eva Wolf', 'USD00100036', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-036');
SET @st := (SELECT station_id FROM station WHERE name = 'Munich' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 5950.00, 892.50, 1493.10, 5349.40, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 5950.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 892.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1093.10 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 5950.00, 892.50, 1493.10, 5349.40, 1093.10, 0, 0, 0, 0, 0, 0, 0, 400.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 5950.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 892.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1093.10 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 400.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 400.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks) VALUES (@emp, 4800.00, 400.00, 400.00, '2026-09-01', 1, 'USD staff loan recovered on the September payslip');
INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by) VALUES (@emp, 4800.00, 'Personal loan', '2026-09-01', '2027-08-31', 'approved', 1);
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Munich', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Thomas de Vries', 'thomas.devries37', 'thomas.devries37@hr360.demo', '+31555010037', 'P-SEED-037', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Software Engineer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Technology' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Amsterdam' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-037', '2024-03-01', 0, '1995-02-15', 'Single', 'Amsterdam, Netherlands', 'Monthly', 0, 0, 'Thomas de Vries', 'USD00100037', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-037');
SET @st := (SELECT station_id FROM station WHERE name = 'Amsterdam' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 9500.00, 1425.00, 2042.21, 8882.79, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 9500.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1425.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 2042.21 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 9500.00, 1425.00, 2042.21, 8882.79, 2042.21, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 9500.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1425.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 2042.21 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Amsterdam', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Sophie Bakker', 'sophie.bakker38', 'sophie.bakker38@hr360.demo', '+31555010038', 'P-SEED-038', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Operations Lead' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Operations' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Amsterdam' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-038', '2024-03-01', 0, '1996-03-15', 'Single', 'Amsterdam, Netherlands', 'Monthly', 0, 0, 'Sophie Bakker', 'USD00100038', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-038');
SET @st := (SELECT station_id FROM station WHERE name = 'Amsterdam' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 10950.00, 1642.50, 2442.41, 10150.09, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 10950.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1642.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 2442.41 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 10950.00, 1642.50, 2442.41, 10150.09, 2442.41, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 10950.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1642.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 2442.41 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Amsterdam', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Julian Visser', 'julian.visser39', 'julian.visser39@hr360.demo', '+31555010039', 'P-SEED-039', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Accountant' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Finance' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Amsterdam' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-039', '2024-03-01', 0, '1997-04-15', 'Single', 'Amsterdam, Netherlands', 'Monthly', 0, 0, 'Julian Visser', 'USD00100039', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-039');
SET @st := (SELECT station_id FROM station WHERE name = 'Amsterdam' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 7400.00, 1110.00, 1712.61, 6797.39, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 7400.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1110.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1462.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 7400.00, 1110.00, 1712.61, 6797.39, 1462.61, 0, 0, 0, 0, 0, 0, 0, 250.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 7400.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1110.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1462.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks) VALUES (@emp, 3000.00, 250.00, 250.00, '2026-09-01', 1, 'USD staff loan recovered on the September payslip');
INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by) VALUES (@emp, 3000.00, 'Personal loan', '2026-09-01', '2027-08-31', 'approved', 1);
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Amsterdam', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Emma Jansen', 'emma.jansen40', 'emma.jansen40@hr360.demo', '+31555010040', 'P-SEED-040', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Sales Executive' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Sales' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Amsterdam' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-040', '2024-03-01', 0, '1990-05-15', 'Married', 'Amsterdam, Netherlands', 'Monthly', 0, 0, 'Emma Jansen', 'USD00100040', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-040');
SET @st := (SELECT station_id FROM station WHERE name = 'Amsterdam' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 5200.00, 780.00, 903.35, 5076.65, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 5200.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 780.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 903.35 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 5200.00, 780.00, 903.35, 5076.65, 903.35, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 5200.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 780.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 903.35 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Amsterdam', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Hugo Moreau', 'hugo.moreau41', 'hugo.moreau41@hr360.demo', '+33555010041', 'P-SEED-041', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Software Engineer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Technology' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Paris' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-041', '2024-03-01', 0, '1991-06-15', 'Single', 'Paris, France', 'Monthly', 0, 0, 'Hugo Moreau', 'USD00100041', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-041');
SET @st := (SELECT station_id FROM station WHERE name = 'Paris' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 9350.00, 1402.50, 2000.81, 8751.69, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 9350.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1402.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 2000.81 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 9350.00, 1402.50, 2000.81, 8751.69, 2000.81, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 9350.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1402.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 2000.81 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Paris', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Camille Laurent', 'camille.laurent42', 'camille.laurent42@hr360.demo', '+33555010042', 'P-SEED-042', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'HR Officer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Human Resources' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Paris' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-042', '2024-03-01', 0, '1992-07-15', 'Single', 'Paris, France', 'Monthly', 0, 0, 'Camille Laurent', 'USD00100042', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-042');
SET @st := (SELECT station_id FROM station WHERE name = 'Paris' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 6100.00, 915.00, 1531.05, 5483.95, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 6100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 915.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1131.05 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 6100.00, 915.00, 1531.05, 5483.95, 1131.05, 0, 0, 0, 0, 0, 0, 0, 400.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 6100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 915.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1131.05 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 400.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 400.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks) VALUES (@emp, 4800.00, 400.00, 400.00, '2026-09-01', 1, 'USD staff loan recovered on the September payslip');
INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by) VALUES (@emp, 4800.00, 'Personal loan', '2026-09-01', '2027-08-31', 'approved', 1);
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:20:00', '2026-09-03 17:30:00', 510, 20, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Paris', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Antoine Bernard', 'antoine.bernard43', 'antoine.bernard43@hr360.demo', '+33555010043', 'P-SEED-043', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Finance Manager' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Finance' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Paris' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-043', '2024-03-01', 0, '1993-08-15', 'Single', 'Paris, France', 'Monthly', 0, 0, 'Antoine Bernard', 'USD00100043', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-043');
SET @st := (SELECT station_id FROM station WHERE name = 'Paris' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 13250.00, 1987.50, 3077.21, 12160.29, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 13250.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1987.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 3077.21 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 13250.00, 1987.50, 3077.21, 12160.29, 3077.21, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 13250.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1987.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 3077.21 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Paris', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Elise Martin', 'elise.martin44', 'elise.martin44@hr360.demo', '+33555010044', 'P-SEED-044', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Accountant' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Finance' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Paris' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-044', '2024-03-01', 0, '1994-09-15', 'Married', 'Paris, France', 'Monthly', 0, 0, 'Elise Martin', 'USD00100044', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-044');
SET @st := (SELECT station_id FROM station WHERE name = 'Paris' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 7400.00, 1110.00, 1462.61, 7047.39, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 7400.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1110.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1462.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 7400.00, 1110.00, 1462.61, 7047.39, 1462.61, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 7400.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1110.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1462.61 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Paris', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Louis Petit', 'louis.petit45', 'louis.petit45@hr360.demo', '+33555010045', 'P-SEED-045', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Support Officer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Operations' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Paris' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-045', '2024-03-01', 0, '1995-01-15', 'Single', 'Paris, France', 'Monthly', 0, 0, 'Louis Petit', 'USD00100045', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-045');
SET @st := (SELECT station_id FROM station WHERE name = 'Paris' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 4200.00, 630.00, 900.35, 3929.65, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 4200.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 630.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 650.35 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 4200.00, 630.00, 900.35, 3929.65, 650.35, 0, 0, 0, 0, 0, 0, 0, 250.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 4200.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 630.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 650.35 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 250.00 FROM hr_payroll_item WHERE code = 'LOAN';
INSERT INTO hr_loan (employee_id, principal, recovered_amount, installment, start_date, status, remarks) VALUES (@emp, 3000.00, 250.00, 250.00, '2026-09-01', 1, 'USD staff loan recovered on the September payslip');
INSERT INTO loan_application (employee, loan_amount, purpose_of_loan, start_date, end_date, status, created_by) VALUES (@emp, 3000.00, 'Personal loan', '2026-09-01', '2027-08-31', 'approved', 1);
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Paris', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Nina Keller', 'nina.keller46', 'nina.keller46@hr360.demo', '+41555010046', 'P-SEED-046', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Software Engineer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Technology' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Zurich' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-046', '2024-03-01', 0, '1996-02-15', 'Single', 'Zurich, Switzerland', 'Monthly', 0, 0, 'Nina Keller', 'USD00100046', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-046');
SET @st := (SELECT station_id FROM station WHERE name = 'Zurich' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 9350.00, 1402.50, 2000.81, 8751.69, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 9350.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1402.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 2000.81 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 9350.00, 1402.50, 2000.81, 8751.69, 2000.81, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 9350.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1402.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 2000.81 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Zurich', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'David Meier', 'david.meier47', 'david.meier47@hr360.demo', '+41555010047', 'P-SEED-047', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Finance Manager' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Finance' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Zurich' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-047', '2024-03-01', 0, '1997-03-15', 'Single', 'Zurich, Switzerland', 'Monthly', 0, 0, 'David Meier', 'USD00100047', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-047');
SET @st := (SELECT station_id FROM station WHERE name = 'Zurich' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 13100.00, 1965.00, 3035.81, 12029.19, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 13100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1965.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 3035.81 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 13100.00, 1965.00, 3035.81, 12029.19, 3035.81, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 13100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1965.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 3035.81 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Zurich', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Lena Brunner', 'lena.brunner48', 'lena.brunner48@hr360.demo', '+41555010048', 'P-SEED-048', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'HR Officer' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Human Resources' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Zurich' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-048', '2024-03-01', 0, '1990-04-15', 'Married', 'Zurich, Switzerland', 'Monthly', 0, 0, 'Lena Brunner', 'USD00100048', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-048');
SET @st := (SELECT station_id FROM station WHERE name = 'Zurich' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 6250.00, 937.50, 1169.00, 6018.50, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 6250.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 937.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1169.00 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 6250.00, 937.50, 1169.00, 6018.50, 1169.00, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 6250.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 937.50, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1169.00 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Zurich', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Marco Steiner', 'marco.steiner49', 'marco.steiner49@hr360.demo', '+41555010049', 'P-SEED-049', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 1,
 (SELECT designation_id FROM designation WHERE name = 'Operations Lead' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Operations' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Zurich' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-049', '2024-03-01', 0, '1991-05-15', 'Single', 'Zurich, Switzerland', 'Monthly', 0, 0, 'Marco Steiner', 'USD00100049', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-049');
SET @st := (SELECT station_id FROM station WHERE name = 'Zurich' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 11100.00, 1665.00, 2483.81, 10281.19, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 11100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1665.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 2483.81 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 11100.00, 1665.00, 2483.81, 10281.19, 2483.81, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 11100.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1665.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 2483.81 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:20:00', '2026-09-03 17:30:00', 510, 20, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Zurich', 1);
INSERT INTO employee (name, user_name, email, phone, cnic, password, status, gender, designation, department, station, project, line_manager, employee_code, joining_date, is_first_login, date_of_birth, marital_status, address, payroll_type, eobi, sessi, bnk_title, bnk_number, bnk_code)
SELECT 'Sara Frei', 'sara.frei50', 'sara.frei50@hr360.demo', '+41555010050', 'P-SEED-050', '$2y$10$mpjfZFtK./SCss2QELKpHeXtJLIY4hrM3v5tumAcn5mHWJQy9Z0z6', 1, 2,
 (SELECT designation_id FROM designation WHERE name = 'Accountant' LIMIT 1),
 (SELECT department_id FROM department WHERE name = 'Finance' LIMIT 1),
 (SELECT station_id FROM station WHERE name = 'Zurich' LIMIT 1),
 (SELECT project_id FROM project ORDER BY project_id LIMIT 1), 1, 'SEED-050', '2024-03-01', 0, '1992-06-15', 'Single', 'Zurich, Switzerland', 'Monthly', 0, 0, 'Sara Frei', 'USD00100050', 'SEED';
SET @emp := (SELECT employee_id FROM employee WHERE employee_code = 'SEED-050');
SET @st := (SELECT station_id FROM station WHERE name = 'Zurich' LIMIT 1);
SET @prj := (SELECT project_id FROM project ORDER BY project_id LIMIT 1);
INSERT INTO define_salary (station_id, project_id, employee_id, basic_salary, total_allowance, total_deduction, net_salary, created_by) VALUES (@st, @prj, @emp, 6800.00, 1020.00, 1308.15, 6511.85, 1);
SET @def := LAST_INSERT_ID();
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 6800.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 1020.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO define_salary_details (define_salary_id, payroll_item_id, allowance, deduction) SELECT @def, id, 0, 1308.15 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO process_salary (project_id, employee_id, days, basic_salary, total_allowance, total_deduction, net_salary, tax_amount, eobi_amount, sessi_amount, pf_amount, overtime_amount, advance_amount, late_amount, lwp_amount, loan_amount, arrears_amount, date, created_by) VALUES (@prj, @emp, 30, 6800.00, 1020.00, 1308.15, 6511.85, 1308.15, 0, 0, 0, 0, 0, 0, 0, 0.00, 0, '2026-09-30', 1);
SET @pay := LAST_INSERT_ID();
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 6800.00, 0 FROM hr_payroll_item WHERE code = 'BASIC';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 1020.00, 0 FROM hr_payroll_item WHERE code = 'HRA';
INSERT INTO process_salary_details (process_salary_id, payroll_item_id, allowance, deduction) SELECT @pay, id, 0, 1308.15 FROM hr_payroll_item WHERE code = 'TAX';
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-01', '2026-09-01 09:00:00', '2026-09-01 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-02', '2026-09-02 09:00:00', '2026-09-02 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-03', '2026-09-03 09:00:00', '2026-09-03 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-04', '2026-09-04 09:00:00', '2026-09-04 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-07', '2026-09-07 09:00:00', '2026-09-07 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-08', '2026-09-08 09:00:00', '2026-09-08 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-09', '2026-09-09 09:00:00', '2026-09-09 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-10', '2026-09-10 09:00:00', '2026-09-10 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO attendance (employee_id, date, punch_in, punch_out, total_minutes, late_minutes, status, notes) VALUES (@emp, '2026-09-11', '2026-09-11 09:00:00', '2026-09-11 17:30:00', 510, 0, 1, 'USD seed attendance');
INSERT INTO timesheet (employee_id, project_id, from_date, to_date, hours, description, status) VALUES (@emp, @prj, '2026-09-01', '2026-09-11', 72, 'September timesheet for Zurich', 1);
UPDATE employee e JOIN employee m ON m.employee_code = 'SEED-001' JOIN station s ON s.station_id = e.station AND s.name = 'New York' SET e.line_manager = m.employee_id WHERE e.employee_code LIKE 'SEED-%' AND e.employee_id <> m.employee_id;
UPDATE employee e JOIN employee m ON m.employee_code = 'SEED-007' JOIN station s ON s.station_id = e.station AND s.name = 'Chicago' SET e.line_manager = m.employee_id WHERE e.employee_code LIKE 'SEED-%' AND e.employee_id <> m.employee_id;
UPDATE employee e JOIN employee m ON m.employee_code = 'SEED-013' JOIN station s ON s.station_id = e.station AND s.name = 'Toronto' SET e.line_manager = m.employee_id WHERE e.employee_code LIKE 'SEED-%' AND e.employee_id <> m.employee_id;
UPDATE employee e JOIN employee m ON m.employee_code = 'SEED-019' JOIN station s ON s.station_id = e.station AND s.name = 'Vancouver' SET e.line_manager = m.employee_id WHERE e.employee_code LIKE 'SEED-%' AND e.employee_id <> m.employee_id;
UPDATE employee e JOIN employee m ON m.employee_code = 'SEED-025' JOIN station s ON s.station_id = e.station AND s.name = 'Berlin' SET e.line_manager = m.employee_id WHERE e.employee_code LIKE 'SEED-%' AND e.employee_id <> m.employee_id;
UPDATE employee e JOIN employee m ON m.employee_code = 'SEED-031' JOIN station s ON s.station_id = e.station AND s.name = 'Munich' SET e.line_manager = m.employee_id WHERE e.employee_code LIKE 'SEED-%' AND e.employee_id <> m.employee_id;
UPDATE employee e JOIN employee m ON m.employee_code = 'SEED-037' JOIN station s ON s.station_id = e.station AND s.name = 'Amsterdam' SET e.line_manager = m.employee_id WHERE e.employee_code LIKE 'SEED-%' AND e.employee_id <> m.employee_id;
UPDATE employee e JOIN employee m ON m.employee_code = 'SEED-041' JOIN station s ON s.station_id = e.station AND s.name = 'Paris' SET e.line_manager = m.employee_id WHERE e.employee_code LIKE 'SEED-%' AND e.employee_id <> m.employee_id;
UPDATE employee e JOIN employee m ON m.employee_code = 'SEED-046' JOIN station s ON s.station_id = e.station AND s.name = 'Zurich' SET e.line_manager = m.employee_id WHERE e.employee_code LIKE 'SEED-%' AND e.employee_id <> m.employee_id;
COMMIT;
