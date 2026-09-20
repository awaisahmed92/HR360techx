<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Company-wide dashboard feed (status / holiday / announcement).
 * Visible to every employee in the tenant.
 */
class StatusFeedController extends Controller
{
    public function index()
    {
        $this->ensureTable();

        $rows = DB::table('status_posts')->orderByDesc('id')->limit(50)->get();
        $meta = $this->authorMetaMap($rows->pluck('employee_id')->all());

        return response()->json([
            'success' => true,
            'posts' => $rows->map(fn ($r) => $this->rowToPost($r, $meta))->values(),
            'celebrations' => $this->celebrations(),
        ]);
    }

    public function store(Request $request)
    {
        $this->ensureTable();

        $data = $request->validate([
            'text' => 'required|string|max:4000',
            'type' => 'nullable|string|max:40',
        ]);

        $type = $this->normalizeType($data['type'] ?? 'status');
        $author = $this->actorName($request);
        $employeeId = $this->actorId($request);
        $now = now();

        $id = DB::table('status_posts')->insertGetId([
            'employee_id' => $employeeId,
            'author' => $author,
            'body' => trim($data['text']),
            'type' => $type,
            'likes_json' => '[]',
            'comments_json' => '[]',
            'created_at' => $now,
        ]);

        if (in_array($type, ['holiday', 'announcement', 'recognition'], true)) {
            $title = match ($type) {
                'holiday' => 'Holiday',
                'recognition' => 'Recognition',
                default => 'Announcement',
            };
            $this->fanoutNotifications(
                $title,
                trim($data['text']),
                $type,
                $id,
                $employeeId
            );
        }

        $row = DB::table('status_posts')->where('id', $id)->first();

        return response()->json([
            'success' => true,
            'post' => $this->rowToPost($row),
        ]);
    }

    public function like(Request $request, int $id)
    {
        $this->ensureTable();
        $row = DB::table('status_posts')->where('id', $id)->first();
        if (!$row) {
            return response()->json(['success' => false, 'message' => 'Post not found.'], 404);
        }

        $name = $this->actorName($request);
        $likes = $this->decodeList($row->likes_json ?? '[]');
        $likes = array_values(array_filter($likes, fn ($x) => is_string($x) || is_numeric($x)));
        $likes = array_map('strval', $likes);
        if (in_array($name, $likes, true)) {
            $likes = array_values(array_filter($likes, fn ($x) => $x !== $name));
        } else {
            $likes[] = $name;
        }

        DB::table('status_posts')->where('id', $id)->update([
            'likes_json' => json_encode(array_values($likes)),
        ]);
        $row->likes_json = json_encode(array_values($likes));

        return response()->json([
            'success' => true,
            'post' => $this->rowToPost($row),
        ]);
    }

    public function comment(Request $request, int $id)
    {
        $this->ensureTable();
        $data = $request->validate([
            'text' => 'required|string|max:2000',
        ]);
        $row = DB::table('status_posts')->where('id', $id)->first();
        if (!$row) {
            return response()->json(['success' => false, 'message' => 'Post not found.'], 404);
        }

        $comments = $this->decodeMaps($row->comments_json ?? '[]');
        $comments[] = [
            'author' => $this->actorName($request),
            'text' => trim($data['text']),
            'created_at' => now()->toIso8601String(),
        ];

        DB::table('status_posts')->where('id', $id)->update([
            'comments_json' => json_encode($comments),
        ]);
        $row->comments_json = json_encode($comments);

        return response()->json([
            'success' => true,
            'post' => $this->rowToPost($row),
        ]);
    }

    protected function rowToPost(object $row, ?array $metaMap = null): array
    {
        $empId = (int) ($row->employee_id ?? 0);
        $meta = $metaMap[$empId] ?? ($empId > 0 ? $this->authorMetaMap([$empId])[$empId] ?? [] : []);

        return [
            'id' => (string) $row->id,
            'author' => (string) $row->author,
            'author_title' => (string) ($meta['title'] ?? ''),
            'author_department' => (string) ($meta['department'] ?? ''),
            'text' => (string) $row->body,
            'type' => (string) $row->type,
            'created_at' => $this->iso($row->created_at ?? null),
            'likes' => $this->decodeList($row->likes_json ?? '[]'),
            'comments' => $this->decodeMaps($row->comments_json ?? '[]'),
        ];
    }

