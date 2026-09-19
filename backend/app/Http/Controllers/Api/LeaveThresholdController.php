<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class LeaveThresholdController extends Controller
{
    public function index()
    {
        if (!Schema::hasTable('leave_threshold')) {
            return response()->json(['success' => false, 'message' => 'Run database/18_leave_threshold_assign.sql'], 503);
        }

        $rows = DB::table('leave_threshold as t')
            ->leftJoin('designation as d', 'd.designation_id', '=', 't.designation_id')
            ->orderByDesc('t.id')
            ->get([
                't.*',
                'd.name as designation_name',
            ])
            ->map(fn ($r) => $this->map($r));

        return response()->json(['success' => true, 'rows' => $rows]);
    }

    public function store(Request $request)
    {
        return $this->upsert($request, null);
    }

    public function update(Request $request, int $id)
    {
        return $this->upsert($request, $id);
    }

    public function destroy(int $id)
    {
        if (!Schema::hasTable('leave_threshold')) {
            return response()->json(['success' => false, 'message' => 'Table missing.'], 503);
        }
        DB::table('leave_threshold')->where('id', $id)->delete();

        return response()->json(['success' => true, 'message' => 'Deleted.']);
    }

    protected function upsert(Request $request, ?int $id)
    {
        if (!Schema::hasTable('leave_threshold')) {
            return response()->json(['success' => false, 'message' => 'Run database/18_leave_threshold_assign.sql'], 503);
        }

        $data = $request->validate([
            'designation_id' => 'required|integer',
            'leave_type_ids' => 'required|array|min:1',
            'leave_type_ids.*' => 'integer',
            'threshold_from' => 'required|integer|min:0',
            'threshold_to' => 'required|integer|min:0',
            'status' => 'nullable|integer',
        ]);

        $claims = $request->attributes->get('hr_claims') ?? [];
        $actor = (int) ($claims['employee_id'] ?? 0) ?: null;
        $csv = implode(',', array_map('intval', $data['leave_type_ids']));

        $payload = [
            'designation_id' => (int) $data['designation_id'],
            'leave_type_id' => $csv,
            'threshold_from' => (int) $data['threshold_from'],
            'threshold_to' => (int) $data['threshold_to'],
            'status' => (int) ($data['status'] ?? 1),
        ];

        if ($id === null) {
            $payload['created_by'] = $actor;
            $newId = (int) DB::table('leave_threshold')->insertGetId($payload);
            $row = DB::table('leave_threshold as t')
                ->leftJoin('designation as d', 'd.designation_id', '=', 't.designation_id')
                ->where('t.id', $newId)
                ->first(['t.*', 'd.name as designation_name']);

            return response()->json(['success' => true, 'message' => 'Created.', 'row' => $this->map($row)]);
        }

        $payload['updated_by'] = $actor;
        DB::table('leave_threshold')->where('id', $id)->update($payload);
        $row = DB::table('leave_threshold as t')
            ->leftJoin('designation as d', 'd.designation_id', '=', 't.designation_id')
            ->where('t.id', $id)
            ->first(['t.*', 'd.name as designation_name']);

        return response()->json(['success' => true, 'message' => 'Updated.', 'row' => $this->map($row)]);
    }

    protected function map(object $r): array
    {
        $ids = array_values(array_filter(array_map('intval', explode(',', (string) ($r->leave_type_id ?? '')))));
        $names = [];
        if ($ids !== [] && Schema::hasTable('leave_type')) {
            $names = DB::table('leave_type')->whereIn('id', $ids)->pluck('name')->all();
        }

        return [
            'id' => (int) $r->id,
            'designation_id' => (int) $r->designation_id,
            'designation_name' => (string) ($r->designation_name ?? ''),
            'leave_type_ids' => $ids,
            'leave_type_names' => $names,
            'leave_type_label' => implode(', ', $names),
            'threshold_from' => (int) $r->threshold_from,
            'threshold_to' => (int) $r->threshold_to,
            'status' => (int) ($r->status ?? 1),
        ];
    }
}
