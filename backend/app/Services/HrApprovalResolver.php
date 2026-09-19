<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Port of PHP HrApprovalResolver — designation / line-manager / same-project rules.
 * Reads live `hr_approval_setup` when present.
 */
class HrApprovalResolver
{
    public const LINE_MANAGER = -1;
    public const ED_FALLBACK_LEVEL = 999;

    /** @var array<int, int> */
    protected array $employeeProjectCache = [];

    protected ?int $edDesignationId = null;

    /** Module API key → hr_approval_setup.component */
    public static function componentFor(string $module): string
    {
        return match ($module) {
            'leave' => 'leaves',
            'travel' => 'travelrequest',
            'timesheet' => 'timesheet',
            default => $module,
        };
    }

    public function hasSetupTable(): bool
    {
        return Schema::hasTable('hr_approval_setup');
    }

    /**
     * @return array<int, list<int>> level => [primary, alternate?]
     */
    public function levelMap(string $module): array
    {
        if (!$this->hasSetupTable()) {
            return [];
        }

        $component = self::componentFor($module);
        $rows = DB::table('hr_approval_setup')
            ->where('component', $component)
            ->orderBy('level')
            ->get();

        $map = [];
        $hasAlt = Schema::hasColumn('hr_approval_setup', 'alternate_designation_id');
        foreach ($rows as $r) {
            $ids = [];
            $primary = (int) $r->designation_id;
            if ($primary === self::LINE_MANAGER || $primary > 0) {
                $ids[] = $primary;
            }
            if ($hasAlt && isset($r->alternate_designation_id) && $r->alternate_designation_id !== null && $r->alternate_designation_id !== '') {
                $alt = (int) $r->alternate_designation_id;
                if (($alt === self::LINE_MANAGER || $alt > 0) && $alt !== $primary) {
                    $ids[] = $alt;
                }
            }
            if ($ids !== []) {
                $map[(int) $r->level] = $ids;
            }
        }

        return $map;
    }

    public function submitterId(array|object $row): int
    {
        $a = is_array($row) ? $row : (array) $row;
        $by = (int) ($a['added_by'] ?? 0);
        if ($by > 0) {
            return $by;
        }

        return (int) ($a['employee_id'] ?? $a['employee'] ?? 0);
    }

    /** @return list<int> */
    public function employeeIdsWhoCanApproveLevel(int $submitterId, int $designationRuleId, array|object $requestRow = []): array
    {
        if ($designationRuleId === self::LINE_MANAGER) {
            $lm = (int) (DB::table('employee')->where('employee_id', $submitterId)->value('line_manager') ?? 0);

            return $lm > 0 ? [$lm] : [];
        }

        $rows = $this->employeesHoldingDesignation($designationRuleId);
        $rows = $this->preferSameProject($rows, $this->resolveProjectId($submitterId, $requestRow));

        return array_map('intval', array_column($rows, 'employee_id'));
    }

    /** @param list<int>|int $rules @return list<int> */
    public function employeeIdsWhoCanApproveRules(int $submitterId, $rules, array|object $requestRow = []): array
    {
        $seen = [];
        foreach ($this->normalizeRules($rules) as $ruleId) {
            foreach ($this->employeeIdsWhoCanApproveLevel($submitterId, $ruleId, $requestRow) as $eid) {
                $seen[$eid] = true;
            }
        }

        return array_map('intval', array_keys($seen));
    }

    public function primaryRule($rule): ?int
    {
        $rules = $this->normalizeRules($rule);

        return $rules[0] ?? null;
    }

    /** @return list<int> */
    public function normalizeRules($rule): array
    {
        if ($rule === null || $rule === '' || $rule === []) {
            return [];
        }
        $raw = is_array($rule) ? $rule : [$rule];
        $out = [];
        foreach ($raw as $id) {
            $i = (int) $id;
            if ($i === self::LINE_MANAGER || $i > 0) {
                $out[$i] = $i;
            }
        }

        return array_values($out);
    }

    public function firstConfiguredLevel(array $levelMap): ?int
    {
        if ($levelMap === []) {
            return null;
        }
        $keys = array_map('intval', array_keys($levelMap));
        sort($keys, SORT_NUMERIC);

        return $keys[0] ?? null;
    }

