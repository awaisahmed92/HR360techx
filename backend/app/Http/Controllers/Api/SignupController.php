<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\TenantProvisioner;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class SignupController extends Controller
{
    public function __construct(protected TenantProvisioner $provisioner)
    {
    }

    /** Live check for the Company Code field. */
    public function availability(Request $request)
    {
        $raw = (string) $request->query('code', $request->input('code', ''));
        $code = TenantProvisioner::normalizeCode($raw);

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
        if (TenantProvisioner::codeTaken($code)) {
            return response()->json([
                'success' => true,
                'code' => $code,
                'available' => false,
                'message' => 'That company code is already registered.',
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
        ]);

        $code = TenantProvisioner::normalizeCode($data['company_code']);
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
        if (TenantProvisioner::codeTaken($code)) {
            return response()->json([
                'success' => false,
                'message' => 'That company code is already registered.',
            ], 422);
        }

        try {
            $result = $this->provisioner->provision([
                'company_name' => trim($data['company_name']),
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
