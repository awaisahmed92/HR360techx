<?php

namespace App\Services\Calendar;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;

class TeamsMeetingService
{
    public function isConfigured(): bool
    {
        $s = $this->settings();

        return $s && !empty($s->teams_tenant_id) && !empty($s->teams_client_id) && !empty($s->teams_client_secret);
    }

    public function settings(): ?object
    {
        if (!Schema::hasTable('hr_calendar_settings')) {
            return null;
        }

        return DB::table('hr_calendar_settings')->orderBy('id')->first();
    }

    /** @return array{ok:bool,join_url?:string,message?:string} */
    public function createOnlineMeeting(string $subject, string $startIso, string $endIso): array
    {
        if (!$this->isConfigured()) {
            return ['ok' => false, 'message' => 'Teams credentials not configured'];
        }
        $token = $this->appToken();
        if (!$token) {
            return ['ok' => false, 'message' => 'Could not obtain Graph token'];
        }
        try {
            $res = Http::withToken($token)->post('https://graph.microsoft.com/v1.0/me/onlineMeetings', [
                'subject' => $subject,
                'startDateTime' => $startIso,
                'endDateTime' => $endIso,
            ]);
            // App-only often needs /users/{id}/onlineMeetings — soft-fail with clear message.
            if (!$res->successful()) {
                $res = Http::withToken($token)->post('https://graph.microsoft.com/v1.0/communications/onlineMeetings', [
                    'subject' => $subject,
                    'startDateTime' => $startIso,
                    'endDateTime' => $endIso,
                ]);
            }
            if ($res->successful()) {
                $url = (string) ($res->json('joinWebUrl') ?? $res->json('joinUrl') ?? '');

                return ['ok' => true, 'join_url' => $url];
            }

            return ['ok' => false, 'message' => 'Graph meeting create failed: '.$res->status()];
        } catch (\Throwable $e) {
            return ['ok' => false, 'message' => $e->getMessage()];
        }
    }

    protected function appToken(): ?string
    {
        $s = $this->settings();
        if (!$s) {
            return null;
        }
        try {
            $res = Http::asForm()->post(
                'https://login.microsoftonline.com/'.$s->teams_tenant_id.'/oauth2/v2.0/token',
                [
                    'client_id' => $s->teams_client_id,
                    'client_secret' => $s->teams_client_secret,
                    'scope' => 'https://graph.microsoft.com/.default',
                    'grant_type' => 'client_credentials',
                ]
            );
            if ($res->successful()) {
                return (string) $res->json('access_token');
            }
        } catch (\Throwable) {
        }

        return null;
    }
}
