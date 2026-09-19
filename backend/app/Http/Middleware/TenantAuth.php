<?php

namespace App\Http\Middleware;

use App\Services\TenantManager;
use Closure;
use Illuminate\Http\Request;

class TenantAuth
{
    public function handle(Request $request, Closure $next)
    {
        $claims = TenantManager::parseToken($request->header('Authorization'));
        if ($claims === null) {
            $q = $request->query('access_token') ?? $request->query('token');
            if (is_string($q) && $q !== '') {
                $claims = TenantManager::parseToken('Bearer '.$q);
            }
        }
        if ($claims === null) {
            return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);
        }

        $tenant = TenantManager::findBySubdomain((string) $claims['subdomain']);
        if ($tenant === null) {
            return response()->json(['success' => false, 'message' => 'Organization not found.'], 404);
        }

        TenantManager::connect($tenant);
        $request->attributes->set('hr_claims', $claims);
        $request->attributes->set('hr_tenant', $tenant);

        return $next($request);
    }
}
