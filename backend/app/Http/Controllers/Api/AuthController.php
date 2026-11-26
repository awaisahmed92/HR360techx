<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\LoginSecurityService;
use App\Services\TenantHost;
use App\Services\TenantManager;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;

class AuthController extends Controller
{
    public function __construct(protected LoginSecurityService $security)
    {
    }

    public function login(Request $request)
    {
        try {
            return $this->attemptLogin($request);
        } catch (\Throwable $e) {
            report($e);

            return response()->json([
                'success' => false,
                'message' => 'Login failed: '.$e->getMessage(),
            ], 500);
        }
    }

    public function loginCaptcha()
    {
        try {
            return response()->json(['success' => true] + $this->security->issueCaptcha());
        } catch (\Throwable $e) {
            report($e);

            return response()->json(['success' => false, 'message' => 'Captcha unavailable.'], 500);
        }
    }

    public function securityActivity(Request $request)
    {
        $claims = $request->attributes->get('hr_claims') ?? [];
        if ((int) ($claims['user_status'] ?? 0) !== 2 && empty($claims['is_superuser'])) {
            return response()->json(['success' => false, 'message' => 'Admin access required.'], 403);
        }

        $subdomain = strtolower(trim((string) ($claims['subdomain'] ?? '')));
        // Org admins only see their tenant. Platform superusers may pass ?all=1.
        $scopeAll = ! empty($claims['is_superuser']) && $request->boolean('all');
        $scope = $scopeAll ? null : $subdomain;

        return response()->json([
            'success' => true,
            'subdomain' => $subdomain,
            'attempts' => $this->security->recentActivity(200, $scope),
            'ip_blocks' => $this->security->activeBlocks($scope),
            'account_locks' => $this->security->accountLocks($scope),
        ]);
    }

    public function unblockIp(Request $request)
    {
        $claims = $request->attributes->get('hr_claims') ?? [];
        if ((int) ($claims['user_status'] ?? 0) !== 2 && empty($claims['is_superuser'])) {
            return response()->json(['success' => false, 'message' => 'Admin access required.'], 403);
        }
        $data = $request->validate(['ip' => 'required|string|max:64']);
        $this->security->unblockIp(trim($data['ip']));

        return response()->json(['success' => true]);
    }

    public function unlockAccount(Request $request)
    {
        $claims = $request->attributes->get('hr_claims') ?? [];
        if ((int) ($claims['user_status'] ?? 0) !== 2 && empty($claims['is_superuser'])) {
            return response()->json(['success' => false, 'message' => 'Admin access required.'], 403);
        }
        $data = $request->validate([
            'username' => 'required|string|max:191',
            'subdomain' => 'nullable|string|max:100',
        ]);
        $sub = strtolower(trim((string) ($data['subdomain'] ?? $claims['subdomain'] ?? '')));
        if ($sub === '') {
            return response()->json(['success' => false, 'message' => 'Organization is required.'], 422);
        }
        // Org admins can only unlock accounts in their own tenant.
        $claimSub = strtolower(trim((string) ($claims['subdomain'] ?? '')));
        if (empty($claims['is_superuser']) && $sub !== $claimSub) {
            return response()->json(['success' => false, 'message' => 'Not allowed for this organization.'], 403);
        }
        $this->security->unlockAccount($sub, trim($data['username']));

        return response()->json(['success' => true]);
    }

