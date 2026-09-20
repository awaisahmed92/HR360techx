<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;

class EmployeeController extends Controller
{
    /** Scalar columns we accept on create/update (when present on table). */
    protected array $scalarFields = [
        'name', 'surname', 'father_name', 'husband_name', 'user_name', 'email', 'cnic',
        'employee_code', 'status', 'gender', 'date_of_birth', 'contact_number', 'phone',
        'religion', 'blood_group', 'marital_status', 'address',
        'designation', 'department', 'station', 'project', 'line_manager', 'employee_type', 'payroll_type',
        'joining_date', 'probation_end_date', 'contract_start_date', 'contract_end_date', 'leaving_date', 'exit_date',
        'eobi', 'sessi',
        'bnk_title', 'bnk_number', 'bnk_bank_id', 'bnk_code', 'bnk_address',
        'emg_name', 'emg_relationship', 'emg_phone', 'emg_phone2', 'emg_email',
        'fam_name', 'fam_relationship', 'fam_date_of_birth', 'fam_phone',
        'total_experience', 'profile_picture',
        // Extended WebHR parity
        'personal_email', 'salutation', 'preferred_name', 'nickname', 'pronoun',
        'nationality', 'race', 'home_phone', 'office_phone', 'mobile_number',
        'passport_number', 'passport_expiry', 'passport_country',
        'driving_license', 'driving_license_expiry',
        'ssn', 'ssn_expiry', 'ein', 'calculated_service_date',
        'company_id', 'division_id', 'work_shift_id', 'grade', 'grade_step', 'employee_category',
        'supervisor_id', 'allow_mobile_login', 'show_in_organogram', 'exclude_from_reports',
        'not_actively_working', 'not_actively_reason', 'notify_by_email',
        'visa_sponsorship', 'notes',
        'permanent_address', 'permanent_city', 'permanent_province', 'permanent_postal', 'permanent_country',
        'weekday_same_as_permanent', 'weekday_address', 'weekday_city', 'weekday_province', 'weekday_postal', 'weekday_country',
    ];

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

        if (Schema::hasColumn('employee', 'surname')) {
            $query->addSelect('e.surname');
            $query->addSelect('m.surname as reports_to_surname');
        }

        if (Schema::hasColumn('employee', 'gender')) {
            $query->addSelect('e.gender');
        }
        if (Schema::hasColumn('employee', 'joining_date')) {
            $query->addSelect('e.joining_date');
        }

        if ($q !== '') {
            $like = '%'.$q.'%';
            $query->where(function ($w) use ($like) {
                $w->where('e.name', 'like', $like)
                    ->orWhere('e.user_name', 'like', $like)
                    ->orWhere('e.email', 'like', $like)
                    ->orWhere('e.employee_code', 'like', $like);
                if (Schema::hasColumn('employee', 'cnic')) {
                    $w->orWhere('e.cnic', 'like', $like);
                }
            });
        }
        if ($status !== null && $status !== '') {
            $query->where('e.status', (int) $status);
        }

        $rows = $query->orderBy('e.name')->limit(500)->get()->map(fn ($r) => $this->mapListRow($r));

