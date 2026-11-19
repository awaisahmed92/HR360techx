<?php

namespace App\Services\Calendar;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class IcsFeedService
{
    public function regenerateToken(int $employeeId): string
    {
        $token = bin2hex(random_bytes(24));
        if (Schema::hasTable('hr_calendar_feed_tokens')) {
            DB::table('hr_calendar_feed_tokens')->where('employee_id', $employeeId)->whereNull('revoked_at')->update([
                'revoked_at' => now(),
            ]);
            DB::table('hr_calendar_feed_tokens')->insert([
                'employee_id' => $employeeId,
                'token' => $token,
                'created_at' => now(),
            ]);
        }

        return $token;
    }

    public function currentToken(int $employeeId): ?string
    {
        if (!Schema::hasTable('hr_calendar_feed_tokens')) {
            return null;
        }
        $row = DB::table('hr_calendar_feed_tokens')
            ->where('employee_id', $employeeId)
            ->whereNull('revoked_at')
            ->orderByDesc('id')
            ->first();

        return $row ? (string) $row->token : null;
    }

    public function buildForToken(string $token): ?string
    {
        if (!Schema::hasTable('hr_calendar_feed_tokens')) {
            return null;
        }
        $row = DB::table('hr_calendar_feed_tokens')->where('token', $token)->whereNull('revoked_at')->first();
        if (!$row) {
            return null;
        }
        $lines = [
            'BEGIN:VCALENDAR',
            'VERSION:2.0',
            'PRODID:-//HR360//Company Calendar//EN',
            'CALSCALE:GREGORIAN',
        ];
        if (Schema::hasTable('hr_calendar_events')) {
            $events = DB::table('hr_calendar_events')
                ->where('status', 1)
                ->where('start_at', '>=', now()->subMonths(2))
                ->orderBy('start_at')
                ->limit(500)
                ->get();
            foreach ($events as $e) {
                $uid = 'evt-'.$e->id.'@hr360';
                $start = $this->icsDate((string) $e->start_at, (int) $e->all_day === 1);
                $end = $this->icsDate((string) ($e->end_at ?: $e->start_at), (int) $e->all_day === 1);
                $lines[] = 'BEGIN:VEVENT';
                $lines[] = 'UID:'.$uid;
                $lines[] = ((int) $e->all_day === 1 ? 'DTSTART;VALUE=DATE:' : 'DTSTART:').$start;
                $lines[] = ((int) $e->all_day === 1 ? 'DTEND;VALUE=DATE:' : 'DTEND:').$end;
                $lines[] = 'SUMMARY:'.$this->escape((string) $e->title);
                if (!empty($e->location)) {
                    $lines[] = 'LOCATION:'.$this->escape((string) $e->location);
                }
                if (!empty($e->description)) {
                    $lines[] = 'DESCRIPTION:'.$this->escape((string) $e->description);
                }
                $lines[] = 'END:VEVENT';
            }
        }
        if (Schema::hasTable('hr_calendar_meetings')) {
            foreach (DB::table('hr_calendar_meetings')->where('meeting_date', '>=', now()->subMonths(1)->toDateString())->limit(200)->get() as $m) {
                $dt = preg_replace('/\D/', '', (string) $m->meeting_date).(str_replace(':', '', substr((string) ($m->meeting_time ?? '090000'), 0, 8)) ?: '090000');
                $lines[] = 'BEGIN:VEVENT';
                $lines[] = 'UID:meet-'.$m->id.'@hr360';
                $lines[] = 'DTSTART:'.$dt;
                $lines[] = 'SUMMARY:'.$this->escape((string) $m->title);
                $lines[] = 'END:VEVENT';
            }
        }
        $lines[] = 'END:VCALENDAR';

        return implode("\r\n", $lines);
    }

    protected function icsDate(string $dt, bool $allDay): string
    {
        $ts = strtotime($dt) ?: time();
        if ($allDay) {
            return gmdate('Ymd', $ts);
        }

        return gmdate('Ymd\THis\Z', $ts);
    }

    protected function escape(string $s): string
    {
        return str_replace(["\n", ',', ';'], ['\\n', '\\,', '\\;'], $s);
    }
}
