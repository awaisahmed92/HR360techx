<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\MasterRegistry;
use App\Support\SimpleXlsx;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class SystemLogController extends Controller
{
    public function months()
    {
        if (!Schema::hasTable('hr_system_log')) {
            return response()->json(['success' => true, 'months' => []]);
        }

        $rows = DB::table('hr_system_log')
            ->selectRaw("DATE_FORMAT(created_at, '%Y-%m') as month, COUNT(*) as records")
            ->groupByRaw("DATE_FORMAT(created_at, '%Y-%m')")
            ->orderByRaw("DATE_FORMAT(created_at, '%Y-%m') desc")
            ->get();

        $months = [];
        foreach ($rows as $row) {
            $key = (string) $row->month;
            if (!preg_match('/^\d{4}-\d{2}$/', $key)) {
                continue;
            }
            $label = Carbon::createFromFormat('Y-m-d', $key.'-01')->format('F Y');
            $months[] = [
                'month' => $key,
                'label' => $label,
                'records' => (int) $row->records,
                'file' => 'System-Logs-'.str_replace(' ', '-', $label).'.xlsx',
            ];
        }

        return response()->json(['success' => true, 'months' => $months]);
    }

    public function export(Request $request)
    {
        $month = (string) $request->query('month', '');
        if (!preg_match('/^\d{4}-(0[1-9]|1[0-2])$/', $month)) {
            return response()->json(['success' => false, 'message' => 'Choose a valid month.'], 422);
        }
        if (!Schema::hasTable('hr_system_log')) {
            return response()->json(['success' => false, 'message' => 'System logs are not available.'], 404);
        }

        $query = DB::table('hr_system_log as l')
            ->whereRaw("DATE_FORMAT(l.created_at, '%Y-%m') = ?", [$month])
            ->orderBy('l.created_at')
            ->orderBy('l.id');

        if (Schema::hasTable('employee')) {
            $query->leftJoin('employee as e', 'e.employee_id', '=', 'l.actor_id')
                ->select('l.created_at', 'l.action', 'l.entity', 'l.entity_id', 'l.detail', 'e.name as actor');
        } else {
            $query->select('l.created_at', 'l.action', 'l.entity', 'l.entity_id', 'l.detail');
        }

        $lines = [];
        foreach ($query->get() as $row) {
            $when = $row->created_at ? Carbon::parse($row->created_at)->format('d M Y, H:i') : '';
            $lines[] = [
                $when,
                trim((string) ($row->actor ?? '')) !== '' ? (string) $row->actor : 'System',
                $this->actionLabel((string) $row->action),
                $this->entityLabel((string) ($row->entity ?? '')),
                $row->entity_id ? (string) $row->entity_id : '',
                $this->detailText($row->detail),
            ];
        }

        $label = Carbon::createFromFormat('Y-m-d', $month.'-01')->format('F Y');
        $filename = 'System-Logs-'.str_replace(' ', '-', $label).'.xlsx';

        return SimpleXlsx::download($filename, $label, [
            'When',
            'User',
            'Action',
            'Module',
            'Record',
            'Details',
        ], $lines);
    }

    private function actionLabel(string $action): string
    {
        return match (strtolower($action)) {
            'create' => 'Created',
            'update' => 'Updated',
            'delete' => 'Deleted',
            default => $action !== '' ? ucfirst($action) : '',
        };
    }

    private function entityLabel(string $entity): string
    {
        if ($entity === '') {
            return '';
        }
        $def = MasterRegistry::get($entity);
        if (is_array($def) && !empty($def['title'])) {
            return (string) $def['title'];
        }

        return ucwords(str_replace('_', ' ', $entity));
    }

    private function detailText(mixed $detail): string
    {
        $text = trim((string) ($detail ?? ''));
        if ($text === '') {
            return '';
        }
        $decoded = json_decode($text, true);
        if (!is_array($decoded)) {
            return $text;
        }
        $parts = [];
        foreach ($decoded as $key => $value) {
            $name = (string) $key;
            if (preg_match('/password|token|secret/i', $name)) {
                continue;
            }
            if ($value === null || $value === '') {
                continue;
            }
            if (is_array($value)) {
                $value = json_encode($value, JSON_UNESCAPED_UNICODE);
            }
            $label = ucwords(str_replace('_', ' ', $name));
            $parts[] = $label.': '.$value;
        }

        return implode("\n", $parts);
    }
}
