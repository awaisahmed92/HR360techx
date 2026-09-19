<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ApprovalService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WorkflowSettingsController extends Controller
{
    public function __construct(private ApprovalService $approvals)
    {
    }

    public function getApprovals(Request $request)
    {
        $module = $this->module($request);

        return response()->json([
            'success' => true,
            'settings' => $this->approvals->settings($module),
            'employees' => $this->employees(),
            'level_options' => [
                ['value' => 0, 'label' => 'Auto Approved'],
                ['value' => 1, 'label' => 'One Level'],
                ['value' => 2, 'label' => 'Two Levels'],
                ['value' => 3, 'label' => 'Three Levels'],
                ['value' => 4, 'label' => 'Four Levels'],
                ['value' => 5, 'label' => 'Five Levels'],
            ],
        ]);
    }

    public function saveApprovals(Request $request)
    {
        $module = $this->module($request);
        $data = $request->validate([
            'approval_method' => 'nullable|string|max:50',
            'approval_levels' => 'required|integer|min:0|max:5',
            'restart_on_edit' => 'nullable|boolean',
            'skip_specific' => 'nullable|boolean',
            'hide_rejected' => 'nullable|boolean',
            'do_not_notify_employee' => 'nullable|boolean',
            'sms_on_submission' => 'nullable|boolean',
            'level_assignees' => 'nullable|array',
            'level_assignees.*' => 'nullable|integer',
        ]);

        $settings = $this->approvals->saveSettings($module, $data);

        return response()->json(['success' => true, 'settings' => $settings, 'message' => 'Approval settings saved.']);
    }

    public function getNotifications(Request $request)
    {
        $module = $this->module($request);

        return response()->json([
            'success' => true,
            'settings' => $this->approvals->notificationSettings($module),
            'employees' => $this->employees(),
        ]);
    }

    public function saveNotifications(Request $request)
    {
        $module = $this->module($request);
        $data = $request->validate([
            'do_not_notify_employee' => 'nullable|boolean',
            'sms_on_submission' => 'nullable|boolean',
            'notify_on_submission' => 'nullable|array',
            'notify_on_submission.*' => 'integer',
            'notify_on_approval' => 'nullable|array',
            'notify_on_approval.*' => 'integer',
            'notify_on_reassignment' => 'nullable|array',
            'notify_on_reassignment.*' => 'integer',
        ]);

        $settings = $this->approvals->saveNotificationSettings($module, $data);

        return response()->json(['success' => true, 'settings' => $settings, 'message' => 'Notification settings saved.']);
    }

    public function listNotifications(Request $request)
    {
        $claims = $request->attributes->get('hr_claims');
        $uid = (int) ($claims['employee_id'] ?? 0);
        $items = $this->approvals->listNotifications($uid);
        $unread = $this->approvals->unreadCount($uid);

        return response()->json([
            'success' => true,
            'notifications' => $items,
            'unread_count' => $unread,
        ]);
    }

    public function markRead(Request $request)
    {
        $claims = $request->attributes->get('hr_claims');
        $uid = (int) ($claims['employee_id'] ?? 0);
        $id = $request->input('id');
        $this->approvals->markRead($uid, $id !== null ? (int) $id : null);

        return response()->json(['success' => true, 'message' => 'Marked read.']);
    }

    protected function module(Request $request): string
    {
        $module = strtolower((string) $request->query('module', $request->input('module', 'travel')));
        if (!in_array($module, ApprovalService::MODULES, true)) {
            $module = 'travel';
        }

        return $module;
    }

    protected function employees(): array
    {
        return DB::table('employee')
            ->orderBy('name')
            ->get(['employee_id as id', 'name', 'employee_code'])
            ->map(fn ($e) => [
                'id' => (int) $e->id,
                'name' => (string) $e->name,
                'employee_code' => (string) ($e->employee_code ?? ''),
            ])
            ->all();
    }
}
