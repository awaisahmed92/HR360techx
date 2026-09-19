<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Phase 5 — device status UI. ZKTeco ingest stays server-side;
 * Flutter only lists devices and recent raw punches.
 */
class DevicesController extends Controller
{
    public function overview()
    {
        $hasDevices = Schema::hasTable('biometric_devices');
        $hasPunches = Schema::hasTable('device_attendance');

        $deviceCount = $hasDevices ? (int) DB::table('biometric_devices')->count() : 0;
        $activeCount = $hasDevices
            ? (int) DB::table('biometric_devices')->where(function ($q) {
                $q->where('is_active', 1)->orWhere('status', 'active');
            })->count()
            : 0;

        $today = now()->toDateString();
        $punchesToday = 0;
        $unprocessed = 0;
        $lastPunchAt = null;
        if ($hasPunches) {
            $punchesToday = (int) DB::table('device_attendance')
                ->whereDate('punch_time', $today)
                ->count();
            $unprocessed = (int) DB::table('device_attendance')
                ->where('processed', 0)
                ->count();
            $lastPunchAt = DB::table('device_attendance')->max('punch_time');
        }

        return response()->json([
            'success' => true,
            'tables' => [
                'biometric_devices' => $hasDevices,
                'device_attendance' => $hasPunches,
            ],
            'stats' => [
                'devices' => $deviceCount,
                'active_devices' => $activeCount,
                'punches_today' => $punchesToday,
                'unprocessed' => $unprocessed,
                'last_punch_at' => $lastPunchAt,
            ],
        ]);
    }

    public function index()
    {
        if (!Schema::hasTable('biometric_devices')) {
            return response()->json([
                'success' => true,
                'devices' => [],
                'message' => 'biometric_devices table not present in this tenant',
            ]);
        }

        $rows = DB::table('biometric_devices')->orderByDesc('id')->get()->map(function ($r) {
            $status = (string) ($r->status ?? 'inactive');
            $isActive = (int) ($r->is_active ?? 0) === 1 || $status === 'active';

            return [
                'id' => (int) $r->id,
                'name' => (string) $r->name,
                'device_type' => (string) ($r->device_type ?? ''),
                'serial_number' => (string) ($r->serial_number ?? ''),
                'ip_address' => (string) ($r->ip_address ?? ''),
                'port' => (int) ($r->port ?? 80),
                'protocol' => (string) ($r->protocol ?? ''),
                'timezone' => (string) ($r->timezone ?? 'Asia/Karachi'),
                'status' => $status,
                'status_label' => ucfirst($status),
                'is_active' => $isActive,
                'last_sync' => $r->last_sync ?? null,
                'last_error' => (string) ($r->last_error ?? ''),
                'endpoint_url' => (string) ($r->endpoint_url ?? ''),
            ];
        });

        return response()->json(['success' => true, 'devices' => $rows]);
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
        if (!Schema::hasTable('biometric_devices')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }
        DB::table('biometric_devices')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function punches(Request $request)
    {
        if (!Schema::hasTable('device_attendance')) {
            return response()->json([
                'success' => true,
                'punches' => [],
                'message' => 'device_attendance table not present in this tenant',
            ]);
        }

        $limit = min(200, max(20, (int) $request->query('limit', 80)));
        $processed = $request->query('processed');
        $q = DB::table('device_attendance as da')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'da.employee_id')
            ->orderByDesc('da.punch_time')
            ->select(
                'da.*',
                'e.name as employee_name',
                'e.employee_code as emp_code'
            );

        if ($processed !== null && $processed !== '') {
            $q->where('da.processed', (int) $processed);
        }
        if ($request->filled('device_id')) {
            $q->where('da.device_id', (string) $request->query('device_id'));
        }

        $rows = $q->limit($limit)->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'device_id' => (string) ($r->device_id ?? ''),
            'device_name' => (string) ($r->device_name ?? ''),
            'employee_code' => (string) ($r->employee_code ?? ''),
            'employee_id' => $r->employee_id ? (int) $r->employee_id : null,
            'employee_name' => (string) ($r->employee_name ?? $r->emp_code ?? ''),
            'punch_time' => $r->punch_time,
            'punch_type' => (string) ($r->punch_type ?? 'in'),
            'verify_mode' => (string) ($r->verify_mode ?? ''),
            'processed' => (int) ($r->processed ?? 0) === 1,
            'processed_at' => $r->processed_at ?? null,
            'created_at' => $r->created_at ?? null,
        ]);

        return response()->json(['success' => true, 'punches' => $rows]);
    }

    protected function upsert(Request $request, ?int $id)
    {
        if (!Schema::hasTable('biometric_devices')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'device_type' => 'nullable|string|max:100',
            'serial_number' => 'required|string|max:100',
            'ip_address' => 'required|string|max:50',
            'port' => 'nullable|integer|min:1|max:65535',
            'protocol' => 'nullable|string|max:50',
            'timezone' => 'nullable|string|max:50',
            'status' => 'nullable|string|in:active,inactive,testing,error',
            'is_active' => 'nullable|boolean',
            'endpoint_url' => 'nullable|string|max:255',
            'employee_identifier' => 'nullable|string|max:50',
        ]);

        $status = $data['status'] ?? 'inactive';
        $isActive = array_key_exists('is_active', $data)
            ? (int) (bool) $data['is_active']
            : ($status === 'active' ? 1 : 0);

        $payload = [
            'name' => $data['name'],
            'device_type' => $data['device_type'] ?? 'ZKTeco',
            'serial_number' => $data['serial_number'],
            'ip_address' => $data['ip_address'],
            'port' => (int) ($data['port'] ?? 80),
            'protocol' => $data['protocol'] ?? 'http',
            'timezone' => $data['timezone'] ?? 'Asia/Karachi',
            'status' => $status,
            'is_active' => $isActive,
            'endpoint_url' => $data['endpoint_url'] ?? null,
            'employee_identifier' => $data['employee_identifier'] ?? 'employee_id',
            'updated_at' => now(),
        ];

        if ($id === null) {
            $payload['created_at'] = now();
            $newId = (int) DB::table('biometric_devices')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }

        DB::table('biometric_devices')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }
}