    public function getFirstApprovalLevel(array $levelMap, array|object $row = []): ?int
    {
        $submitter = $this->submitterId($row);
        if ($submitter < 1) {
            return $this->firstConfiguredLevel($levelMap);
        }

        $keys = array_map('intval', array_keys($levelMap));
        sort($keys, SORT_NUMERIC);
        foreach ($keys as $k) {
            $primary = $this->primaryRule($levelMap[$k] ?? null);
            if ($primary === null) {
                continue;
            }
            if ($this->employeeIdsWhoCanApproveLevel($submitter, $primary, $row) !== []) {
                return $k;
            }
        }

        if ($this->executiveDirectorIsConfigured($levelMap) && $this->executiveDirectorApproverIds($row, $submitter) !== []) {
            return self::ED_FALLBACK_LEVEL;
        }

        return $this->firstConfiguredLevel($levelMap);
    }

    public function nextApprovalLevelAfter(int $currentLevel, array $levelMap, array|object $row = []): ?int
    {
        $submitter = $this->submitterId($row);
        if ($currentLevel === self::ED_FALLBACK_LEVEL) {
            return null;
        }

        $keys = array_map('intval', array_keys($levelMap));
        sort($keys, SORT_NUMERIC);
        foreach ($keys as $k) {
            if ($k <= $currentLevel) {
                continue;
            }
            $primary = $this->primaryRule($levelMap[$k] ?? null);
            if ($primary === null) {
                continue;
            }
            if ($submitter < 1 || $this->employeeIdsWhoCanApproveLevel($submitter, $primary, $row) !== []) {
                return $k;
            }
        }

        if ($this->executiveDirectorIsConfigured($levelMap) && $this->executiveDirectorApproverIds($row, $submitter) !== []) {
            return self::ED_FALLBACK_LEVEL;
        }

        return null;
    }

    public function effectivePendingLevel(array|object $row, array $levelMap): int
    {
        $a = is_array($row) ? $row : (array) $row;
        $pending = (int) ($a['approval_pending_level'] ?? $a['current_approval_level'] ?? 0);
        if ($pending === self::ED_FALLBACK_LEVEL && !$this->executiveDirectorIsConfigured($levelMap)) {
            return (int) ($this->firstConfiguredLevel($levelMap) ?? 0);
        }

        return $pending;
    }

    public function canUserApprovePendingRow(int $userId, array|object $row, array $levelMap, bool $superUser = false): bool
    {
        $a = is_array($row) ? $row : (array) $row;
        if ((int) ($a['status'] ?? -1) !== 0) {
            return false;
        }
        if ($superUser) {
            return $this->effectivePendingLevel($row, $levelMap) > 0;
        }

        $pending = $this->effectivePendingLevel($row, $levelMap);
        if ($pending < 1) {
            return false;
        }

        $submitter = $this->submitterId($row);
        if ($submitter < 1 || $submitter === $userId) {
            return false;
        }

        if ($pending === self::ED_FALLBACK_LEVEL) {
            return in_array($userId, $this->executiveDirectorApproverIds($row, $submitter), true);
        }

        $primary = $this->primaryRule($levelMap[$pending] ?? null);
        if ($primary === null) {
            return false;
        }

        return in_array($userId, $this->employeeIdsWhoCanApproveLevel($submitter, $primary, $row), true);
    }

    public function canUserViewPendingRow(int $userId, array|object $row, array $levelMap, bool $superUser = false): bool
    {
        if ($this->canUserApprovePendingRow($userId, $row, $levelMap, $superUser)) {
            return true;
        }

        $pending = $this->effectivePendingLevel($row, $levelMap);
        if ($pending < 1 || $pending === self::ED_FALLBACK_LEVEL) {
            return false;
        }
        if ((int) ((is_array($row) ? $row : (array) $row)['status'] ?? -1) !== 0) {
            return false;
        }

        $submitter = $this->submitterId($row);
        $rules = $this->normalizeRules($levelMap[$pending] ?? null);
        foreach ($rules as $ruleId) {
            if (in_array($userId, $this->employeeIdsWhoCanApproveLevel($submitter, $ruleId, $row), true)) {
                return true;
            }
        }

        return false;
    }

    /** @return list<int> */
    public function pendingApproverIds(array|object $row, array $levelMap): array
    {
        if ((int) ((is_array($row) ? $row : (array) $row)['status'] ?? -1) !== 0) {
            return [];
        }
        $pending = $this->effectivePendingLevel($row, $levelMap);
        $submitter = $this->submitterId($row);
        if ($pending < 1 || $submitter < 1) {
            return [];
        }
        if ($pending === self::ED_FALLBACK_LEVEL) {
            return $this->executiveDirectorApproverIds($row, $submitter);
        }
        $primary = $this->primaryRule($levelMap[$pending] ?? null);
        if ($primary === null) {
            return [];
        }

        return $this->employeeIdsWhoCanApproveLevel($submitter, $primary, $row);
    }

