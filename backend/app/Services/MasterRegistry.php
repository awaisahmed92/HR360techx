<?php

namespace App\Services;

use Illuminate\Support\Facades\Schema;

/**
 * Declarative master-data entities for Phase 2 org / lifecycle / payroll masters.
 * Each entity maps a Flutter submenu → table + fields + FK option sources.
 */
class MasterRegistry
{
    /**
     * @return array<string, array<string, mixed>>
     */
    public static function all(): array
    {
        return [
            // ── Organization ──
            'companies' => [
                'title' => 'Companies',
                'table' => 'company',
                'pk' => null, // auto-detect id | company_id
                'label' => 'hr_company_name',
                'search' => ['hr_company_name', 'name', 'code', 'email'],
                'columns' => [
                    ['key' => 'code', 'label' => 'Company Code'],
                    ['key' => 'hr_company_name', 'label' => 'Company Name', 'fallback' => 'name'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                    ['key' => 'company_type', 'label' => 'Company Type'],
                    ['key' => 'contact_person', 'label' => 'Contact Person'],
                    ['key' => 'address', 'label' => 'Address'],
                    ['key' => 'email', 'label' => 'Email'],
                    ['key' => 'province', 'label' => 'Province'],
                    ['key' => 'website', 'label' => 'Website'],
                ],
                'fields' => [
                    ['key' => 'code', 'label' => 'Company Code', 'type' => 'text', 'required' => true],
                    ['key' => 'hr_company_name', 'label' => 'Company Name', 'type' => 'text', 'required' => true],
                    ['key' => 'name', 'label' => 'Legal Name', 'type' => 'text'],
                    ['key' => 'company_type', 'label' => 'Company Type', 'type' => 'select', 'options' => ['Head Office', 'Branch', 'Subsidiary']],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                    ['key' => 'contact_person', 'label' => 'Contact Person', 'type' => 'text'],
                    ['key' => 'email', 'label' => 'Email', 'type' => 'email'],
                    ['key' => 'address', 'label' => 'Address', 'type' => 'text'],
                    ['key' => 'province', 'label' => 'Province', 'type' => 'text'],
                    ['key' => 'website', 'label' => 'Website', 'type' => 'text'],
                    ['key' => 'currency', 'label' => 'Currency', 'type' => 'text', 'default' => 'PKR'],
                ],
            ],
            'divisions' => [
                'title' => 'Divisions',
                'table' => 'hr_org_division',
                'columns' => [
                    ['key' => 'code', 'label' => 'Code'],
                    ['key' => 'name', 'label' => 'Division Name'],
                    ['key' => 'company_name', 'label' => 'Company'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'code', 'label' => 'Code', 'type' => 'text'],
                    ['key' => 'name', 'label' => 'Division Name', 'type' => 'text', 'required' => true],
                    ['key' => 'company_id', 'label' => 'Company', 'type' => 'fk', 'fk' => 'companies'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                ],
                'joins' => [
                    ['table' => 'company', 'alias' => 'c', 'on' => 'c.{cpk} = t.company_id', 'select' => 'COALESCE(c.hr_company_name, c.name) as company_name'],
                ],
            ],
            'cost_centers' => [
                'title' => 'Cost Centers',
                'table' => 'hr_cost_center',
                'columns' => [
                    ['key' => 'code', 'label' => 'Code'],
                    ['key' => 'name', 'label' => 'Cost Center'],
                    ['key' => 'division_name', 'label' => 'Division'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'code', 'label' => 'Code', 'type' => 'text'],
                    ['key' => 'name', 'label' => 'Name', 'type' => 'text', 'required' => true],
                    ['key' => 'division_id', 'label' => 'Division', 'type' => 'fk', 'fk' => 'divisions'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                ],
                'joins' => [
                    ['table' => 'hr_org_division', 'alias' => 'd', 'on' => 'd.id = t.division_id', 'select' => 'd.name as division_name'],
                ],
            ],
            'stations' => [
                'title' => 'Stations',
                'table' => 'station',
                'pk' => 'station_id',
                'columns' => [
                    ['key' => 'code', 'label' => 'Code'],
                    ['key' => 'name', 'label' => 'Station'],
                    ['key' => 'office_type', 'label' => 'Office Type'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'code', 'label' => 'Code', 'type' => 'text'],
                    ['key' => 'name', 'label' => 'Station Name', 'type' => 'text', 'required' => true],
                    ['key' => 'office_type', 'label' => 'Office Type', 'type' => 'select', 'options' => ['head_office' => 'Head Office', 'field_office' => 'Field Office', 'liaison_office' => 'Liaison Office']],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                ],
            ],
            'parent_departments' => [
                'title' => 'Parent Departments',
                'table' => 'hr_parent_department',
                'columns' => [
                    ['key' => 'code', 'label' => 'Code'],
                    ['key' => 'name', 'label' => 'Name'],
                    ['key' => 'division_name', 'label' => 'Division'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'code', 'label' => 'Code', 'type' => 'text'],
                    ['key' => 'name', 'label' => 'Name', 'type' => 'text', 'required' => true],
                    ['key' => 'division_id', 'label' => 'Division', 'type' => 'fk', 'fk' => 'divisions'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                ],
                'joins' => [
                    ['table' => 'hr_org_division', 'alias' => 'd', 'on' => 'd.id = t.division_id', 'select' => 'd.name as division_name'],
                ],
            ],
            'departments' => [
                'title' => 'Departments',
                'table' => 'department',
                'pk' => 'department_id',
                'columns' => [
                    ['key' => 'code', 'label' => 'Code'],
                    ['key' => 'name', 'label' => 'Department'],
                    ['key' => 'parent_name', 'label' => 'Parent Dept'],
                    ['key' => 'division_name', 'label' => 'Division'],
                    ['key' => 'cost_center_name', 'label' => 'Cost Center'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'code', 'label' => 'Code', 'type' => 'text'],
                    ['key' => 'name', 'label' => 'Department Name', 'type' => 'text', 'required' => true],
                    ['key' => 'parent_department_id', 'label' => 'Parent Department', 'type' => 'fk', 'fk' => 'parent_departments'],
                    ['key' => 'division_id', 'label' => 'Division', 'type' => 'fk', 'fk' => 'divisions'],
                    ['key' => 'cost_center_id', 'label' => 'Cost Center', 'type' => 'fk', 'fk' => 'cost_centers'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                ],
                'joins' => [
                    ['table' => 'hr_parent_department', 'alias' => 'pd', 'on' => 'pd.id = t.parent_department_id', 'select' => 'pd.name as parent_name'],
                    ['table' => 'hr_org_division', 'alias' => 'd', 'on' => 'd.id = t.division_id', 'select' => 'd.name as division_name'],
                    ['table' => 'hr_cost_center', 'alias' => 'cc', 'on' => 'cc.id = t.cost_center_id', 'select' => 'cc.name as cost_center_name'],
                ],
            ],
            'teams' => [
                'title' => 'Teams',
                'table' => 'hr_team',
                'columns' => [
                    ['key' => 'code', 'label' => 'Code'],
                    ['key' => 'name', 'label' => 'Team'],
                    ['key' => 'department_name', 'label' => 'Department'],
                    ['key' => 'lead_name', 'label' => 'Team Lead'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'code', 'label' => 'Code', 'type' => 'text'],
                    ['key' => 'name', 'label' => 'Team Name', 'type' => 'text', 'required' => true],
                    ['key' => 'department_id', 'label' => 'Department', 'type' => 'fk', 'fk' => 'departments'],
                    ['key' => 'lead_employee_id', 'label' => 'Team Lead', 'type' => 'fk', 'fk' => 'employees'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                ],
                'joins' => [
                    ['table' => 'department', 'alias' => 'dep', 'on' => 'dep.department_id = t.department_id', 'select' => 'dep.name as department_name'],
                    ['table' => 'employee', 'alias' => 'e', 'on' => 'e.employee_id = t.lead_employee_id', 'select' => 'e.name as lead_name'],
                ],
            ],
            'policies' => [
                'title' => 'Policies',
                'table' => 'hr_policy',
                'columns' => [
                    ['key' => 'title', 'label' => 'Title'],
                    ['key' => 'category', 'label' => 'Category'],
                    ['key' => 'version', 'label' => 'Version'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'title', 'label' => 'Title', 'type' => 'text', 'required' => true],
                    ['key' => 'category', 'label' => 'Category', 'type' => 'select', 'options' => ['HR', 'Leave', 'Attendance', 'Code of Conduct', 'Safety']],
                    ['key' => 'version', 'label' => 'Version', 'type' => 'text', 'default' => '1.0'],
                    ['key' => 'file_path', 'label' => 'File / URL', 'type' => 'text'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                ],
            ],
            'announcements' => [
                'title' => 'Announcements',
                'table' => 'hr_announcement',
                'columns' => [
                    ['key' => 'title', 'label' => 'Title'],
                    ['key' => 'audience', 'label' => 'Audience'],
                    ['key' => 'starts_on', 'label' => 'Starts'],
                    ['key' => 'ends_on', 'label' => 'Ends'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'title', 'label' => 'Title', 'type' => 'text', 'required' => true],
                    ['key' => 'body', 'label' => 'Body', 'type' => 'textarea'],
                    ['key' => 'audience', 'label' => 'Audience', 'type' => 'select', 'options' => ['all', 'managers', 'hr'], 'default' => 'all'],
                    ['key' => 'starts_on', 'label' => 'Starts On', 'type' => 'date'],
                    ['key' => 'ends_on', 'label' => 'Ends On', 'type' => 'date'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Published', '0' => 'Draft'], 'default' => '1'],
                ],
            ],
            'system_logs' => [
                'title' => 'System Logs',
                'table' => 'hr_system_log',
                'read_only' => true,
                'columns' => [
                    ['key' => 'created_at', 'label' => 'When'],
                    ['key' => 'action', 'label' => 'Action'],
                    ['key' => 'entity', 'label' => 'Entity'],
                    ['key' => 'entity_id', 'label' => 'ID'],
                    ['key' => 'detail', 'label' => 'Detail'],
                ],
                'fields' => [],
            ],

            // ── Employee lifecycle ──
            'contracts' => self::empLinked('Contracts', 'hr_contract', [
                ['key' => 'contract_no', 'label' => 'Contract No', 'type' => 'text'],
                ['key' => 'contract_type', 'label' => 'Type', 'type' => 'select', 'options' => ['Permanent', 'Contract', 'Internship', 'Consultant'], 'default' => 'Permanent'],
                ['key' => 'start_date', 'label' => 'Start', 'type' => 'date'],
                ['key' => 'end_date', 'label' => 'End', 'type' => 'date'],
                ['key' => 'project_id', 'label' => 'Project', 'type' => 'fk', 'fk' => 'projects'],
                ['key' => 'station_id', 'label' => 'Station', 'type' => 'fk', 'fk' => 'stations'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Ended'], 'default' => '1'],
                ['key' => 'notes', 'label' => 'Notes', 'type' => 'textarea'],
            ], [
                ['key' => 'contract_no', 'label' => 'Contract No'],
                ['key' => 'employee_name', 'label' => 'Employee'],
                ['key' => 'contract_type', 'label' => 'Type'],
                ['key' => 'start_date', 'label' => 'Start'],
                ['key' => 'end_date', 'label' => 'End'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
            ]),
            'assignments' => self::empLinked('Assignments', 'hr_assignment', [
                ['key' => 'project_id', 'label' => 'Project', 'type' => 'fk', 'fk' => 'projects'],
                ['key' => 'station_id', 'label' => 'Station', 'type' => 'fk', 'fk' => 'stations'],
                ['key' => 'department_id', 'label' => 'Department', 'type' => 'fk', 'fk' => 'departments'],
                ['key' => 'role_title', 'label' => 'Role Title', 'type' => 'text'],
                ['key' => 'start_date', 'label' => 'Start', 'type' => 'date'],
                ['key' => 'end_date', 'label' => 'End', 'type' => 'date'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Ended'], 'default' => '1'],
            ], [
                ['key' => 'employee_name', 'label' => 'Employee'],
                ['key' => 'role_title', 'label' => 'Role'],
                ['key' => 'project_name', 'label' => 'Project'],
                ['key' => 'station_name', 'label' => 'Station'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
            ], extraJoins: [
                ['table' => 'project', 'alias' => 'p', 'on' => 'p.project_id = t.project_id', 'select' => 'p.name as project_name'],
                ['table' => 'station', 'alias' => 's', 'on' => 's.station_id = t.station_id', 'select' => 's.name as station_name'],
            ]),
            'transfers' => self::empLinked('Transfers', 'hr_transfer', [
                ['key' => 'from_station_id', 'label' => 'From Station', 'type' => 'fk', 'fk' => 'stations'],
                ['key' => 'to_station_id', 'label' => 'To Station', 'type' => 'fk', 'fk' => 'stations'],
                ['key' => 'from_project_id', 'label' => 'From Project', 'type' => 'fk', 'fk' => 'projects'],
                ['key' => 'to_project_id', 'label' => 'To Project', 'type' => 'fk', 'fk' => 'projects'],
                ['key' => 'effective_date', 'label' => 'Effective Date', 'type' => 'date'],
                ['key' => 'reason', 'label' => 'Reason', 'type' => 'textarea'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['0' => 'Pending', '1' => 'Approved', '2' => 'Rejected'], 'default' => '0'],
            ], [
                ['key' => 'employee_name', 'label' => 'Employee'],
                ['key' => 'effective_date', 'label' => 'Effective'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ['key' => 'reason', 'label' => 'Reason'],
            ]),
            'promotions' => self::empLinked('Promotions', 'hr_promotion', [
                ['key' => 'from_designation_id', 'label' => 'From Designation', 'type' => 'fk', 'fk' => 'designations'],
                ['key' => 'to_designation_id', 'label' => 'To Designation', 'type' => 'fk', 'fk' => 'designations'],
                ['key' => 'effective_date', 'label' => 'Effective Date', 'type' => 'date'],
                ['key' => 'remarks', 'label' => 'Remarks', 'type' => 'textarea'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['0' => 'Pending', '1' => 'Approved', '2' => 'Rejected'], 'default' => '0'],
            ], [
                ['key' => 'employee_name', 'label' => 'Employee'],
                ['key' => 'from_desig', 'label' => 'From'],
                ['key' => 'to_desig', 'label' => 'To'],
                ['key' => 'effective_date', 'label' => 'Effective'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
            ], extraJoins: [
                ['table' => 'designation', 'alias' => 'fd', 'on' => 'fd.designation_id = t.from_designation_id', 'select' => 'fd.name as from_desig'],
                ['table' => 'designation', 'alias' => 'td', 'on' => 'td.designation_id = t.to_designation_id', 'select' => 'td.name as to_desig'],
            ]),
            'resignations' => self::empLinked('Resignations', 'hr_resignation', [
                ['key' => 'resign_date', 'label' => 'Resign Date', 'type' => 'date'],
                ['key' => 'last_working_day', 'label' => 'Last Working Day', 'type' => 'date'],
                ['key' => 'reason', 'label' => 'Reason', 'type' => 'textarea'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['0' => 'Pending', '1' => 'Accepted', '2' => 'Withdrawn'], 'default' => '0'],
            ], [
                ['key' => 'employee_name', 'label' => 'Employee'],
                ['key' => 'resign_date', 'label' => 'Resign Date'],
                ['key' => 'last_working_day', 'label' => 'LWD'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
            ]),
            'employment_changes' => self::empLinked('Employment Changes', 'hr_employment_change', [
                ['key' => 'change_type', 'label' => 'Change Type', 'type' => 'select', 'options' => ['Designation', 'Department', 'Station', 'Project', 'Salary', 'Other'], 'required' => true],
                ['key' => 'effective_date', 'label' => 'Effective Date', 'type' => 'date'],
                ['key' => 'old_value', 'label' => 'Old Value', 'type' => 'text'],
                ['key' => 'new_value', 'label' => 'New Value', 'type' => 'text'],
                ['key' => 'remarks', 'label' => 'Remarks', 'type' => 'textarea'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['0' => 'Pending', '1' => 'Applied', '2' => 'Cancelled'], 'default' => '0'],
            ], [
                ['key' => 'employee_name', 'label' => 'Employee'],
                ['key' => 'change_type', 'label' => 'Type'],
                ['key' => 'old_value', 'label' => 'Old'],
                ['key' => 'new_value', 'label' => 'New'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
            ]),
            'achievements' => self::empLinked('Achievements', 'hr_achievement', [
                ['key' => 'title', 'label' => 'Title', 'type' => 'text', 'required' => true],
                ['key' => 'achieved_on', 'label' => 'Date', 'type' => 'date'],
                ['key' => 'description', 'label' => 'Description', 'type' => 'textarea'],
            ], [
                ['key' => 'employee_name', 'label' => 'Employee'],
                ['key' => 'title', 'label' => 'Title'],
                ['key' => 'achieved_on', 'label' => 'Date'],
            ], includeStatus: false),
            'complaints' => self::empLinked('Complaints', 'hr_complaint', [
                ['key' => 'against_employee_id', 'label' => 'Against', 'type' => 'fk', 'fk' => 'employees'],
                ['key' => 'subject', 'label' => 'Subject', 'type' => 'text', 'required' => true],
                ['key' => 'detail', 'label' => 'Detail', 'type' => 'textarea'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['0' => 'Open', '1' => 'Resolved', '2' => 'Dismissed'], 'default' => '0'],
            ], [
                ['key' => 'employee_name', 'label' => 'Complainant'],
                ['key' => 'subject', 'label' => 'Subject'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
            ]),
            'discipline' => self::empLinked('Discipline', 'hr_discipline', [
                ['key' => 'action_type', 'label' => 'Action', 'type' => 'select', 'options' => ['Warning', 'Written Warning', 'Suspension', 'Termination'], 'required' => true],
                ['key' => 'action_date', 'label' => 'Date', 'type' => 'date'],
                ['key' => 'detail', 'label' => 'Detail', 'type' => 'textarea'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Recorded', '0' => 'Void'], 'default' => '1'],
            ], [
                ['key' => 'employee_name', 'label' => 'Employee'],
                ['key' => 'action_type', 'label' => 'Action'],
                ['key' => 'action_date', 'label' => 'Date'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
            ]),

            // Lookup entities used as FKs
            'employees' => [
                'title' => 'Employees',
                'table' => 'employee',
                'pk' => 'employee_id',
                'label' => 'name',
                'options_only' => true,
                'columns' => [],
                'fields' => [],
            ],
            'projects' => [
                'title' => 'Projects',
                'table' => 'project',
                'pk' => 'project_id',
                'label' => 'name',
                'columns' => [
                    ['key' => 'name', 'label' => 'Project'],
                ],
                'fields' => [
                    ['key' => 'name', 'label' => 'Project Name', 'type' => 'text', 'required' => true],
                ],
            ],
            'designations' => [
                'title' => 'Designations',
                'table' => 'designation',
                'pk' => 'designation_id',
                'label' => 'name',
                'columns' => [
                    ['key' => 'name', 'label' => 'Designation'],
                ],
                'fields' => [
                    ['key' => 'name', 'label' => 'Name', 'type' => 'text', 'required' => true],
                ],
            ],

            // ── Timesheet masters ──
            'work_shifts' => [
                'title' => 'Work Shifts',
                'table' => 'hr_work_shift',
                'columns' => [
                    ['key' => 'code', 'label' => 'Code'],
                    ['key' => 'name', 'label' => 'Shift'],
                    ['key' => 'start_time', 'label' => 'Start'],
                    ['key' => 'end_time', 'label' => 'End'],
                    ['key' => 'grace_minutes', 'label' => 'Grace (min)'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'code', 'label' => 'Code', 'type' => 'text'],
                    ['key' => 'name', 'label' => 'Shift Name', 'type' => 'text', 'required' => true],
                    ['key' => 'start_time', 'label' => 'Start Time', 'type' => 'text', 'hint' => 'HH:MM:SS'],
                    ['key' => 'end_time', 'label' => 'End Time', 'type' => 'text'],
                    ['key' => 'grace_minutes', 'label' => 'Grace Minutes', 'type' => 'number', 'default' => '15'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                ],
            ],
            'holidays' => [
                'title' => 'Holidays',
                'table' => 'hr_holiday',
                'columns' => [
                    ['key' => 'name', 'label' => 'Holiday'],
                    ['key' => 'holiday_date', 'label' => 'Date'],
                    ['key' => 'holiday_type', 'label' => 'Type'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'name', 'label' => 'Name', 'type' => 'text', 'required' => true],
                    ['key' => 'holiday_date', 'label' => 'Date', 'type' => 'date', 'required' => true],
                    ['key' => 'holiday_type', 'label' => 'Type', 'type' => 'select', 'options' => ['Public', 'Optional', 'Company'], 'default' => 'Public'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                ],
            ],
            'wfh' => self::empLinked('Work From Home', 'hr_wfh_request', [
                ['key' => 'from_date', 'label' => 'From', 'type' => 'date', 'required' => true],
                ['key' => 'to_date', 'label' => 'To', 'type' => 'date', 'required' => true],
                ['key' => 'reason', 'label' => 'Reason', 'type' => 'textarea'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['0' => 'Pending', '1' => 'Approved', '2' => 'Rejected'], 'default' => '0'],
            ], [
                ['key' => 'employee_name', 'label' => 'Employee'],
                ['key' => 'from_date', 'label' => 'From'],
                ['key' => 'to_date', 'label' => 'To'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
            ]),
            'flex_hours' => self::empLinked('Flex Hours', 'hr_flex_hour', [
                ['key' => 'work_date', 'label' => 'Date', 'type' => 'date', 'required' => true],
                ['key' => 'planned_in', 'label' => 'Planned In', 'type' => 'text'],
                ['key' => 'planned_out', 'label' => 'Planned Out', 'type' => 'text'],
                ['key' => 'reason', 'label' => 'Reason', 'type' => 'textarea'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['0' => 'Pending', '1' => 'Approved', '2' => 'Rejected'], 'default' => '0'],
            ], [
                ['key' => 'employee_name', 'label' => 'Employee'],
                ['key' => 'work_date', 'label' => 'Date'],
                ['key' => 'planned_in', 'label' => 'In'],
                ['key' => 'planned_out', 'label' => 'Out'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
            ]),

            // ── Payroll masters (not full process) ──
            'allowances' => self::payItems('Allowances', 'allowance'),
            'deductions' => self::payItems('Deductions', 'deduction'),
            'bonuses' => self::payItems('Bonuses', 'bonus'),
            'commissions' => self::payItems('Commissions', 'commission'),
            'earnings' => self::payItems('Earnings', 'earning'),
            'adjustments' => self::payItems('Adjustments', 'adjustment'),
            'overtime' => [
                'title' => 'Overtime',
                'table' => 'hr_overtime_entry',
                'columns' => [
                    ['key' => 'employee_name', 'label' => 'Employee'],
                    ['key' => 'work_date', 'label' => 'Date'],
                    ['key' => 'hours', 'label' => 'Hours'],
                    ['key' => 'rate_multiplier', 'label' => 'Multiplier'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'employee_id', 'label' => 'Employee', 'type' => 'fk', 'fk' => 'employees', 'required' => true],
                    ['key' => 'work_date', 'label' => 'Date', 'type' => 'date', 'required' => true],
                    ['key' => 'hours', 'label' => 'Hours', 'type' => 'number', 'required' => true],
                    ['key' => 'rate_multiplier', 'label' => 'Rate Multiplier', 'type' => 'number', 'default' => '1.5'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['0' => 'Pending', '1' => 'Approved', '2' => 'Rejected'], 'default' => '0'],
                ],
                'joins' => [
                    ['table' => 'employee', 'alias' => 'e', 'on' => 'e.employee_id = t.employee_id', 'select' => 'e.name as employee_name'],
                ],
            ],
            'advance' => self::empLinked('Advance', 'hr_advance', [
                ['key' => 'amount', 'label' => 'Amount', 'type' => 'number', 'required' => true],
                ['key' => 'request_date', 'label' => 'Request Date', 'type' => 'date'],
                ['key' => 'recover_months', 'label' => 'Recover Months', 'type' => 'number', 'default' => '1'],
                ['key' => 'remarks', 'label' => 'Remarks', 'type' => 'textarea'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['0' => 'Pending', '1' => 'Approved', '2' => 'Rejected', '3' => 'Recovered'], 'default' => '0'],
            ], [
                ['key' => 'employee_name', 'label' => 'Employee'],
                ['key' => 'amount', 'label' => 'Amount'],
                ['key' => 'request_date', 'label' => 'Date'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
            ]),
            'loans' => self::empLinked('Loans', 'hr_loan', [
                ['key' => 'principal', 'label' => 'Principal', 'type' => 'number', 'required' => true],
                ['key' => 'installment', 'label' => 'Monthly Installment', 'type' => 'number', 'required' => true],
                ['key' => 'start_date', 'label' => 'Start Date', 'type' => 'date'],
                ['key' => 'remarks', 'label' => 'Remarks', 'type' => 'textarea'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['0' => 'Pending', '1' => 'Active', '2' => 'Closed', '3' => 'Rejected'], 'default' => '1'],
            ], [
                ['key' => 'employee_name', 'label' => 'Employee'],
                ['key' => 'principal', 'label' => 'Principal'],
                ['key' => 'installment', 'label' => 'Installment'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
            ]),
            'arrears' => self::empLinked('Arrears', 'hr_arrears', [
                ['key' => 'amount', 'label' => 'Amount', 'type' => 'number', 'required' => true],
                ['key' => 'for_month', 'label' => 'For Month (YYYY-MM)', 'type' => 'text', 'required' => true],
                ['key' => 'remarks', 'label' => 'Remarks', 'type' => 'textarea'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Pending', '2' => 'Applied'], 'default' => '1'],
            ], [
                ['key' => 'employee_name', 'label' => 'Employee'],
                ['key' => 'amount', 'label' => 'Amount'],
                ['key' => 'for_month', 'label' => 'Month'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
            ]),
            'salary_scales' => [
                'title' => 'Salary Scales',
                'table' => 'hr_salary_scale',
                'columns' => [
                    ['key' => 'code', 'label' => 'Code'],
                    ['key' => 'name', 'label' => 'Scale'],
                    ['key' => 'min_amount', 'label' => 'Min'],
                    ['key' => 'max_amount', 'label' => 'Max'],
                    ['key' => 'designation_name', 'label' => 'Designation'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'code', 'label' => 'Code', 'type' => 'text'],
                    ['key' => 'name', 'label' => 'Name', 'type' => 'text', 'required' => true],
                    ['key' => 'min_amount', 'label' => 'Min Amount', 'type' => 'number'],
                    ['key' => 'max_amount', 'label' => 'Max Amount', 'type' => 'number'],
                    ['key' => 'designation_id', 'label' => 'Designation', 'type' => 'fk', 'fk' => 'designations'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                ],
                'joins' => [
                    ['table' => 'designation', 'alias' => 'd', 'on' => 'd.designation_id = t.designation_id', 'select' => 'd.name as designation_name'],
                ],
            ],
            'hourly_wages' => [
                'title' => 'Hourly Wages',
                'table' => 'hr_hourly_wage',
                'columns' => [
                    ['key' => 'employee_name', 'label' => 'Employee'],
                    ['key' => 'designation_name', 'label' => 'Designation'],
                    ['key' => 'rate_per_hour', 'label' => 'Rate/Hour'],
                    ['key' => 'effective_from', 'label' => 'From'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'employee_id', 'label' => 'Employee', 'type' => 'fk', 'fk' => 'employees'],
                    ['key' => 'designation_id', 'label' => 'Designation', 'type' => 'fk', 'fk' => 'designations'],
                    ['key' => 'rate_per_hour', 'label' => 'Rate Per Hour', 'type' => 'number', 'required' => true],
                    ['key' => 'effective_from', 'label' => 'Effective From', 'type' => 'date'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                ],
                'joins' => [
                    ['table' => 'employee', 'alias' => 'e', 'on' => 'e.employee_id = t.employee_id', 'select' => 'e.name as employee_name'],
                    ['table' => 'designation', 'alias' => 'd', 'on' => 'd.designation_id = t.designation_id', 'select' => 'd.name as designation_name'],
                ],
            ],
            'ctc' => [
                'title' => 'Cost To Company',
                'table' => 'hr_payroll_item',
                'filter' => ['category' => 'earning'],
                'columns' => [
                    ['key' => 'code', 'label' => 'Code'],
                    ['key' => 'name', 'label' => 'Component'],
                    ['key' => 'calc_type', 'label' => 'Calc'],
                    ['key' => 'default_value', 'label' => 'Default'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'code', 'label' => 'Code', 'type' => 'text'],
                    ['key' => 'name', 'label' => 'Component', 'type' => 'text', 'required' => true],
                    ['key' => 'category', 'label' => 'Category', 'type' => 'hidden', 'default' => 'earning'],
                    ['key' => 'calc_type', 'label' => 'Calc Type', 'type' => 'select', 'options' => ['fixed', 'percent', 'formula'], 'default' => 'fixed'],
                    ['key' => 'default_value', 'label' => 'Default Value', 'type' => 'number'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                ],
            ],
            'salary' => [
                'title' => 'Salary (Define)',
                'table' => 'hr_salary_scale',
                'note' => 'Prefer Payroll → Define Salary for full structures. Scales remain for grade bands.',
                'columns' => [
                    ['key' => 'code', 'label' => 'Code'],
                    ['key' => 'name', 'label' => 'Scale'],
                    ['key' => 'min_amount', 'label' => 'Min'],
                    ['key' => 'max_amount', 'label' => 'Max'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'code', 'label' => 'Code', 'type' => 'text'],
                    ['key' => 'name', 'label' => 'Name', 'type' => 'text', 'required' => true],
                    ['key' => 'min_amount', 'label' => 'Min', 'type' => 'number'],
                    ['key' => 'max_amount', 'label' => 'Max', 'type' => 'number'],
                    ['key' => 'designation_id', 'label' => 'Designation', 'type' => 'fk', 'fk' => 'designations'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                ],
            ],

            // ── PHP replica: statutory + formulas + settlement ──
            'payroll_items' => [
                'title' => 'Payroll Items',
                'table' => 'hr_payroll_item',
                'label' => 'name',
                'search' => ['code', 'name'],
                'columns' => [
                    ['key' => 'code', 'label' => 'Code'],
                    ['key' => 'name', 'label' => 'Name'],
                    ['key' => 'category', 'label' => 'Category'],
                    ['key' => 'calc_type', 'label' => 'Calc'],
                    ['key' => 'default_value', 'label' => 'Default'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'code', 'label' => 'Code', 'type' => 'text'],
                    ['key' => 'name', 'label' => 'Name', 'type' => 'text', 'required' => true],
                    ['key' => 'category', 'label' => 'Category', 'type' => 'select', 'options' => [
                        'General', 'allowance', 'deduction', 'earning', 'EOBI', 'SESSI', 'Provident Fund',
                    ], 'default' => 'General'],
                    ['key' => 'calc_type', 'label' => 'Calc Type', 'type' => 'select', 'options' => ['fixed', 'percent', 'formula'], 'default' => 'fixed'],
                    ['key' => 'default_value', 'label' => 'Default Value', 'type' => 'number'],
                    ['key' => 'taxable', 'label' => 'Taxable', 'type' => 'select', 'options' => ['1' => 'Yes', '0' => 'No'], 'default' => '1'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                ],
            ],
            'payroll_formulas' => self::payrollFormula('Payroll Setup (Formulas)', 'General'),
            'eobi_setup' => self::payrollFormula('EOBI', 'EOBI'),
            'pf_setup' => self::payrollFormula('Provident Fund', 'Provident Fund'),
            'sessi_setup' => self::payrollFormula('SESSI', 'SESSI'),
            'tax_slabs' => [
                'title' => 'Tax Slabs',
                'table' => 'tax',
                'search' => ['year'],
                'columns' => [
                    ['key' => 'from_amount', 'label' => 'From'],
                    ['key' => 'to_amount', 'label' => 'To'],
                    ['key' => 'fixed_amount', 'label' => 'Fixed'],
                    ['key' => 'percentage', 'label' => '%'],
                    ['key' => 'year', 'label' => 'FY'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
                ],
                'fields' => [
                    ['key' => 'from_amount', 'label' => 'From Amount', 'type' => 'number', 'required' => true],
                    ['key' => 'to_amount', 'label' => 'To Amount', 'type' => 'number'],
                    ['key' => 'fixed_amount', 'label' => 'Fixed Amount', 'type' => 'number', 'default' => '0'],
                    ['key' => 'percentage', 'label' => 'Percentage', 'type' => 'number', 'default' => '0'],
                    ['key' => 'year', 'label' => 'Fiscal Year', 'type' => 'text', 'default' => '2025-2026'],
                    ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
                ],
            ],
            'eobi_rates' => [
                'title' => 'EOBI Rates',
                'table' => 'eobi',
                'columns' => [
                    ['key' => 'emp_amount', 'label' => 'Employee Amt'],
                    ['key' => 'emp_percentage', 'label' => 'Emp %'],
                    ['key' => 'org_amount', 'label' => 'Employer Amt'],
                    ['key' => 'org_percentage', 'label' => 'Org %'],
                    ['key' => 'description', 'label' => 'Description'],
                ],
                'fields' => [
                    ['key' => 'emp_amount', 'label' => 'Employee Amount', 'type' => 'number', 'required' => true, 'default' => '370'],
                    ['key' => 'emp_percentage', 'label' => 'Employee %', 'type' => 'number'],
                    ['key' => 'org_amount', 'label' => 'Employer Amount', 'type' => 'number', 'default' => '370'],
                    ['key' => 'org_percentage', 'label' => 'Employer %', 'type' => 'number'],
                    ['key' => 'description', 'label' => 'Description', 'type' => 'textarea'],
                ],
            ],
            'sessi_rates' => [
                'title' => 'SESSI Rates',
                'table' => 'sessi',
                'columns' => [
                    ['key' => 'emp_percentage', 'label' => 'Emp %'],
                    ['key' => 'org_percentage', 'label' => 'Org %'],
                    ['key' => 'emp_amount', 'label' => 'Emp Amt'],
                    ['key' => 'org_amount', 'label' => 'Org Amt'],
                    ['key' => 'description', 'label' => 'Description'],
                ],
                'fields' => [
                    ['key' => 'emp_percentage', 'label' => 'Employee %', 'type' => 'number', 'default' => '1'],
                    ['key' => 'org_percentage', 'label' => 'Employer %', 'type' => 'number', 'default' => '6'],
                    ['key' => 'emp_amount', 'label' => 'Employee Amount', 'type' => 'number', 'default' => '0'],
                    ['key' => 'org_amount', 'label' => 'Employer Amount', 'type' => 'number', 'default' => '0'],
                    ['key' => 'description', 'label' => 'Description', 'type' => 'textarea'],
                ],
            ],
            'pf_rates' => [
                'title' => 'PF Rates',
                'table' => 'provident_fund',
                'columns' => [
                    ['key' => 'emp_percentage', 'label' => 'Emp %'],
                    ['key' => 'org_percentage', 'label' => 'Org %'],
                    ['key' => 'emp_amount', 'label' => 'Emp Amt'],
                    ['key' => 'org_amount', 'label' => 'Org Amt'],
                    ['key' => 'description', 'label' => 'Description'],
                ],
                'fields' => [
                    ['key' => 'emp_percentage', 'label' => 'Employee %', 'type' => 'number', 'default' => '0'],
                    ['key' => 'org_percentage', 'label' => 'Employer %', 'type' => 'number', 'default' => '0'],
                    ['key' => 'emp_amount', 'label' => 'Employee Amount', 'type' => 'number', 'default' => '0'],
                    ['key' => 'org_amount', 'label' => 'Employer Amount', 'type' => 'number', 'default' => '0'],
                    ['key' => 'description', 'label' => 'Description', 'type' => 'textarea'],
                ],
            ],
            'final_settlements' => [
                'title' => 'Final Settlement',
                'table' => 'employee_settlements',
                'columns' => [
                    ['key' => 'employee_name', 'label' => 'Employee'],
                    ['key' => 'date_of_joining', 'label' => 'DOJ'],
                    ['key' => 'last_working_date', 'label' => 'LWD'],
                    ['key' => 'total_pf', 'label' => 'Total PF'],
                    ['key' => 'gratuity_amount', 'label' => 'Gratuity'],
                    ['key' => 'outstanding_loan', 'label' => 'Loan'],
                    ['key' => 'net_payable', 'label' => 'Net Payable'],
                    ['key' => 'clearance_status', 'label' => 'Status'],
                ],
                'fields' => [
                    ['key' => 'employee', 'label' => 'Employee', 'type' => 'fk', 'fk' => 'employees', 'required' => true],
                    ['key' => 'date_of_joining', 'label' => 'Date of Joining', 'type' => 'date'],
                    ['key' => 'last_working_date', 'label' => 'Last Working Date', 'type' => 'date'],
                    ['key' => 'employee_pf', 'label' => 'Employee PF', 'type' => 'number', 'default' => '0'],
                    ['key' => 'employer_pf', 'label' => 'Employer PF', 'type' => 'number', 'default' => '0'],
                    ['key' => 'total_pf', 'label' => 'Total PF', 'type' => 'number', 'default' => '0'],
                    ['key' => 'gratuity_eligibility', 'label' => 'Gratuity Eligible', 'type' => 'select', 'options' => ['1' => 'Yes', '0' => 'No'], 'default' => '0'],
                    ['key' => 'gratuity_amount', 'label' => 'Gratuity Amount', 'type' => 'number', 'default' => '0'],
                    ['key' => 'outstanding_loan', 'label' => 'Outstanding Loan', 'type' => 'number', 'default' => '0'],
                    ['key' => 'loan_deduction', 'label' => 'Loan Deduction', 'type' => 'number', 'default' => '0'],
                    ['key' => 'assets_returned', 'label' => 'Assets Returned', 'type' => 'select', 'options' => ['1' => 'Yes', '0' => 'No'], 'default' => '0'],
                    ['key' => 'clearance_status', 'label' => 'Clearance Status', 'type' => 'select', 'options' => ['Pending', 'Cleared', 'Hold'], 'default' => 'Pending'],
                    ['key' => 'total_payable', 'label' => 'Total Payable', 'type' => 'number', 'default' => '0'],
                    ['key' => 'net_payable', 'label' => 'Net Payable', 'type' => 'number', 'default' => '0'],
                ],
                'joins' => [
                    ['table' => 'employee', 'alias' => 'e', 'on' => 'e.employee_id = t.employee', 'select' => 'e.name as employee_name'],
                ],
            ],
        ];
    }

    public static function get(string $key): ?array
    {
        $all = self::all();

        return $all[$key] ?? null;
    }

    public static function resolvePk(array $def): string
    {
        if (!empty($def['pk'])) {
            return $def['pk'];
        }
        $table = $def['table'];
        if (Schema::hasColumn($table, 'id')) {
            return 'id';
        }
        if ($table === 'company' && Schema::hasColumn($table, 'company_id')) {
            return 'company_id';
        }

        return 'id';
    }

    protected static function empLinked(
        string $title,
        string $table,
        array $fields,
        array $columns,
        array $extraJoins = [],
        bool $includeStatus = true
    ): array {
        array_unshift($fields, [
            'key' => 'employee_id',
            'label' => 'Employee',
            'type' => 'fk',
            'fk' => 'employees',
            'required' => true,
        ]);
        $joins = array_merge([
            ['table' => 'employee', 'alias' => 'e', 'on' => 'e.employee_id = t.employee_id', 'select' => 'e.name as employee_name'],
        ], $extraJoins);

        return [
            'title' => $title,
            'table' => $table,
            'columns' => $columns,
            'fields' => $fields,
            'joins' => $joins,
        ];
    }

    protected static function payrollFormula(string $title, string $category): array
    {
        return [
            'title' => $title,
            'table' => 'payroll_setup',
            'filter' => ['category' => $category],
            'search' => ['condition', 'category'],
            'columns' => [
                ['key' => 'item_name', 'label' => 'Payroll Item'],
                ['key' => 'condition', 'label' => 'Type'],
                ['key' => 'amount', 'label' => 'Amount'],
                ['key' => 'category', 'label' => 'Category'],
            ],
            'fields' => [
                ['key' => 'target', 'label' => 'Payroll Item', 'type' => 'fk', 'fk' => 'payroll_items', 'required' => true],
                ['key' => 'condition', 'label' => 'Type', 'type' => 'select', 'options' => [
                    'Fix' => 'Fix',
                    'Percentage' => 'Percentage',
                ], 'default' => 'Percentage'],
                ['key' => 'amount', 'label' => 'Amount / %', 'type' => 'number', 'required' => true],
                ['key' => 'category', 'label' => 'Category', 'type' => 'hidden', 'default' => $category],
            ],
            'joins' => [
                ['table' => 'hr_payroll_item', 'alias' => 'pi', 'on' => 'pi.id = t.target', 'select' => 'pi.name as item_name'],
            ],
        ];
    }

    protected static function payItems(string $title, string $category): array
    {
        return [
            'title' => $title,
            'table' => 'hr_payroll_item',
            'filter' => ['category' => $category],
            'columns' => [
                ['key' => 'code', 'label' => 'Code'],
                ['key' => 'name', 'label' => 'Name'],
                ['key' => 'calc_type', 'label' => 'Calc'],
                ['key' => 'default_value', 'label' => 'Default'],
                ['key' => 'taxable', 'label' => 'Taxable'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'status'],
            ],
            'fields' => [
                ['key' => 'code', 'label' => 'Code', 'type' => 'text'],
                ['key' => 'name', 'label' => 'Name', 'type' => 'text', 'required' => true],
                ['key' => 'category', 'label' => 'Category', 'type' => 'hidden', 'default' => $category],
                ['key' => 'calc_type', 'label' => 'Calc Type', 'type' => 'select', 'options' => ['fixed', 'percent', 'formula'], 'default' => 'fixed'],
                ['key' => 'default_value', 'label' => 'Default Value', 'type' => 'number'],
                ['key' => 'taxable', 'label' => 'Taxable', 'type' => 'select', 'options' => ['1' => 'Yes', '0' => 'No'], 'default' => '1'],
                ['key' => 'status', 'label' => 'Status', 'type' => 'select', 'options' => ['1' => 'Active', '0' => 'Inactive'], 'default' => '1'],
            ],
        ];
    }
}