    /** @param list<mixed> $employeeIds */
    protected function authorMetaMap(array $employeeIds): array
    {
        $ids = array_values(array_unique(array_filter(array_map('intval', $employeeIds))));
        if ($ids === [] || !Schema::hasTable('employee')) {
            return [];
        }

        $q = DB::table('employee as e')->whereIn('e.employee_id', $ids);
        if (Schema::hasTable('designation')) {
            $q->leftJoin('designation as d', 'd.designation_id', '=', 'e.designation');
            $q->addSelect('d.name as job_title');
        }
        if (Schema::hasTable('department')) {
            $q->leftJoin('department as dep', 'dep.department_id', '=', 'e.department');
            $q->addSelect('dep.name as department_name');
        }
        $q->addSelect('e.employee_id');

        $out = [];
        foreach ($q->get() as $row) {
            $out[(int) $row->employee_id] = [
                'title' => (string) ($row->job_title ?? ''),
                'department' => (string) ($row->department_name ?? ''),
            ];
        }

        return $out;
    }

    protected function celebrations(): array
    {
        $empty = [
            'birthdays' => [],
            'anniversaries' => [],
            'upcoming_birthdays' => [],
            'upcoming_anniversaries' => [],
        ];
        if (!Schema::hasTable('employee')) {
            return $empty;
        }

        $q = DB::table('employee as e');
        if (Schema::hasTable('designation')) {
            $q->leftJoin('designation as d', 'd.designation_id', '=', 'e.designation');
            $q->addSelect('d.name as job_title');
        }
        if (Schema::hasTable('department')) {
            $q->leftJoin('department as dep', 'dep.department_id', '=', 'e.department');
            $q->addSelect('dep.name as department_name');
        }
        $q->addSelect('e.employee_id', 'e.name');
        if (Schema::hasColumn('employee', 'surname')) {
            $q->addSelect('e.surname');
        }
        if (Schema::hasColumn('employee', 'date_of_birth')) {
            $q->addSelect('e.date_of_birth');
        }
        if (Schema::hasColumn('employee', 'joining_date')) {
            $q->addSelect('e.joining_date');
        }
        if (Schema::hasColumn('employee', 'status')) {
            $q->where(function ($w) {
                $w->where('e.status', '>', 0)->orWhereNull('e.status');
            });
        }

        $todayMd = now()->format('m-d');
        $upcoming = [];
        for ($i = 1; $i <= 30; $i++) {
            $d = now()->copy()->addDays($i);
            $upcoming[$d->format('m-d')] = $i;
        }

        $birthdays = [];
        $anniversaries = [];
        $upcomingBirthdays = [];
        $upcomingAnniversaries = [];

        foreach ($q->get() as $row) {
            $person = [
                'name' => UiPrefsController::displayName($row),
                'title' => (string) ($row->job_title ?? ''),
                'department' => (string) ($row->department_name ?? ''),
            ];
            $dob = $row->date_of_birth ?? null;
            $dobMd = $this->monthDay($dob);
            if ($dobMd === $todayMd) {
                $birthdays[] = $person + ['date' => (string) $dob, 'days_until' => 0];
            } elseif ($dobMd !== null && isset($upcoming[$dobMd])) {
                $upcomingBirthdays[] = $person + [
                    'date' => (string) $dob,
                    'days_until' => $upcoming[$dobMd],
                ];
            }

            $joined = $row->joining_date ?? null;
            $joinMd = $this->monthDay($joined);
            if ($joinMd === $todayMd) {
                $anniversaries[] = $person + ['date' => (string) $joined, 'days_until' => 0];
            } elseif ($joinMd !== null && isset($upcoming[$joinMd])) {
                $upcomingAnniversaries[] = $person + [
                    'date' => (string) $joined,
                    'days_until' => $upcoming[$joinMd],
                ];
            }
        }

        usort($upcomingBirthdays, fn ($a, $b) => ($a['days_until'] ?? 99) <=> ($b['days_until'] ?? 99));
        usort($upcomingAnniversaries, fn ($a, $b) => ($a['days_until'] ?? 99) <=> ($b['days_until'] ?? 99));

        return [
            'birthdays' => $birthdays,
            'anniversaries' => $anniversaries,
            'upcoming_birthdays' => array_slice($upcomingBirthdays, 0, 12),
            'upcoming_anniversaries' => array_slice($upcomingAnniversaries, 0, 12),
        ];
    }

