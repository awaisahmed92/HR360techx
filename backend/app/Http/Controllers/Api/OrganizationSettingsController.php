<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Organization Details · General Settings · Clock Faces (stored in company.ui_prefs).
 */
class OrganizationSettingsController extends Controller
{
    public function get(Request $request)
    {
        return response()->json([
            'success' => true,
            'settings' => $this->read($request),
        ]);
    }

    public function save(Request $request)
    {
        $incoming = $request->all();
        $current = $this->read($request);
        $merged = array_merge($current, array_filter(
            $incoming,
            fn ($v, $k) => $k !== '_token' && $k !== 'file',
            ARRAY_FILTER_USE_BOTH
        ));

        $this->write($request, $merged);

        // Mirror a few fields onto company table when columns exist.
        if (Schema::hasTable('company')) {
            $row = DB::table('company')->first();
            if ($row) {
                $upd = [];
                if (Schema::hasColumn('company', 'name') && isset($merged['org_name'])) {
                    $upd['name'] = (string) $merged['org_name'];
                }
                if (Schema::hasColumn('company', 'hr_company_name') && isset($merged['org_name'])) {
                    $upd['hr_company_name'] = (string) $merged['org_name'];
                }
                if (Schema::hasColumn('company', 'email') && isset($merged['contact_email'])) {
                    $upd['email'] = (string) $merged['contact_email'];
                }
                if (Schema::hasColumn('company', 'currency') && isset($merged['base_currency'])) {
                    $upd['currency'] = (string) $merged['base_currency'];
                }
                if (Schema::hasColumn('company', 'hr_date_format') && isset($merged['date_format'])) {
                    $upd['hr_date_format'] = (string) $merged['date_format'];
                }
                if ($upd !== []) {
                    DB::table('company')->where('id', $row->id)->update($upd);
                }
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Organization settings saved.',
            'settings' => $merged,
        ]);
    }

    protected function read(Request $request): array
    {
        $defaults = [
            'org_code' => 'demo',
            'org_url' => (string) config('app.url', 'https://hr360techx.com'),
            'org_name' => 'HR360 Demo Org',
            'industry' => 'Technology',
            'starting_year' => '2020',
            'contact_preferred' => '',
            'contact_last' => '',
            'contact_email' => '',
            'contact_country' => 'United States',
            'contact_province' => '',
            'contact_phone' => '',
            'logo_url' => null,
            'time_zone' => '(GMT+05:00) Pakistan Standard Time',
            'date_format' => 'YYYY-MM-DD',
            'time_format' => '12 Hour Format',
            'phone_format' => '(Country Code) 999-999999',
            'ssn_format' => '99999-9999999-9',
            'show_time_decimals' => false,
            'time_field_format' => '5',
            'calendar_start_day' => 'Monday',
            'default_theme' => '',
            'employee_name_display' => '{Last Name}, {Preferred Name}',
            'base_currency' => 'PKR',
            'currency_sign' => 'Rs',
            'decimal_places' => '2',
            'temperature_format' => 'Celsius (C)',
            'no_birthday_notifications' => false,
            'hide_email_approval_actions' => false,
            'bypass_own_approvals' => false,
            'clock_type' => 'Digital Clock',
            'clock_face_id' => 'digital_vortex',
            'clock_country' => 'PK',
        ];

        if (!Schema::hasTable('company')) {
            return $defaults;
        }

        $company = DB::table('company')->first();
        if (!$company) {
            return $defaults;
        }

        $defaults['org_name'] = (string) ($company->hr_company_name ?? $company->name ?? $defaults['org_name']);
        $defaults['contact_email'] = (string) ($company->email ?? '');
        $defaults['base_currency'] = (string) ($company->currency ?? 'PKR');
        $defaults['logo_url'] = $company->hr_logo ?? $company->logo ?? null;
        if (Schema::hasColumn('company', 'code') && !empty($company->code)) {
            $defaults['org_code'] = (string) $company->code;
        }

        if (Schema::hasColumn('company', 'ui_prefs') && !empty($company->ui_prefs)) {
            $decoded = json_decode((string) $company->ui_prefs, true);
            if (is_array($decoded) && isset($decoded['organization']) && is_array($decoded['organization'])) {
                return array_merge($defaults, $decoded['organization']);
            }
            // Also accept flat keys if previously saved that way.
            $orgKeys = array_keys($defaults);
            $flat = [];
            foreach ($orgKeys as $k) {
                if (array_key_exists($k, $decoded)) {
                    $flat[$k] = $decoded[$k];
                }
            }
            if ($flat !== []) {
                return array_merge($defaults, $flat);
            }
        }

        return $defaults;
    }

    protected function write(Request $request, array $settings): void
    {
        if (!Schema::hasTable('company') || !Schema::hasColumn('company', 'ui_prefs')) {
            return;
        }
        $company = DB::table('company')->first();
        if (!$company) {
            return;
        }
        $existing = [];
        if (!empty($company->ui_prefs)) {
            $decoded = json_decode((string) $company->ui_prefs, true);
            if (is_array($decoded)) {
                $existing = $decoded;
            }
        }
        $existing['organization'] = $settings;
        DB::table('company')->where('id', $company->id)->update([
            'ui_prefs' => json_encode($existing),
        ]);
    }
}
