<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\MasterRegistry;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class MasterDataController extends Controller
{
    public function catalog()
    {
        $out = [];
        foreach (MasterRegistry::all() as $key => $def) {
            if (!empty($def['options_only'])) {
                continue;
            }
            $out[] = [
                'key' => $key,
                'title' => $def['title'],
                'read_only' => !empty($def['read_only']),
                'note' => $def['note'] ?? null,
            ];
        }

        return response()->json(['success' => true, 'entities' => $out]);
    }

    public function meta(string $entity)
    {
        $def = MasterRegistry::get($entity);
        if (!$def || !empty($def['options_only'])) {
            return response()->json(['success' => false, 'message' => 'Unknown entity.'], 404);
        }
        if (!Schema::hasTable($def['table'])) {
            return response()->json([
                'success' => false,
                'message' => 'Table missing. Run database/09_phase2_masters.sql on the tenant DB.',
            ], 503);
        }

        $fields = [];
        foreach ($def['fields'] as $f) {
            $field = $f;
            if (($f['type'] ?? '') === 'fk' && !empty($f['fk'])) {
                $field['options'] = $this->fkOptions($f['fk']);
            } elseif (($f['type'] ?? '') === 'select' && isset($f['options']) && $this->isList($f['options'])) {
                $map = [];
                foreach ($f['options'] as $opt) {
                    $map[(string) $opt] = (string) $opt;
                }
                $field['options'] = $map;
            }
            $fields[] = $field;
        }

        return response()->json([
            'success' => true,
            'entity' => $entity,
            'title' => $def['title'],
            'read_only' => !empty($def['read_only']),
            'note' => $def['note'] ?? null,
            'columns' => $def['columns'],
            'fields' => $fields,
            'pk' => MasterRegistry::resolvePk($def),
        ]);
    }

    public function index(Request $request, string $entity)
    {
        $def = MasterRegistry::get($entity);
        if (!$def || !empty($def['options_only'])) {
            return response()->json(['success' => false, 'message' => 'Unknown entity.'], 404);
        }
        if (!Schema::hasTable($def['table'])) {
            return response()->json(['success' => false, 'message' => 'Table missing for '.$entity.'. Run 09_phase2_masters.sql.'], 503);
        }

        $pk = MasterRegistry::resolvePk($def);
        $q = DB::table($def['table'].' as t');

        foreach ($def['joins'] ?? [] as $j) {
            $on = $j['on'];
            if (str_contains($on, '{cpk}')) {
                $cpk = Schema::hasColumn('company', 'company_id') ? 'company_id' : 'id';
                $on = str_replace('{cpk}', $cpk, $on);
            }
            // "alias.col = t.col"
            if (preg_match('/^(\w+)\.(\w+)\s*=\s*(\w+)\.(\w+)$/', trim($on), $m)) {
                $q->leftJoin($j['table'].' as '.$j['alias'], $m[1].'.'.$m[2], '=', $m[3].'.'.$m[4]);
            } else {
                $q->leftJoin($j['table'].' as '.$j['alias'], function ($join) use ($on) {
                    $join->whereRaw($on);
                });
            }
        }

        $select = ['t.*'];
        foreach ($def['joins'] ?? [] as $j) {
            if (!empty($j['select'])) {
                $select[] = DB::raw($j['select']);
            }
        }
        $q->select($select);

        foreach ($def['filter'] ?? [] as $col => $val) {
            if (Schema::hasColumn($def['table'], $col)) {
                $q->where('t.'.$col, $val);
            }
        }

        $search = trim((string) $request->query('q', ''));
        if ($search !== '') {
            $cols = $def['search'] ?? array_column(array_filter($def['fields'], fn ($f) => ($f['type'] ?? '') === 'text'), 'key');
            $q->where(function ($w) use ($cols, $search, $def) {
                $any = false;
                foreach ($cols as $c) {
                    if (Schema::hasColumn($def['table'], $c)) {
                        $w->orWhere('t.'.$c, 'like', '%'.$search.'%');
                        $any = true;
                    }
                }
                if (!$any && Schema::hasColumn($def['table'], 'name')) {
                    $w->orWhere('t.name', 'like', '%'.$search.'%');
                }
            });
        }

        $rows = $q->orderByDesc('t.'.$pk)->limit(500)->get()->map(function ($r) use ($pk, $def) {
            $row = (array) $r;
            $row['id'] = (int) ($row[$pk] ?? 0);
            // Ensure display fallbacks
            if (empty($row['hr_company_name']) && !empty($row['name']) && ($def['table'] ?? '') === 'company') {
                $row['hr_company_name'] = $row['name'];
            }

            return $row;
        });

        return response()->json([
            'success' => true,
            'entity' => $entity,
            'rows' => $rows,
            'count' => count($rows),
        ]);
    }

    public function store(Request $request, string $entity)
    {
        return $this->upsert($request, $entity, null);
    }

    public function update(Request $request, string $entity, int $id)
    {
        return $this->upsert($request, $entity, $id);
    }

    public function destroy(Request $request, string $entity, int $id)
    {
        $def = MasterRegistry::get($entity);
        if (!$def || !empty($def['read_only']) || !empty($def['options_only'])) {
            return response()->json(['success' => false, 'message' => 'Not deletable.'], 422);
        }
        $pk = MasterRegistry::resolvePk($def);
        DB::table($def['table'])->where($pk, $id)->delete();
        $this->log($request, 'delete', $entity, $id);

        return response()->json(['success' => true, 'message' => 'Deleted.']);
    }

    public function options(string $entity)
    {
        $opts = $this->fkOptions($entity);

        return response()->json(['success' => true, 'options' => $opts]);
    }

    protected function upsert(Request $request, string $entity, ?int $id)
    {
        $def = MasterRegistry::get($entity);
        if (!$def || !empty($def['read_only']) || !empty($def['options_only'])) {
            return response()->json(['success' => false, 'message' => 'Unknown or read-only entity.'], 404);
        }
        if (!Schema::hasTable($def['table'])) {
            return response()->json(['success' => false, 'message' => 'Table missing. Run 09_phase2_masters.sql.'], 503);
        }

        $data = [];
        foreach ($def['fields'] as $f) {
            $key = $f['key'];
            if (($f['type'] ?? '') === 'hidden' && !$request->has($key) && isset($f['default'])) {
                $data[$key] = $f['default'];
                continue;
            }
            if (!$request->has($key) && $id !== null) {
                continue;
            }
            if (!$request->has($key) && isset($f['default'])) {
                $data[$key] = $f['default'];
                continue;
            }
            if (!$request->has($key)) {
                if (!empty($f['required']) && $id === null) {
                    return response()->json(['success' => false, 'message' => $f['label'].' is required.'], 422);
                }
                continue;
            }
            $val = $request->input($key);
            if (!empty($f['required']) && ($val === null || $val === '')) {
                return response()->json(['success' => false, 'message' => $f['label'].' is required.'], 422);
            }
            if (!Schema::hasColumn($def['table'], $key)) {
                continue;
            }
            $data[$key] = $val === '' ? null : $val;
        }

        // Force filter category on payroll items
        foreach ($def['filter'] ?? [] as $col => $val) {
            if (Schema::hasColumn($def['table'], $col)) {
                $data[$col] = $val;
            }
        }

        if ($data === []) {
            return response()->json(['success' => false, 'message' => 'No fields to save.'], 422);
        }

        $pk = MasterRegistry::resolvePk($def);
        if ($id === null) {
            if ($pk === 'id') {
                $newId = (int) DB::table($def['table'])->insertGetId($data);
            } else {
                DB::table($def['table'])->insert($data);
                $newId = (int) DB::table($def['table'])->orderByDesc($pk)->value($pk);
            }
            $this->log($request, 'create', $entity, $newId, json_encode($data));

            return response()->json(['success' => true, 'message' => 'Created.', 'id' => $newId]);
        }

        DB::table($def['table'])->where($pk, $id)->update($data);
        $this->log($request, 'update', $entity, $id, json_encode($data));

        return response()->json(['success' => true, 'message' => 'Updated.', 'id' => $id]);
    }

    /** @return array<int, array{id:int,label:string}> */
    protected function fkOptions(string $fkEntity): array
    {
        $def = MasterRegistry::get($fkEntity);
        if (!$def || !Schema::hasTable($def['table'])) {
            return [];
        }
        $pk = MasterRegistry::resolvePk($def);
        $label = $def['label'] ?? 'name';
        if (!Schema::hasColumn($def['table'], $label)) {
            $label = Schema::hasColumn($def['table'], 'name') ? 'name' : $pk;
        }

        return DB::table($def['table'])
            ->orderBy($label)
            ->limit(1000)
            ->get([$pk, $label])
            ->map(fn ($r) => [
                'id' => (int) $r->{$pk},
                'label' => (string) ($r->{$label} ?? '#'.$r->{$pk}),
            ])
            ->all();
    }

    protected function isList(array $options): bool
    {
        return array_keys($options) === range(0, count($options) - 1);
    }

    protected function log(Request $request, string $action, string $entity, int $id, ?string $detail = null): void
    {
        if (!Schema::hasTable('hr_system_log')) {
            return;
        }
        $claims = $request->attributes->get('hr_claims') ?? [];
        DB::table('hr_system_log')->insert([
            'actor_id' => (int) ($claims['employee_id'] ?? 0) ?: null,
            'action' => $action,
            'entity' => $entity,
            'entity_id' => $id,
            'detail' => $detail,
            'created_at' => now(),
        ]);
    }
}