    protected function monthDay(mixed $value): ?string
    {
        if ($value === null || $value === '' || $value === '0000-00-00') {
            return null;
        }
        try {
            return \Carbon\Carbon::parse((string) $value)->format('m-d');
        } catch (\Throwable $e) {
            return null;
        }
    }

    protected function claims(Request $request): array
    {
        $c = $request->attributes->get('hr_claims');

        return is_array($c) ? $c : [];
    }

    protected function actorId(Request $request): int
    {
        return (int) ($this->claims($request)['employee_id'] ?? 0);
    }

    protected function actorName(Request $request): string
    {
        $id = $this->actorId($request);
        if ($id > 0 && Schema::hasTable('employee')) {
            $row = DB::table('employee')->where('employee_id', $id)->first();
            if ($row) {
                return UiPrefsController::displayName($row);
            }
        }
        if (!empty($this->claims($request)['is_superuser'])) {
            return 'Superuser';
        }

        return 'Employee';
    }

    protected function normalizeType(string $type): string
    {
        $t = strtolower(trim($type));

        return in_array($t, ['status', 'holiday', 'announcement', 'recognition'], true)
            ? $t
            : 'status';
    }

    protected function fanoutNotifications(string $title, string $body, string $kind, int $refId, int $exceptId): void
    {
        if (!Schema::hasTable('notifications') || !Schema::hasTable('employee')) {
            return;
        }
        $q = DB::table('employee');
        if (Schema::hasColumn('employee', 'user_status')) {
            $q->where(function ($w) {
                $w->whereIn('user_status', [1, 2])->orWhereNull('user_status');
            });
        }
        $ids = $q->pluck('employee_id')
            ->map(fn ($id) => (int) $id)
            ->filter(fn ($id) => $id > 0);
        $now = now();
        $rows = [];
        foreach ($ids as $id) {
            $rows[] = [
                'employee_id' => $id,
                'title' => $title,
                'body' => $body,
                'kind' => $kind,
                'ref_type' => 'status_post',
                'ref_id' => $refId,
                'level' => null,
                'is_read' => 0,
                'created_at' => $now,
            ];
        }
        foreach (array_chunk($rows, 100) as $chunk) {
            try {
                DB::table('notifications')->insert($chunk);
            } catch (\Throwable $e) {
                break;
            }
        }
    }

    protected function decodeList(string $raw): array
    {
        $decoded = json_decode($raw, true);

        return is_array($decoded) ? array_values(array_map('strval', $decoded)) : [];
    }

    protected function decodeMaps(string $raw): array
    {
        $decoded = json_decode($raw, true);
        if (!is_array($decoded)) {
            return [];
        }
        $out = [];
        foreach ($decoded as $row) {
            if (is_array($row)) {
                $out[] = $row;
            }
        }

        return $out;
    }

    protected function iso(mixed $value): string
    {
        if ($value instanceof \DateTimeInterface) {
            return $value->format(DATE_ATOM);
        }
        $s = trim((string) $value);

        return $s === '' ? now()->toIso8601String() : $s;
    }

    protected function ensureTable(): void
    {
        if (Schema::hasTable('status_posts')) {
            return;
        }
        Schema::create('status_posts', function ($table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('employee_id')->default(0);
            $table->string('author', 190);
            $table->text('body');
            $table->string('type', 40)->default('status');
            $table->text('likes_json')->nullable();
            $table->text('comments_json')->nullable();
            $table->dateTime('created_at')->nullable();
        });
    }
}
