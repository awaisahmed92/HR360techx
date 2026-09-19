<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;

class EmployeeController extends Controller
{
    public function index(Request $request)
    {
        $q = trim((string) $request->query('q', ''));
        $status = $request->query('status');

        $query = DB::table('employee as e')
            ->leftJoin('designation as d', 'd.designation_id', '=', 'e.designation')
            ->leftJoin('department as dep', 'dep.department_id', '=', 'e.department')
            ->leftJoin('station as s', 's.station_id', '=', 'e.station')
            ->leftJoin('employee as m', 'm.employee_id', '=', 'e.line_manager')
            ->select([
                'e.employee_id',
                'e.name',
                'e.user_name',
                'e.email',
                'e.status',
                'e.employee_code',
                'e.profile_picture',
                'e.designation',
                'e.department',
                'e.station',
                'e.project',
                'e.line_manager',
                'd.name as job_title',
                'dep.name as department_name',
                's.name as station_name',
                'm.name as reports_to',
            ]);

        if (Schema::hasColumn('employee', 'gender')) {
            $query->addSelect('e.gender');
        }

        if ($q !== '') {
            $like = '%'.$q.'%';
            $query->where(function ($w) use ($like) {
                $w->where('e.name', 'like', $like)
                    ->orWhere('e.user_name', 'like', $like)
                    ->orWhere('e.email', 'like', $like)
                    ->orWhere('e.employee_code', 'like', $like);
            });
        }
        if ($status !== null && $status !== '') {
            $query->where('e.status', (int) $status);
        }

        $rows = $query->orderBy('e.name')->limit(500)->get()->map(function ($r) {
            return [
                'employee_id' => (int) $r->employee_id,
                'name' => (string) $r->name,
                'user_name' => (string) ($r->user_name ?? ''),
                'email' => (string) ($r->email ?? ''),
                'status' => (int) ($r->status ?? 0),
                'gender' => isset($r->gender) ? (int) $r->gender : null,
                'employee_code' => (string) ($r->employee_code ?? ''),
                'profile_picture' => $r->profile_picture,
                'job_title' => (string) ($r->job_title ?? ''),
                'department_name' => (string) ($r->department_name ?? ''),
                'station_name' => (string) ($r->station_name ?? ''),
                'reports_to' => (string) ($r->reports_to ?? ''),
                'designation' => (int) ($r->designation ?? 0),
                'department' => (int) ($r->department ?? 0),
                'station' => (int) ($r->station ?? 0),
                'project' => (int) ($r->project ?? 0),
                'line_manager' => (int) ($r->line_manager ?? 0),
            ];
        });

        return response()->json(['success' => true, 'rows' => $rows]);
    }

    public function stats()
    {
        $total = (int) DB::table('employee')->count();
        $active = (int) DB::table('employee')->where('status', '>', 0)->count();
        $inactive = (int) DB::table('employee')->where('status', 0)->count();
        $male = 0;
        $female = 0;
        if (Schema::hasColumn('employee', 'gender')) {
            $male = (int) DB::table('employee')->where('gender', 1)->count();
            $female = (int) DB::table('employee')->where('gender', 2)->count();
        }

        return response()->json([
            'success' => true,
            'stats' => [
                'total' => $total,
                'active' => $active,
                'inactive' => $inactive,
                'male' => $male,
                'female' => $female,
            ],
        ]);
    }

