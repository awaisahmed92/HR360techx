<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\EmployeeController;
use App\Http\Controllers\Api\EmployeePayController;
use App\Http\Controllers\Api\LeaveTypeController;
use App\Http\Controllers\Api\MasterDataController;
use App\Http\Controllers\Api\PayrollController;
use App\Http\Controllers\Api\SelfServiceController;
use App\Http\Controllers\Api\TravelController;
use App\Http\Controllers\Api\UploadController;
use App\Http\Controllers\Api\WorkflowSettingsController;
use App\Http\Middleware\TenantAuth;
use Illuminate\Support\Facades\Route;

Route::post('/auth/login', [AuthController::class, 'login']);

Route::middleware([TenantAuth::class])->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/change-password', [AuthController::class, 'changePassword']);

    Route::get('/profile', [SelfServiceController::class, 'profile']);
    Route::post('/profile', [SelfServiceController::class, 'updateProfile']);

    Route::get('/leave/types', [SelfServiceController::class, 'leaveTypes']);
    Route::get('/leave', [SelfServiceController::class, 'leaveIndex']);
    Route::post('/leave/apply', [SelfServiceController::class, 'leaveApply']);
    Route::post('/leave/approve', [SelfServiceController::class, 'leaveApprove']);
    Route::post('/leave/reject', [SelfServiceController::class, 'leaveReject']);

    Route::get('/leave-types', [LeaveTypeController::class, 'index']);
    Route::post('/leave-types', [LeaveTypeController::class, 'store']);
    Route::post('/leave-types/{id}', [LeaveTypeController::class, 'update'])->whereNumber('id');
    Route::post('/leave-types/{id}/delete', [LeaveTypeController::class, 'destroy'])->whereNumber('id');
    Route::get('/leave/module-options', [LeaveTypeController::class, 'options']);
    Route::post('/leave/module-options', [LeaveTypeController::class, 'saveOptions']);

    Route::get('/attendance/today', [SelfServiceController::class, 'attendanceToday']);
    Route::get('/attendance', [SelfServiceController::class, 'attendanceList']);
    Route::post('/attendance/punch', [SelfServiceController::class, 'punch']);

    Route::get('/travel/projects', [TravelController::class, 'projects']);
    Route::get('/travel/employees', [TravelController::class, 'employees']);
    Route::get('/travel/meta', [TravelController::class, 'meta']);
    Route::get('/travel', [TravelController::class, 'index']);
    Route::get('/travel/{id}', [TravelController::class, 'show'])->whereNumber('id');
    Route::post('/travel/apply', [TravelController::class, 'store']);
    Route::post('/travel/approve', [TravelController::class, 'approve']);
    Route::post('/travel/reject', [TravelController::class, 'reject']);

    Route::get('/timesheet', [SelfServiceController::class, 'timesheetIndex']);
    Route::post('/timesheet/apply', [SelfServiceController::class, 'timesheetApply']);
    Route::post('/timesheet/approve', [SelfServiceController::class, 'timesheetApprove']);
    Route::post('/timesheet/reject', [SelfServiceController::class, 'timesheetReject']);

    Route::get('/approvals/inbox', [SelfServiceController::class, 'approvalsInbox']);

    Route::get('/settings/approvals', [WorkflowSettingsController::class, 'getApprovals']);
    Route::post('/settings/approvals', [WorkflowSettingsController::class, 'saveApprovals']);
    Route::get('/settings/notifications', [WorkflowSettingsController::class, 'getNotifications']);
    Route::post('/settings/notifications', [WorkflowSettingsController::class, 'saveNotifications']);
    Route::get('/notifications', [WorkflowSettingsController::class, 'listNotifications']);
    Route::get('/employees/stats', [EmployeeController::class, 'stats']);
    Route::get('/employees/meta', [EmployeeController::class, 'meta']);
    Route::get('/employees', [EmployeeController::class, 'index']);
    Route::post('/employees', [EmployeeController::class, 'store']);
    Route::post('/employees/{id}', [EmployeeController::class, 'update'])->whereNumber('id');
    Route::get('/employees/{id}/roles', [EmployeeController::class, 'roles'])->whereNumber('id');
    Route::post('/employees/{id}/roles', [EmployeeController::class, 'saveRoles'])->whereNumber('id');

    Route::get('/masters', [MasterDataController::class, 'catalog']);
    Route::get('/masters/{entity}/meta', [MasterDataController::class, 'meta']);
    Route::get('/masters/{entity}/options', [MasterDataController::class, 'options']);
    Route::get('/masters/{entity}', [MasterDataController::class, 'index']);
    Route::post('/masters/{entity}', [MasterDataController::class, 'store']);
    Route::post('/masters/{entity}/{id}', [MasterDataController::class, 'update'])->whereNumber('id');
    Route::post('/masters/{entity}/{id}/delete', [MasterDataController::class, 'destroy'])->whereNumber('id');

    Route::get('/payroll/dashboard', [PayrollController::class, 'dashboard']);
    Route::get('/payroll/meta', [PayrollController::class, 'meta']);
    Route::get('/payroll/tax-slabs', [PayrollController::class, 'taxSlabs']);
    Route::get('/payroll/define', [PayrollController::class, 'defineIndex']);
    Route::get('/payroll/define/{id}', [PayrollController::class, 'defineShow'])->whereNumber('id');
    Route::post('/payroll/define', [PayrollController::class, 'defineStore']);
    Route::post('/payroll/define/{id}', [PayrollController::class, 'defineUpdate'])->whereNumber('id');
    Route::post('/payroll/define/{id}/delete', [PayrollController::class, 'defineDelete'])->whereNumber('id');
    Route::get('/payroll/process', [PayrollController::class, 'processIndex']);
    Route::post('/payroll/process', [PayrollController::class, 'processRun']);
    Route::get('/payroll/payslip/{id}', [PayrollController::class, 'payslip'])->whereNumber('id');

    Route::get('/payroll/setup', [PayrollController::class, 'setupGet']);
    Route::post('/payroll/setup', [PayrollController::class, 'setupSave']);
    Route::post('/payroll/payslip-options', [PayrollController::class, 'payslipOptionsSave']);
    Route::get('/payroll/calendars', [PayrollController::class, 'calendarIndex']);
    Route::post('/payroll/calendars', [PayrollController::class, 'calendarStore']);
    Route::post('/payroll/calendars/{id}', [PayrollController::class, 'calendarUpdate'])->whereNumber('id');
    Route::post('/payroll/calendars/{id}/delete', [PayrollController::class, 'calendarDelete'])->whereNumber('id');
    Route::get('/payroll/banks', [PayrollController::class, 'bankIndex']);
    Route::post('/payroll/banks', [PayrollController::class, 'bankStore']);
    Route::post('/payroll/banks/{id}', [PayrollController::class, 'bankUpdate'])->whereNumber('id');
    Route::post('/payroll/banks/{id}/delete', [PayrollController::class, 'bankDelete'])->whereNumber('id');

    Route::post('/uploads/company-logo', [UploadController::class, 'companyLogo']);
    Route::post('/uploads/employees/{id}/photo', [UploadController::class, 'employeePhoto'])->whereNumber('id');

    Route::get('/employees/{id}/pay', [EmployeePayController::class, 'show'])->whereNumber('id');
    Route::post('/employees/{id}/pay', [EmployeePayController::class, 'save'])->whereNumber('id');
    Route::post('/employees/{id}/banks', [EmployeePayController::class, 'saveBank'])->whereNumber('id');
    Route::post('/employees/{id}/banks/{bankId}/delete', [EmployeePayController::class, 'deleteBank'])->whereNumber('id')->whereNumber('bankId');

    Route::get('/payroll/auto-deductions', [PayrollController::class, 'autoDeductions']);
    Route::post('/payroll/auto-deductions', [PayrollController::class, 'autoDeductionsSave']);
    Route::post('/payroll/auto-deductions/{id}/delete', [PayrollController::class, 'autoDeductionsDelete'])->whereNumber('id');
    Route::get('/payroll/auto-additions', [PayrollController::class, 'autoAdditions']);
    Route::post('/payroll/auto-additions', [PayrollController::class, 'autoAdditionsSave']);
    Route::post('/payroll/auto-additions/{id}/delete', [PayrollController::class, 'autoAdditionsDelete'])->whereNumber('id');
    Route::get('/payroll/salary-sheet', [PayrollController::class, 'salarySheet']);
    Route::get('/payroll/salary-structure', [PayrollController::class, 'salaryStructure']);
    Route::get('/payroll/payslip/{id}/print', [PayrollController::class, 'payslipPrint'])->whereNumber('id');
    Route::get('/payroll/salary-certificate', [PayrollController::class, 'salaryCertificate']);
    Route::get('/payroll/salary-statement', [PayrollController::class, 'salaryStatement']);
    Route::post('/payroll/preview-formulas', [PayrollController::class, 'previewFormulas']);
});