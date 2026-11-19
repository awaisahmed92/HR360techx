<?php

namespace App\Services\Calendar;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;

class GoogleCalendarService
{
    public function settings(): ?object
    {
        if (!Schema::hasTable('hr_calendar_settings')) {
            return null;
        }

        return DB::table('hr_calendar_settings')->orderBy('id')->first();
    }

    public function isConfigured(): bool
    {
        $s = $this->settings();

        return $s && !empty($s->google_client_id) && !empty($s->google_client_secret);
    }

    public function connectUrl(string $redirectUri, int $employeeId): ?string
    {
        $s = $this->settings();
        if (!$s || empty($s->google_client_id)) {
            return null;
        }
        $q = http_build_query([
            'client_id' => $s->google_client_id,
            'redirect_uri' => $redirectUri,
            'response_type' => 'code',
            'scope' => 'https://www.googleapis.com/auth/calendar',
            'access_type' => 'offline',
            'prompt' => 'consent',
            'state' => (string) $employeeId,
        ]);

        return 'https://accounts.google.com/o/oauth2/v2/auth?'.$q;
    }

    public function handleCallback(string $code, string $redirectUri, int $employeeId): array
    {
        $s = $this->settings();
        if (!$s || empty($s->google_client_id)) {
            return ['ok' => false, 'message' => 'Google credentials not configured'];
        }
        try {
            $res = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                'code' => $code,
                'client_id' => $s->google_client_id,
                'client_secret' => $s->google_client_secret,
                'redirect_uri' => $redirectUri,
                'grant_type' => 'authorization_code',
            ]);
            if (!$res->successful()) {
                return ['ok' => false, 'message' => 'Token exchange failed'];
            }
            $json = $res->json();
            $this->storeTokens($employeeId, $json);

            return ['ok' => true, 'message' => 'Google Calendar connected'];
        } catch (\Throwable $e) {
            return ['ok' => false, 'message' => $e->getMessage()];
        }
    }

    public function pushEvent(int $employeeId, object $event): ?string
    {
        $token = $this->accessToken($employeeId);
        if (!$token) {
            return null;
        }
        try {
            $body = [
                'summary' => (string) $event->title,
                'location' => (string) ($event->location ?? ''),
                'description' => (string) ($event->description ?? ''),
                'start' => ['dateTime' => date('c', strtotime((string) $event->start_at))],
                'end' => ['dateTime' => date('c', strtotime((string) ($event->end_at ?: $event->start_at)))],
            ];
            if (!empty($event->google_calendar_id)) {
                $res = Http::withToken($token)->put(
                    'https://www.googleapis.com/calendar/v3/calendars/primary/events/'.$event->google_calendar_id,
                    $body
                );
            } else {
                $res = Http::withToken($token)->post(
                    'https://www.googleapis.com/calendar/v3/calendars/primary/events',
                    $body
                );
            }
            if ($res->successful()) {
                return (string) ($res->json('id') ?? '');
            }
        } catch (\Throwable) {
        }

        return null;
    }

    public function pull(int $employeeId): array
    {
        $token = $this->accessToken($employeeId);
        if (!$token) {
            return ['ok' => false, 'message' => 'Not connected', 'imported' => 0];
        }
        $imported = 0;
        try {
            $res = Http::withToken($token)->get('https://www.googleapis.com/calendar/v3/calendars/primary/events', [
                'timeMin' => now()->subDays(30)->toIso8601String(),
                'maxResults' => 50,
                'singleEvents' => true,
            ]);
            if (!$res->successful()) {
                return ['ok' => false, 'message' => 'Pull failed', 'imported' => 0];
            }
            foreach ((array) $res->json('items') as $item) {
                $gid = (string) ($item['id'] ?? '');
                if ($gid === '' || !Schema::hasTable('hr_calendar_events')) {
                    continue;
                }
                $exists = DB::table('hr_calendar_events')->where('google_calendar_id', $gid)->exists();
                if ($exists) {
                    continue;
                }
                $start = $item['start']['dateTime'] ?? ($item['start']['date'] ?? null);
                $end = $item['end']['dateTime'] ?? ($item['end']['date'] ?? null);
                if (!$start) {
                    continue;
                }
                DB::table('hr_calendar_events')->insert([
                    'employee_id' => $employeeId,
                    'title' => (string) ($item['summary'] ?? 'Google Event'),
                    'start_at' => date('Y-m-d H:i:s', strtotime($start)),
                    'end_at' => $end ? date('Y-m-d H:i:s', strtotime($end)) : null,
                    'all_day' => isset($item['start']['date']) ? 1 : 0,
                    'description' => (string) ($item['description'] ?? ''),
                    'location' => (string) ($item['location'] ?? ''),
                    'status' => 1,
                    'google_calendar_id' => $gid,
                    'created_at' => now(),
                ]);
                $imported++;
            }

            return ['ok' => true, 'message' => 'Synced', 'imported' => $imported];
        } catch (\Throwable $e) {
            return ['ok' => false, 'message' => $e->getMessage(), 'imported' => 0];
        }
    }

    protected function storeTokens(int $employeeId, array $json): void
    {
        if (!Schema::hasTable('hr_calendar_integrations')) {
            return;
        }
        $existing = DB::table('hr_calendar_integrations')->where('provider', 'google')->where('employee_id', $employeeId)->first();
        $payload = [
            'access_token' => $json['access_token'] ?? null,
            'refresh_token' => $json['refresh_token'] ?? ($existing->refresh_token ?? null),
            'expires_at' => isset($json['expires_in']) ? now()->addSeconds((int) $json['expires_in']) : null,
            'meta_json' => json_encode($json),
            'updated_at' => now(),
        ];
        if ($existing) {
            DB::table('hr_calendar_integrations')->where('id', $existing->id)->update($payload);
        } else {
            $payload['provider'] = 'google';
            $payload['employee_id'] = $employeeId;
            $payload['created_at'] = now();
            DB::table('hr_calendar_integrations')->insert($payload);
        }
    }

    protected function accessToken(int $employeeId): ?string
    {
        if (!Schema::hasTable('hr_calendar_integrations')) {
            return null;
        }
        $row = DB::table('hr_calendar_integrations')->where('provider', 'google')->where('employee_id', $employeeId)->first();
        if (!$row || empty($row->access_token)) {
            return null;
        }
        if ($row->expires_at && strtotime((string) $row->expires_at) < time() - 60) {
            return $this->refresh($employeeId, $row) ?? (string) $row->access_token;
        }

        return (string) $row->access_token;
    }

    protected function refresh(int $employeeId, object $row): ?string
    {
        $s = $this->settings();
        if (!$s || empty($row->refresh_token)) {
            return null;
        }
        try {
            $res = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                'client_id' => $s->google_client_id,
                'client_secret' => $s->google_client_secret,
                'refresh_token' => $row->refresh_token,
                'grant_type' => 'refresh_token',
            ]);
            if ($res->successful()) {
                $json = $res->json();
                $this->storeTokens($employeeId, array_merge($json, ['refresh_token' => $row->refresh_token]));

                return (string) ($json['access_token'] ?? '');
            }
        } catch (\Throwable) {
        }

        return null;
    }
}
