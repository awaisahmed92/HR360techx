<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/** Directory, org chart, and the signed-in person's reporting chain. */
class InsightsController extends Controller
{
    public function people()
    {
        return response()->json(['success' => true, 'rows' => $this->peopleRows()]);
    }

    public function chain(Request $request)
    {
        $uid = (int) ($request->attributes->get('hr_claims')['employee_id'] ?? 0);
        $rows = $this->peopleRows();
        $byId = [];
        $children = [];
        foreach ($rows as $row) {
            $byId[$row['employee_id']] = $row;
            $children[$row['line_manager']][] = $row['employee_id'];
        }

        $managers = [];
        $seen = [$uid => true];
        $cursor = $uid;
        for ($i = 0; $i < 12; $i++) {
            $mgr = (int) ($byId[$cursor]['line_manager'] ?? 0);
            if ($mgr <= 0 || isset($seen[$mgr]) || !isset($byId[$mgr])) {
                break;
            }
            $seen[$mgr] = true;
            $managers[] = $byId[$mgr];
            $cursor = $mgr;
        }
        $managers = array_reverse($managers);

        $team = [];
        foreach ($children[$uid] ?? [] as $id) {
            if (isset($byId[$id])) {
                $team[] = $byId[$id];
            }
        }

        $accolades = [];
        if (Schema::hasTable('hr_achievement')) {
            $accolades = DB::table('hr_achievement')
                ->when(Schema::hasColumn('hr_achievement', 'employee_id'), fn ($q) => $q->where('employee_id', $uid))
                ->orderByDesc('id')
                ->limit(20)
                ->get()
                ->map(fn ($r) => [
                    'title' => (string) ($r->title ?? ''),
                    'date' => (string) ($r->achieved_on ?? ''),
                    'description' => (string) ($r->description ?? ''),
                ])
                ->all();
        }

        return response()->json([
            'success' => true,
            'me' => $byId[$uid] ?? null,
            'managers' => $managers,
            'team' => $team,
            'reports' => $this->branch($uid, $children, $byId, 0),
            'accolades' => $accolades,
        ]);
    }

    public function accolades()
    {
        if (!Schema::hasTable('hr_achievement')) {
            return response()->json(['success' => true, 'rows' => []]);
        }
        $q = DB::table('hr_achievement as a');
        if (Schema::hasColumn('hr_achievement', 'employee_id') && Schema::hasTable('employee')) {
            $q->leftJoin('employee as e', 'e.employee_id', '=', 'a.employee_id')
                ->select('a.*', 'e.name as employee_name');
        } else {
            $q->select('a.*');
        }
        $rows = $q->orderByDesc('a.id')->limit(100)->get()->map(fn ($r) => [
            'title' => (string) ($r->title ?? ''),
            'date' => (string) ($r->achieved_on ?? ''),
            'description' => (string) ($r->description ?? ''),
            'employee_name' => (string) ($r->employee_name ?? ''),
        ]);

        return response()->json(['success' => true, 'rows' => $rows]);
    }

    /** @return list<array<string, mixed>> */
    protected function peopleRows(): array
    {
        if (!Schema::hasTable('employee')) {
            return [];
        }
        $q = DB::table('employee as e');
        if (Schema::hasTable('designation')) {
            $q->leftJoin('designation as d', 'd.designation_id', '=', 'e.designation');
        }
        if (Schema::hasTable('department')) {
            $q->leftJoin('department as dep', 'dep.department_id', '=', 'e.department');
        }
        if (Schema::hasTable('station')) {
            $q->leftJoin('station as s', 's.station_id', '=', 'e.station');
        }
        $q->select('e.employee_id', 'e.name', 'e.user_name', 'e.employee_code', 'e.line_manager');
        if (Schema::hasColumn('employee', 'surname')) {
            $q->addSelect('e.surname');
        }
        if (Schema::hasColumn('employee', 'profile_picture')) {
            $q->addSelect('e.profile_picture');
        }
        if (Schema::hasColumn('employee', 'joining_date')) {
            $q->addSelect('e.joining_date');
        }
        if (Schema::hasColumn('employee', 'gender')) {
            $q->addSelect('e.gender');
        }
        if (Schema::hasColumn('employee', 'nationality')) {
            $q->addSelect('e.nationality');
        }
        if (Schema::hasColumn('employee', 'department')) {
            $q->addSelect('e.department as department_id');
        }
        if (Schema::hasColumn('employee', 'station')) {
            $q->addSelect('e.station as station_id');
        }
        if (Schema::hasTable('designation')) {
            $q->addSelect('d.name as designation_name');
        }
        if (Schema::hasTable('department')) {
            $q->addSelect('dep.name as department_name');
        }
        if (Schema::hasTable('station')) {
            $q->addSelect('s.name as station_name');
        }

        return $q->orderBy('e.name')->limit(800)->get()->map(function ($r) {
            $name = trim((string) ($r->name ?? ''));
            $surname = trim((string) ($r->surname ?? ''));
            if ($surname !== '' && !str_contains($name, $surname)) {
                $name = trim("$name $surname");
            }

            return [
                'employee_id' => (int) $r->employee_id,
                'name' => $name !== '' ? $name : (string) ($r->user_name ?? 'Employee'),
                'employee_code' => (string) ($r->employee_code ?? ''),
                'user_name' => (string) ($r->user_name ?? ''),
                'designation_name' => (string) ($r->designation_name ?? ''),
                'department_id' => (int) ($r->department_id ?? 0),
                'department_name' => (string) ($r->department_name ?? ''),
                'station_id' => (int) ($r->station_id ?? 0),
                'station_name' => (string) ($r->station_name ?? ''),
                'line_manager' => (int) ($r->line_manager ?? 0),
                'profile_picture' => $r->profile_picture ?? null,
                'joining_date' => $r->joining_date ?? null,
                'gender' => isset($r->gender) ? (int) $r->gender : null,
                'nationality' => (string) ($r->nationality ?? ''),
            ];
        })->all();
    }

    /** @param array<int, list<int>> $children
     *  @param array<int, array<string, mixed>> $byId
     *  @return list<array<string, mixed>>
     */
    protected function branch(int $id, array $children, array $byId, int $depth): array
    {
        if ($depth > 8) {
            return [];
        }
        $out = [];
        foreach ($children[$id] ?? [] as $childId) {
            if (!isset($byId[$childId]) || $childId === $id) {
                continue;
            }
            $node = $byId[$childId];
            $node['children'] = $this->branch($childId, $children, $byId, $depth + 1);
            $out[] = $node;
        }

        return $out;
    }
}
