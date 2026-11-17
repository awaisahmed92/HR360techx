<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ApprovalService;
use App\Services\HrLetterMergeService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class HrLetterController extends Controller
{
    public function __construct(
        private HrLetterMergeService $merge,
        private ApprovalService $approvals
    ) {
    }

    protected function ready()
    {
        if (!Schema::hasTable('hr_letter_types') || !Schema::hasTable('hr_letter_instances')) {
            return response()->json(['success' => false, 'message' => 'Run database/35_hr_letters_module.sql'], 503);
        }

        return null;
    }

    public function dashboard()
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $monthStart = date('Y-m-01 00:00:00');

        return response()->json([
            'success' => true,
            'stats' => [
                'templates' => (int) DB::table('hr_letter_types')->where('status', 1)->count(),
                'categories' => Schema::hasTable('hr_letter_categories')
                    ? (int) DB::table('hr_letter_categories')->where('status', 1)->count()
                    : 0,
                'pending_approvals' => (int) DB::table('hr_letter_instances')->where('status', 0)->count(),
                'awaiting_ack' => (int) DB::table('hr_letter_instances')
                    ->where('status', 1)->whereNull('acknowledged_at')->count(),
                'issued_this_month' => (int) DB::table('hr_letter_instances')
                    ->where('created_at', '>=', $monthStart)->count(),
                'employee_letters' => (int) DB::table('hr_letter_instances')->whereNotNull('employee_id')->count(),
                'candidate_letters' => (int) DB::table('hr_letter_instances')->whereNotNull('candidate_id')->count(),
            ],
        ]);
    }

    public function meta()
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $employees = [];
        if (Schema::hasTable('employee')) {
            $employees = DB::table('employee')->where('status', '>', 0)->orderBy('name')
                ->get(['employee_id', 'name', 'employee_code'])->map(fn ($r) => [
                    'id' => (int) $r->employee_id,
                    'name' => (string) $r->name,
                    'code' => (string) ($r->employee_code ?? ''),
                ])->all();
        }
        $candidates = [];
        if (Schema::hasTable('hr_candidate')) {
            $candidates = DB::table('hr_candidate')->orderByDesc('id')->limit(500)
                ->get(['id', 'name', 'email', 'job_id'])->map(fn ($r) => [
                    'id' => (int) $r->id,
                    'name' => (string) $r->name,
                    'email' => (string) ($r->email ?? ''),
                    'job_id' => (int) ($r->job_id ?? 0),
                ])->all();
        }
        $categories = Schema::hasTable('hr_letter_categories')
            ? DB::table('hr_letter_categories')->orderBy('name')->get()->map(fn ($r) => [
                'id' => (int) $r->id,
                'name' => (string) $r->name,
                'status' => (int) ($r->status ?? 1),
            ])->all()
            : [];

        return response()->json([
            'success' => true,
            'options' => [
                'employees' => $employees,
                'candidates' => $candidates,
                'categories' => $categories,
                'page_sizes' => ['A4', 'LETTER', 'LEGAL', 'A3', 'EXECUTIVE'],
                'employee_placeholders' => $this->merge->employeePlaceholders(),
                'candidate_placeholders' => $this->merge->candidatePlaceholders(),
                'variable_field_types' => ['Text', 'TextArea', 'Date', 'List'],
            ],
        ]);
    }

    // ── Categories ──────────────────────────────────────────────

    public function categoriesIndex()
    {
        if ($block = $this->ready()) {
            return $block;
        }
        if (!Schema::hasTable('hr_letter_categories')) {
            return response()->json(['success' => true, 'categories' => []]);
        }
        $rows = DB::table('hr_letter_categories')->orderBy('name')->get()->map(fn ($r) => [
            'id' => (int) $r->id,
            'name' => (string) $r->name,
            'status' => (int) ($r->status ?? 1),
            'template_count' => (int) DB::table('hr_letter_types')->where('category_id', $r->id)->count(),
        ]);

        return response()->json(['success' => true, 'categories' => $rows]);
    }

    public function categoriesStore(Request $request)
    {
        return $this->categoryUpsert($request, null);
    }

    public function categoriesUpdate(Request $request, int $id)
    {
        return $this->categoryUpsert($request, $id);
    }

    public function categoriesDelete(int $id)
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $inUse = (int) DB::table('hr_letter_types')->where('category_id', $id)->count();
        if ($inUse > 0) {
            return response()->json(['success' => false, 'message' => 'Category is used by templates.'], 422);
        }
        DB::table('hr_letter_categories')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    protected function categoryUpsert(Request $request, ?int $id)
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $data = $request->validate([
            'name' => 'required|string|max:191',
            'status' => 'nullable|integer',
        ]);
        $payload = [
            'name' => trim($data['name']),
            'status' => (int) ($data['status'] ?? 1),
            'updated_at' => now(),
        ];
        if ($id === null) {
            $payload['created_at'] = now();
            $newId = (int) DB::table('hr_letter_categories')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('hr_letter_categories')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    // ── Designer types ──────────────────────────────────────────

    public function typesIndex(Request $request)
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $q = DB::table('hr_letter_types as t')
            ->leftJoin('hr_letter_categories as c', 'c.id', '=', 't.category_id')
            ->orderByDesc('t.id')
            ->select('t.*', 'c.name as category_name');
        if ($request->filled('letter_kind')) {
            $q->where('t.letter_kind', (int) $request->query('letter_kind'));
        }
        if ($request->filled('status')) {
            $q->where('t.status', (int) $request->query('status'));
        }
        if ($request->filled('active_only')) {
            $q->where('t.status', 1);
        }
        $rows = $q->get()->map(fn ($r) => $this->mapType($r));

        return response()->json(['success' => true, 'types' => $rows]);
    }

    public function typesShow(int $id)
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $r = DB::table('hr_letter_types as t')
            ->leftJoin('hr_letter_categories as c', 'c.id', '=', 't.category_id')
            ->where('t.id', $id)
            ->first(['t.*', 'c.name as category_name']);
        if (!$r) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }

        return response()->json(['success' => true, 'type' => $this->mapType($r)]);
    }

    public function typesStore(Request $request)
    {
        return $this->typeUpsert($request, null);
    }

    public function typesUpdate(Request $request, int $id)
    {
        return $this->typeUpsert($request, $id);
    }

    public function typesDelete(int $id)
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $used = (int) DB::table('hr_letter_instances')->where('type_id', $id)->count();
        if ($used > 0) {
            DB::table('hr_letter_types')->where('id', $id)->update(['status' => 0, 'updated_at' => now()]);

            return response()->json(['success' => true, 'deactivated' => true]);
        }
        DB::table('hr_letter_types')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    protected function typeUpsert(Request $request, ?int $id)
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'category_id' => 'nullable|integer',
            'letter_kind' => 'nullable|integer|in:0,1',
            'contents' => 'nullable|string',
            'header_html' => 'nullable|string',
            'footer_html' => 'nullable|string',
            'custom_variables' => 'nullable|array',
            'options' => 'nullable|array',
            'employees_access' => 'nullable|array',
            'logo_path' => 'nullable|string|max:255',
            'footer_image_path' => 'nullable|string|max:255',
            'reference_pattern' => 'nullable|string|max:80',
            'status' => 'nullable|integer',
        ]);
        $claims = $request->attributes->get('hr_claims') ?? [];
        $payload = [
            'name' => trim($data['name']),
            'category_id' => isset($data['category_id']) ? (int) $data['category_id'] : null,
            'letter_kind' => (int) ($data['letter_kind'] ?? 0),
            'contents' => $data['contents'] ?? null,
            'header_html' => $data['header_html'] ?? null,
            'footer_html' => $data['footer_html'] ?? null,
            'custom_variables' => json_encode($data['custom_variables'] ?? []),
            'options' => json_encode($data['options'] ?? [
                'page_size' => 'A4',
                'margin_top' => 20,
                'margin_right' => 20,
                'margin_bottom' => 20,
                'margin_left' => 20,
                'skip_approval' => false,
                'logo_align' => 'left',
            ]),
            'employees_access' => json_encode($data['employees_access'] ?? []),
            'logo_path' => $data['logo_path'] ?? null,
            'footer_image_path' => $data['footer_image_path'] ?? null,
            'reference_pattern' => $data['reference_pattern'] ?? null,
            'status' => (int) ($data['status'] ?? 1),
            'updated_at' => now(),
        ];
        if ($id === null) {
            $payload['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
            $payload['created_at'] = now();
            $newId = (int) DB::table('hr_letter_types')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('hr_letter_types')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    protected function mapType(object $r): array
    {
        return [
            'id' => (int) $r->id,
            'category_id' => $r->category_id !== null ? (int) $r->category_id : null,
            'category_name' => (string) ($r->category_name ?? ''),
            'letter_kind' => (int) ($r->letter_kind ?? 0),
            'name' => (string) $r->name,
            'contents' => (string) ($r->contents ?? ''),
            'header_html' => (string) ($r->header_html ?? ''),
            'footer_html' => (string) ($r->footer_html ?? ''),
            'custom_variables' => $this->decodeJson($r->custom_variables ?? null, []),
            'options' => $this->decodeJson($r->options ?? null, []),
            'employees_access' => $this->decodeJson($r->employees_access ?? null, []),
            'logo_path' => (string) ($r->logo_path ?? ''),
            'footer_image_path' => (string) ($r->footer_image_path ?? ''),
            'reference_pattern' => (string) ($r->reference_pattern ?? ''),
            'status' => (int) ($r->status ?? 1),
        ];
    }

    // ── Issue / send ────────────────────────────────────────────

    public function issue(Request $request)
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $data = $request->validate([
            'type_id' => 'required|integer',
            'employee_ids' => 'nullable|array',
            'employee_ids.*' => 'integer',
            'candidate_id' => 'nullable|integer',
            'letter_data' => 'nullable|array',
            'options' => 'nullable|array',
        ]);
        $type = DB::table('hr_letter_types')->where('id', (int) $data['type_id'])->first();
        if (!$type || (int) ($type->status ?? 0) !== 1) {
            return response()->json(['success' => false, 'message' => 'Active template required.'], 422);
        }
        $kind = (int) ($type->letter_kind ?? 0);
        $fieldDefs = $this->decodeJson($type->custom_variables ?? null, []);
        $typeOptions = $this->decodeJson($type->options ?? null, []);
        $sendOptions = array_merge([
            'save_to_documents' => true,
            'email' => false,
            'attachment' => false,
            'esign' => false,
        ], $data['options'] ?? []);
        $custom = $data['letter_data'] ?? [];
        $claims = $request->attributes->get('hr_claims') ?? [];
        $actor = (int) ($claims['employee_id'] ?? 0);
        $created = [];

        if ($kind === 1) {
            $candidateId = (int) ($data['candidate_id'] ?? 0);
            if ($candidateId < 1) {
                return response()->json(['success' => false, 'message' => 'Select a job candidate.'], 422);
            }
            $created[] = $this->issueOne($type, $typeOptions, $fieldDefs, $custom, $sendOptions, $actor, null, $candidateId);
        } else {
            $ids = array_values(array_unique(array_map('intval', $data['employee_ids'] ?? [])));
            $ids = array_filter($ids, fn ($id) => $id > 0);
            if ($ids === []) {
                return response()->json(['success' => false, 'message' => 'Select at least one employee.'], 422);
            }
            foreach ($ids as $employeeId) {
                $created[] = $this->issueOne($type, $typeOptions, $fieldDefs, $custom, $sendOptions, $actor, $employeeId, null);
            }
        }

        return response()->json(['success' => true, 'ids' => $created, 'count' => count($created)]);
    }

    protected function issueOne(
        object $type,
        array $typeOptions,
        array $fieldDefs,
        array $custom,
        array $sendOptions,
        int $actor,
        ?int $employeeId,
        ?int $candidateId
    ): int {
        $ref = $this->merge->nextReference(
            array_merge($typeOptions, ['reference_pattern' => $type->reference_pattern ?? ($typeOptions['reference_pattern'] ?? null)]),
            (int) $type->id
        );
        $builtIn = $employeeId
            ? $this->merge->varsForEmployee($employeeId, $ref)
            : $this->merge->varsForCandidate((int) $candidateId, $ref);
        $contents = $this->merge->merge((string) ($type->contents ?? ''), $builtIn, $custom, $fieldDefs);
        $header = $this->merge->merge((string) ($type->header_html ?? ''), $builtIn, $custom, $fieldDefs);
        $footer = $this->merge->merge((string) ($type->footer_html ?? ''), $builtIn, $custom, $fieldDefs);
        $skip = !empty($typeOptions['skip_approval']);

        $payload = [
            'type_id' => (int) $type->id,
            'employee_id' => $employeeId,
            'candidate_id' => $candidateId,
            'name' => (string) $type->name,
            'reference_number' => $ref,
            'contents' => $contents,
            'header_html' => $header,
            'footer_html' => $footer,
            'letter_data' => json_encode($custom),
            'options' => json_encode($sendOptions),
            'status' => $skip ? 1 : 0,
            'approval_levels' => 0,
            'current_approval_level' => 0,
            'created_by' => $actor ?: null,
            'created_at' => now(),
            'updated_at' => now(),
        ];
        $id = (int) DB::table('hr_letter_instances')->insertGetId($payload);

        if (!$skip && $employeeId) {
            try {
                $boot = $this->approvals->bootstrapRequest(
                    'letter',
                    $employeeId,
                    'hr_letter',
                    $id,
                    'HR Letter: '.$type->name.' ('.$ref.')',
                    ['employee_id' => $employeeId, 'status' => 0]
                );
                DB::table('hr_letter_instances')->where('id', $id)->update([
                    'approval_levels' => (int) ($boot['approval_levels'] ?? 0),
                    'current_approval_level' => (int) ($boot['current_approval_level'] ?? 0),
                    'approval_pending_level' => (int) ($boot['current_approval_level'] ?? 0) ?: null,
                    'level1_approver_id' => $boot['level1_approver_id'] ?? null,
                    'level2_approver_id' => $boot['level2_approver_id'] ?? null,
                    'level3_approver_id' => $boot['level3_approver_id'] ?? null,
                    'status' => (int) ($boot['status'] ?? 0),
                    'updated_at' => now(),
                ]);
            } catch (\Throwable $e) {
                // Keep pending; admins can still approve from the module.
            }
        }

        return $id;
    }

    // ── Instances ───────────────────────────────────────────────

    public function instancesIndex(Request $request)
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $claims = $request->attributes->get('hr_claims') ?? [];
        $uid = (int) ($claims['employee_id'] ?? 0);
        $isAdmin = (int) ($claims['user_status'] ?? 0) === 2 || !empty($claims['is_superuser']);

        $q = DB::table('hr_letter_instances as i')
            ->leftJoin('hr_letter_types as t', 't.id', '=', 'i.type_id')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'i.employee_id')
            ->orderByDesc('i.id')
            ->select(
                'i.*',
                't.name as type_name',
                't.letter_kind',
                'e.name as employee_name',
                'e.employee_code',
                'e.line_manager'
            );
        if (Schema::hasTable('hr_candidate')) {
            $q->leftJoin('hr_candidate as c', 'c.id', '=', 'i.candidate_id')
                ->addSelect('c.name as candidate_name', 'c.email as candidate_email');
        }

        $kind = $request->query('kind');
        if ($kind === 'employee') {
            $q->whereNotNull('i.employee_id');
        } elseif ($kind === 'candidate') {
            $q->whereNotNull('i.candidate_id');
        }
        if ($request->filled('status')) {
            $q->where('i.status', (int) $request->query('status'));
        }
        if ($request->filled('type_id')) {
            $q->where('i.type_id', (int) $request->query('type_id'));
        }
        if ($request->filled('from')) {
            $q->whereDate('i.created_at', '>=', $request->query('from'));
        }
        if ($request->filled('to')) {
            $q->whereDate('i.created_at', '<=', $request->query('to'));
        }
        if (!$isAdmin && $uid > 0) {
            $q->where(function ($w) use ($uid) {
                $w->where('i.employee_id', $uid)
                    ->orWhere('i.created_by', $uid)
                    ->orWhere('i.level1_approver_id', $uid)
                    ->orWhere('i.level2_approver_id', $uid)
                    ->orWhere('i.level3_approver_id', $uid)
                    ->orWhere('e.line_manager', $uid);
            });
        }

        $rows = $q->limit(500)->get()->map(fn ($r) => $this->mapInstance($r));

        return response()->json(['success' => true, 'instances' => $rows]);
    }

    public function instancesShow(int $id)
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $r = $this->instanceRow($id);
        if (!$r) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }

        return response()->json(['success' => true, 'instance' => $this->mapInstance($r)]);
    }

    public function instancesUpdate(Request $request, int $id)
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $data = $request->validate([
            'contents' => 'nullable|string',
            'header_html' => 'nullable|string',
            'footer_html' => 'nullable|string',
        ]);
        $payload = ['updated_at' => now()];
        foreach (['contents', 'header_html', 'footer_html'] as $col) {
            if (array_key_exists($col, $data)) {
                $payload[$col] = $data[$col];
            }
        }
        DB::table('hr_letter_instances')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    public function acknowledge(Request $request, int $id)
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $claims = $request->attributes->get('hr_claims') ?? [];
        $uid = (int) ($claims['employee_id'] ?? 0);
        $note = (string) $request->input('ack_note', '');
        $row = DB::table('hr_letter_instances')->where('id', $id)->first();
        if (!$row) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }
        if ((int) ($row->status ?? 0) !== 1) {
            return response()->json(['success' => false, 'message' => 'Only approved letters can be acknowledged.'], 422);
        }
        DB::table('hr_letter_instances')->where('id', $id)->update([
            'acknowledged_at' => now(),
            'acknowledged_by' => $uid ?: null,
            'ack_note' => $note !== '' ? mb_substr($note, 0, 500) : null,
            'updated_at' => now(),
        ]);

        return response()->json(['success' => true]);
    }

    public function approve(Request $request, int $id)
    {
        return $this->actApproval($request, $id, 1);
    }

    public function reject(Request $request, int $id)
    {
        return $this->actApproval($request, $id, 2);
    }

    protected function actApproval(Request $request, int $id, int $status)
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $claims = $request->attributes->get('hr_claims') ?? [];
        $uid = (int) ($claims['employee_id'] ?? 0);
        $isAdmin = (int) ($claims['user_status'] ?? 0) === 2 || !empty($claims['is_superuser']);
        $row = $this->instanceRow($id);
        if (!$row) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }
        if ((int) ($row->status ?? -1) !== 0) {
            return response()->json(['success' => false, 'message' => 'Letter is not pending approval.'], 422);
        }

        $can = false;
        try {
            $can = $this->approvals->canActOnTravel($row, $uid, $isAdmin, 'letter');
        } catch (\Throwable $e) {
            $can = $isAdmin || $uid === (int) ($row->line_manager ?? 0) || $uid === (int) ($row->level1_approver_id ?? 0);
        }
        if (!$can && !$isAdmin) {
            return response()->json(['success' => false, 'message' => 'Not allowed to act on this letter.'], 403);
        }

        try {
            $result = $this->approvals->act(
                'letter',
                $row,
                $uid,
                $isAdmin,
                $status === 1,
                'hr_letter',
                (string) ($row->name ?? 'HR Letter'),
                $request->input('remarks')
            );
            if (!empty($result['ok'])) {
                return response()->json(['success' => true, 'result' => $result]);
            }
        } catch (\Throwable $e) {
            // Fall through to direct status update.
        }

        DB::table('hr_letter_instances')->where('id', $id)->update([
            'status' => $status,
            'current_approval_level' => 0,
            'approval_pending_level' => null,
            'updated_at' => now(),
        ]);

        return response()->json(['success' => true]);
    }

    public function print(Request $request, int $id)
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $r = $this->instanceRow($id);
        if (!$r) {
            return response('Not found', 404);
        }
        $opts = $this->decodeJson($r->options ?? null, []);
        $typeOpts = [];
        if (!empty($r->type_id)) {
            $type = DB::table('hr_letter_types')->where('id', $r->type_id)->first();
            $typeOpts = $this->decodeJson($type->options ?? null, []);
        }
        $page = strtoupper((string) ($typeOpts['page_size'] ?? 'A4'));
        $mt = (float) ($typeOpts['margin_top'] ?? 20);
        $mr = (float) ($typeOpts['margin_right'] ?? 20);
        $mb = (float) ($typeOpts['margin_bottom'] ?? 20);
        $ml = (float) ($typeOpts['margin_left'] ?? 20);
        $title = htmlspecialchars((string) ($r->name ?? 'HR Letter'));
        $ref = htmlspecialchars((string) ($r->reference_number ?? ''));
        $header = (string) ($r->header_html ?? '');
        $body = (string) ($r->contents ?? '');
        $footer = (string) ($r->footer_html ?? '');
        $download = $request->boolean('download');
        $filename = 'hr-letter-'.$id.'.html';

        $html = '<!DOCTYPE html><html><head><meta charset="utf-8"><title>'.$title.'</title>
