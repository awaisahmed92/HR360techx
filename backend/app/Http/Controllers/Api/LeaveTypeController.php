<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class LeaveTypeController extends Controller
{
    public function index()
    {
        $cols = ['id', 'name', 'days'];
        foreach (['calendar_title', 'reference_number', 'category', 'duration_type', 'quota_reset', 'is_active'] as $c) {
            if (Schema::hasColumn('leave_type', $c)) {
                $cols[] = $c;
            }
        }

        $rows = DB::table('leave_type')->orderBy('name')->get($cols)->map(fn ($r) => $this->map($r));

        return response()->json(['success' => true, 'types' => $rows]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:191',
            'calendar_title' => 'nullable|string|max:191',
            'reference_number' => 'nullable|string|max:100',
            'category' => 'nullable|string|max:50',
            'days' => 'nullable|numeric|min:0',
            'duration_type' => 'nullable|string|max:30',
            'quota_reset' => 'nullable|boolean',
            'is_active' => 'nullable|boolean',
        ]);

        $payload = [
            'name' => $data['name'],
            'days' => (float) ($data['days'] ?? 1),
        ];
        foreach (['calendar_title', 'reference_number', 'category', 'duration_type'] as $c) {
            if (Schema::hasColumn('leave_type', $c) && array_key_exists($c, $data)) {
                $payload[$c] = $data[$c];
            }
        }
        if (Schema::hasColumn('leave_type', 'quota_reset')) {
            $payload['quota_reset'] = !empty($data['quota_reset']) ? 1 : 0;
        }
        if (Schema::hasColumn('leave_type', 'is_active')) {
            $payload['is_active'] = ($data['is_active'] ?? true) ? 1 : 0;
        }
        if (Schema::hasColumn('leave_type', 'category') && empty($payload['category'])) {
            $payload['category'] = 'Paid Leave';
        }
        if (Schema::hasColumn('leave_type', 'duration_type') && empty($payload['duration_type'])) {
            $payload['duration_type'] = 'Days';
        }

        $id = DB::table('leave_type')->insertGetId($payload);

        return response()->json([
            'success' => true,
            'message' => 'Leave type created.',
            'type' => $this->map(DB::table('leave_type')->where('id', $id)->first()),
        ]);
    }

    public function update(Request $request, int $id)
    {
        $row = DB::table('leave_type')->where('id', $id)->first();
        if (!$row) {
            return response()->json(['success' => false, 'message' => 'Not found.'], 404);
        }

        $data = $request->validate([
            'name' => 'sometimes|required|string|max:191',
            'calendar_title' => 'nullable|string|max:191',
            'reference_number' => 'nullable|string|max:100',
            'category' => 'nullable|string|max:50',
            'days' => 'nullable|numeric|min:0',
            'duration_type' => 'nullable|string|max:30',
            'quota_reset' => 'nullable|boolean',
            'is_active' => 'nullable|boolean',
        ]);

        $payload = [];
        if (isset($data['name'])) {
            $payload['name'] = $data['name'];
        }
        if (isset($data['days'])) {
            $payload['days'] = (float) $data['days'];
        }
        foreach (['calendar_title', 'reference_number', 'category', 'duration_type'] as $c) {
            if (Schema::hasColumn('leave_type', $c) && array_key_exists($c, $data)) {
                $payload[$c] = $data[$c];
            }
        }
        if (Schema::hasColumn('leave_type', 'quota_reset') && array_key_exists('quota_reset', $data)) {
            $payload['quota_reset'] = !empty($data['quota_reset']) ? 1 : 0;
        }
        if (Schema::hasColumn('leave_type', 'is_active') && array_key_exists('is_active', $data)) {
            $payload['is_active'] = !empty($data['is_active']) ? 1 : 0;
        }

        if ($payload !== []) {
            DB::table('leave_type')->where('id', $id)->update($payload);
        }

        return response()->json([
            'success' => true,
            'message' => 'Leave type updated.',
            'type' => $this->map(DB::table('leave_type')->where('id', $id)->first()),
        ]);
    }

    public function destroy(int $id)
    {
        $used = DB::table('leave')->where('leave_type', $id)->count();
        if ($used > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Cannot delete: leave type is used by existing leave records.',
            ], 422);
        }
        DB::table('leave_type')->where('id', $id)->delete();

        return response()->json(['success' => true, 'message' => 'Leave type deleted.']);
    }

    public function options()
    {
        if (!Schema::hasTable('leave_module_options')) {
            return response()->json([
                'success' => true,
                'options' => [
                    'allow_edit_quota' => false,
                    'carry_forward' => false,
                    'pro_rata' => false,
                    'show_prorated' => false,
                    'disable_quota_deletion' => false,
                    'create_future_quota' => false,
                ],
            ]);
        }
        $row = DB::table('leave_module_options')->where('id', 1)->first();

        return response()->json([
            'success' => true,
            'options' => [
                'allow_edit_quota' => (bool) ($row->allow_edit_quota ?? false),
                'carry_forward' => (bool) ($row->carry_forward ?? false),
                'pro_rata' => (bool) ($row->pro_rata ?? false),
                'show_prorated' => (bool) ($row->show_prorated ?? false),
                'disable_quota_deletion' => (bool) ($row->disable_quota_deletion ?? false),
                'create_future_quota' => (bool) ($row->create_future_quota ?? false),
            ],
        ]);
    }

    public function saveOptions(Request $request)
    {
        $data = $request->validate([
            'allow_edit_quota' => 'nullable|boolean',
            'carry_forward' => 'nullable|boolean',
            'pro_rata' => 'nullable|boolean',
            'show_prorated' => 'nullable|boolean',
            'disable_quota_deletion' => 'nullable|boolean',
            'create_future_quota' => 'nullable|boolean',
        ]);

        if (!Schema::hasTable('leave_module_options')) {
            return response()->json(['success' => false, 'message' => 'Run database/07_leave_types_settings.sql'], 500);
        }

        $payload = [];
        foreach ($data as $k => $v) {
            $payload[$k] = $v ? 1 : 0;
        }
        DB::table('leave_module_options')->updateOrInsert(['id' => 1], $payload);

        return $this->options();
    }

    protected function map(object $r): array
    {
        return [
            'id' => (int) $r->id,
            'name' => (string) $r->name,
            'title' => (string) $r->name,
            'calendar_title' => (string) ($r->calendar_title ?? $r->name),
            'reference_number' => (string) ($r->reference_number ?? ''),
            'category' => (string) ($r->category ?? 'Paid Leave'),
            'days' => (float) ($r->days ?? 0),
            'leaves_allowed_per_year' => (float) ($r->days ?? 0),
            'duration_type' => (string) ($r->duration_type ?? 'Days'),
            'quota_reset' => (bool) ($r->quota_reset ?? false),
            'is_active' => (bool) ($r->is_active ?? true),
            'company' => 'All Companies',
            'station' => 'All Stations',
        ];
    }
}
