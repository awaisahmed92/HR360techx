<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ApprovalService;
use App\Services\Calendar\GoogleCalendarService;
use App\Services\Calendar\IcsFeedService;
use App\Services\Calendar\TeamsMeetingService;
use App\Services\TenantManager;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class CalendarController extends Controller
{
    public function feed(Request $request)
    {
        $from = $request->query('from', now()->startOfMonth()->toDateString());
        $to = $request->query('to', now()->endOfMonth()->toDateString());
        $events = [];
        if (Schema::hasTable('hr_calendar_events')) {
            $events = DB::table('hr_calendar_events as e')
                ->leftJoin('hr_calendar_event_types as t', 't.id', '=', 'e.event_type_id')
                ->whereBetween('e.start_at', [$from.' 00:00:00', $to.' 23:59:59'])
                ->orderBy('e.start_at')
                ->get(['e.*', 't.title as type_title', 't.color as type_color'])
                ->map(fn ($r) => $this->mapEvent($r));
        }
        $meetings = [];
        if (Schema::hasTable('hr_calendar_meetings')) {
            $meetings = DB::table('hr_calendar_meetings')
                ->whereBetween('meeting_date', [$from, $to])
                ->orderBy('meeting_date')
                ->get()
                ->map(fn ($r) => $this->mapMeeting($r));
        }

        return response()->json(['success' => true, 'events' => $events, 'meetings' => $meetings]);
    }

    public function overlays(Request $request)
    {
        $from = $request->query('from', now()->startOfMonth()->toDateString());
        $to = $request->query('to', now()->endOfMonth()->toDateString());
        $out = [
            'leave' => [],
            'holiday' => [],
            'birthday' => [],
            'anniversary' => [],
            'training' => [],
            'interview' => [],
        ];

        if (Schema::hasTable('leave')) {
            $q = DB::table('leave');
            $dateCol = Schema::hasColumn('leave', 'from_date') ? 'from_date' : (Schema::hasColumn('leave', 'start_date') ? 'start_date' : null);
            if ($dateCol) {
                $out['leave'] = $q->whereBetween($dateCol, [$from, $to])
                    ->limit(200)
                    ->get()
                    ->map(fn ($r) => [
                        'id' => (int) ($r->id ?? 0),
                        'title' => 'Leave',
                        'date' => (string) ($r->{$dateCol} ?? ''),
                        'employee_id' => (int) ($r->employee_id ?? $r->employee ?? 0),
                    ]);
            }
        }

        foreach (['holidays', 'holiday'] as $ht) {
            if (Schema::hasTable($ht)) {
                $dateCol = Schema::hasColumn($ht, 'holiday_date') ? 'holiday_date' : (Schema::hasColumn($ht, 'date') ? 'date' : null);
                $titleCol = Schema::hasColumn($ht, 'name') ? 'name' : (Schema::hasColumn($ht, 'title') ? 'title' : null);
                if ($dateCol) {
                    $out['holiday'] = DB::table($ht)->whereBetween($dateCol, [$from, $to])->limit(100)->get()->map(fn ($r) => [
                        'id' => (int) ($r->id ?? $r->holiday_id ?? 0),
                        'title' => (string) ($titleCol ? $r->{$titleCol} : 'Holiday'),
                        'date' => (string) $r->{$dateCol},
                    ]);
                }
                break;
            }
        }

        if (Schema::hasTable('employee')) {
            $dobCol = Schema::hasColumn('employee', 'date_of_birth') ? 'date_of_birth' : (Schema::hasColumn('employee', 'dob') ? 'dob' : null);
            if ($dobCol) {
                $emps = DB::table('employee')->whereNotNull($dobCol)->limit(500)->get(['employee_id', 'name', $dobCol]);
                foreach ($emps as $e) {
                    $md = date('m-d', strtotime((string) $e->{$dobCol}));
                    $fromMd = date('m-d', strtotime($from));
                    $toMd = date('m-d', strtotime($to));
                    if ($md >= $fromMd && $md <= $toMd) {
                        $out['birthday'][] = [
                            'id' => (int) $e->employee_id,
                            'title' => ($e->name ?? 'Employee').' Birthday',
                            'date' => date('Y', strtotime($from)).'-'.$md,
                        ];
                    }
                }
            }
            $joinCol = Schema::hasColumn('employee', 'joining_date') ? 'joining_date' : (Schema::hasColumn('employee', 'date_of_joining') ? 'date_of_joining' : null);
            if ($joinCol) {
                foreach (DB::table('employee')->whereNotNull($joinCol)->limit(500)->get(['employee_id', 'name', $joinCol]) as $e) {
                    $md = date('m-d', strtotime((string) $e->{$joinCol}));
                    $fromMd = date('m-d', strtotime($from));
                    $toMd = date('m-d', strtotime($to));
                    if ($md >= $fromMd && $md <= $toMd) {
                        $out['anniversary'][] = [
                            'id' => (int) $e->employee_id,
                            'title' => ($e->name ?? 'Employee').' Anniversary',
                            'date' => date('Y', strtotime($from)).'-'.$md,
                        ];
                    }
                }
            }
        }

        if (Schema::hasTable('hr_training') || Schema::hasTable('training')) {
            $tt = Schema::hasTable('hr_training') ? 'hr_training' : 'training';
            $startCol = Schema::hasColumn($tt, 'start_date') ? 'start_date' : (Schema::hasColumn($tt, 'training_date') ? 'training_date' : null);
            if ($startCol) {
                $out['training'] = DB::table($tt)->whereBetween($startCol, [$from, $to])->limit(100)->get()->map(fn ($r) => [
                    'id' => (int) ($r->id ?? 0),
                    'title' => (string) ($r->title ?? $r->name ?? 'Training'),
                    'date' => (string) $r->{$startCol},
                ]);
            }
        }

        if (Schema::hasTable('hr_recruit_interviews')) {
            $out['interview'] = DB::table('hr_recruit_interviews as i')
                ->leftJoin('hr_recruit_applications as a', 'a.id', '=', 'i.application_id')
                ->leftJoin('hr_candidate as c', 'c.id', '=', 'a.candidate_id')
                ->whereBetween('i.scheduled_at', [$from.' 00:00:00', $to.' 23:59:59'])
                ->get(['i.id', 'i.title', 'i.scheduled_at', 'c.name as candidate_name'])
                ->map(fn ($r) => [
                    'id' => (int) $r->id,
                    'title' => (string) (($r->title ?: 'Interview').' — '.($r->candidate_name ?? '')),
                    'date' => substr((string) $r->scheduled_at, 0, 10),
                    'datetime' => (string) $r->scheduled_at,
                ]);
        }

        return response()->json(['success' => true, 'overlays' => $out]);
    }

    public function eventsIndex()
    {
        $rows = Schema::hasTable('hr_calendar_events')
            ? DB::table('hr_calendar_events as e')
                ->leftJoin('hr_calendar_event_types as t', 't.id', '=', 'e.event_type_id')
                ->orderByDesc('e.start_at')
                ->limit(200)
                ->get(['e.*', 't.title as type_title', 't.color as type_color'])
                ->map(fn ($r) => $this->mapEvent($r))
            : [];

        return response()->json(['success' => true, 'events' => $rows]);
    }

    public function eventsStore(Request $request, ApprovalService $approvals, GoogleCalendarService $google)
    {
        return $this->eventUpsert($request, null, $approvals, $google);
    }

    public function eventsUpdate(Request $request, int $id, ApprovalService $approvals, GoogleCalendarService $google)
    {
        return $this->eventUpsert($request, $id, $approvals, $google);
    }

    public function eventsDelete(int $id)
    {
        DB::table('hr_calendar_events')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function typesIndex()
    {
        $rows = Schema::hasTable('hr_calendar_event_types')
            ? DB::table('hr_calendar_event_types')->orderBy('title')->get()->map(fn ($r) => [
                'id' => (int) $r->id,
                'title' => (string) $r->title,
                'color' => (string) ($r->color ?? '#1E4B8C'),
                'requires_approval' => (int) ($r->requires_approval ?? 0) === 1,
                'status' => (int) $r->status,
            ])
            : [];

        return response()->json(['success' => true, 'types' => $rows]);
    }

    public function typesStore(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'color' => 'nullable|string|max:20',
            'requires_approval' => 'nullable|boolean',
            'status' => 'nullable|integer',
        ]);
        $id = (int) DB::table('hr_calendar_event_types')->insertGetId([
            'title' => $data['title'],
            'color' => $data['color'] ?? '#1E4B8C',
            'requires_approval' => ($data['requires_approval'] ?? false) ? 1 : 0,
            'status' => (int) ($data['status'] ?? 1),
            'created_by' => (int) (($request->attributes->get('hr_claims') ?? [])['employee_id'] ?? 0) ?: null,
            'created_at' => now(),
        ]);

        return response()->json(['success' => true, 'id' => $id]);
    }

    public function recurringStore(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'dates' => 'required|array|min:1',
            'template' => 'nullable|array',
        ]);
        $recId = (int) DB::table('hr_calendar_recurring')->insertGetId([
            'title' => $data['title'],
            'dates_json' => json_encode($data['dates']),
            'template_json' => json_encode($data['template'] ?? []),
            'created_by' => (int) (($request->attributes->get('hr_claims') ?? [])['employee_id'] ?? 0) ?: null,
            'created_at' => now(),
        ]);
        $tpl = $data['template'] ?? [];
        $created = [];
        foreach ($data['dates'] as $d) {
            $day = is_string($d) ? $d : (string) ($d['date'] ?? '');
            if ($day === '') {
                continue;
            }
            $start = $day.' '.($tpl['time'] ?? '09:00:00');
            $eid = (int) DB::table('hr_calendar_events')->insertGetId([
                'title' => $data['title'],
                'start_at' => $start,
                'end_at' => $day.' '.($tpl['end_time'] ?? '10:00:00'),
                'all_day' => !empty($tpl['all_day']) ? 1 : 0,
                'location' => $tpl['location'] ?? null,
                'description' => $tpl['description'] ?? null,
                'event_type_id' => $tpl['event_type_id'] ?? null,
                'status' => 1,
                'recurring_id' => $recId,
                'created_by' => (int) (($request->attributes->get('hr_claims') ?? [])['employee_id'] ?? 0) ?: null,
                'created_at' => now(),
            ]);
            $created[] = $eid;
        }

        return response()->json(['success' => true, 'recurring_id' => $recId, 'event_ids' => $created]);
    }

    public function meetingsIndex()
    {
        $rows = Schema::hasTable('hr_calendar_meetings')
            ? DB::table('hr_calendar_meetings')->orderByDesc('meeting_date')->limit(200)->get()->map(fn ($r) => $this->mapMeeting($r))
            : [];

        return response()->json(['success' => true, 'meetings' => $rows]);
    }

    public function meetingsStore(Request $request, TeamsMeetingService $teams)
    {
        return $this->meetingUpsert($request, null, $teams);
    }

    public function meetingsUpdate(Request $request, int $id, TeamsMeetingService $teams)
    {
        return $this->meetingUpsert($request, $id, $teams);
    }

    public function meetingsDelete(int $id)
    {
        DB::table('hr_calendar_meetings')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function settingsGet()
    {
        $row = Schema::hasTable('hr_calendar_settings')
            ? DB::table('hr_calendar_settings')->orderBy('id')->first()
            : null;

        return response()->json([
            'success' => true,
            'settings' => [
                'start_of_week' => (int) ($row->start_of_week ?? 1),
                'default_overlays' => json_decode((string) ($row->default_overlays ?? '[]'), true) ?: [],
                'show_everyone' => (int) ($row->show_everyone ?? 1) === 1,
                'google_configured' => $row && !empty($row->google_client_id),
                'teams_configured' => $row && !empty($row->teams_client_id),
                'google_client_id' => (string) ($row->google_client_id ?? ''),
                'teams_tenant_id' => (string) ($row->teams_tenant_id ?? ''),
                'teams_client_id' => (string) ($row->teams_client_id ?? ''),
            ],
        ]);
    }

    public function settingsSave(Request $request)
    {
        $data = $request->validate([
            'start_of_week' => 'nullable|integer|min:0|max:6',
            'default_overlays' => 'nullable|array',
            'show_everyone' => 'nullable|boolean',
            'google_client_id' => 'nullable|string|max:255',
            'google_client_secret' => 'nullable|string|max:255',
            'teams_tenant_id' => 'nullable|string|max:120',
            'teams_client_id' => 'nullable|string|max:120',
            'teams_client_secret' => 'nullable|string|max:255',
        ]);
        $row = DB::table('hr_calendar_settings')->orderBy('id')->first();
        $payload = [
            'start_of_week' => (int) ($data['start_of_week'] ?? 1),
            'default_overlays' => json_encode($data['default_overlays'] ?? []),
            'show_everyone' => ($data['show_everyone'] ?? true) ? 1 : 0,
            'updated_at' => now(),
        ];
        foreach (['google_client_id', 'google_client_secret', 'teams_tenant_id', 'teams_client_id', 'teams_client_secret'] as $k) {
            if (!empty($data[$k])) {
                $payload[$k] = $data[$k];
            }
        }
        if ($row) {
            DB::table('hr_calendar_settings')->where('id', $row->id)->update($payload);
        } else {
            DB::table('hr_calendar_settings')->insert($payload);
        }

        return response()->json(['success' => true]);
    }

    public function reports(Request $request)
    {
        $month = $request->query('month', now()->format('Y-m'));
        $from = $month.'-01';
        $to = date('Y-m-t', strtotime($from));
        $events = Schema::hasTable('hr_calendar_events')
            ? (int) DB::table('hr_calendar_events')->whereBetween('start_at', [$from, $to.' 23:59:59'])->count()
            : 0;
        $meetings = Schema::hasTable('hr_calendar_meetings')
            ? (int) DB::table('hr_calendar_meetings')->whereBetween('meeting_date', [$from, $to])->count()
            : 0;

        return response()->json([
            'success' => true,
            'reports' => [
                'month' => $month,
                'events' => $events,
                'meetings' => $meetings,
            ],
        ]);
    }

    public function icsToken(Request $request, IcsFeedService $ics)
    {
        $uid = (int) (($request->attributes->get('hr_claims') ?? [])['employee_id'] ?? 0);
        $regen = $request->boolean('regenerate');
        $token = $regen ? $ics->regenerateToken($uid) : ($ics->currentToken($uid) ?: $ics->regenerateToken($uid));

        return response()->json([
            'success' => true,
            'token' => $token,
            'path' => '/api/calendar/ics/'.$token.'.ics',
        ]);
    }

    public function icsFeed(Request $request, string $token, IcsFeedService $ics)
    {
        $sub = trim((string) $request->query('org', 'demo'));
        $tenant = TenantManager::findBySubdomain($sub);
        if ($tenant) {
            TenantManager::connect($tenant);
        }
        $token = preg_replace('/\.ics$/i', '', $token) ?? $token;
        $body = $ics->buildForToken($token);
        if ($body === null) {
            return response('Not found', 404);
        }

        return response($body, 200, [
            'Content-Type' => 'text/calendar; charset=utf-8',
            'Content-Disposition' => 'attachment; filename="hr360.ics"',
        ]);
    }

    public function googleConnect(Request $request, GoogleCalendarService $google)
    {
        $uid = (int) (($request->attributes->get('hr_claims') ?? [])['employee_id'] ?? 0);
        $redirect = url('/api/calendar/google/callback');
        $url = $google->connectUrl($redirect, $uid);
        if (!$url) {
            return response()->json(['success' => false, 'message' => 'Google credentials not configured in Calendar Settings'], 422);
        }

        return response()->json(['success' => true, 'url' => $url]);
    }

    public function googleCallback(Request $request, GoogleCalendarService $google)
    {
        $sub = trim((string) $request->query('org', 'demo'));
        $tenant = TenantManager::findBySubdomain($sub);
        if ($tenant) {
            TenantManager::connect($tenant);
        }
        $code = (string) $request->query('code', '');
        $uid = (int) $request->query('state', 0);
        $redirect = url('/api/calendar/google/callback');
        $result = $google->handleCallback($code, $redirect, $uid);

        return response(
            '<html><body><h3>'.($result['ok'] ? 'Connected' : 'Failed').'</h3><p>'.e($result['message'] ?? '').'</p><p>You can close this window.</p></body></html>',
            $result['ok'] ? 200 : 400,
            ['Content-Type' => 'text/html']
        );
    }

    public function googleSync(Request $request, GoogleCalendarService $google)
    {
        $uid = (int) (($request->attributes->get('hr_claims') ?? [])['employee_id'] ?? 0);
        $result = $google->pull($uid);

        return response()->json(['success' => $result['ok'], 'imported' => $result['imported'], 'message' => $result['message']]);
    }

    public function teamsTest(TeamsMeetingService $teams)
    {
        return response()->json([
            'success' => true,
            'configured' => $teams->isConfigured(),
            'message' => $teams->isConfigured() ? 'Teams Graph credentials present' : 'Add Teams tenant/client/secret in Calendar Settings',
        ]);
    }

    protected function eventUpsert(Request $request, ?int $id, ApprovalService $approvals, GoogleCalendarService $google)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'start_at' => 'required|date',
            'end_at' => 'nullable|date',
            'all_day' => 'nullable|boolean',
            'location' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'event_type_id' => 'nullable|integer',
            'budget' => 'nullable|numeric',
            'participants' => 'nullable|array',
            'status' => 'nullable|integer',
            'notes' => 'nullable|string',
        ]);
        $claims = $request->attributes->get('hr_claims') ?? [];
        $uid = (int) ($claims['employee_id'] ?? 0);
        $needsApproval = false;
        if (!empty($data['event_type_id'])) {
            $type = DB::table('hr_calendar_event_types')->where('id', $data['event_type_id'])->first();
            $needsApproval = $type && (int) $type->requires_approval === 1;
        }
        $payload = [
            'title' => $data['title'],
            'start_at' => $data['start_at'],
            'end_at' => $data['end_at'] ?? null,
            'all_day' => ($data['all_day'] ?? false) ? 1 : 0,
            'location' => $data['location'] ?? null,
            'description' => $data['description'] ?? null,
            'event_type_id' => $data['event_type_id'] ?? null,
            'budget' => $data['budget'] ?? 0,
            'participants' => json_encode($data['participants'] ?? []),
            'notes' => $data['notes'] ?? null,
            'employee_id' => $uid ?: null,
            'status' => $needsApproval ? 0 : (int) ($data['status'] ?? 1),
            'updated_at' => now(),
        ];
        if ($id === null) {
            $payload['created_by'] = $uid ?: null;
            $payload['created_at'] = now();
            $newId = (int) DB::table('hr_calendar_events')->insertGetId($payload);
            $id = $newId;
            if ($needsApproval) {
                $row = DB::table('hr_calendar_events')->where('id', $id)->first();
                $approvals->bootstrapRequest('calendar_event', $uid, 'calendar_event', $id, 'Event: '.$data['title'], (array) $row);
            }
        } else {
            DB::table('hr_calendar_events')->where('id', $id)->update($payload);
        }
        $event = DB::table('hr_calendar_events')->where('id', $id)->first();
        if ($event && (int) $event->status === 1) {
            $gid = $google->pushEvent($uid, $event);
            if ($gid) {
                DB::table('hr_calendar_events')->where('id', $id)->update(['google_calendar_id' => $gid]);
            }
        }

        return response()->json(['success' => true, 'id' => $id]);
    }

    protected function meetingUpsert(Request $request, ?int $id, TeamsMeetingService $teams)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'agenda' => 'nullable|string|max:255',
            'minutes' => 'nullable|string',
            'details' => 'nullable|string',
            'meeting_date' => 'required|date',
            'meeting_time' => 'nullable|string',
            'duration_min' => 'nullable|integer',
            'location' => 'nullable|string|max:255',
            'chaired_by' => 'nullable|integer',
            'attendee_ids' => 'nullable|array',
            'teams_enabled' => 'nullable|boolean',
            'notes' => 'nullable|string',
        ]);
        $payload = [
            'title' => $data['title'],
            'agenda' => $data['agenda'] ?? null,
            'minutes' => $data['minutes'] ?? null,
            'details' => $data['details'] ?? null,
            'meeting_date' => $data['meeting_date'],
            'meeting_time' => $data['meeting_time'] ?? null,
            'duration_min' => (int) ($data['duration_min'] ?? 60),
            'location' => $data['location'] ?? null,
            'chaired_by' => $data['chaired_by'] ?? null,
            'attendee_ids' => json_encode($data['attendee_ids'] ?? []),
            'teams_enabled' => ($data['teams_enabled'] ?? false) ? 1 : 0,
            'notes' => $data['notes'] ?? null,
            'updated_at' => now(),
        ];
        $teamsMsg = null;
        if (!empty($data['teams_enabled'])) {
            $start = $data['meeting_date'].' '.($data['meeting_time'] ?? '09:00:00');
            $endTs = strtotime($start) + ((int) ($data['duration_min'] ?? 60)) * 60;
            $result = $teams->createOnlineMeeting($data['title'], date('c', strtotime($start)), date('c', $endTs));
            if ($result['ok'] ?? false) {
                $payload['teams_join_url'] = $result['join_url'] ?? null;
                $payload['additional_info'] = json_encode(['teams' => $result]);
            } else {
                $teamsMsg = $result['message'] ?? 'Teams setup needed';
                $payload['additional_info'] = json_encode(['teams_error' => $teamsMsg]);
            }
        }
        $claims = $request->attributes->get('hr_claims') ?? [];
        if ($id === null) {
            $payload['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
            $payload['created_at'] = now();
            $newId = (int) DB::table('hr_calendar_meetings')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId, 'teams_message' => $teamsMsg]);
        }
        DB::table('hr_calendar_meetings')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id, 'teams_message' => $teamsMsg]);
    }

    protected function mapEvent(object $r): array
    {
        return [
            'id' => (int) $r->id,
            'title' => (string) $r->title,
            'start_at' => (string) $r->start_at,
            'end_at' => (string) ($r->end_at ?? ''),
            'all_day' => (int) ($r->all_day ?? 0) === 1,
            'location' => (string) ($r->location ?? ''),
            'description' => (string) ($r->description ?? ''),
            'event_type_id' => $r->event_type_id ? (int) $r->event_type_id : null,
            'type_title' => (string) ($r->type_title ?? ''),
            'type_color' => (string) ($r->type_color ?? '#1E4B8C'),
            'budget' => (float) ($r->budget ?? 0),
            'status' => (int) ($r->status ?? 1),
            'google_calendar_id' => (string) ($r->google_calendar_id ?? ''),
            'recurring_id' => $r->recurring_id ? (int) $r->recurring_id : null,
        ];
    }

    protected function mapMeeting(object $r): array
    {
        return [
            'id' => (int) $r->id,
            'title' => (string) $r->title,
            'agenda' => (string) ($r->agenda ?? ''),
            'meeting_date' => (string) $r->meeting_date,
            'meeting_time' => (string) ($r->meeting_time ?? ''),
            'duration_min' => (int) ($r->duration_min ?? 60),
            'location' => (string) ($r->location ?? ''),
            'teams_enabled' => (int) ($r->teams_enabled ?? 0) === 1,
            'teams_join_url' => (string) ($r->teams_join_url ?? ''),
            'attendee_ids' => json_decode((string) ($r->attendee_ids ?? '[]'), true) ?: [],
            'notes' => (string) ($r->notes ?? ''),
        ];
    }
}