    protected function attemptLogin(Request $request)
    {
        $data = $request->validate([
            'subdomain' => 'required|string',
            'username' => 'required|string',
            'password' => 'required|string',
            'captcha_token' => 'nullable|string|max:64',
            'captcha_answer' => 'nullable|string|max:12',
        ]);

        [$subdomain, $rejected] = $this->resolveSubdomain($request, (string) $data['subdomain']);
        if ($rejected !== null) {
            return $rejected;
        }
        $data['subdomain'] = $subdomain;

        $ip = $this->security->clientIp();
        $ua = substr((string) $request->userAgent(), 0, 255);
        $username = trim((string) $data['username']);
        $sub = trim((string) $data['subdomain']);

        $gate = $this->security->precheck($ip, $sub, $username);
        if (!empty($gate['blocked'])) {
            $this->security->recordBlocked($ip, $sub, $username, (string) ($gate['code'] ?? 'rate_limited'), $ua);

            return response()->json([
                'success' => false,
                'message' => $gate['message'] ?? 'Too many attempts.',
                'code' => $gate['code'] ?? 'rate_limited',
                'retry_after' => (int) ($gate['retry_after'] ?? 60),
                'captcha_required' => true,
            ], 429);
        }

        if (!empty($gate['captcha_required'])) {
            if (!$this->security->verifyCaptcha($data['captcha_token'] ?? null, $data['captcha_answer'] ?? null)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Complete the human verification to continue.',
                    'code' => 'captcha_required',
                    'captcha_required' => true,
                    'retry_after' => 0,
                ], 422);
            }
        }

        $tenant = TenantManager::findBySubdomain(trim($data['subdomain']));
        if (!$tenant) {
            $fail = $this->security->recordFailure($ip, $sub, $username, 'org_not_found', $ua);

            return response()->json([
                'success' => false,
                'message' => 'Organization not found or inactive.',
                'code' => 'org_not_found',
                'retry_after' => $fail['retry_after'],
                'captcha_required' => true,
            ], 404);
        }
        if (isset($tenant->hr_app) && (int) $tenant->hr_app !== 1) {
            return response()->json(['success' => false, 'message' => 'HR application is disabled for this organization.'], 403);
        }

        TenantManager::connect($tenant);

        $company = Schema::hasTable('company') ? DB::table('company')->first() : null;
        $suUser = trim((string) ($company?->superuser_username ?? ''));
        $suPass = (string) ($company?->superuser_password ?? '');
        if ($suUser !== '' && strcasecmp($suUser, $data['username']) === 0 && $this->passwordOk($data['password'], $suPass)) {
            $this->security->recordSuccess($ip, $sub, $username, $ua);
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
                    'name' => (string) ($company?->hr_company_name ?? $company?->name ?? $data['subdomain']),
                    'code' => (string) ($company?->code ?? ''),
                    'logo' => $company?->hr_logo ?? $company?->logo ?? null,
                    'currency' => (string) ($company?->currency ?? 'USD'),
                    'date_format' => (string) ($company?->hr_date_format ?? 'd-m-Y'),
                    'subdomain' => trim($data['subdomain']),
                ],
                'permissions' => TenantManager::normalizePermissions([], true),
                'ui_prefs' => UiPrefsController::prefsForEmployee(null, $company),
            ]);
        }

        $loginName = trim($data['username']);
        $user = DB::table('employee')
            ->where(function ($q) use ($loginName) {
                $q->whereRaw('LOWER(user_name) = ?', [strtolower($loginName)])
                    ->orWhereRaw('LOWER(email) = ?', [strtolower($loginName)]);
            })
            ->first();

        $storedPassword = $user ? (string) ($user->password ?? '') : '';
        if (!$user || !$this->passwordOk($data['password'], $storedPassword)) {
            $fail = $this->security->recordFailure($ip, $sub, $username, 'invalid_credentials', $ua);

            return response()->json([
                'success' => false,
                'message' => $fail['message'],
                'code' => !empty($fail['account_locked']) ? 'account_locked' : 'invalid_credentials',
                'retry_after' => $fail['retry_after'],
                'captcha_required' => true,
            ], !empty($fail['account_locked']) ? 429 : 401);
        }

        // Rewrite legacy hashes ($2Y$, cost 10, …) to the hasher this app verifies.
        if ($user->employee_id && $this->passwordNeedsUpgrade($storedPassword)) {
            DB::table('employee')->where('employee_id', $user->employee_id)->update([
                'password' => Hash::make($data['password']),
            ]);
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

        $this->security->recordSuccess($ip, $sub, $username, $ua);

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
                'name' => (string) ($company?->hr_company_name ?? $company?->name ?? $data['subdomain']),
                'code' => (string) ($company?->code ?? ''),
                'logo' => $company?->hr_logo ?? $company?->logo ?? null,
                'currency' => (string) ($company?->currency ?? 'USD'),
                'date_format' => (string) ($company?->hr_date_format ?? 'd-m-Y'),
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
                'currency' => (string) ($company->currency ?? 'USD'),
                'date_format' => (string) ($company->hr_date_format ?? 'd-m-Y'),
                'subdomain' => (string) $claims['subdomain'],
            ],
            'permissions' => TenantManager::normalizePermissions($rolls, $allAccess),
            'ui_prefs' => UiPrefsController::prefsForEmployee($user, $company),
        ]);
    }

    /** Public org name + logo for the Employee Login page (no secrets). */
    public function branding(Request $request)
    {
        $sub = trim((string) ($request->query('subdomain') ?? $request->input('subdomain') ?? ''));
        [$sub, $rejected] = $this->resolveSubdomain($request, $sub);
        if ($rejected !== null) {
            return $rejected;
        }
        if ($sub === '') {
            return response()->json(['success' => false, 'message' => 'Organization required.'], 422);
        }

        try {
            $tenant = TenantManager::findBySubdomain($sub);
            if (!$tenant) {
                return response()->json(['success' => false, 'message' => 'Organization not found.'], 404);
            }

            TenantManager::connect($tenant);
            $company = Schema::hasTable('company') ? DB::table('company')->first() : null;
            $name = $sub;
            $logo = null;

            if ($company) {
                $name = (string) ($company->hr_company_name ?? $company->name ?? $sub);
                $logo = $company->hr_logo ?? $company->logo ?? null;
                if (Schema::hasColumn('company', 'ui_prefs') && !empty($company->ui_prefs)) {
                    $decoded = json_decode((string) $company->ui_prefs, true);
                    if (is_array($decoded)) {
                        $org = (isset($decoded['organization']) && is_array($decoded['organization']))
                            ? $decoded['organization']
                            : $decoded;
                        if (!empty($org['logo_url'])) {
                            $logo = $org['logo_url'];
                        }
                        if (!empty($org['org_name'])) {
                            $name = (string) $org['org_name'];
                        }
                    }
                }
            }

            return response()->json([
                'success' => true,
                'name' => $name,
                'logo' => $logo,
                'subdomain' => $sub,
            ]);
        } catch (\Throwable $e) {
            report($e);

            return response()->json([
                'success' => false,
                'message' => 'Unable to load branding.',
            ], 500);
        }
    }

    /**
     * On a company host, the code in the request must be that host's label.
     *
     * @return array{0: string, 1: \Illuminate\Http\JsonResponse|null}
     */
    protected function resolveSubdomain(Request $request, string $submitted): array
    {
        $fromHost = TenantHost::companyCode($request->getHost());
        $submitted = trim($submitted);
        if ($fromHost === null) {
            return [$submitted, null];
        }
        if ($submitted === '') {
            return [$fromHost, null];
        }

        $given = strtolower($submitted);
        if (str_starts_with($given, 'hr360_')) {
            $given = substr($given, 6);
        }
        if ($given !== $fromHost) {
            return ['', response()->json([
                'success' => false,
                'message' => 'This address is for '.$fromHost.'.',
            ], 422)];
        }

        return [$fromHost, null];
    }

    protected function passwordOk(string $plain, string $stored): bool
    {
        $stored = trim($stored);
        if ($stored === '') {
            return false;
        }

        // Some bcrypt builds store $2Y$ / $2A$. PHP only recognizes $2y$, $2a$, $2b$,
        // and Laravel then throws instead of checking the password.
        $hash = $stored;
        if (preg_match('/^\$2[aAxXyY]\$/', $stored)) {
            $hash = '$2y$'.substr($stored, 4);
        }
        try {
            if (Hash::check($plain, $hash)) {
                return true;
            }
        } catch (\Throwable $e) {
            // Not a hash this verifier understands; try the legacy comparisons below.
        }
        if (hash_equals($stored, $plain)) {
            return true;
        }
        if (hash_equals($stored, md5($plain))) {
            return true;
        }

        return false;
    }

    protected function passwordNeedsUpgrade(string $stored): bool
    {
        $stored = trim($stored);
        if ($stored === '' || !str_starts_with($stored, '$2y$')) {
            return true;
        }
        try {
            return Hash::needsRehash($stored);
        } catch (\Throwable $e) {
            return true;
        }
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
