<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AttendanceAdminController;
use App\Http\Controllers\Api\DevicesController;
use App\Http\Controllers\Api\EmployeeController;
use App\Http\Controllers\Api\EmployeePayController;
use App\Http\Controllers\Api\LoanApplicationController;
use App\Http\Controllers\Api\LetterController;
use App\Http\Controllers\Api\LeaveTypeController;
use App\Http\Controllers\Api\LeaveThresholdController;
use App\Http\Controllers\Api\MasterDataController;
use App\Http\Controllers\Api\PayrollController;
use App\Http\Controllers\Api\HrReportController;
use App\Http\Controllers\Api\PerformanceController;
use App\Http\Controllers\Api\RecruitmentController;
use App\Http\Controllers\Api\SelfServiceController;
use App\Http\Controllers\Api\TrainingController;
use App\Http\Controllers\Api\TerminationController;
use App\Http\Controllers\Api\TravelController;
use App\Http\Controllers\Api\UiPrefsController;
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
    Route::get('/leave-thresholds', [LeaveThresholdController::class, 'index']);
    Route::post('/leave-thresholds', [LeaveThresholdController::class, 'store']);
    Route::post('/leave-thresholds/{id}', [LeaveThresholdController::class, 'update'])->whereNumber('id');
    Route::post('/leave-thresholds/{id}/delete', [LeaveThresholdController::class, 'destroy'])->whereNumber('id');

    Route::get('/attendance/today', [SelfServiceController::class, 'attendanceToday']);
    Route::get('/attendance', [SelfServiceController::class, 'attendanceList']);
    Route::post('/attendance/punch', [SelfServiceController::class, 'punch']);
    Route::get('/attendance/admin', [AttendanceAdminController::class, 'grid']);
    Route::post('/attendance/admin/mark', [AttendanceAdminController::class, 'mark']);
    Route::post('/attendance/admin/save', [AttendanceAdminController::class, 'save']);
    Route::post('/attendance/admin/{id}/delete', [AttendanceAdminController::class, 'destroy'])->whereNumber('id');
    Route::get('/schedule', [AttendanceAdminController::class, 'scheduleIndex']);
    Route::post('/schedule', [AttendanceAdminController::class, 'scheduleSave']);
    Route::get('/reports/attendance/register', [AttendanceAdminController::class, 'register']);

    Route::get('/devices/overview', [DevicesController::class, 'overview']);
    Route::get('/devices', [DevicesController::class, 'index']);
    Route::post('/devices', [DevicesController::class, 'store']);
    Route::post('/devices/{id}', [DevicesController::class, 'update'])->whereNumber('id');
    Route::post('/devices/{id}/delete', [DevicesController::class, 'destroy'])->whereNumber('id');
    Route::get('/devices/punches', [DevicesController::class, 'punches']);

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
    Route::get('/settings/ui-prefs', [UiPrefsController::class, 'get']);
    Route::post('/settings/ui-prefs', [UiPrefsController::class, 'save']);
    Route::get('/notifications', [WorkflowSettingsController::class, 'listNotifications']);
    Route::post('/notifications/read', [WorkflowSettingsController::class, 'markRead']);
    Route::get('/employees/stats', [EmployeeController::class, 'stats']);
    Route::get('/employees/meta', [EmployeeController::class, 'meta']);
    Route::get('/employees/next-code', [EmployeeController::class, 'nextCode']);
    Route::get('/employees', [EmployeeController::class, 'index']);
    Route::get('/employees/{id}', [EmployeeController::class, 'show'])->whereNumber('id');
    Route::post('/employees', [EmployeeController::class, 'store']);
    Route::post('/employees/{id}', [EmployeeController::class, 'update'])->whereNumber('id');
    Route::post('/employees/{id}/delete', [EmployeeController::class, 'destroy'])->whereNumber('id');
    Route::get('/employees/{id}/leave-assignments', [EmployeeController::class, 'leaveAssignments'])->whereNumber('id');
    Route::post('/employees/{id}/leave-assignments', [EmployeeController::class, 'saveLeaveAssignments'])->whereNumber('id');
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

    Route::get('/recruitment/meta', [RecruitmentController::class, 'meta']);
    Route::get('/recruitment/jobs', [RecruitmentController::class, 'jobsIndex']);
    Route::post('/recruitment/jobs', [RecruitmentController::class, 'jobsStore']);
    Route::post('/recruitment/jobs/{id}', [RecruitmentController::class, 'jobsUpdate'])->whereNumber('id');
    Route::post('/recruitment/jobs/{id}/delete', [RecruitmentController::class, 'jobsDelete'])->whereNumber('id');
    Route::get('/recruitment/candidates', [RecruitmentController::class, 'candidatesIndex']);
    Route::get('/recruitment/candidates/{id}', [RecruitmentController::class, 'candidatesShow'])->whereNumber('id');
    Route::post('/recruitment/candidates', [RecruitmentController::class, 'candidatesStore']);
    Route::post('/recruitment/candidates/{id}', [RecruitmentController::class, 'candidatesUpdate'])->whereNumber('id');
    Route::post('/recruitment/candidates/{id}/profile', [RecruitmentController::class, 'candidatesSaveProfile'])->whereNumber('id');
    Route::post('/recruitment/candidates/{id}/delete', [RecruitmentController::class, 'candidatesDelete'])->whereNumber('id');
    Route::post('/recruitment/candidates/{id}/status', [RecruitmentController::class, 'candidatesStatus'])->whereNumber('id');
    Route::post('/recruitment/candidates/{id}/hire', [RecruitmentController::class, 'candidatesHire'])->whereNumber('id');

    Route::get('/performance/meta', [PerformanceController::class, 'meta']);
    Route::get('/performance/indicators', [PerformanceController::class, 'indicatorsIndex']);
    Route::post('/performance/indicators', [PerformanceController::class, 'indicatorsStore']);
    Route::post('/performance/indicators/{id}', [PerformanceController::class, 'indicatorsUpdate'])->whereNumber('id');
    Route::post('/performance/indicators/{id}/delete', [PerformanceController::class, 'indicatorsDelete'])->whereNumber('id');
    Route::get('/performance/reviews', [PerformanceController::class, 'reviewsIndex']);
    Route::post('/performance/reviews', [PerformanceController::class, 'reviewsStore']);
    Route::post('/performance/reviews/{id}', [PerformanceController::class, 'reviewsUpdate'])->whereNumber('id');
    Route::post('/performance/reviews/{id}/delete', [PerformanceController::class, 'reviewsDelete'])->whereNumber('id');
    Route::get('/performance/appraisals', [PerformanceController::class, 'appraisalsIndex']);
    Route::post('/performance/appraisals', [PerformanceController::class, 'appraisalsStore']);
    Route::post('/performance/appraisals/{id}', [PerformanceController::class, 'appraisalsUpdate'])->whereNumber('id');
    Route::post('/performance/appraisals/{id}/advance', [PerformanceController::class, 'appraisalsAdvance'])->whereNumber('id');
    Route::post('/performance/appraisals/{id}/delete', [PerformanceController::class, 'appraisalsDelete'])->whereNumber('id');
    Route::get('/performance/goals', [PerformanceController::class, 'goalsIndex']);
    Route::post('/performance/goals', [PerformanceController::class, 'goalsStore']);
    Route::post('/performance/goals/{id}', [PerformanceController::class, 'goalsUpdate'])->whereNumber('id');
    Route::post('/performance/goals/{id}/delete', [PerformanceController::class, 'goalsDelete'])->whereNumber('id');
    Route::get('/performance/goal-types', [PerformanceController::class, 'goalTypesIndex']);
    Route::post('/performance/goal-types', [PerformanceController::class, 'goalTypesStore']);
    Route::post('/performance/goal-types/{id}', [PerformanceController::class, 'goalTypesUpdate'])->whereNumber('id');
    Route::post('/performance/goal-types/{id}/delete', [PerformanceController::class, 'goalTypesDelete'])->whereNumber('id');
    Route::get('/performance/cycles', [PerformanceController::class, 'cyclesIndex']);
    Route::post('/performance/cycles', [PerformanceController::class, 'cyclesStore']);
    Route::post('/performance/cycles/{id}', [PerformanceController::class, 'cyclesUpdate'])->whereNumber('id');
    Route::post('/performance/cycles/{id}/delete', [PerformanceController::class, 'cyclesDelete'])->whereNumber('id');

    Route::get('/reports/hr/meta', [HrReportController::class, 'meta']);
    Route::get('/reports/hr/leave', [HrReportController::class, 'leave']);
    Route::get('/reports/hr/leave/balance', [HrReportController::class, 'leaveBalance']);
    Route::get('/reports/hr/leave/usage', [HrReportController::class, 'leaveUsage']);
    Route::get('/reports/hr/employees', [HrReportController::class, 'employees']);
    Route::get('/reports/hr/attendance/monthly', [HrReportController::class, 'attendanceMonthly']);
    Route::get('/reports/hr/attendance/log', [HrReportController::class, 'attendanceLog']);

    Route::get('/training/meta', [TrainingController::class, 'meta']);
    Route::get('/training', [TrainingController::class, 'index']);
    Route::get('/training/calendar', [TrainingController::class, 'calendar']);
    Route::get('/training/types', [TrainingController::class, 'typesIndex']);
    Route::post('/training/types', [TrainingController::class, 'typesStore']);
    Route::post('/training/types/{id}', [TrainingController::class, 'typesUpdate'])->whereNumber('id');
    Route::post('/training/types/{id}/delete', [TrainingController::class, 'typesDelete'])->whereNumber('id');
    Route::get('/training/trainers', [TrainingController::class, 'trainersIndex']);
    Route::post('/training/trainers', [TrainingController::class, 'trainersStore']);
    Route::post('/training/trainers/{id}', [TrainingController::class, 'trainersUpdate'])->whereNumber('id');
    Route::post('/training/trainers/{id}/delete', [TrainingController::class, 'trainersDelete'])->whereNumber('id');
    Route::get('/training/{id}', [TrainingController::class, 'show'])->whereNumber('id');
    Route::post('/training', [TrainingController::class, 'store']);
    Route::post('/training/{id}', [TrainingController::class, 'update'])->whereNumber('id');
    Route::post('/training/{id}/delete', [TrainingController::class, 'destroy'])->whereNumber('id');
    Route::post('/training/{id}/complete', [TrainingController::class, 'markComplete'])->whereNumber('id');

    Route::get('/termination/meta', [TerminationController::class, 'meta']);
    Route::get('/termination', [TerminationController::class, 'index']);
    Route::post('/termination', [TerminationController::class, 'store']);
    Route::post('/termination/{id}', [TerminationController::class, 'update'])->whereNumber('id');
    Route::post('/termination/{id}/delete', [TerminationController::class, 'destroy'])->whereNumber('id');

    Route::get('/loan-applications/meta', [LoanApplicationController::class, 'meta']);
    Route::get('/loan-applications', [LoanApplicationController::class, 'index']);
    Route::post('/loan-applications', [LoanApplicationController::class, 'store']);
    Route::post('/loan-applications/{id}', [LoanApplicationController::class, 'update'])->whereNumber('id');
    Route::post('/loan-applications/{id}/status', [LoanApplicationController::class, 'setStatus'])->whereNumber('id');
    Route::post('/loan-applications/{id}/delete', [LoanApplicationController::class, 'destroy'])->whereNumber('id');

    Route::get('/letters/meta', [LetterController::class, 'meta']);
    Route::get('/letters', [LetterController::class, 'index']);
    Route::get('/letters/{id}', [LetterController::class, 'show'])->whereNumber('id');
    Route::get('/letters/{id}/preview', [LetterController::class, 'preview'])->whereNumber('id');
    Route::post('/letters', [LetterController::class, 'store']);
    Route::post('/letters/{id}', [LetterController::class, 'update'])->whereNumber('id');
    Route::post('/letters/{id}/delete', [LetterController::class, 'destroy'])->whereNumber('id');
});