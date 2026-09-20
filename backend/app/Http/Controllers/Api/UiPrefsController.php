<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Persist UI theme prefs (brand + dark mode) as JSON — same idea as employee.rolls.
 */
class UiPrefsController extends Controller
{
    public function get(Request $request)
    {
        return response()->json([
            'success' => true,
            'prefs' => $this->readPrefs($request),
        ]);
    }

    public function save(Request $request)
    {
        $data = $request->validate([
            'brand_theme_id' => 'nullable|string|max:64',
            'dark_mode' => 'nullable|boolean',
        ]);

        $current = $this->readPrefs($request);
        if (array_key_exists('brand_theme_id', $data) && $data['brand_theme_id'] !== null) {
            $current['brand_theme_id'] = (string) $data['brand_theme_id'];
        }
        if (array_key_exists('dark_mode', $data) && $data['dark_mode'] !== null) {
            $current['dark_mode'] = (bool) $data['dark_mode'];
        }

        $this->writePrefs($request, $current);

        return response()->json([
            'success' => true,
            'message' => 'Theme preferences saved.',
            'prefs' => $current,
        ]);
    }

    /** @return array{brand_theme_id: string, dark_mode: bool} */
    public static function prefsForEmployee(?object $user, ?object $company = null): array
    {
        $defaults = ['brand_theme_id' => 'bright_navy_blue', 'dark_mode' => false];

        if ($user && Schema::hasColumn('employee', 'ui_prefs') && !empty($user->ui_prefs)) {
            $decoded = json_decode((string) $user->ui_prefs, true);
            if (is_array($decoded)) {
                return array_merge($defaults, [
                    'brand_theme_id' => (string) ($decoded['brand_theme_id'] ?? $defaults['brand_theme_id']),
                    'dark_mode' => (bool) ($decoded['dark_mode'] ?? false),
                ]);
            }
        }

        $company ??= DB::table('company')->first();
        if ($company && Schema::hasColumn('company', 'ui_prefs') && !empty($company->ui_prefs)) {
            $decoded = json_decode((string) $company->ui_prefs, true);
            if (is_array($decoded)) {
                return array_merge($defaults, [
                    'brand_theme_id' => (string) ($decoded['brand_theme_id'] ?? $defaults['brand_theme_id']),
                    'dark_mode' => (bool) ($decoded['dark_mode'] ?? false),
                ]);
            }
        }

        return $defaults;
    }

    public static function displayName(?object $user): string
    {
        if (!$user) {
            return '';
        }
        $first = trim((string) ($user->name ?? ''));
        $last = trim((string) ($user->surname ?? ''));
        // Strip accidental leading commas from bad concatenations
        $first = ltrim($first, " \t,");
        $last = ltrim($last, " \t,");
        if ($last !== '' && $first !== '') {
            return $last.', '.$first;
        }

        return $first !== '' ? $first : $last;
    }

    /** @return array{brand_theme_id: string, dark_mode: bool} */
    protected function readPrefs(Request $request): array
    {
        $claims = $request->attributes->get('hr_claims') ?? [];
        $employeeId = (int) ($claims['employee_id'] ?? 0);
        $user = $employeeId > 0
            ? DB::table('employee')->where('employee_id', $employeeId)->first()
            : null;

        return self::prefsForEmployee($user);
    }

    protected function writePrefs(Request $request, array $prefs): void
    {
        $json = json_encode([
            'brand_theme_id' => (string) ($prefs['brand_theme_id'] ?? 'bright_navy_blue'),
            'dark_mode' => (bool) ($prefs['dark_mode'] ?? false),
        ]);

        $claims = $request->attributes->get('hr_claims') ?? [];
        $employeeId = (int) ($claims['employee_id'] ?? 0);
        $isSuper = !empty($claims['is_superuser']);

        if ($employeeId > 0 && Schema::hasColumn('employee', 'ui_prefs')) {
            DB::table('employee')->where('employee_id', $employeeId)->update(['ui_prefs' => $json]);

            return;
        }

        // Superuser / no employee row → company-level prefs (merge so org settings stay).
        if (($isSuper || $employeeId < 1) && Schema::hasColumn('company', 'ui_prefs')) {
            $company = DB::table('company')->first();
            if ($company) {
                $existing = [];
                if (!empty($company->ui_prefs)) {
                    $decoded = json_decode((string) $company->ui_prefs, true);
                    if (is_array($decoded)) {
                        $existing = $decoded;
                    }
                }
                $existing['brand_theme_id'] = (string) ($prefs['brand_theme_id'] ?? 'bright_navy_blue');
                $existing['dark_mode'] = (bool) ($prefs['dark_mode'] ?? false);
                DB::table('company')->where('id', $company->id)->update([
                    'ui_prefs' => json_encode($existing),
                ]);
            }
        }
    }
}