    public function meta()
    {
        $fk = function (string $table, string $pk, string $label = 'name') {
            if (!Schema::hasTable($table)) {
                return [];
            }

            return DB::table($table)->orderBy($label)->get([$pk, $label])->map(fn ($r) => [
                'id' => (int) $r->{$pk},
                'name' => (string) $r->{$label},
            ])->values()->all();
        };

        $managers = DB::table('employee')
            ->where('status', '>', 0)
            ->orderBy('name')
            ->get(['employee_id', 'name', 'user_name'])
            ->map(fn ($r) => [
                'id' => (int) $r->employee_id,
                'name' => (string) $r->name,
                'user_name' => (string) ($r->user_name ?? ''),
            ])->values()->all();

        return response()->json([
            'success' => true,
            'options' => [
                'designations' => $fk('designation', 'designation_id'),
                'departments' => $fk('department', 'department_id'),
                'stations' => $fk('station', 'station_id'),
                'projects' => $fk('project', 'project_id'),
                'managers' => $managers,
                'statuses' => [
                    ['id' => 1, 'name' => 'Active'],
                    ['id' => 0, 'name' => 'Inactive'],
                    ['id' => 2, 'name' => 'Admin (all access)'],
                ],
                'genders' => [
                    ['id' => 1, 'name' => 'Male'],
                    ['id' => 2, 'name' => 'Female'],
                ],
            ],
            'role_catalog' => $this->roleCatalog(),
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:191',
            'user_name' => 'required|string|max:100',
            'email' => 'nullable|email|max:191',
            'password' => 'required|string|min:4',
            'employee_code' => 'nullable|string|max:50',
            'status' => 'nullable|integer',
            'gender' => 'nullable|integer',
            'designation' => 'nullable|integer',
            'department' => 'nullable|integer',
            'station' => 'nullable|integer',
            'project' => 'nullable|integer',
            'line_manager' => 'nullable|integer',
            'profile_picture' => 'nullable|string|max:255',
            'allow_login' => 'nullable|boolean',
        ]);

        $userName = trim($data['user_name']);
        if (DB::table('employee')->where('user_name', $userName)->exists()) {
            return response()->json(['success' => false, 'message' => 'Employee ID / username already exists.'], 422);
        }

        $row = [
            'name' => trim($data['name']),
            'user_name' => $userName,
            'email' => $data['email'] ?? null,
            'password' => Hash::make($data['password']),
            'status' => (int) ($data['status'] ?? 1),
            'designation' => !empty($data['designation']) ? (int) $data['designation'] : null,
            'department' => !empty($data['department']) ? (int) $data['department'] : null,
            'station' => !empty($data['station']) ? (int) $data['station'] : null,
            'project' => !empty($data['project']) ? (int) $data['project'] : null,
            'line_manager' => !empty($data['line_manager']) ? (int) $data['line_manager'] : null,
            'employee_code' => $data['employee_code'] ?? $userName,
            'profile_picture' => $data['profile_picture'] ?? null,
            'is_first_login' => 0,
        ];

        if (isset($data['allow_login']) && $data['allow_login'] === false) {
            $row['status'] = 0;
        }
        if (Schema::hasColumn('employee', 'gender') && isset($data['gender'])) {
            $row['gender'] = (int) $data['gender'];
        }

        $id = DB::table('employee')->insertGetId($row);

        return response()->json(['success' => true, 'employee_id' => $id, 'message' => 'Employee created.']);
    }

