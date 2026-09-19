<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\PayrollService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class PayrollController extends Controller
{
    public function __construct(private PayrollService $payroll)
    {
    }

    public function dashboard()
    {
        if (!Schema::hasTable('define_salary')) {
            return response()->json([
                'success' => false,
                'message' => 'Run database/10_phase3_payroll.sql on the tenant DB.',
            ], 503);
        }

        return response()->json(['success' => true, 'stats' => $this->payroll->dashboard()]);
    }

    public function meta()
    {
        return response()->json(['success' => true, 'meta' => $this->payroll->metaLookups()]);
    }

    public function defineIndex(Request $request)
    {
        $projectId = $request->query('project_id') ? (int) $request->query('project_id') : null;

        return response()->json([
            'success' => true,
            'salaries' => $this->payroll->listDefines($projectId),
        ]);
    }

    public function defineShow(int $id)
    {
        $row = $this->payroll->getDefine($id);
        if (!$row) {
            return response()->json(['success' => false, 'message' => 'Not found.'], 404);
        }

        return response()->json(['success' => true, 'salary' => $row]);
    }

    public function defineStore(Request $request)
    {
        $data = $request->validate([
            'employee_id' => 'required|integer',
            'project_id' => 'required|integer',
            'station_id' => 'nullable|integer',
            'basic_salary' => 'required|numeric|min:0',
            'items' => 'nullable|array',
            'items.*.payroll_item_id' => 'required|integer',
            'items.*.allowance' => 'nullable|numeric',
            'items.*.deduction' => 'nullable|numeric',
        ]);
        $actor = (int) ($request->attributes->get('hr_claims')['employee_id'] ?? 0);
        $row = $this->payroll->saveDefine($data, $actor);

        return response()->json(['success' => true, 'message' => 'Salary structure saved.', 'salary' => $row]);
    }

    public function defineUpdate(Request $request, int $id)
    {
        $data = $request->validate([
            'employee_id' => 'required|integer',
            'project_id' => 'required|integer',
            'station_id' => 'nullable|integer',
            'basic_salary' => 'required|numeric|min:0',
            'items' => 'nullable|array',
            'items.*.payroll_item_id' => 'required|integer',
            'items.*.allowance' => 'nullable|numeric',
            'items.*.deduction' => 'nullable|numeric',
        ]);
        $actor = (int) ($request->attributes->get('hr_claims')['employee_id'] ?? 0);
        $row = $this->payroll->saveDefine($data, $actor, $id);

        return response()->json(['success' => true, 'message' => 'Updated.', 'salary' => $row]);
    }

    public function defineDelete(int $id)
    {
        $this->payroll->deleteDefine($id);

        return response()->json(['success' => true, 'message' => 'Deleted.']);
    }

    public function processIndex(Request $request)
    {
        return response()->json([
            'success' => true,
            'runs' => $this->payroll->listProcessed(
                $request->query('date'),
                $request->query('project_id') ? (int) $request->query('project_id') : null
            ),
        ]);
    }

    public function processRun(Request $request)
    {
        $data = $request->validate([
            'project_id' => 'required|integer',
            'date' => 'required|date',
            'days' => 'nullable|integer|min:1|max:31',
        ]);
        $actor = (int) ($request->attributes->get('hr_claims')['employee_id'] ?? 0);
        $result = $this->payroll->processProject(
            (int) $data['project_id'],
            $data['date'],
            (int) ($data['days'] ?? 30),
            $actor
        );

        return response()->json([
            'success' => true,
            'message' => 'Processed '.$result['count'].' employee(s).',
            'result' => $result,
        ]);
    }

    public function payslip(int $id)
    {
        $slip = $this->payroll->payslip($id);
        if (!$slip) {
            return response()->json(['success' => false, 'message' => 'Not found.'], 404);
        }

        return response()->json(['success' => true, 'payslip' => $slip]);
    }

    public function taxSlabs()
    {
        return response()->json(['success' => true, 'slabs' => $this->payroll->taxSlabs()]);
    }

    public function setupGet()
    {
        return response()->json([
            'success' => true,
            'setup' => $this->payroll->getSetup(),
            'payslip_options' => $this->payroll->getPayslipOptions(),
            'calendars' => $this->payroll->listCalendars(),
            'banks' => $this->payroll->listBanks(),
            'items' => Schema::hasTable('hr_payroll_item')
                ? \Illuminate\Support\Facades\DB::table('hr_payroll_item')->where('status', 1)->orderBy('name')->get()
                : [],
        ]);
    }

    public function setupSave(Request $request)
    {
        $data = $request->validate([
            'name' => 'nullable|string|max:100',
            'payroll_type' => 'nullable|string|max:80',
            'pay_schedule' => 'nullable|string|max:40',
            'salaries_per_year' => 'nullable|integer',
            'fiscal_start_month' => 'nullable|string|max:20',
            'divide_with_days' => 'nullable|boolean',
            'per_day_method' => 'nullable|string|max:120',
            'pro_rata_method' => 'nullable|string|max:120',
            'exit_join_proration' => 'nullable|string|max:60',
            'enable_basic_salary' => 'nullable|boolean',
            'enable_auto_overtime' => 'nullable|boolean',
            'sessi_emp_percent' => 'nullable|numeric',
            'sessi_org_percent' => 'nullable|numeric',
            'pf_emp_percent' => 'nullable|numeric',
            'pf_org_percent' => 'nullable|numeric',
            'enable_sessi' => 'nullable|boolean',
            'enable_pf' => 'nullable|boolean',
            'enable_auto_late' => 'nullable|boolean',
            'work_start_time' => 'nullable|string|max:8',
            'late_grace_minutes' => 'nullable|integer',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Payroll options saved.',
            'setup' => $this->payroll->saveSetup($data),
        ]);
    }

    public function payslipOptionsSave(Request $request)
    {
        $data = $request->validate([
            'payslip_title' => 'nullable|string|max:120',
            'payslip_format' => 'nullable|string|max:40',
            'logo_alignment' => 'nullable|string|max:20',
            'approval_levels' => 'nullable|integer|min:0|max:5',
            'auto_email' => 'nullable|boolean',
            'add_signature' => 'nullable|boolean',
            'show_bank' => 'nullable|boolean',
            'show_ytd' => 'nullable|boolean',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Payslip options saved.',
            'payslip_options' => $this->payroll->savePayslipOptions($data),
        ]);
    }

    public function calendarIndex()
    {
        return response()->json(['success' => true, 'rows' => $this->payroll->listCalendars()]);
    }

    public function calendarStore(Request $request)
    {
        $data = $request->validate([
            'year' => 'required|integer',
            'start_date' => 'required|date',
            'end_date' => 'required|date',
            'pay_periods' => 'nullable|integer',
            'label' => 'nullable|string|max:80',
        ]);

        return response()->json([
            'success' => true,
            'row' => $this->payroll->saveCalendar($data),
        ]);
    }

    public function calendarUpdate(Request $request, int $id)
    {
        $data = $request->validate([
            'year' => 'required|integer',
            'start_date' => 'required|date',
            'end_date' => 'required|date',
            'pay_periods' => 'nullable|integer',
            'label' => 'nullable|string|max:80',
        ]);

        return response()->json([
            'success' => true,
            'row' => $this->payroll->saveCalendar($data, $id),
        ]);
    }

    public function calendarDelete(int $id)
    {
        $this->payroll->deleteCalendar($id);

        return response()->json(['success' => true, 'message' => 'Deleted.']);
    }

    public function bankIndex()
    {
        return response()->json(['success' => true, 'rows' => $this->payroll->listBanks()]);
    }

    public function bankStore(Request $request)
    {
        $data = $request->validate([
            'bank_name' => 'required|string|max:120',
            'account_title' => 'nullable|string|max:120',
            'account_number' => 'required|string|max:60',
            'iban' => 'nullable|string|max:40',
            'branch' => 'nullable|string|max:120',
            'is_primary' => 'nullable|boolean',
            'status' => 'nullable|integer',
        ]);

        return response()->json(['success' => true, 'row' => $this->payroll->saveBank($data)]);
    }

    public function bankUpdate(Request $request, int $id)
    {
        $data = $request->validate([
            'bank_name' => 'required|string|max:120',
            'account_title' => 'nullable|string|max:120',
            'account_number' => 'required|string|max:60',
            'iban' => 'nullable|string|max:40',
            'branch' => 'nullable|string|max:120',
            'is_primary' => 'nullable|boolean',
            'status' => 'nullable|integer',
        ]);

        return response()->json(['success' => true, 'row' => $this->payroll->saveBank($data, $id)]);
    }

    public function bankDelete(int $id)
    {
        $this->payroll->deleteBank($id);

        return response()->json(['success' => true, 'message' => 'Deleted.']);
    }

    public function autoDeductions()
    {
        return response()->json([
            'success' => true,
            'rows' => $this->payroll->listAutoRules('hr_auto_deduction_rule'),
        ]);
    }

    public function autoDeductionsSave(Request $request)
    {
        $data = $request->validate([
            'minutes_from' => 'nullable|integer',
            'minutes_to' => 'nullable|integer',
            'amount_type' => 'nullable|string',
            'method' => 'nullable|string',
            'amount' => 'nullable|numeric',
            'status' => 'nullable|integer',
            'id' => 'nullable|integer',
        ]);
        $id = isset($data['id']) ? (int) $data['id'] : null;

        return response()->json([
            'success' => true,
            'row' => $this->payroll->saveAutoRule('hr_auto_deduction_rule', $data, $id),
        ]);
    }

    public function autoDeductionsDelete(int $id)
    {
        $this->payroll->deleteAutoRule('hr_auto_deduction_rule', $id);

        return response()->json(['success' => true]);
    }

    public function autoAdditions()
    {
        return response()->json([
            'success' => true,
            'rows' => $this->payroll->listAutoRules('hr_auto_addition_rule'),
        ]);
    }

    public function autoAdditionsSave(Request $request)
    {
        $data = $request->validate([
            'minutes_from' => 'nullable|integer',
            'minutes_to' => 'nullable|integer',
            'amount_type' => 'nullable|string',
            'method' => 'nullable|string',
            'amount' => 'nullable|numeric',
            'status' => 'nullable|integer',
            'id' => 'nullable|integer',
        ]);
        $id = isset($data['id']) ? (int) $data['id'] : null;

        return response()->json([
            'success' => true,
            'row' => $this->payroll->saveAutoRule('hr_auto_addition_rule', $data, $id),
        ]);
    }

    public function autoAdditionsDelete(int $id)
    {
        $this->payroll->deleteAutoRule('hr_auto_addition_rule', $id);

        return response()->json(['success' => true]);
    }

    public function salarySheet(Request $request)
    {
        $sheet = $this->payroll->salarySheet(
            $request->query('date'),
            $request->query('project_id') ? (int) $request->query('project_id') : null
        );

        return response()->json(['success' => true, 'sheet' => $sheet]);
    }

    public function payslipPrint(Request $request, int $id)
    {
        $base = rtrim($request->getSchemeAndHttpHost().$request->getBasePath(), '/');
        $html = $this->payroll->payslipHtml($id, preg_replace('#/api$#', '', $base));
        if ($html === null) {
            return response('Payslip not found', 404);
        }

        if ($request->query('download') === '1') {
            return response($html, 200, [
                'Content-Type' => 'text/html; charset=UTF-8',
                'Content-Disposition' => 'attachment; filename="payslip-'.$id.'.html"',
            ]);
        }

        return response($html, 200)->header('Content-Type', 'text/html; charset=UTF-8');
    }

    public function salaryStructure()
    {
        return response()->json([
            'success' => true,
            'rows' => $this->payroll->listDefines(),
        ]);
    }

    public function salaryCertificate(Request $request)
    {
        $employeeId = (int) $request->query('employee_id', 0);
        if ($employeeId < 1) {
            return response()->json(['success' => false, 'message' => 'employee_id required'], 422);
        }
        $base = rtrim($request->getSchemeAndHttpHost().$request->getBasePath(), '/');
        $html = $this->payroll->salaryCertificateHtml($employeeId, preg_replace('#/api$#', '', $base));
        if ($html === null) {
            return response('Employee not found', 404);
        }

        return response($html, 200)->header('Content-Type', 'text/html; charset=UTF-8');
    }

    public function salaryStatement(Request $request)
    {
        $employeeId = (int) $request->query('employee_id', 0);
        if ($employeeId < 1) {
            return response()->json(['success' => false, 'message' => 'employee_id required'], 422);
        }
        $html = $this->payroll->salaryStatementHtml(
            $employeeId,
            $request->query('from'),
            $request->query('to')
        );
        if ($html === null) {
            return response('Employee not found', 404);
        }

        return response($html, 200)->header('Content-Type', 'text/html; charset=UTF-8');
    }

    public function previewFormulas(Request $request)
    {
        $basic = (float) $request->input('basic_salary', 0);
        $items = $request->input('items', []);
        if (!is_array($items)) {
            $items = [];
        }

        return response()->json([
            'success' => true,
            'items' => $this->payroll->applySetupFormulas($basic, $items),
            'tax_monthly' => $this->payroll->taxOnMonthly($basic),
            'eobi' => $this->payroll->eobiEmployeeAmount(),
            'rates' => $this->payroll->statutoryRates(),
        ]);
    }
}
