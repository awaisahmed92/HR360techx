<?php

namespace App\Services;

/**
 * Maps a browser host to the company code stored on tenants.subdomain.
 * https://acme.hr360techx.com is company code "acme".
 * The apex, www, api, and localhost stay unlocked so signup and typed codes still work.
 */
class TenantHost
{
    public static function baseDomain(): string
    {
        $domain = strtolower(trim((string) config('app.hr360_base_domain', 'hr360techx.com')));

        return $domain !== '' ? $domain : 'hr360techx.com';
    }

    public static function urlFor(string $code): string
    {
        return 'https://'.strtolower(trim($code)).'.'.self::baseDomain();
    }

    /** Company code from a Host header, or null when this host is not a company site. */
    public static function companyCode(?string $host): ?string
    {
        $host = strtolower(trim((string) $host));
        $host = explode(':', $host, 2)[0];
        if ($host === '' || $host === 'localhost' || $host === '127.0.0.1') {
            return null;
        }

        $base = self::baseDomain();
        if ($host === $base) {
            return null;
        }

        $suffix = '.'.$base;
        if (!str_ends_with($host, $suffix)) {
            return null;
        }

        $label = substr($host, 0, -strlen($suffix));
        if ($label === '' || str_contains($label, '.') || in_array($label, ['www', 'api'], true)) {
            return null;
        }
        if (!preg_match('/^[a-z0-9]{1,40}$/', $label)) {
            return null;
        }

        return $label;
    }
}