    public function update(Request $request, int $id)
    {
        $emp = DB::table('employee')->where('employee_id', $id)->first();
        if (!$emp) {
            return response()->json(['success' => false, 'message' => 'Employee not found.'], 404);
        }

        $data = $request->validate([
            'name' => 'required|string|max:191',
            'user_name' => 'required|string|max:100',
            'email' => 'nullable|email|max:191',
            'password' => 'nullable|string|min:4',
            'employee_code' => 'nullable|string|max:50',
            'status' => 'nullable|integer',
            'gender' => 'nullable|integer',
            'designation' => 'nullable|integer',
            'department' => 'nullable|integer',
            'station' => 'nullable|integer',
            'project' => 'nullable|integer',
            'line_manager' => 'nullable|integer',
            'profile_picture' => 'nullable|string|max:255',
        ]);

        $userName = trim($data['user_name']);
        $dup = DB::table('employee')
            ->where('user_name', $userName)
            ->where('employee_id', '!=', $id)
            ->exists();
        if ($dup) {
            return response()->json(['success' => false, 'message' => 'Employee ID / username already exists.'], 422);
        }

        $row = [
            'name' => trim($data['name']),
            'user_name' => $userName,
            'email' => $data['email'] ?? null,
            'status' => (int) ($data['status'] ?? $emp->status),
            'designation' => !empty($data['designation']) ? (int) $data['designation'] : null,
            'department' => !empty($data['department']) ? (int) $data['department'] : null,
            'station' => !empty($data['station']) ? (int) $data['station'] : null,
            'project' => !empty($data['project']) ? (int) $data['project'] : null,
            'line_manager' => !empty($data['line_manager']) ? (int) $data['line_manager'] : null,
            'employee_code' => $data['employee_code'] ?? $emp->employee_code,
            'profile_picture' => $data['profile_picture'] ?? $emp->profile_picture,
        ];
        if (!empty($data['password'])) {
            $row['password'] = Hash::make($data['password']);
        }
        if (Schema::hasColumn('employee', 'gender') && array_key_exists('gender', $data)) {
            $row['gender'] = $data['gender'] !== null ? (int) $data['gender'] : null;
        }

        DB::table('employee')->where('employee_id', $id)->update($row);

        return response()->json(['success' => true, 'message' => 'Employee updated.']);
    }

    public function roles(int $id)
    {
        $emp = DB::table('employee as e')
            ->leftJoin('designation as d', 'd.designation_id', '=', 'e.designation')
            ->where('e.employee_id', $id)
            ->first(['e.employee_id', 'e.name', 'e.user_name', 'e.rolls', 'd.rolls as designation_rolls', 'd.name as job_title']);

        if (!$emp) {
            return response()->json(['success' => false, 'message' => 'Employee not found.'], 404);
        }

        $raw = null;
        if (Schema::hasColumn('employee', 'rolls') && !empty($emp->rolls)) {
            $raw = $emp->rolls;
        } elseif (!empty($emp->designation_rolls)) {
            $raw = $emp->designation_rolls;
        }

        $rolls = [];
        if ($raw) {
            $parsed = @unserialize($raw);
            if (is_array($parsed)) {
                $rolls = $parsed;
            }
        }

        return response()->json([
            'success' => true,
            'employee' => [
                'employee_id' => (int) $emp->employee_id,
                'name' => (string) $emp->name,
                'user_name' => (string) ($emp->user_name ?? ''),
                'job_title' => (string) ($emp->job_title ?? ''),
            ],
            'permissions' => $this->normalizeRolls($rolls),
            'role_catalog' => $this->roleCatalog(),
        ]);
    }

    public function saveRoles(Request $request, int $id)
    {
        $emp = DB::table('employee')->where('employee_id', $id)->first();
        if (!$emp) {
            return response()->json(['success' => false, 'message' => 'Employee not found.'], 404);
        }

        $data = $request->validate([
            'permissions' => 'required|array',
        ]);

        $rolls = $this->denormalizeRolls($data['permissions']);
        $serialized = serialize($rolls);

        if (Schema::hasColumn('employee', 'rolls')) {
            DB::table('employee')->where('employee_id', $id)->update(['rolls' => $serialized]);
        } elseif (!empty($emp->designation)) {
            DB::table('designation')->where('designation_id', $emp->designation)->update(['rolls' => $serialized]);
        } else {
            return response()->json([
                'success' => false,
                'message' => 'Cannot save roles — run database/12_employee_module.sql or assign a job title.',
            ], 422);
        }

        return response()->json(['success' => true, 'message' => 'Roles saved.']);
    }