    public function resolveRuleForPending(array|object $row, array $levelMap): ?int
    {
        $pending = $this->effectivePendingLevel($row, $levelMap);
        if ($pending < 1) {
            return null;
        }
        if ($pending === self::ED_FALLBACK_LEVEL) {
            return $this->getExecutiveDirectorDesignationId();
        }

        return $this->primaryRule($levelMap[$pending] ?? null);
    }

    public function executiveDirectorIsConfigured(array $levelMap): bool
    {
        $edId = $this->getExecutiveDirectorDesignationId();
        if ($edId === null) {
            return false;
        }
        foreach ($levelMap as $rule) {
            if (in_array($edId, $this->normalizeRules($rule), true)) {
                return true;
            }
        }

        return false;
    }

    /** @return list<int> */
    public function executiveDirectorApproverIds(array|object $row = [], int $submitterId = 0): array
    {
        $designationId = $this->getExecutiveDirectorDesignationId();
        if ($designationId === null) {
            return [];
        }
        if ($submitterId < 1) {
            $submitterId = $this->submitterId($row);
        }
        $rows = $this->employeesHoldingDesignation($designationId);
        $rows = $this->preferSameProject($rows, $this->resolveProjectId($submitterId, $row));

        return array_map('intval', array_column($rows, 'employee_id'));
    }

    protected function getExecutiveDirectorDesignationId(): ?int
    {
        if ($this->edDesignationId !== null) {
            return $this->edDesignationId > 0 ? $this->edDesignationId : null;
        }
        if (!Schema::hasTable('designation')) {
            $this->edDesignationId = 0;

            return null;
        }
        $id = (int) (DB::table('designation')
            ->whereRaw('LOWER(TRIM(name)) = ?', ['executive director'])
            ->value('designation_id') ?? 0);
        $this->edDesignationId = $id;

        return $id > 0 ? $id : null;
    }

    protected function getEmployeeProjectId(int $employeeId): int
    {
        if ($employeeId < 1) {
            return 0;
        }
        if (array_key_exists($employeeId, $this->employeeProjectCache)) {
            return $this->employeeProjectCache[$employeeId];
        }
        $projectId = (int) (DB::table('employee')->where('employee_id', $employeeId)->value('project') ?? 0);
        $this->employeeProjectCache[$employeeId] = $projectId;

        return $projectId;
    }

    protected function resolveProjectId(int $submitterId, array|object $requestRow = []): int
    {
        $a = is_array($requestRow) ? $requestRow : (array) $requestRow;
        $fromRow = (int) ($a['project_id'] ?? $a['project'] ?? 0);
        if ($fromRow > 0) {
            return $fromRow;
        }
        $traveler = (int) ($a['employee_id'] ?? $a['employee'] ?? 0);
        if ($traveler > 0) {
            $p = $this->getEmployeeProjectId($traveler);
            if ($p > 0) {
                return $p;
            }
        }

        return $this->getEmployeeProjectId($submitterId);
    }

    /**
     * @return list<array{employee_id: int, project: int}>
     */
    protected function employeesHoldingDesignation(int $designationRuleId): array
    {
        $ids = $this->designationIdsMatchingRule($designationRuleId);
        if ($ids === []) {
            return [];
        }

        return DB::table('employee')
            ->select('employee_id', 'project')
            ->whereIn('designation', $ids)
            ->whereIn('status', [1, 2])
            ->get()
            ->map(fn ($r) => [
                'employee_id' => (int) $r->employee_id,
                'project' => (int) ($r->project ?? 0),
            ])
            ->all();
    }

    /** @return list<int> */
    protected function designationIdsMatchingRule(int $designationRuleId): array
    {
        if ($designationRuleId < 1) {
            return [];
        }
        $ids = [$designationRuleId => $designationRuleId];
        $name = trim((string) (DB::table('designation')->where('designation_id', $designationRuleId)->value('name') ?? ''));
        if ($name === '') {
            return array_values($ids);
        }
        $same = DB::table('designation')
            ->whereRaw('LOWER(TRIM(name)) = ?', [strtolower($name)])
            ->pluck('designation_id');
        foreach ($same as $id) {
            $i = (int) $id;
            if ($i > 0) {
                $ids[$i] = $i;
            }
        }

        return array_values($ids);
    }

    /**
     * @param list<array{employee_id: int, project: int}> $rows
     * @return list<array{employee_id: int, project: int}>
     */
    protected function preferSameProject(array $rows, int $projectId): array
    {
        if ($projectId < 1 || $rows === []) {
            return $rows;
        }
        $matched = array_values(array_filter($rows, fn ($r) => (int) $r['project'] === $projectId));

        return $matched !== [] ? $matched : $rows;
    }
}
