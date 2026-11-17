<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class HrLetterMergeService
{
    /** Built-in employee placeholders. */
    public function employeePlaceholders(): array
    {
        return [
            '{{employee_name}}',
            '{{employee_code}}',
            '{{designation}}',
            '{{department}}',
            '{{joining_date}}',
            '{{leaving_date}}',
            '{{company_name}}',
            '{{today}}',
            '{{reference_number}}',
        ];
    }

    /** Built-in candidate placeholders. */
    public function candidatePlaceholders(): array
    {
        return [
            '{{candidate_name}}',
            '{{candidate_email}}',
            '{{candidate_phone}}',
            '{{job_title}}',
            '{{company_name}}',
            '{{today}}',
            '{{reference_number}}',
        ];
    }

    public function companyName(): string
    {
        if (!Schema::hasTable('company')) {
            return 'Organization';
        }
        $pk = Schema::hasColumn('company', 'id') ? 'id' : (Schema::hasColumn('company', 'company_id') ? 'company_id' : null);
        $q = DB::table('company');
        if ($pk !== null) {
            $q->orderBy($pk);
        }
        $c = $q->first();
        if (!$c) {
            return 'Organization';
        }

        return (string) ($c->hr_company_name ?? $c->name ?? 'Organization');
    }

    /** @return array<string, string> */
    public function varsForEmployee(int $employeeId, string $reference = ''): array
    {
        $vars = [
            'employee_name' => '',
            'employee_code' => '',
            'designation' => '',
            'department' => '',
            'joining_date' => '',
            'leaving_date' => '',
            'company_name' => $this->companyName(),
            'today' => date('d M Y'),
            'reference_number' => $reference,
        ];
        if ($employeeId < 1 || !Schema::hasTable('employee')) {
            return $vars;
        }
        $q = DB::table('employee as e')->where('e.employee_id', $employeeId);
        if (Schema::hasTable('designation')) {
            $q->leftJoin('designation as d', 'd.designation_id', '=', 'e.designation');
            $q->addSelect('d.name as designation_name');
        }
        if (Schema::hasTable('department')) {
            $q->leftJoin('department as dep', 'dep.department_id', '=', 'e.department');
            $q->addSelect('dep.name as department_name');
        }
        $q->addSelect('e.name', 'e.employee_code', 'e.joining_date');
        if (Schema::hasColumn('employee', 'leaving_date')) {
            $q->addSelect('e.leaving_date');
        }
        if (Schema::hasColumn('employee', 'exit_date')) {
            $q->addSelect('e.exit_date');
        }
        $e = $q->first();
        if (!$e) {
            return $vars;
        }
        $vars['employee_name'] = (string) ($e->name ?? '');
        $vars['employee_code'] = (string) ($e->employee_code ?? '');
        $vars['designation'] = (string) ($e->designation_name ?? '');
        $vars['department'] = (string) ($e->department_name ?? '');
        $vars['joining_date'] = (string) ($e->joining_date ?? '');
        $vars['leaving_date'] = (string) ($e->leaving_date ?? $e->exit_date ?? '');

        return $vars;
    }

    /** @return array<string, string> */
    public function varsForCandidate(int $candidateId, string $reference = ''): array
    {
        $vars = [
            'candidate_name' => '',
            'candidate_email' => '',
            'candidate_phone' => '',
            'job_title' => '',
            'company_name' => $this->companyName(),
            'today' => date('d M Y'),
            'reference_number' => $reference,
            // Aliases so employee-style templates still render something useful.
            'employee_name' => '',
            'employee_code' => '',
            'designation' => '',
            'department' => '',
            'joining_date' => '',
            'leaving_date' => '',
        ];
        if ($candidateId < 1 || !Schema::hasTable('hr_candidate')) {
            return $vars;
        }
        $q = DB::table('hr_candidate as c')->where('c.id', $candidateId);
        if (Schema::hasTable('hr_job')) {
            $q->leftJoin('hr_job as j', 'j.id', '=', 'c.job_id');
            $q->addSelect('j.title as job_title');
        }
        $q->addSelect('c.name', 'c.email', 'c.phone');
        $c = $q->first();
        if (!$c) {
            return $vars;
        }
        $vars['candidate_name'] = (string) ($c->name ?? '');
        $vars['candidate_email'] = (string) ($c->email ?? '');
        $vars['candidate_phone'] = (string) ($c->phone ?? '');
        $vars['job_title'] = (string) ($c->job_title ?? '');
        $vars['employee_name'] = $vars['candidate_name'];
        $vars['designation'] = $vars['job_title'];

        return $vars;
    }

    /**
     * @param  array<string, mixed>  $custom
     * @param  array<int, array<string, mixed>>  $fieldDefs
     */
    public function merge(string $html, array $builtIn, array $custom = [], array $fieldDefs = []): string
    {
        $out = $html;
        foreach ($builtIn as $k => $v) {
            $out = str_replace('{{'.$k.'}}', (string) $v, $out);
        }
        foreach ($fieldDefs as $i => $def) {
            $key = (string) ($def['key'] ?? ('CustomVariable'.($i + 1)));
            $slot = 'CustomVariable'.($i + 1);
            $val = (string) ($custom[$key] ?? $custom[$slot] ?? $custom[(string) ($i + 1)] ?? '');
            $out = str_replace('{{'.$key.'}}', $val, $out);
            $out = str_replace('{{'.$slot.'}}', $val, $out);
        }
        foreach ($custom as $k => $v) {
            $out = str_replace('{{'.$k.'}}', (string) $v, $out);
        }

        return $out;
    }

    /** @param  array<string, mixed>|null  $options */
    public function nextReference(?array $options, int $typeId): string
    {
        $pattern = (string) ($options['reference_pattern'] ?? 'HRL-{YYYY}-{####}');
        $year = date('Y');
        $count = 1;
        if (Schema::hasTable('hr_letter_instances')) {
            $count = (int) DB::table('hr_letter_instances')
                ->where('type_id', $typeId)
                ->whereYear('created_at', (int) $year)
                ->count() + 1;
        }
        $ref = str_replace(['{YYYY}', '{####}', '{###}', '{##}'], [
            $year,
            str_pad((string) $count, 4, '0', STR_PAD_LEFT),
            str_pad((string) $count, 3, '0', STR_PAD_LEFT),
            str_pad((string) $count, 2, '0', STR_PAD_LEFT),
        ], $pattern);

        return $ref !== '' ? $ref : ('HRL-'.$year.'-'.str_pad((string) $count, 4, '0', STR_PAD_LEFT));
    }
}
