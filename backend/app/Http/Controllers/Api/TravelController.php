<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ApprovalService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TravelController extends Controller
{
    public function __construct(private ApprovalService $approvals)
    {
    }

    public function index(Request $request)
    {
        $claims = $request->attributes->get('hr_claims');
        $uid = (int) ($claims['employee_id'] ?? 0);
        $isAdmin = (int) ($claims['user_status'] ?? 0) === 2;
        $q = trim((string) $request->query('q', ''));
        $page = max(1, (int) $request->query('page', 1));
        $perPage = min(100, max(5, (int) $request->query('per_page', 20)));

        $query = DB::table('travel_request as t')
            ->leftJoin('employee as e', 'e.employee_id', '=', 't.employee_id')
            ->leftJoin('project as p', 'p.project_id', '=', 't.project_id')
            ->select('t.*', 'e.name as employee_name', 'e.line_manager', 'p.name as project_name')
            ->orderByDesc('t.id');

        if (!$isAdmin) {
            $query->where(function ($w) use ($uid) {
                $w->where('t.employee_id', $uid)
                    ->orWhere('e.line_manager', $uid)
                    ->orWhere('t.level1_approver_id', $uid)
                    ->orWhere('t.level2_approver_id', $uid)
                    ->orWhere('t.level3_approver_id', $uid);
            });
        }
        if ($q !== '') {
            $query->where(function ($w) use ($q) {
                $w->where('t.request_no', 'like', "%{$q}%")
                    ->orWhere('t.purpose', 'like', "%{$q}%")
                    ->orWhere('e.name', 'like', "%{$q}%");
            });
        }

        $total = (clone $query)->count();
        $rows = $query->forPage($page, $perPage)->get()
            ->map(fn ($r) => $this->map($r, $uid, $isAdmin));

        return response()->json([
            'success' => true,
            'travels' => $rows,
            'pagination' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'total_pages' => (int) ceil($total / max(1, $perPage)),
            ],
        ]);
    }

    public function store(Request $request)
    {
        $claims = $request->attributes->get('hr_claims');
        $uid = (int) ($claims['employee_id'] ?? 0);
        $isAdmin = (int) ($claims['user_status'] ?? 0) === 2;

        $data = $request->validate([
            'employee_id' => 'nullable|integer',
            'travel_type' => 'nullable|string|max:100',
            'purpose' => 'required|string',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'expected_budget' => 'nullable|numeric|min:0',
            'actual_budget' => 'nullable|numeric|min:0',
            'project_id' => 'nullable|integer',
            'destinations' => 'nullable|array',
            'destinations.*.place_of_visit' => 'nullable|string|max:191',
            'destinations.*.travel_mode' => 'nullable|string|max:100',
            'destinations.*.arrangement_type' => 'nullable|string|max:100',
            'destinations.*.travel_date' => 'nullable|date',
        ]);

        $employeeId = (int) ($data['employee_id'] ?? $uid);
        if (!$isAdmin) {
            $employeeId = $uid;
        }
        if ($employeeId < 1) {
            return response()->json(['success' => false, 'message' => 'Employee is required.'], 422);
        }

        $no = (string) (time() % 1000000);
        $destinations = $data['destinations'] ?? [];
        $firstPlace = '';
        $firstMode = null;
        if (is_array($destinations) && count($destinations) > 0) {
            $firstPlace = (string) ($destinations[0]['place_of_visit'] ?? '');
            $firstMode = $destinations[0]['travel_mode'] ?? null;
        }

        $id = DB::table('travel_request')->insertGetId([
            'request_no' => $no,
            'employee_id' => $employeeId,
            'project_id' => $data['project_id'] ?? 1,
            'start_date' => $data['start_date'],
            'end_date' => $data['end_date'],
            'from_location' => $firstPlace !== '' ? '—' : '—',
            'to_location' => $firstPlace !== '' ? $firstPlace : '—',
            'mode_of_travel' => $firstMode,
            'purpose' => $data['purpose'],
            'travel_type' => $data['travel_type'] ?? null,
            'advance_amount' => $data['expected_budget'] ?? 0,
            'expected_budget' => $data['expected_budget'] ?? 0,
            'actual_budget' => $data['actual_budget'] ?? 0,
            'status' => 0,
            'created_at' => now(),
        ]);

        if (is_array($destinations)) {
            foreach ($destinations as $d) {
                if (empty($d['place_of_visit']) && empty($d['travel_mode']) && empty($d['arrangement_type'])) {
                    continue;
                }
                DB::table('travel_destination')->insert([
                    'travel_id' => $id,
                    'place_of_visit' => (string) ($d['place_of_visit'] ?? ''),
                    'travel_mode' => $d['travel_mode'] ?? null,
                    'arrangement_type' => $d['arrangement_type'] ?? null,
                    'travel_date' => $d['travel_date'] ?? null,
                ]);
            }
        }

        $empName = (string) (DB::table('employee')->where('employee_id', $employeeId)->value('name') ?? 'Employee');
        $title = 'Travel #'.$no.' — '.$empName.': '.$data['purpose'];

        try {
            $boot = $this->approvals->bootstrapRequest('travel', $employeeId, 'travel', $id, $title);
            DB::table('travel_request')->where('id', $id)->update($boot);
        } catch (\Throwable $e) {
            // Tables may not exist yet — keep pending single-level
        }

        return response()->json([
            'success' => true,
            'message' => 'Travel request submitted.',
            'request_no' => $no,
            'id' => $id,
        ]);
    }

    public function show(Request $request, int $id)
    {
        $claims = $request->attributes->get('hr_claims');
        $uid = (int) ($claims['employee_id'] ?? 0);
        $isAdmin = (int) ($claims['user_status'] ?? 0) === 2;

        $row = DB::table('travel_request as t')
            ->leftJoin('employee as e', 'e.employee_id', '=', 't.employee_id')
            ->select('t.*', 'e.name as employee_name', 'e.line_manager')
            ->where('t.id', $id)
            ->first();
        if (!$row) {
            return response()->json(['success' => false, 'message' => 'Not found.'], 404);
        }

        $destinations = DB::table('travel_destination')
            ->where('travel_id', $id)
            ->orderBy('id')
            ->get();

        return response()->json([
            'success' => true,
            'travel' => $this->map($row, $uid, $isAdmin),
            'destinations' => $destinations,
        ]);
    }

    public function approve(Request $request)
    {
        return $this->act($request, true);
    }

    public function reject(Request $request)
    {
        return $this->act($request, false);
    }

    public function projects()
    {
        $rows = DB::table('project')->orderBy('name')->get(['project_id as id', 'name']);

        return response()->json(['success' => true, 'projects' => $rows]);
    }

    public function employees()
    {
        $rows = DB::table('employee')
            ->orderBy('name')
            ->get(['employee_id as id', 'name', 'employee_code']);

        return response()->json(['success' => true, 'employees' => $rows]);
    }

    public function meta()
    {
        $cfg = [];
        try {
            $cfg = $this->approvals->settings('travel');
        } catch (\Throwable $e) {
            $cfg = ['approval_levels' => 1];
        }

        return response()->json([
            'success' => true,
            'travel_types' => ['Domestic', 'International', 'Local', 'Site Visit'],
            'travel_modes' => ['Road', 'Air', 'Rail', 'Bus', 'Other'],
            'arrangement_types' => ['Company Arranged', 'Self Arranged', 'Client Arranged'],
            'next_reference' => (string) (time() % 1000000),
            'approval' => $cfg,
        ]);
    }

    protected function act(Request $request, bool $approve)
    {
        $claims = $request->attributes->get('hr_claims');
        $uid = (int) ($claims['employee_id'] ?? 0);
        $isAdmin = (int) ($claims['user_status'] ?? 0) === 2;
        $id = (int) $request->input('id');

        $row = DB::table('travel_request as t')
            ->leftJoin('employee as e', 'e.employee_id', '=', 't.employee_id')
            ->select('t.*', 'e.line_manager', 'e.name as employee_name')
            ->where('t.id', $id)
            ->first();

        if (!$row) {
            return response()->json(['success' => false, 'message' => 'Not found.'], 404);
        }

        $title = 'Travel #'.$row->request_no.' — '.($row->employee_name ?? '').': '.($row->purpose ?? '');

        try {
            $result = $this->approvals->act('travel', $row, $uid, $isAdmin, $approve, 'travel', $title, $request->input('remarks'));
        } catch (\Throwable $e) {
            // Legacy fallback
            if ((int) $row->status !== 0) {
                return response()->json(['success' => false, 'message' => 'Already finalized.'], 422);
            }
            $lm = (int) ($row->line_manager ?? 0);
            $owner = (int) $row->employee_id;
            if (!$isAdmin && !($lm === $uid && $owner !== $uid)) {
                return response()->json(['success' => false, 'message' => 'Not allowed.'], 403);
            }
            DB::table('travel_request')->where('id', $id)->update(['status' => $approve ? 1 : 2]);

            return response()->json(['success' => true, 'message' => 'Travel '.($approve ? 'approved' : 'rejected').'.']);
        }

        if (!$result['ok']) {
            $code = str_contains($result['message'], 'Not allowed') ? 403 : 422;

            return response()->json(['success' => false, 'message' => $result['message']], $code);
        }

        return response()->json(['success' => true, 'message' => $result['message'], 'status' => $result['status'] ?? null]);
    }

    protected function map(object $r, int $uid, bool $isAdmin): array
    {
        $st = (int) $r->status;
        $owner = (int) $r->employee_id;
        $can = false;
        try {
            $can = $this->approvals->canActOnTravel($r, $uid, $isAdmin);
        } catch (\Throwable $e) {
            $can = $st === 0 && ($isAdmin || $owner !== $uid);
        }

        $label = 'Level 1 Approval Pending';
        try {
            $label = $this->approvals->statusLabel($r);
        } catch (\Throwable $e) {
            $label = match ($st) {
                1 => 'Approved',
                2 => 'Rejected',
                default => 'Level 1 Approval Pending',
            };
        }

        return [
            'id' => (int) $r->id,
            'request_no' => (string) $r->request_no,
            'reference_number' => (string) $r->request_no,
            'employee_id' => $owner,
            'employee_name' => (string) ($r->employee_name ?? ''),
            'project_id' => (int) ($r->project_id ?? 0),
            'project_name' => (string) ($r->project_name ?? ''),
            'travel_type' => (string) ($r->travel_type ?? ''),
            'purpose' => (string) ($r->purpose ?? ''),
            'start_date' => (string) $r->start_date,
            'end_date' => (string) $r->end_date,
            'expected_budget' => (float) ($r->expected_budget ?? $r->advance_amount ?? 0),
            'actual_budget' => (float) ($r->actual_budget ?? 0),
            'from_location' => (string) ($r->from_location ?? ''),
            'to_location' => (string) ($r->to_location ?? ''),
            'mode_of_travel' => (string) ($r->mode_of_travel ?? ''),
            'status' => $st,
            'status_label' => $label,
            'approval_levels' => (int) ($r->approval_levels ?? 1),
            'current_approval_level' => (int) ($r->current_approval_level ?? 1),
            'can_approve' => $can,
            'created_at' => (string) ($r->created_at ?? ''),
        ];
    }
}
