<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AttendanceAdminController extends Controller
{
    /** Admin day grid: all active employees + attendance for date. */
    public function grid(Request $request)
    {
        $date = $request->query('date', now()->toDateString());
        $department = $request->query('department') ? (int) $request->query('department') : null;

        $emps = DB::table('employee as e')
            ->leftJoin('department as d', 'd.department_id', '=', 'e.department')
            ->leftJoin('designation as des', 'des.designation_id', '=', 'e.designation')
            ->where('e.status', '>', 0)
            ->when($department, fn ($q) => $q->where('e.department', $department))
            ->orderBy('e.name')
            ->get([
                'e.employee_id', 'e.name', 'e.employee_code', 'e.user_name',
                'e.department', 'd.name as department_name', 'des.name as designation_name',
            ]);

        $attByEmp = [];
        if (Schema::hasTable('attendance')) {
            $rows = DB::table('attendance')->where('date', $date)->get();
            foreach ($rows as $r) {
                $attByEmp[(int) $r->employee_id] = $r;
            }
        }

        $onLeave = $this->employeesOnLeave($date);

        $out = [];
        foreach ($emps as $e) {
            $id = (int) $e->employee_id;
            $att = $attByEmp[$id] ?? null;
            $status = $this->resolveStatus($att, in_array($id, $onLeave, true), $date);
            $out[] = [
                'employee_id' => $id,
                'name' => (string) $e->name,
                'employee_code' => (string) ($e->employee_code ?? $e->user_name ?? ''),
                'department_name' => (string) ($e->department_name ?? ''),
                'designation_name' => (string) ($e->designation_name ?? ''),
                'attendance_id' => $att ? (int) $att->id : null,
                'punch_in' => $att?->punch_in,
                'punch_out' => $att?->punch_out,
                'total_minutes' => $att && isset($att->total_minutes) ? (int) $att->total_minutes : null,
                'late_minutes' => $att && isset($att->late_minutes) ? (int) $att->late_minutes : null,
                'status' => $status['code'],
                'status_label' => $status['label'],
                'on_leave' => in_array($id, $onLeave, true),
            ];
        }

        return response()->json([
            'success' => true,
            'date' => $date,
            'is_off_day' => $this->isOffDay($date),
            'rows' => $out,
        ]);
    }

    /** Mark present / absent / leave for one employee on a date. */
    public function mark(Request $request)
    {
        $data = $request->validate([
            'employee_id' => 'required|integer',
            'date' => 'required|date',
            'status' => 'required|integer|in:0,1,2', // 0 absent, 1 present, 2 leave
            'punch_in' => 'nullable|string',
            'punch_out' => 'nullable|string',
        ]);

        $empId = (int) $data['employee_id'];
        $date = $data['date'];
        $status = (int) $data['status'];

        $existing = DB::table('attendance')
            ->where('employee_id', $empId)
            ->where('date', $date)
            ->first();

        $punchIn = null;
        $punchOut = null;
        $total = null;

        if ($status === 1) {
            // Present: use provided times or default schedule start
            $sched = $this->scheduleForDate($date);
            $start = $sched['start_time'] ?? '09:00:00';
            $end = $sched['end_time'] ?? '18:00:00';
            $inTime = $data['punch_in'] ?? substr($start, 0, 5);
            $outTime = $data['punch_out'] ?? substr($end, 0, 5);
            $punchIn = $date.' '.$this->normalizeTime($inTime);
            $punchOut = $date.' '.$this->normalizeTime($outTime);
            $total = max(0, (int) ((strtotime($punchOut) - strtotime($punchIn)) / 60));
        }

        $payload = [
            'employee_id' => $empId,
            'date' => $date,
            'punch_in' => $punchIn,
            'punch_out' => $punchOut,
            'total_minutes' => $total,
            'status' => $status,
        ];
        if (Schema::hasColumn('attendance', 'late_minutes') && $status === 1) {
            $payload['late_minutes'] = $this->calcLateMinutes($date, $punchIn);
        }

        if ($existing) {
            DB::table('attendance')->where('id', $existing->id)->update($payload);
            $id = (int) $existing->id;
        } else {
            if (Schema::hasColumn('attendance', 'created_at')) {
                $payload['created_at'] = now();
            }
            $id = (int) DB::table('attendance')->insertGetId($payload);
        }

        return response()->json(['success' => true, 'id' => $id, 'message' => 'Marked.']);
    }

    /** Save/edit full punch row (PHP admin CRUD parity). */
    public function save(Request $request)
    {
        $data = $request->validate([
            'id' => 'nullable|integer',
            'employee_id' => 'required|integer',
            'date' => 'required|date',
            'punch_in' => 'nullable|string',
            'punch_out' => 'nullable|string',
            'status' => 'nullable|integer',
            'notes' => 'nullable|string|max:255',
        ]);

        $date = $data['date'];
        $punchIn = !empty($data['punch_in']) ? $date.' '.$this->normalizeTime($data['punch_in']) : null;
        $punchOut = !empty($data['punch_out']) ? $date.' '.$this->normalizeTime($data['punch_out']) : null;
        $total = null;
        if ($punchIn && $punchOut) {
            $total = max(0, (int) ((strtotime($punchOut) - strtotime($punchIn)) / 60));
        }
        $status = (int) ($data['status'] ?? ($punchIn ? 1 : 0));

        $payload = [
            'employee_id' => (int) $data['employee_id'],
            'date' => $date,
            'punch_in' => $punchIn,
            'punch_out' => $punchOut,
            'total_minutes' => $total,
            'status' => $status,
        ];
        if (Schema::hasColumn('attendance', 'notes') && array_key_exists('notes', $data)) {
            $payload['notes'] = $data['notes'];
        }
        if (Schema::hasColumn('attendance', 'late_minutes') && $punchIn) {
            $payload['late_minutes'] = $this->calcLateMinutes($date, $punchIn);
        }

        $id = $data['id'] ?? null;
        if ($id) {
            DB::table('attendance')->where('id', $id)->update($payload);
        } else {
            $existing = DB::table('attendance')
                ->where('employee_id', $payload['employee_id'])
                ->where('date', $date)
                ->value('id');
            if ($existing) {
                DB::table('attendance')->where('id', $existing)->update($payload);
                $id = (int) $existing;
            } else {
                if (Schema::hasColumn('attendance', 'created_at')) {
                    $payload['created_at'] = now();
                }
                $id = (int) DB::table('attendance')->insertGetId($payload);
            }
        }

        return response()->json(['success' => true, 'id' => $id]);
    }

    public function destroy(int $id)
    {
        DB::table('attendance')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function scheduleIndex()
    {
        $this->ensureSchedule();
        $rows = DB::table('hr_weekly_schedule')->orderBy('id')->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'day' => (string) $r->day,
            'start_time' => substr((string) $r->start_time, 0, 5),
            'end_time' => substr((string) $r->end_time, 0, 5),
            'break_minutes' => (int) $r->break_minutes,
            'is_off_day' => (int) $r->is_off_day === 1,
        ]);

        return response()->json(['success' => true, 'rows' => $rows]);
    }

    public function scheduleSave(Request $request)
    {
        $this->ensureSchedule();
        $data = $request->validate([
            'rows' => 'required|array|min:1',
            'rows.*.id' => 'required|integer',
            'rows.*.start_time' => 'nullable|string',
            'rows.*.end_time' => 'nullable|string',
            'rows.*.break_minutes' => 'nullable|integer',
            'rows.*.is_off_day' => 'nullable|boolean',
        ]);

        foreach ($data['rows'] as $row) {
            DB::table('hr_weekly_schedule')->where('id', $row['id'])->update([
                'start_time' => $this->normalizeTime($row['start_time'] ?? '09:00'),
                'end_time' => $this->normalizeTime($row['end_time'] ?? '18:00'),
                'break_minutes' => (int) ($row['break_minutes'] ?? 0),
                'is_off_day' => !empty($row['is_off_day']) ? 1 : 0,
            ]);
        }

        return $this->scheduleIndex();
    }

    /** Attendance register / summary for one date. */
    public function register(Request $request)
    {
        $date = $request->query('date', now()->toDateString());
        $filter = strtolower((string) $request->query('status', 'all'));
        $department = $request->query('department') ? (int) $request->query('department') : null;

        // Reuse grid logic via internal call
        $fake = Request::create('/attendance/admin', 'GET', array_filter([
            'date' => $date,
            'department' => $department,
        ]));
        $grid = $this->grid($fake);
        $payload = json_decode($grid->getContent(), true);
        $rows = $payload['rows'] ?? [];

        // Summary before filter
        $allRows = $rows;
        $summary = [
            'present' => count(array_filter($allRows, fn ($r) => (int) $r['status'] === 1)),
            'absent' => count(array_filter($allRows, fn ($r) => (int) $r['status'] === 0)),
            'leave' => count(array_filter($allRows, fn ($r) => (int) $r['status'] === 2)),
            'total' => count($allRows),
        ];

        if ($filter !== 'all') {
            $map = ['present' => 1, 'absent' => 0, 'leave' => 2];
            $code = $map[$filter] ?? null;
            if ($code !== null) {
                $rows = array_values(array_filter($rows, fn ($r) => (int) $r['status'] === $code));
            }
        }

        return response()->json([
            'success' => true,
            'date' => $date,
            'is_off_day' => $payload['is_off_day'] ?? false,
            'summary' => $summary,
            'rows' => $rows,
        ]);
    }

    protected function resolveStatus(?object $att, bool $onLeave, string $date): array
    {
        if ($onLeave) {
            return ['code' => 2, 'label' => 'Leave'];
        }
        if ($this->isOffDay($date)) {
            return ['code' => 1, 'label' => 'Off Day'];
        }
        if ($att) {
            $st = isset($att->status) ? (int) $att->status : null;
            if ($st === 0) {
                return ['code' => 0, 'label' => 'Absent'];
            }
            if ($st === 2) {
                return ['code' => 2, 'label' => 'Leave'];
            }
            if (!empty($att->punch_in) || $st === 1) {
                return ['code' => 1, 'label' => 'Present'];
            }
        }

        return ['code' => 0, 'label' => 'Absent'];
    }

    /** @return list<int> */
    protected function employeesOnLeave(string $date): array
    {
        if (!Schema::hasTable('leave')) {
            return [];
        }

        return DB::table('leave')
            ->where('status', 1)
            ->where('from', '<=', $date)
            ->where('to', '>=', $date)
            ->when(Schema::hasColumn('leave', 'assigned'), function ($q) {
                $q->where(function ($w) {
                    $w->whereNull('assigned')->orWhere('assigned', '<=', 0);
                });
            })
            ->pluck('employee')
            ->map(fn ($v) => (int) $v)
            ->unique()
            ->values()
            ->all();
    }

    protected function isOffDay(string $date): bool
    {
        $sched = $this->scheduleForDate($date);
        if (!empty($sched['is_off_day'])) {
            return true;
        }
        // Holidays
        if (Schema::hasTable('hr_holiday') && Schema::hasColumn('hr_holiday', 'holiday_date')) {
            if (DB::table('hr_holiday')->where('holiday_date', $date)->where('status', 1)->exists()) {
                return true;
            }
        }

        return false;
    }

    /** @return array{start_time?:string,end_time?:string,is_off_day?:bool} */
    protected function scheduleForDate(string $date): array
    {
        $this->ensureSchedule();
        $dayName = date('l', strtotime($date));
        $row = DB::table('hr_weekly_schedule')->where('day', $dayName)->first();
        if (!$row) {
            return ['start_time' => '09:00:00', 'end_time' => '18:00:00', 'is_off_day' => false];
        }

        return [
            'start_time' => (string) $row->start_time,
            'end_time' => (string) $row->end_time,
            'is_off_day' => (int) $row->is_off_day === 1,
        ];
    }

    protected function calcLateMinutes(string $date, string $punchInDt): int
    {
        $sched = $this->scheduleForDate($date);
        $start = $date.' '.($sched['start_time'] ?? '09:00:00');
        $diff = (int) ((strtotime($punchInDt) - strtotime($start)) / 60);

        return max(0, $diff);
    }

    protected function normalizeTime(string $t): string
    {
        $t = trim($t);
        if (preg_match('/^\d{1,2}:\d{2}$/', $t)) {
            return $t.':00';
        }
        if (preg_match('/^\d{1,2}:\d{2}:\d{2}$/', $t)) {
            return $t;
        }

        return '09:00:00';
    }

    protected function ensureSchedule(): void
    {
        if (!Schema::hasTable('hr_weekly_schedule')) {
            return;
        }
        if (DB::table('hr_weekly_schedule')->count() > 0) {
            return;
        }
        $days = [
            ['Monday', '09:00:00', '18:00:00', 60, 0],
            ['Tuesday', '09:00:00', '18:00:00', 60, 0],
            ['Wednesday', '09:00:00', '18:00:00', 60, 0],
            ['Thursday', '09:00:00', '18:00:00', 60, 0],
            ['Friday', '09:00:00', '18:00:00', 60, 0],
            ['Saturday', '09:00:00', '14:00:00', 30, 0],
            ['Sunday', '00:00:00', '00:00:00', 0, 1],
        ];
        foreach ($days as $d) {
            DB::table('hr_weekly_schedule')->insert([
                'day' => $d[0],
                'start_time' => $d[1],
                'end_time' => $d[2],
                'break_minutes' => $d[3],
                'is_off_day' => $d[4],
            ]);
        }
    }
}