<style>
@page{size:'.$page.';margin:'.$mt.'mm '.$mr.'mm '.$mb.'mm '.$ml.'mm}
body{margin:0;background:#eef2f6;color:#1f2937;font-family:Segoe UI,Arial,sans-serif}
.toolbar{padding:12px 16px;background:#fff;border-bottom:1px solid #e5e7eb}
button{padding:8px 14px;background:#1E4B8C;color:#fff;border:0;border-radius:6px;cursor:pointer}
.page{max-width:820px;margin:24px auto;background:#fff;padding:36px 42px;box-shadow:0 12px 40px rgba(15,23,42,.08)}
.meta{color:#64748b;font-size:13px;margin-bottom:16px}
.header,.footer{margin:12px 0;color:#334155}
.body{line-height:1.7;font-size:15px}
@media print{body{background:#fff}.toolbar{display:none}.page{box-shadow:none;margin:0;max-width:none}}
</style></head><body>
<div class="toolbar"><button onclick="window.print()">Print / Save PDF</button></div>
<div class="page">
<div class="meta"><b>'.$title.'</b>'.($ref !== '' ? ' · Ref '.$ref : '').'</div>
'.($header !== '' ? '<div class="header">'.$header.'</div>' : '').'
<div class="body">'.$body.'</div>
'.($footer !== '' ? '<div class="footer">'.$footer.'</div>' : '').'
</div></body></html>';

        $headers = ['Content-Type' => 'text/html; charset=UTF-8'];
        if ($download) {
            $headers['Content-Disposition'] = 'attachment; filename="'.$filename.'"';
        }

        return response($html, 200, $headers);
    }

    // ── Reports ─────────────────────────────────────────────────

    public function reportEmployeeLetters(Request $request)
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $request->merge(['kind' => 'employee']);

        return $this->instancesIndex($request);
    }

    public function reportCustomVariables(Request $request)
    {
        if ($block = $this->ready()) {
            return $block;
        }
        $rows = [];
        $list = $this->instancesIndex($request)->getData(true);
        foreach (($list['instances'] ?? []) as $inst) {
            $data = is_array($inst['letter_data'] ?? null) ? $inst['letter_data'] : [];
            $flat = [
                'id' => $inst['id'],
                'name' => $inst['name'],
                'reference_number' => $inst['reference_number'],
                'recipient' => $inst['employee_name'] ?: $inst['candidate_name'],
                'type_name' => $inst['type_name'],
                'status_label' => $inst['status_label'],
                'created_at' => $inst['created_at'],
            ];
            foreach ($data as $k => $v) {
                $flat['var_'.$k] = is_scalar($v) ? (string) $v : json_encode($v);
            }
            $rows[] = $flat;
        }

        return response()->json(['success' => true, 'rows' => $rows]);
    }

    protected function instanceRow(int $id): ?object
    {
        $q = DB::table('hr_letter_instances as i')
            ->leftJoin('hr_letter_types as t', 't.id', '=', 'i.type_id')
            ->leftJoin('employee as e', 'e.employee_id', '=', 'i.employee_id')
            ->where('i.id', $id)
            ->select(
                'i.*',
                't.name as type_name',
                't.letter_kind',
                't.options as type_options',
                'e.name as employee_name',
                'e.employee_code',
                'e.line_manager'
            );
        if (Schema::hasTable('hr_candidate')) {
            $q->leftJoin('hr_candidate as c', 'c.id', '=', 'i.candidate_id')
                ->addSelect('c.name as candidate_name', 'c.email as candidate_email');
        }

        return $q->first();
    }

    protected function mapInstance(object $r): array
    {
        $status = (int) ($r->status ?? 0);

        return [
            'id' => (int) $r->id,
            'type_id' => (int) ($r->type_id ?? 0),
            'type_name' => (string) ($r->type_name ?? $r->name ?? ''),
            'letter_kind' => (int) ($r->letter_kind ?? ($r->candidate_id ? 1 : 0)),
            'employee_id' => $r->employee_id !== null ? (int) $r->employee_id : null,
            'candidate_id' => $r->candidate_id !== null ? (int) $r->candidate_id : null,
            'employee_name' => (string) ($r->employee_name ?? ''),
            'employee_code' => (string) ($r->employee_code ?? ''),
            'candidate_name' => (string) ($r->candidate_name ?? ''),
            'candidate_email' => (string) ($r->candidate_email ?? ''),
            'name' => (string) ($r->name ?? ''),
            'reference_number' => (string) ($r->reference_number ?? ''),
            'contents' => (string) ($r->contents ?? ''),
            'header_html' => (string) ($r->header_html ?? ''),
            'footer_html' => (string) ($r->footer_html ?? ''),
            'letter_data' => $this->decodeJson($r->letter_data ?? null, []),
            'options' => $this->decodeJson($r->options ?? null, []),
            'status' => $status,
            'status_label' => match ($status) {
                1 => 'Approved',
                2 => 'Rejected',
                default => 'Pending',
            },
            'acknowledged_at' => (string) ($r->acknowledged_at ?? ''),
            'acknowledged_by' => $r->acknowledged_by !== null ? (int) $r->acknowledged_by : null,
            'ack_note' => (string) ($r->ack_note ?? ''),
            'created_by' => $r->created_by !== null ? (int) $r->created_by : null,
            'created_at' => (string) ($r->created_at ?? ''),
            'can_approve' => $status === 0,
        ];
    }

    /** @return array<mixed> */
    protected function decodeJson(mixed $value, array $default): array
    {
        if (is_array($value)) {
            return $value;
        }
        if ($value === null || $value === '') {
            return $default;
        }
        if (is_string($value)) {
            $decoded = json_decode($value, true);

            return is_array($decoded) ? $decoded : $default;
        }

        return $default;
    }
}
