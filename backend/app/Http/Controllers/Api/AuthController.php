<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\TenantManager;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $data = $request->validate([
            'subdomain' => 'required|string',
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        $tenant = TenantManager::findBySubdomain(trim($data['subdomain']));
        if (!$tenant) {
            return response()->json(['success' => false, 'message' => 'Organization not found or inactive.'], 404);
        }
        if (isset($tenant->hr_app) && (int) $tenant->hr_app !== 1) {
            return response()->json(['success' => false, 'message' => 'HR application is disabled for this organization.'], 403);
        }

        TenantManager::connect($tenant);

        // Company superuser (plan Phase 0) — before employee lookup
        $company = DB::table('company')->first();
        $suUser = trim((string) ($company->superuser_username ?? ''));
        $suPass = (string) ($company->superuser_password ?? '');
        if ($suUser !== '' && strcasecmp($suUser, $data['username']) === 0 && $this->passwordOk($data['password'], $suPass)) {
            $token = TenantManager::issueToken([
                'subdomain' => trim($data['subdomain']),
                'employee_id' => 0,
                'user_status' => 2,
                'is_superuser' => 1,
            ]);

            return response()->json([
                'success' => true,
                'token' => $token,
                'user' => [
                    'employee_id' => 0,
                    'name' => 'Superuser',
                    'surname' => '',
                    'user_name' => $suUser,
                    'email' => (string) ($company->email ?? ''),
                    'designation_id' => 0,
                    'designation_name' => 'Company Superuser',
                    'user_status' => 2,
                    'is_first_login' => 0,
                    'profile_picture' => null,
                    'is_superuser' => true,
                ],
                'company' => [
                    'name' => (string) ($company->hr_company_name ?? $company->name ?? $data['subdomain']),
                    'code' => (string) ($company->code ?? ''),
                    'logo' => $company->hr_logo ?? $company->logo ?? null,
                    'currency' => (string) ($company->currency ?? 'PKR'),
                    'date_format' => (string) ($company->hr_date_format ?? 'd-m-Y'),
                    'subdomain' => trim($data['subdomain']),
                ],
                'permissions' => TenantManager::normalizePermissions([], true),
                'ui_prefs' => UiPrefsController::prefsForEmployee(null, $company),
            ]);
        }

        $user = DB::table('employee')
            ->where(function ($q) use ($data) {
                $q->where('user_name', $data['username'])
                    ->orWhere('email', $data['username']);
            })
            ->first();

        if (!$user || !$this->passwordOk($data['password'], (string) ($user->password ?? ''))) {
            return response()->json(['success' => false, 'message' => 'Invalid credentials.'], 401);
        }

        $employeeId = (int) $user->employee_id;
        $userStatus = (int) ($user->status ?? 0);
        $allAccess = $userStatus === 2;
        $rolls = $allAccess ? [] : $this->loadRolls($employeeId);

        $designationName = '';
        $designationId = (int) ($user->designation ?? 0);
        if ($designationId > 0) {
            $designationName = (string) (DB::table('designation')->where('designation_id', $designationId)->value('name') ?? '');
        }

        $token = TenantManager::issueToken([
            'subdomain' => trim($data['subdomain']),
            'employee_id' => $employeeId,
            'user_status' => $userStatus,
            'is_superuser' => 0,
        ]);

        return response()->json([
            'success' => true,
            'token' => $token,
            'user' => [
                'employee_id' => $employeeId,
                'name' => UiPrefsController::displayName($user),
                'surname' => trim((string) ($user->surname ?? '')),
                'user_name' => (string) ($user->user_name ?? $data['username']),
                'email' => (string) ($user->email ?? ''),
                'designation_id' => $designationId,
                'designation_name' => $designationName,
                'user_status' => $userStatus,
                'is_first_login' => (int) ($user->is_first_login ?? 0),
                'profile_picture' => $user->profile_picture ?? null,
                'is_superuser' => false,
            ],
            'company' => [
                'name' => (string) ($company->hr_company_name ?? $company->name ?? $data['subdomain']),
                'code' => (string) ($company->code ?? ''),
                'logo' => $company->hr_logo ?? $company->logo ?? null,
                'currency' => (string) ($company->currency ?? 'PKR'),
                'date_format' => (string) ($company->hr_date_format ?? 'd-m-Y'),
                'subdomain' => trim($data['subdomain']),
            ],
            'permissions' => TenantManager::normalizePermissions($rolls, $allAccess),
            'ui_prefs' => UiPrefsController::prefsForEmployee($user, $company),
        ]);
    }

    public function changePassword(Request $request)
    {
        $claims = $request->attributes->get('hr_claims');
        $employeeId = (int) ($claims['employee_id'] ?? 0);
        if ($employeeId < 1 || !empty($claims['is_superuser'])) {
            return response()->json(['success' => false, 'message' => 'Password change is only for employee accounts.'], 422);
        }

        $data = $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:6',
        ]);

        $user = DB::table('employee')->where('employee_id', $employeeId)->first();
        if (!$user || !$this->passwordOk($data['current_password'], (string) ($user->password ?? ''))) {
            return response()->json(['success' => false, 'message' => 'Current password is incorrect.'], 401);
        }

        $update = ['password' => Hash::make($data['new_password'])];
        if (Schema::hasColumn('employee', 'is_first_login')) {
            $update['is_first_login'] = 0;
        }
        DB::table('employee')->where('employee_id', $employeeId)->update($update);

        return response()->json(['success' => true, 'message' => 'Password updated.']);
    }

    public function me(Request $request)
    {
        $claims = $request->attributes->get('hr_claims');
        $employeeId = (int) ($claims['employee_id'] ?? 0);
        $userStatus = (int) ($claims['user_status'] ?? 0);
        $allAccess = $userStatus === 2 || !empty($claims['is_superuser']);

        $user = $employeeId > 0
            ? DB::table('employee')->where('employee_id', $employeeId)->first()
            : null;

        $designationId = (int) ($user->designation ?? 0);
        $designationName = $designationId > 0
            ? (string) (DB::table('designation')->where('designation_id', $designationId)->value('name') ?? '')
            : '';
        $company = DB::table('company')->first();
        $rolls = $allAccess ? [] : $this->loadRolls($employeeId);

        return response()->json([
            'success' => true,
            'user' => [
                'employee_id' => $employeeId,
                'name' => $user
                    ? UiPrefsController::displayName($user)
                    : (!empty($claims['is_superuser']) ? 'Superuser' : ''),
                'surname' => trim((string) ($user->surname ?? '')),
                'user_name' => (string) ($user->user_name ?? ''),
                'email' => (string) ($user->email ?? ''),
                'designation_id' => $designationId,
                'designation_name' => $designationName,
                'user_status' => $userStatus,
                'is_first_login' => (int) ($user->is_first_login ?? 0),
                'profile_picture' => $user->profile_picture ?? null,
                'is_superuser' => !empty($claims['is_superuser']),
            ],
            'company' => [
                'name' => (string) ($company->hr_company_name ?? $company->name ?? $claims['subdomain']),
                'code' => (string) ($company->code ?? ''),
                'logo' => $company->hr_logo ?? $company->logo ?? null,
                'currency' => (string) ($company->currency ?? 'PKR'),
                'date_format' => (string) ($company->hr_date_format ?? 'd-m-Y'),
                'subdomain' => (string) $claims['subdomain'],
            ],
            'permissions' => TenantManager::normalizePermissions($rolls, $allAccess),
            'ui_prefs' => UiPrefsController::prefsForEmployee($user, $company),
        ]);
    }

    protected function passwordOk(string $plain, string $stored): bool
    {
        if ($stored !== '' && Hash::check($plain, $stored)) {
            return true;
        }
        if ($stored !== '' && $stored === $plain) {
            return true;
        }
        if ($stored !== '' && md5($plain) === $stored) {
            return true;
        }

        return false;
    }

    protected function loadRolls(int $employeeId): array
    {
        if ($employeeId < 1) {
            return [];
        }
        $row = DB::table('employee as e')
            ->leftJoin('designation as d', 'd.designation_id', '=', 'e.designation')
            ->where('e.employee_id', $employeeId)
            ->first(['e.rolls as emp_rolls', 'd.rolls as des_rolls']);
        if (!$row) {
            return [];
        }
        $raw = null;
        if (Schema::hasColumn('employee', 'rolls') && !empty($row->emp_rolls)) {
            $raw = $row->emp_rolls;
        } elseif (!empty($row->des_rolls)) {
            $raw = $row->des_rolls;
        }
        if (!$raw) {
            return [];
        }
        $rolls = @unserialize($raw);

        return is_array($rolls) ? $rolls : [];
    }
}