    protected function roleCatalog(): array
    {
        return [
            [
                'key' => 'general',
                'label' => 'General Roles',
                'screens' => [
                    ['key' => 'profile', 'label' => 'Profile'],
                    ['key' => 'settings', 'label' => 'Account Settings'],
                ],
            ],
            [
                'key' => 'dashboard',
                'label' => 'Dashboard',
                'screens' => [
                    ['key' => 'my_dashboard', 'label' => 'My Dashboard'],
                    ['key' => 'hr_dashboard', 'label' => 'HR Dashboard'],
                ],
            ],
            [
                'key' => 'organization',
                'label' => 'Organization Module',
                'screens' => [
                    ['key' => 'companies', 'label' => 'Companies'],
                    ['key' => 'departments', 'label' => 'Departments'],
                    ['key' => 'designations', 'label' => 'Job Titles'],
                    ['key' => 'stations', 'label' => 'Stations'],
                ],
            ],
            [
                'key' => 'employees',
                'label' => 'Employees Module',
                'screens' => [
                    ['key' => 'employees', 'label' => 'Employees'],
                    ['key' => 'employee_roles', 'label' => 'Employee Roles'],
                    ['key' => 'onboarding', 'label' => 'Onboarding'],
                    ['key' => 'contracts', 'label' => 'Contracts'],
                ],
            ],
            [
                'key' => 'timesheet',
                'label' => 'Timesheet Module',
                'screens' => [
                    ['key' => 'attendance', 'label' => 'Attendance'],
                    ['key' => 'leave', 'label' => 'Leaves'],
                    ['key' => 'timesheet', 'label' => 'Timesheet'],
                ],
            ],
            [
                'key' => 'payroll',
                'label' => 'Payroll',
                'screens' => [
                    ['key' => 'payroll_setup', 'label' => 'Payroll Setup'],
                    ['key' => 'payroll_define', 'label' => 'Define Salary'],
                    ['key' => 'payroll_process', 'label' => 'Process Salary'],
                ],
            ],
            [
                'key' => 'reports',
                'label' => 'Reports',
                'screens' => [
                    ['key' => 'reports', 'label' => 'Reports'],
                ],
            ],
            [
                'key' => 'other',
                'label' => 'Other Modules',
                'screens' => [
                    ['key' => 'travel', 'label' => 'Travel'],
                    ['key' => 'approvals', 'label' => 'Approvals'],
                ],
            ],
            [
                'key' => 'calendar',
                'label' => 'Calendar',
                'screens' => [
                    ['key' => 'calendar', 'label' => 'Calendar'],
                ],
            ],
        ];
    }

    protected function normalizeRolls(array $rolls): array
    {
        $out = [];
        foreach ($rolls as $module => $data) {
            if (!is_array($data)) {
                continue;
            }
            $entry = [
                'enabled' => !empty($data['roll']) && (string) $data['roll'] === '1',
                'screens' => [],
            ];
            foreach ($data as $screen => $flags) {
                if ($screen === 'roll' || !is_array($flags)) {
                    continue;
                }
                $entry['screens'][$screen] = [
                    'view' => !empty($flags[0]) && (string) $flags[0] === '1',
                    'add' => !empty($flags[1]) && (string) $flags[1] === '1',
                    'edit' => !empty($flags[2]) && (string) $flags[2] === '1',
                    'delete' => !empty($flags[3]) && (string) $flags[3] === '1',
                ];
            }
            $out[$module] = $entry;
        }

        return $out;
    }

    /** @param array<string, mixed> $permissions */
    protected function denormalizeRolls(array $permissions): array
    {
        $rolls = [];
        foreach ($permissions as $module => $data) {
            if (!is_array($data)) {
                continue;
            }
            $entry = [
                'roll' => !empty($data['enabled']) ? '1' : '0',
            ];
            $screens = $data['screens'] ?? [];
            if (is_array($screens)) {
                foreach ($screens as $screen => $flags) {
                    if (!is_array($flags)) {
                        continue;
                    }
                    $entry[$screen] = [
                        !empty($flags['view']) ? '1' : '0',
                        !empty($flags['add']) ? '1' : '0',
                        !empty($flags['edit']) ? '1' : '0',
                        !empty($flags['delete']) ? '1' : '0',
                    ];
                }
            }
            $rolls[$module] = $entry;
        }

        return $rolls;
    }
}
