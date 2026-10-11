<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\SignupCaptcha;
use App\Services\TenantProvisioner;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class SignupController extends Controller
{
    public function __construct(
        protected TenantProvisioner $provisioner,
        protected SignupCaptcha $captcha,
    ) {
    }

    public function captcha()
    {
        try {
            return response()->json([
                'success' => true,
            ] + $this->captcha->issue());
        } catch (\Throwable $e) {
            report($e);

            return response()->json([
                'success' => false,
                'message' => 'Could not load the verification code.',
            ], 503);
        }
    }

    /** Live check for the Company Code field. */
    public function availability(Request $request)
    {
        $raw = (string) $request->query('code', $request->input('code', ''));
        $code = TenantProvisioner::normalizeCode($raw);

        if (str_contains($code, '_')) {
            return response()->json([
                'success' => true,
                'code' => $code,
                'available' => false,
                'message' => 'Company code cannot contain underscores. It is used as your web address.',
            ]);
        }
        if (strlen($code) < 3) {
            return response()->json([
                'success' => true,
                'code' => $code,
                'available' => false,
                'message' => 'Company code needs at least 3 letters or digits.',
            ]);
        }
        if (in_array($code, TenantProvisioner::RESERVED_CODES, true)) {
            return response()->json([
                'success' => true,
                'code' => $code,
                'available' => false,
                'message' => 'That company code is reserved. Please pick another.',
            ]);
        }
        $companyName = (string) $request->query('name', '');
        try {
            $hrAlready = TenantProvisioner::codeTaken($code, $companyName);
            $existing = $hrAlready ? null : TenantProvisioner::existingClient($code, $companyName);
        } catch (RuntimeException $e) {
            return response()->json([
                'success' => true,
                'code' => $code,
                'available' => false,
                'message' => $e->getMessage(),
            ]);
        }
        if ($hrAlready || $existing) {
            $row = $existing ?? TenantProvisioner::existingClient($code, $companyName);

            return response()->json([
                'success' => true,
                'code' => $code,
                'available' => false,
                'message' => TenantProvisioner::alreadyRegisteredMessage($row, $companyName),
            ]);
        }

        return response()->json([
            'success' => true,
            'code' => $code,
            'available' => true,
            'message' => 'Company code is available.',
        ]);
    }

    /** Create the organization, its database, and its first admin user. */
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:191',
            'company_name' => 'required|string|max:191',
            'company_code' => 'required|string|max:40',
            'designation' => 'required|string|max:191',
            'industry' => 'required|string|max:120',
            'country' => 'required|string|max:120',
            'email' => 'required|email|max:191',
            'phone' => 'nullable|string|max:60',
            'password' => 'required|string|min:6|max:191',
            'captcha_token' => 'required|string|max:64',
            'captcha_answer' => 'required|string|max:12',
        ]);

        if (! $this->captcha->check($data['captcha_token'], $data['captcha_answer'])) {
            return response()->json([
                'success' => false,
                'message' => 'The verification code is incorrect. Request a new code and try again.',
            ], 422);
        }

        $code = TenantProvisioner::normalizeCode($data['company_code']);
        $companyName = trim($data['company_name']);
        try {
            $existing = TenantProvisioner::existingClient($code, $companyName);
        } catch (RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => TenantProvisioner::alreadyRegisteredMessage($existing, $companyName),
            ], 422);
        }
        if (str_contains($code, '_')) {
            return response()->json([
                'success' => false,
                'message' => 'Company code cannot contain underscores. It is used as your web address.',
            ], 422);
        }
        if (strlen($code) < 3) {
            return response()->json([
                'success' => false,
                'message' => 'Company code needs at least 3 letters or digits.',
            ], 422);
        }
        if (in_array($code, TenantProvisioner::RESERVED_CODES, true)) {
            return response()->json([
                'success' => false,
                'message' => 'That company code is reserved. Please pick another.',
            ], 422);
        }
        if (TenantProvisioner::codeTaken($code, $companyName)) {
            return response()->json([
                'success' => false,
                'message' => TenantProvisioner::alreadyRegisteredMessage(
                    TenantProvisioner::existingClient($code, $companyName),
                    $companyName
                ),
            ], 422);
        }
        if ($this->provisioner->databaseExists(TenantProvisioner::databaseNameFor($code))) {
            return response()->json([
                'success' => false,
                'message' => TenantProvisioner::alreadyRegisteredMessage(null, $companyName),
            ], 422);
        }

        try {
            // Building a new company database takes longer than PHP's 30 second default.
            @set_time_limit(300);
            $result = $this->provisioner->provision([
                'company_name' => $companyName,
                'company_code' => $code,
                'contact_name' => trim($data['name']),
                'designation' => trim($data['designation']),
                'industry' => trim($data['industry']),
                'country' => trim($data['country']),
                'email' => strtolower(trim($data['email'])),
                'phone' => $data['phone'] ?? null,
                'password' => $data['password'],
            ]);
        } catch (\Throwable $e) {
            Log::error('Signup failed', ['code' => $code, 'error' => $e->getMessage()]);
            if (str_contains(strtolower($e->getMessage()), 'already exists')
                || str_contains(strtolower($e->getMessage()), 'already registered')) {
                return response()->json([
                    'success' => false,
                    'message' => TenantProvisioner::alreadyRegisteredMessage(null, $companyName),
                ], 422);
            }

            return response()->json([
                'success' => false,
                'message' => 'Could not create your organization: '.$e->getMessage(),
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Your organization is ready. Sign in with the details below.',
            'organization' => $code,
            'user_name' => $result['user_name'],
            'company_name' => trim($data['company_name']),
        ], 201);
    }
}