        return response()->json(['success' => true, 'rows' => $rows]);
    }

    public function show(int $id)
    {
        $emp = DB::table('employee')->where('employee_id', $id)->first();
        if (!$emp) {
            return response()->json(['success' => false, 'message' => 'Employee not found.'], 404);
        }

        return response()->json([
            'success' => true,
            'employee' => $this->mapFullEmployee($emp),
            'education' => $this->listEducation($id),
            'experience' => $this->listExperience($id),
            'dependents' => $this->listDependents($id),
        ]);
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
            'stats' => compact('total', 'active', 'inactive', 'male', 'female'),
        ]);
    }

    public function meta()
    {
        try {
            return $this->buildMeta();
        } catch (\Throwable $e) {
            report($e);

            return response()->json([
                'success' => false,
                'message' => 'Employee meta failed: '.$e->getMessage(),
            ], 500);
        }
    }

    protected function buildMeta()
    {
        $fk = function (string $table, string $pk, string $label = 'name') {
            if (!Schema::hasTable($table) || !Schema::hasColumn($table, $pk) || !Schema::hasColumn($table, $label)) {
                return [];
            }

            return DB::table($table)->orderBy($label)->get([$pk, $label])->map(fn ($r) => [
                'id' => (int) $r->{$pk},
                'name' => (string) $r->{$label},
            ])->values()->all();
        };

        $managers = [];
        if (Schema::hasTable('employee') && Schema::hasColumn('employee', 'employee_id')) {
            $cols = ['employee_id', 'name', 'user_name'];
            if (Schema::hasColumn('employee', 'surname')) {
                $cols[] = 'surname';
            }
            $q = DB::table('employee');
            if (Schema::hasColumn('employee', 'status')) {
                $q->where('status', '>', 0);
            }
            $managers = $q->orderBy('name')->get($cols)->map(fn ($r) => [
                'id' => (int) $r->employee_id,
                'name' => UiPrefsController::displayName($r),
                'user_name' => (string) ($r->user_name ?? ''),
            ])->values()->all();
        }

        $companies = [];
        if (Schema::hasTable('company')) {
            $companies = DB::table('company')->orderBy('id')->get()->map(fn ($r) => [
                'id' => (int) $r->id,
                'name' => (string) ($r->hr_company_name ?? $r->name ?? 'Company'),
            ])->values()->all();
        }

        return response()->json([
            'success' => true,
            'options' => [
                'designations' => $fk('designation', 'designation_id'),
                'departments' => $fk('department', 'department_id'),
                'stations' => $fk('station', 'station_id'),
                'projects' => $fk('project', 'project_id'),
                'managers' => $managers,
                'employee_types' => $fk('employee_type', 'id'),
                'employee_categories' => $fk('employee_category', 'id'),
                'degrees' => $fk('degree', 'degree_id'),
                'banks' => $fk('banklist', 'id'),
                'companies' => $companies,
                'divisions' => $fk('hr_org_division', 'id'),
                'work_shifts' => $fk('hr_work_shift', 'id'),
                'statuses' => [
                    ['id' => 1, 'name' => 'Active'],
                    ['id' => 0, 'name' => 'Inactive'],
                    ['id' => 2, 'name' => 'Admin (all access)'],
                ],
                'genders' => [
                    ['id' => 1, 'name' => 'Male'],
                    ['id' => 2, 'name' => 'Female'],
                    ['id' => 3, 'name' => 'Other'],
                ],
                'marital_statuses' => [
                    ['id' => 'Single', 'name' => 'Single'],
                    ['id' => 'Married', 'name' => 'Married'],
                    ['id' => 'Divorced', 'name' => 'Divorced'],
                    ['id' => 'Widowed', 'name' => 'Widowed'],
                ],
                'blood_groups' => [
                    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
                ],
                'payroll_types' => [
                    ['id' => 1, 'name' => 'Shared'],
                    ['id' => 2, 'name' => 'Project Wise'],
                ],
                'salutations' => ['Mr', 'Mrs', 'Ms', 'Miss', 'Dr', 'Eng'],
                'pronouns' => ['He/Him', 'She/Her', 'They/Them', 'Prefer not to say'],
                'visa_options' => ['Not Required', 'Sponsored', 'Self', 'Pending'],
            ],
            'role_catalog' => $this->roleCatalog(),
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'nullable|string|max:191',
            'surname' => 'required|string|max:191',
            'user_name' => 'nullable|string|max:100',
            'employee_code' => 'required|string|max:50',
            'password' => 'required|string|min:1',
            'email' => 'required|email|max:191',
            'date_of_birth' => 'required|date',
        ]);

        $identity = $this->allocateIdentity(
            $request->input('user_name') ?: $data['employee_code'],
            $data['employee_code']
        );
        $userName = $identity['user_name'];
        if (DB::table('employee')->where('user_name', $userName)->exists()) {
            return response()->json(['success' => false, 'message' => 'Employee Code / username already exists.'], 422);
        }
        if (Schema::hasColumn('employee', 'employee_code')
            && DB::table('employee')->where('employee_code', $identity['employee_code'])->exists()) {
            return response()->json(['success' => false, 'message' => 'Employee Code already exists.'], 422);
        }

        $row = $this->buildRow($request, null);
        $row['user_name'] = $userName;
        if (Schema::hasColumn('employee', 'employee_code')) {
            $row['employee_code'] = $identity['employee_code'];
        }
        if (Schema::hasColumn('employee', 'address') && $request->filled('permanent_address')) {
            $row['address'] = trim((string) $request->input('permanent_address'));
        }
        $first = trim((string) ($data['name'] ?? ''));
        $last = trim((string) $data['surname']);
        $row['name'] = $first !== '' ? $first : $last;
        $row['surname'] = $last;
        $row['email'] = $data['email'];
        $row['date_of_birth'] = $data['date_of_birth'];
        $row['password'] = Hash::make($data['password']);
        $row['is_first_login'] = 0;
        if (Schema::hasColumn('employee', 'created_by')) {
            $claims = $request->attributes->get('hr_claims') ?? [];
            $row['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
        }
        if ($request->boolean('allow_login') === false) {
            $row['status'] = 0;
        }

        $id = (int) DB::table('employee')->insertGetId($row);
        $this->syncChildren($id, $request);

        return response()->json([
            'success' => true,
            'employee_id' => $id,
            'user_name' => $userName,
            'employee_code' => $identity['employee_code'],
            'message' => 'Employee created.',
        ]);
    }

    public function update(Request $request, int $id)
    {
        $emp = DB::table('employee')->where('employee_id', $id)->first();
        if (!$emp) {
            return response()->json(['success' => false, 'message' => 'Employee not found.'], 404);
        }

        $data = $request->validate([
            'name' => 'nullable|string|max:191',
            'surname' => 'required|string|max:191',
            'user_name' => 'nullable|string|max:100',
            'employee_code' => 'required|string|max:50',
            'password' => 'nullable|string|min:1',
            'email' => 'required|email|max:191',
            'date_of_birth' => 'required|date',
        ]);

        // Employee ID (login) is system-owned — keep existing.
        $userName = (string) ($emp->user_name ?? '');
        if ($userName === '') {
            $userName = $this->allocateIdentity(null, $data['employee_code'])['user_name'];
        }

        if (Schema::hasColumn('employee', 'employee_code')) {
            $codeDup = DB::table('employee')
                ->where('employee_code', $data['employee_code'])
                ->where('employee_id', '!=', $id)
                ->exists();
            if ($codeDup) {
                return response()->json(['success' => false, 'message' => 'Employee Code already exists.'], 422);
            }
        }

        $row = $this->buildRow($request, $emp);
        $row['user_name'] = $userName;
        if (Schema::hasColumn('employee', 'employee_code')) {
            $row['employee_code'] = $data['employee_code'];
        }
        if (Schema::hasColumn('employee', 'address') && $request->filled('permanent_address')) {
            $row['address'] = trim((string) $request->input('permanent_address'));
        }
        $first = trim((string) ($data['name'] ?? ''));
        $last = trim((string) $data['surname']);
        $row['name'] = $first !== '' ? $first : $last;
        $row['surname'] = $last;
        $row['email'] = $data['email'];
        $row['date_of_birth'] = $data['date_of_birth'];
        if ($request->filled('password')) {
            $row['password'] = Hash::make((string) $request->input('password'));
        }
        if ($request->has('allow_login') && $request->boolean('allow_login') === false) {
            $row['status'] = 0;
        }

        DB::table('employee')->where('employee_id', $id)->update($row);
        $this->syncChildren($id, $request);

        return response()->json(['success' => true, 'message' => 'Employee updated.']);
    }

    /** Preview next auto Employee ID / code. */
    public function nextCode()
    {
        $identity = $this->allocateIdentity(null, null);

        return response()->json([
            'success' => true,
            'user_name' => $identity['user_name'],
            'employee_code' => $identity['employee_code'],
        ]);
    }

    /**
     * @return array{user_name: string, employee_code: string}
     */
    protected function allocateIdentity(?string $requestedUser, ?string $requestedCode): array
    {
        $requestedUser = trim((string) $requestedUser);
        $requestedCode = trim((string) $requestedCode);
        if ($requestedUser !== '') {
            $code = $requestedCode !== '' ? $requestedCode : $requestedUser;

            return ['user_name' => $requestedUser, 'employee_code' => $code];
        }

        $next = ((int) DB::table('employee')->max('employee_id')) + 1;
        do {
            $code = 'EMP-'.str_pad((string) $next, 4, '0', STR_PAD_LEFT);
            $exists = DB::table('employee')->where(function ($q) use ($code) {
                $q->where('user_name', $code);
                if (Schema::hasColumn('employee', 'employee_code')) {
                    $q->orWhere('employee_code', $code);
                }
            })->exists();
            if (!$exists) {
                return ['user_name' => $code, 'employee_code' => $code];
            }
            $next++;
        } while ($next < 999999);

        $fallback = 'EMP-'.uniqid();

        return ['user_name' => $fallback, 'employee_code' => $fallback];
    }

    public function destroy(int $id)
    {
        $emp = DB::table('employee')->where('employee_id', $id)->first();
        if (!$emp) {
            return response()->json(['success' => false, 'message' => 'Employee not found.'], 404);
        }
        if (Schema::hasTable('education')) {
            DB::table('education')->where('employee_id', $id)->delete();
        }
        if (Schema::hasTable('experience')) {
            DB::table('experience')->where('employee_id', $id)->delete();
        }
        if (Schema::hasTable('dependents')) {
            DB::table('dependents')->where('employee_id', $id)->delete();
        }
        DB::table('employee')->where('employee_id', $id)->delete();

        return response()->json(['success' => true, 'message' => 'Employee deleted.']);
    }

    public function leaveAssignments(int $id)
    {
        if (!Schema::hasTable('leave') || !Schema::hasColumn('leave', 'assigned')) {
            return response()->json(['success' => true, 'assignments' => []]);
        }
        $rows = DB::table('leave as l')
            ->leftJoin('leave_type as lt', 'lt.id', '=', 'l.leave_type')
            ->where('l.employee', $id)
            ->where('l.assigned', '>', 0)
            ->orderBy('l.id')
            ->get(['l.id', 'l.leave_type', 'l.assigned', 'lt.name as leave_type_name'])
            ->map(fn ($r) => [
                'id' => (int) $r->id,
                'leave_type_id' => (int) $r->leave_type,
                'leave_type_name' => (string) ($r->leave_type_name ?? ''),
                'assigned' => (float) $r->assigned,
            ]);

        return response()->json(['success' => true, 'assignments' => $rows]);
    }

    public function saveLeaveAssignments(Request $request, int $id)
    {
        $emp = DB::table('employee')->where('employee_id', $id)->first();
        if (!$emp) {
            return response()->json(['success' => false, 'message' => 'Employee not found.'], 404);
        }
        if (!Schema::hasColumn('leave', 'assigned')) {
            return response()->json(['success' => false, 'message' => 'Run database/18_leave_threshold_assign.sql'], 503);
        }

        $data = $request->validate([
            'assignments' => 'required|array',
            'assignments.*.leave_type_id' => 'required|integer',
            'assignments.*.assigned' => 'required|numeric|min:0',
        ]);

        $claims = $request->attributes->get('hr_claims') ?? [];
        $actor = (int) ($claims['employee_id'] ?? 0) ?: null;

        // Replace quota rows (assigned > 0)
        DB::table('leave')->where('employee', $id)->where('assigned', '>', 0)->delete();

        foreach ($data['assignments'] as $a) {
            $days = (float) $a['assigned'];
            if ($days <= 0) {
                continue;
            }
            DB::table('leave')->insert([
                'leave_type' => (int) $a['leave_type_id'],
                'employee' => $id,
                'from' => now()->toDateString(),
                'to' => now()->toDateString(),
                'days' => 0,
                'assigned' => $days,
                'reason' => 'Assigned leave quota',
                'status' => 1,
                'date' => now(),
                'added_by' => $actor,
            ]);
        }

        return $this->leaveAssignments($id);
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

        $data = $request->validate(['permissions' => 'required|array']);
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

    protected function buildRow(Request $request, ?object $existing): array
    {
        $row = [];
        foreach ($this->scalarFields as $key) {
            if ($key === 'address' || $key === 'user_name') {
                // address synced from permanent_address; user_name is system-generated
                continue;
            }
            if (!Schema::hasColumn('employee', $key)) {
                continue;
            }
            if (!$request->has($key) && $existing !== null) {
                continue;
            }
            if (!$request->has($key)) {
                continue;
            }
            $val = $request->input($key);
            if ($val === '' || $val === 'null') {
                $val = null;
            }
            if (in_array($key, [
                'status', 'gender', 'designation', 'department', 'station', 'project',
                'line_manager', 'employee_type', 'payroll_type', 'bnk_bank_id',
            ], true)) {
                $row[$key] = $val === null ? null : (int) $val;
            } else {
                $row[$key] = is_string($val) ? trim($val) : $val;
            }
        }
        if (!isset($row['employee_code']) && $request->filled('user_name')) {
            if (Schema::hasColumn('employee', 'employee_code')) {
                $row['employee_code'] = $request->input('employee_code') ?: $request->input('user_name');
            }
        }
        // Map contact_number ↔ phone
        if (isset($row['contact_number']) && Schema::hasColumn('employee', 'phone') && empty($row['phone'])) {
            $row['phone'] = $row['contact_number'];
        }
        if (isset($row['phone']) && Schema::hasColumn('employee', 'contact_number') && empty($row['contact_number'])) {
            $row['contact_number'] = $row['phone'];
        }

        return $row;
    }

    protected function syncChildren(int $employeeId, Request $request): void
    {
        if ($request->has('education') && Schema::hasTable('education')) {
            DB::table('education')->where('employee_id', $employeeId)->delete();
            foreach ((array) $request->input('education', []) as $edu) {
                if (!is_array($edu)) {
                    continue;
                }
                if (empty($edu['institute']) && empty($edu['degree_id']) && empty($edu['field'])) {
                    continue;
                }
                DB::table('education')->insert([
                    'employee_id' => $employeeId,
                    'degree_id' => !empty($edu['degree_id']) ? (int) $edu['degree_id'] : null,
                    'institute' => $edu['institute'] ?? null,
                    'field' => $edu['field'] ?? null,
                    'from' => $edu['from'] ?? null,
                    'to' => $edu['to'] ?? null,
                    'grade' => $edu['grade'] ?? null,
                ]);
            }
        }

        if ($request->has('experience') && Schema::hasTable('experience')) {
            DB::table('experience')->where('employee_id', $employeeId)->delete();
            foreach ((array) $request->input('experience', []) as $exp) {
                if (!is_array($exp)) {
                    continue;
                }
                if (empty($exp['company']) && empty($exp['position'])) {
                    continue;
                }
                DB::table('experience')->insert([
                    'employee_id' => $employeeId,
                    'company' => $exp['company'] ?? null,
                    'location' => $exp['location'] ?? null,
                    'position' => $exp['position'] ?? null,
                    'from' => $exp['from'] ?? null,
                    'to' => $exp['to'] ?? null,
                    'reason' => $exp['reason'] ?? null,
                ]);
            }
        }

        if ($request->has('dependents') && Schema::hasTable('dependents')) {
            DB::table('dependents')->where('employee_id', $employeeId)->delete();
            foreach ((array) $request->input('dependents', []) as $dep) {
                if (!is_array($dep) || empty($dep['name'])) {
                    continue;
                }
                DB::table('dependents')->insert([
                    'employee_id' => $employeeId,
                    'name' => $dep['name'],
                    'relationship' => $dep['relationship'] ?? null,
                    'cnic' => $dep['cnic'] ?? null,
                ]);
            }
        }
    }

    protected function mapListRow(object $r): array
    {
        $reports = UiPrefsController::displayName((object) [
            'name' => $r->reports_to ?? '',
            'surname' => $r->reports_to_surname ?? '',
        ]);

        return [
            'employee_id' => (int) $r->employee_id,
            'name' => UiPrefsController::displayName($r),
            'surname' => trim((string) ($r->surname ?? '')),
            'user_name' => (string) ($r->user_name ?? ''),
            'email' => (string) ($r->email ?? ''),
            'status' => (int) ($r->status ?? 0),
            'gender' => isset($r->gender) ? (int) $r->gender : null,
            'employee_code' => (string) ($r->employee_code ?? ''),
            'profile_picture' => $r->profile_picture ?? null,
            'job_title' => (string) ($r->job_title ?? ''),
            'department_name' => (string) ($r->department_name ?? ''),
            'station_name' => (string) ($r->station_name ?? ''),
            'reports_to' => $reports,
            'designation' => (int) ($r->designation ?? 0),
            'department' => (int) ($r->department ?? 0),
            'station' => (int) ($r->station ?? 0),
            'project' => (int) ($r->project ?? 0),
            'line_manager' => (int) ($r->line_manager ?? 0),
            'joining_date' => $r->joining_date ?? null,
        ];
    }

    protected function mapFullEmployee(object $emp): array
    {
        $out = ['employee_id' => (int) $emp->employee_id];
        foreach ($this->scalarFields as $key) {
            if (property_exists($emp, $key) || Schema::hasColumn('employee', $key)) {
                $out[$key] = $emp->{$key} ?? null;
            }
        }
        $out['status'] = (int) ($emp->status ?? 0);
        foreach (['gender', 'designation', 'department', 'station', 'project', 'line_manager', 'employee_type', 'payroll_type', 'bnk_bank_id', 'company_id', 'division_id', 'work_shift_id', 'supervisor_id', 'allow_mobile_login', 'show_in_organogram', 'exclude_from_reports', 'not_actively_working', 'notify_by_email', 'weekday_same_as_permanent'] as $intKey) {
            if (array_key_exists($intKey, $out) && $out[$intKey] !== null) {
                $out[$intKey] = (int) $out[$intKey];
            }
        }

        return $out;
    }

    protected function listEducation(int $employeeId): array
    {
        if (!Schema::hasTable('education')) {
            return [];
        }

        return DB::table('education')->where('employee_id', $employeeId)->orderBy('id')->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'degree_id' => $r->degree_id ? (int) $r->degree_id : null,
            'institute' => (string) ($r->institute ?? ''),
            'field' => (string) ($r->field ?? ''),
            'from' => $r->from,
            'to' => $r->to,
            'grade' => (string) ($r->grade ?? ''),
        ])->all();
    }

    protected function listExperience(int $employeeId): array
    {
        if (!Schema::hasTable('experience')) {
            return [];
        }

        return DB::table('experience')->where('employee_id', $employeeId)->orderBy('id')->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'company' => (string) ($r->company ?? ''),
            'location' => (string) ($r->location ?? ''),
            'position' => (string) ($r->position ?? ''),
            'from' => $r->from,
            'to' => $r->to,
            'reason' => (string) ($r->reason ?? ''),
        ])->all();
    }

    protected function listDependents(int $employeeId): array
    {
        if (!Schema::hasTable('dependents')) {
            return [];
        }

        return DB::table('dependents')->where('employee_id', $employeeId)->orderBy('id')->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'name' => (string) ($r->name ?? ''),
            'relationship' => (string) ($r->relationship ?? ''),
            'cnic' => (string) ($r->cnic ?? ''),
        ])->all();
    }

    protected function roleCatalog(): array
    {
        return [
            ['key' => 'general', 'label' => 'General Roles', 'screens' => [
                ['key' => 'profile', 'label' => 'Profile'],
                ['key' => 'settings', 'label' => 'Account Settings'],
            ]],
            ['key' => 'dashboard', 'label' => 'Dashboard', 'screens' => [
                ['key' => 'my_dashboard', 'label' => 'My Dashboard'],
                ['key' => 'hr_dashboard', 'label' => 'HR Dashboard'],
            ]],
            ['key' => 'organization', 'label' => 'Organization Module', 'screens' => [
                ['key' => 'companies', 'label' => 'Companies'],
                ['key' => 'departments', 'label' => 'Departments'],
                ['key' => 'designations', 'label' => 'Job Titles'],
                ['key' => 'stations', 'label' => 'Stations'],
            ]],
            ['key' => 'employees', 'label' => 'Employees Module', 'screens' => [
                ['key' => 'employees', 'label' => 'Employees'],
                ['key' => 'employee_roles', 'label' => 'Employee Roles'],
                ['key' => 'onboarding', 'label' => 'Onboarding'],
                ['key' => 'contracts', 'label' => 'Contracts'],
            ]],
            ['key' => 'timesheet', 'label' => 'Timesheet Module', 'screens' => [
                ['key' => 'attendance', 'label' => 'Attendance'],
                ['key' => 'leave', 'label' => 'Leaves'],
                ['key' => 'timesheet', 'label' => 'Timesheet'],
            ]],
            ['key' => 'payroll', 'label' => 'Payroll', 'screens' => [
                ['key' => 'payroll_setup', 'label' => 'Payroll Setup'],
                ['key' => 'payroll_define', 'label' => 'Define Salary'],
                ['key' => 'payroll_process', 'label' => 'Process Salary'],
            ]],
            ['key' => 'reports', 'label' => 'Reports', 'screens' => [
                ['key' => 'reports', 'label' => 'Reports'],
            ]],
            ['key' => 'other', 'label' => 'Other Modules', 'screens' => [
                ['key' => 'travel', 'label' => 'Travel'],
                ['key' => 'approvals', 'label' => 'Approvals'],
            ]],
            ['key' => 'calendar', 'label' => 'Calendar', 'screens' => [
                ['key' => 'calendar', 'label' => 'Calendar'],
            ]],
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
            $entry = ['roll' => !empty($data['enabled']) ? '1' : '0'];
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
