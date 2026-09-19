<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class LetterController extends Controller
{
    public function index()
    {
        if (!Schema::hasTable('letter')) {
            return response()->json(['success' => false, 'message' => 'Run database/23_letter.sql'], 503);
        }
        $rows = DB::table('letter')->orderByDesc('id')->get()->map(fn ($r) => $this->map($r));

        return response()->json(['success' => true, 'letters' => $rows]);
    }

    public function show(int $id)
    {
        $r = DB::table('letter')->where('id', $id)->first();
        if (!$r) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }

        return response()->json(['success' => true, 'letter' => $this->map($r)]);
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
        DB::table('letter')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    /** Render letter with employee placeholders. */
    public function preview(Request $request, int $id)
    {
        $letter = DB::table('letter')->where('id', $id)->first();
        if (!$letter) {
            return response()->json(['success' => false, 'message' => 'Letter not found'], 404);
        }
        $employeeId = (int) $request->query('employee_id', 0);
        $vars = [
            'employee_name' => '',
            'employee_code' => '',
            'designation' => '',
            'department' => '',
            'joining_date' => '',
            'leaving_date' => '',
            'company_name' => 'Organization',
        ];
        if ($employeeId > 0 && Schema::hasTable('employee')) {
            $e = DB::table('employee as e')
                ->leftJoin('designation as d', 'd.designation_id', '=', 'e.designation')
                ->leftJoin('department as dep', 'dep.department_id', '=', 'e.department')
                ->where('e.employee_id', $employeeId)
                ->first([
                    'e.name',
                    'e.employee_code',
                    'e.joining_date',
                    'e.leaving_date',
                    'e.exit_date',
                    'd.name as designation_name',
                    'dep.name as department_name',
                ]);
            if ($e) {
                $vars['employee_name'] = (string) ($e->name ?? '');
                $vars['employee_code'] = (string) ($e->employee_code ?? '');
                $vars['designation'] = (string) ($e->designation_name ?? '');
                $vars['department'] = (string) ($e->department_name ?? '');
                $vars['joining_date'] = (string) ($e->joining_date ?? '');
                $vars['leaving_date'] = (string) ($e->leaving_date ?? $e->exit_date ?? '');
            }
        }
        if (Schema::hasTable('company')) {
            $c = DB::table('company')->orderBy('company_id')->value('name');
            if ($c) {
                $vars['company_name'] = (string) $c;
            }
        }

        $body = (string) ($letter->content ?? '');
        foreach ($vars as $k => $v) {
            $body = str_replace('{{'.$k.'}}', $v, $body);
        }

        return response()->json([
            'success' => true,
            'preview' => [
                'name' => (string) $letter->name,
                'content' => $body,
                'page_size' => (string) ($letter->page_size ?? 'A4'),
                'margin_top' => (float) ($letter->margin_top ?? 20),
                'margin_right' => (float) ($letter->margin_right ?? 20),
                'margin_bottom' => (float) ($letter->margin_bottom ?? 20),
                'margin_left' => (float) ($letter->margin_left ?? 20),
                'variables' => $vars,
            ],
        ]);
    }

    public function meta()
    {
        $employees = [];
        if (Schema::hasTable('employee')) {
            $employees = DB::table('employee')->where('status', '>', 0)->orderBy('name')
                ->get(['employee_id', 'name', 'employee_code'])->map(fn ($r) => [
                    'id' => (int) $r->employee_id,
                    'name' => (string) $r->name,
                    'code' => (string) ($r->employee_code ?? ''),
                ])->all();
        }

        return response()->json([
            'success' => true,
            'options' => [
                'employees' => $employees,
                'page_sizes' => ['A4', 'LETTER', 'LEGAL', 'A3', 'EXECUTIVE'],
                'placeholders' => [
                    '{{employee_name}}',
                    '{{employee_code}}',
                    '{{designation}}',
                    '{{department}}',
                    '{{joining_date}}',
                    '{{leaving_date}}',
                    '{{company_name}}',
                ],
            ],
        ]);
    }

    protected function upsert(Request $request, ?int $id)
    {
        if (!Schema::hasTable('letter')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'content' => 'nullable|string',
            'page_size' => 'nullable|string|max:32',
            'margin_top' => 'nullable|numeric|min:0|max:100',
            'margin_right' => 'nullable|numeric|min:0|max:100',
            'margin_bottom' => 'nullable|numeric|min:0|max:100',
            'margin_left' => 'nullable|numeric|min:0|max:100',
            'status' => 'nullable|integer',
        ]);
        $claims = $request->attributes->get('hr_claims') ?? [];
        $payload = [
            'name' => $data['name'],
            'content' => $data['content'] ?? null,
            'page_size' => strtoupper($data['page_size'] ?? 'A4'),
            'margin_top' => (float) ($data['margin_top'] ?? 20),
            'margin_right' => (float) ($data['margin_right'] ?? 20),
            'margin_bottom' => (float) ($data['margin_bottom'] ?? 20),
            'margin_left' => (float) ($data['margin_left'] ?? 20),
            'status' => (int) ($data['status'] ?? 1),
        ];
        if ($id === null) {
            if (Schema::hasColumn('letter', 'created_by')) {
                $payload['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
            }
            $newId = (int) DB::table('letter')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('letter')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    protected function map(object $r): array
    {
        return [
            'id' => (int) $r->id,
            'name' => (string) $r->name,
            'content' => (string) ($r->content ?? ''),
            'page_size' => (string) ($r->page_size ?? 'A4'),
            'margin_top' => (float) ($r->margin_top ?? 20),
            'margin_right' => (float) ($r->margin_right ?? 20),
            'margin_bottom' => (float) ($r->margin_bottom ?? 20),
            'margin_left' => (float) ($r->margin_left ?? 20),
            'status' => (int) ($r->status ?? 1),
        ];
    }
}
