<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class RecruitmentController extends Controller
{
    public function jobsIndex()
    {
        if (!Schema::hasTable('hr_job')) {
            return response()->json(['success' => false, 'message' => 'Run database/20_hiring_performance_mvp.sql'], 503);
        }
        $rows = DB::table('hr_job as j')
            ->leftJoin('designation as d', 'd.designation_id', '=', 'j.designation_id')
            ->leftJoin('department as dep', 'dep.department_id', '=', 'j.department_id')
            ->orderByDesc('j.id')
            ->get([
                'j.*',
                'd.name as designation_name',
                'dep.name as department_name',
            ])
            ->map(fn ($r) => $this->mapJob($r));

        return response()->json(['success' => true, 'jobs' => $rows]);
    }

    public function jobsStore(Request $request)
    {
        return $this->jobUpsert($request, null);
    }

    public function jobsUpdate(Request $request, int $id)
    {
        return $this->jobUpsert($request, $id);
    }

    public function jobsDelete(int $id)
    {
        DB::table('hr_job')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function candidatesIndex(Request $request)
    {
        if (!Schema::hasTable('hr_candidate')) {
            return response()->json(['success' => false, 'message' => 'Run database/20_hiring_performance_mvp.sql'], 503);
        }
        $q = DB::table('hr_candidate as c')
            ->leftJoin('hr_job as j', 'j.id', '=', 'c.job_id')
            ->orderByDesc('c.id')
            ->select('c.*', 'j.title as job_title');

        if ($request->filled('status')) {
            $q->where('c.status', (int) $request->query('status'));
        }
        if ($request->filled('job_id')) {
            $q->where('c.job_id', (int) $request->query('job_id'));
        }
        if ($request->filled('q')) {
            $like = '%'.trim((string) $request->query('q')).'%';
            $q->where(function ($w) use ($like) {
                $w->where('c.name', 'like', $like)
                    ->orWhere('c.email', 'like', $like)
                    ->orWhere('c.phone', 'like', $like)
                    ->orWhere('c.cnic', 'like', $like);
            });
        }
        if ($request->filled('gender') && Schema::hasColumn('hr_candidate', 'gender')) {
            $q->where('c.gender', (int) $request->query('gender'));
        }
        if ($request->filled('min_exp')) {
            // loose match on total_experience text
            $q->where('c.total_experience', 'like', '%'.trim((string) $request->query('min_exp')).'%');
        }
        if ($request->filled('qualification') && Schema::hasColumn('hr_candidate', 'qualification')) {
            $q->where('c.qualification', 'like', '%'.trim((string) $request->query('qualification')).'%');
        }
        if ($request->filled('district') && Schema::hasColumn('hr_candidate', 'district')) {
            $q->where('c.district', 'like', '%'.trim((string) $request->query('district')).'%');
        }
        if ($request->filled('max_salary') && is_numeric($request->query('max_salary'))) {
            $q->where(function ($w) use ($request) {
                $w->whereNull('c.expected_salary')
                    ->orWhere('c.expected_salary', '<=', (float) $request->query('max_salary'));
            });
        }

        $rows = $q->get()->map(fn ($r) => $this->mapCandidate($r));

        return response()->json(['success' => true, 'candidates' => $rows]);
    }

    public function candidatesShow(int $id)
    {
        $cand = DB::table('hr_candidate as c')
            ->leftJoin('hr_job as j', 'j.id', '=', 'c.job_id')
            ->where('c.id', $id)
            ->first(['c.*', 'j.title as job_title']);
        if (!$cand) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }

        return response()->json([
            'success' => true,
            'candidate' => $this->mapCandidate($cand),
            'education' => $this->listEducation($id),
            'experience' => $this->listExperience($id),
            'references' => $this->listReferences($id),
        ]);
    }

    public function candidatesSaveProfile(Request $request, int $id)
    {
        $cand = DB::table('hr_candidate')->where('id', $id)->first();
        if (!$cand) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'qualification' => 'nullable|string|max:191',
            'district' => 'nullable|string|max:100',
            'education' => 'nullable|array',
            'experience' => 'nullable|array',
            'references' => 'nullable|array',
        ]);

        $scalar = [];
        foreach (['qualification', 'district'] as $col) {
            if (array_key_exists($col, $data) && Schema::hasColumn('hr_candidate', $col)) {
                $scalar[$col] = $data[$col];
            }
        }
        if ($scalar !== []) {
            DB::table('hr_candidate')->where('id', $id)->update($scalar);
        }

        if ($request->has('education') && Schema::hasTable('hr_candidate_education')) {
            DB::table('hr_candidate_education')->where('candidate_id', $id)->delete();
            foreach ((array) $request->input('education', []) as $row) {
                if (!is_array($row)) {
                    continue;
                }
                if (empty($row['institute']) && empty($row['degree_id']) && empty($row['field'])) {
                    continue;
                }
                DB::table('hr_candidate_education')->insert([
                    'candidate_id' => $id,
                    'degree_id' => $row['degree_id'] ?? null,
                    'institute' => $row['institute'] ?? null,
                    'field' => $row['field'] ?? null,
                    'from_year' => $row['from_year'] ?? null,
                    'to_year' => $row['to_year'] ?? null,
                    'grade' => $row['grade'] ?? null,
                ]);
            }
        }

        if ($request->has('experience') && Schema::hasTable('hr_candidate_experience')) {
            DB::table('hr_candidate_experience')->where('candidate_id', $id)->delete();
            foreach ((array) $request->input('experience', []) as $row) {
                if (!is_array($row) || (empty($row['company']) && empty($row['position']))) {
                    continue;
                }
                DB::table('hr_candidate_experience')->insert([
                    'candidate_id' => $id,
                    'company' => $row['company'] ?? null,
                    'position' => $row['position'] ?? null,
                    'from_date' => $row['from_date'] ?? null,
                    'to_date' => $row['to_date'] ?? null,
                    'location' => $row['location'] ?? null,
                    'reason' => $row['reason'] ?? null,
                ]);
            }
        }

        if ($request->has('references') && Schema::hasTable('hr_candidate_reference')) {
            DB::table('hr_candidate_reference')->where('candidate_id', $id)->delete();
            foreach ((array) $request->input('references', []) as $row) {
                if (!is_array($row) || empty($row['name'])) {
                    continue;
                }
                $payload = [
                    'candidate_id' => $id,
                    'name' => $row['name'],
                    'company' => $row['company'] ?? null,
                    'phone' => $row['phone'] ?? null,
                    'email' => $row['email'] ?? null,
                    'feedback' => $row['feedback'] ?? null,
                    'passed' => array_key_exists('passed', $row) ? $row['passed'] : null,
                ];
                if (Schema::hasColumn('hr_candidate_reference', 'designation')) {
                    $payload['designation'] = $row['designation'] ?? null;
                }
                DB::table('hr_candidate_reference')->insert($payload);
            }
        }

        return response()->json(['success' => true, 'message' => 'Candidate profile saved.']);
    }

    protected function listEducation(int $candidateId): array
    {
        if (!Schema::hasTable('hr_candidate_education')) {
            return [];
        }

        return DB::table('hr_candidate_education as e')
            ->leftJoin('degree as d', 'd.degree_id', '=', 'e.degree_id')
            ->where('e.candidate_id', $candidateId)
            ->orderBy('e.id')
            ->get(['e.*', 'd.name as degree_name'])
            ->map(fn ($r) => [
                'id' => (int) $r->id,
                'degree_id' => $r->degree_id ? (int) $r->degree_id : null,
                'degree_name' => (string) ($r->degree_name ?? ''),
                'institute' => (string) ($r->institute ?? ''),
                'field' => (string) ($r->field ?? ''),
                'from_year' => (string) ($r->from_year ?? ''),
                'to_year' => (string) ($r->to_year ?? ''),
                'grade' => (string) ($r->grade ?? ''),
            ])->all();
    }

    protected function listExperience(int $candidateId): array
    {
        if (!Schema::hasTable('hr_candidate_experience')) {
            return [];
        }

        return DB::table('hr_candidate_experience')
            ->where('candidate_id', $candidateId)
            ->orderBy('id')
            ->get()
            ->map(fn ($r) => [
                'id' => (int) $r->id,
                'company' => (string) ($r->company ?? ''),
                'position' => (string) ($r->position ?? ''),
                'from_date' => (string) ($r->from_date ?? ''),
                'to_date' => (string) ($r->to_date ?? ''),
                'location' => (string) ($r->location ?? ''),
                'reason' => (string) ($r->reason ?? ''),
            ])->all();
    }

    protected function listReferences(int $candidateId): array
    {
        if (!Schema::hasTable('hr_candidate_reference')) {
            return [];
        }

        return DB::table('hr_candidate_reference')
            ->where('candidate_id', $candidateId)
            ->orderBy('id')
            ->get()
            ->map(fn ($r) => [
                'id' => (int) $r->id,
                'name' => (string) $r->name,
                'company' => (string) ($r->company ?? ''),
                'designation' => (string) ($r->designation ?? ''),
                'phone' => (string) ($r->phone ?? ''),
                'email' => (string) ($r->email ?? ''),
                'feedback' => (string) ($r->feedback ?? ''),
                'passed' => $r->passed !== null ? (int) $r->passed : null,
            ])->all();
    }

    public function candidatesStore(Request $request)
    {
        return $this->candidateUpsert($request, null);
    }

    public function candidatesUpdate(Request $request, int $id)
    {
        return $this->candidateUpsert($request, $id);
    }

    public function candidatesDelete(int $id)
    {
        DB::table('hr_candidate')->where('id', $id)->delete();

        return response()->json(['success' => true]);
    }

    public function candidatesStatus(Request $request, int $id)
    {
        $data = $request->validate([
            'status' => 'required|integer|min:-1|max:4',
            'remarks' => 'nullable|string',
            'ref_remarks' => 'nullable|string',
        ]);
        $row = DB::table('hr_candidate')->where('id', $id)->first();
        if (!$row) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }
        $update = ['status' => (int) $data['status']];
        if (array_key_exists('remarks', $data) && $data['remarks'] !== null) {
            $update['remarks'] = $data['remarks'];
        }
        if (Schema::hasColumn('hr_candidate', 'ref_remarks') && array_key_exists('ref_remarks', $data) && $data['ref_remarks'] !== null) {
            $update['ref_remarks'] = $data['ref_remarks'];
        }
        if ((int) $data['status'] === -1 && Schema::hasColumn('hr_candidate', 'rejected_at')) {
            $update['rejected_at'] = now();
        }
        DB::table('hr_candidate')->where('id', $id)->update($update);

        return response()->json(['success' => true, 'message' => 'Status updated.']);
    }

    /**
     * Convert Offer/Ready candidate into an employee (PHP ReadyToHire parity).
     */
    public function candidatesHire(Request $request, int $id)
    {
        $cand = DB::table('hr_candidate')->where('id', $id)->first();
        if (!$cand) {
            return response()->json(['success' => false, 'message' => 'Candidate not found.'], 404);
        }
        if ((int) ($cand->status ?? 0) >= 4 && !empty($cand->employee_id)) {
            return response()->json([
                'success' => true,
                'message' => 'Already hired.',
                'employee_id' => (int) $cand->employee_id,
            ]);
        }

        $data = $request->validate([
            'user_name' => 'nullable|string|max:100',
            'password' => 'nullable|string|min:4',
            'designation' => 'nullable|integer',
            'department' => 'nullable|integer',
            'station' => 'nullable|integer',
            'joining_date' => 'nullable|date',
            'employee_code' => 'nullable|string|max:50',
        ]);

        $baseUser = preg_replace('/[^a-zA-Z0-9]/', '', strtolower((string) $cand->name)) ?: 'hire';
        $userName = trim((string) ($data['user_name'] ?? $baseUser.$id));
        if (DB::table('employee')->where('user_name', $userName)->exists()) {
            $userName = $userName.'_'.$id;
        }

        $job = $cand->job_id ? DB::table('hr_job')->where('id', $cand->job_id)->first() : null;
        $password = (string) ($data['password'] ?? ($userName.'@786'));

        $empPayload = [
            'name' => (string) $cand->name,
            'user_name' => $userName,
            'email' => $cand->email ?: null,
            'phone' => $cand->phone ?: null,
            'cnic' => $cand->cnic ?: null,
            'password' => \Illuminate\Support\Facades\Hash::make($password),
            'status' => 1,
            'gender' => $cand->gender ?? null,
            'employee_code' => $data['employee_code'] ?? $userName,
            'contact_number' => $cand->phone ?: null,
            'designation' => $data['designation'] ?? ($job->designation_id ?? null),
            'department' => $data['department'] ?? ($job->department_id ?? null),
            'station' => $data['station'] ?? null,
            'joining_date' => $data['joining_date'] ?? now()->toDateString(),
            'total_experience' => $cand->total_experience ?? null,
        ];
        if (Schema::hasColumn('employee', 'is_first_login')) {
            $empPayload['is_first_login'] = 1;
        }

        // Only set columns that exist
        $row = [];
        foreach ($empPayload as $k => $v) {
            if (Schema::hasColumn('employee', $k)) {
                $row[$k] = $v;
            }
        }

        $employeeId = (int) DB::table('employee')->insertGetId($row);
        $candUpdate = ['status' => 4];
        if (Schema::hasColumn('hr_candidate', 'employee_id')) {
            $candUpdate['employee_id'] = $employeeId;
        }
        DB::table('hr_candidate')->where('id', $id)->update($candUpdate);

        return response()->json([
            'success' => true,
            'message' => 'Candidate hired as employee.',
            'employee_id' => $employeeId,
            'user_name' => $userName,
            'temp_password' => $password,
        ]);
    }

    public function meta()
    {
        $fk = function (string $table, string $pk) {
            if (!Schema::hasTable($table)) {
                return [];
            }

            return DB::table($table)->orderBy('name')->get([$pk, 'name'])->map(fn ($r) => [
                'id' => (int) $r->{$pk},
                'name' => (string) $r->name,
            ])->all();
        };

        return response()->json([
            'success' => true,
            'options' => [
                'designations' => $fk('designation', 'designation_id'),
                'departments' => $fk('department', 'department_id'),
                'stations' => $fk('station', 'station_id'),
                'degrees' => $fk('degree', 'degree_id'),
                'jobs' => Schema::hasTable('hr_job')
                    ? DB::table('hr_job')->where('status', 1)->orderBy('title')->get(['id', 'title'])->map(fn ($r) => [
                        'id' => (int) $r->id,
                        'name' => (string) $r->title,
                    ])->all()
                    : [],
                'job_types' => [
                    ['id' => 1, 'name' => 'Full-time'],
                    ['id' => 2, 'name' => 'Part-time'],
                    ['id' => 3, 'name' => 'Contract'],
                    ['id' => 4, 'name' => 'Intern'],
                    ['id' => 5, 'name' => 'Temporary'],
                ],
                'job_statuses' => [
                    ['id' => 1, 'name' => 'Open'],
                    ['id' => 2, 'name' => 'Closed'],
                    ['id' => 3, 'name' => 'Cancelled'],
                ],
                'candidate_stages' => [
                    ['id' => 0, 'name' => 'Applied'],
                    ['id' => 1, 'name' => 'Screening'],
                    ['id' => 2, 'name' => 'Interview'],
                    ['id' => 3, 'name' => 'Offer'],
                    ['id' => 4, 'name' => 'Hired'],
                    ['id' => -1, 'name' => 'Rejected'],
                ],
            ],
        ]);
    }

    protected function jobUpsert(Request $request, ?int $id)
    {
        if (!Schema::hasTable('hr_job')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }
        $data = $request->validate([
            'title' => 'required|string|max:191',
            'designation_id' => 'nullable|integer',
            'department_id' => 'nullable|integer',
            'vacancies' => 'nullable|integer|min:1',
            'job_type' => 'nullable|integer',
            'experience' => 'nullable|string|max:80',
            'qualification' => 'nullable|string|max:191',
            'description' => 'nullable|string',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'status' => 'nullable|integer',
        ]);
        $claims = $request->attributes->get('hr_claims') ?? [];
        $payload = [
            'title' => $data['title'],
            'designation_id' => $data['designation_id'] ?? null,
            'department_id' => $data['department_id'] ?? null,
            'vacancies' => (int) ($data['vacancies'] ?? 1),
            'job_type' => (int) ($data['job_type'] ?? 1),
            'experience' => $data['experience'] ?? null,
            'qualification' => $data['qualification'] ?? null,
            'description' => $data['description'] ?? null,
            'start_date' => $data['start_date'] ?? null,
            'end_date' => $data['end_date'] ?? null,
            'status' => (int) ($data['status'] ?? 1),
        ];
        if ($id === null) {
            $payload['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
            $newId = (int) DB::table('hr_job')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('hr_job')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    protected function candidateUpsert(Request $request, ?int $id)
    {
        if (!Schema::hasTable('hr_candidate')) {
            return response()->json(['success' => false, 'message' => 'Table missing'], 503);
        }
        $data = $request->validate([
            'name' => 'required|string|max:191',
            'email' => 'nullable|email|max:191',
            'phone' => 'nullable|string|max:40',
            'cnic' => 'nullable|string|max:40',
            'gender' => 'nullable|integer',
            'job_id' => 'nullable|integer',
            'total_experience' => 'nullable|string|max:40',
            'expected_salary' => 'nullable|numeric',
            'status' => 'nullable|integer',
            'remarks' => 'nullable|string',
            'qualification' => 'nullable|string|max:191',
            'district' => 'nullable|string|max:100',
        ]);
        $claims = $request->attributes->get('hr_claims') ?? [];
        $payload = [
            'name' => $data['name'],
            'email' => $data['email'] ?? null,
            'phone' => $data['phone'] ?? null,
            'cnic' => $data['cnic'] ?? null,
            'gender' => $data['gender'] ?? null,
            'job_id' => $data['job_id'] ?? null,
            'total_experience' => $data['total_experience'] ?? null,
            'expected_salary' => $data['expected_salary'] ?? null,
            'status' => (int) ($data['status'] ?? 0),
            'remarks' => $data['remarks'] ?? null,
        ];
        if (Schema::hasColumn('hr_candidate', 'qualification') && array_key_exists('qualification', $data)) {
            $payload['qualification'] = $data['qualification'];
        }
        if (Schema::hasColumn('hr_candidate', 'district') && array_key_exists('district', $data)) {
            $payload['district'] = $data['district'];
        }
        if (Schema::hasColumn('hr_candidate', 'ref_remarks') && $request->has('ref_remarks')) {
            $payload['ref_remarks'] = $request->input('ref_remarks');
        }
        if ($id === null) {
            $payload['created_by'] = (int) ($claims['employee_id'] ?? 0) ?: null;
            $newId = (int) DB::table('hr_candidate')->insertGetId($payload);

            return response()->json(['success' => true, 'id' => $newId]);
        }
        DB::table('hr_candidate')->where('id', $id)->update($payload);

        return response()->json(['success' => true, 'id' => $id]);
    }

    protected function mapJob(object $r): array
    {
        return [
            'id' => (int) $r->id,
            'title' => (string) $r->title,
            'designation_id' => $r->designation_id ? (int) $r->designation_id : null,
            'department_id' => $r->department_id ? (int) $r->department_id : null,
            'designation_name' => (string) ($r->designation_name ?? ''),
            'department_name' => (string) ($r->department_name ?? ''),
            'vacancies' => (int) $r->vacancies,
            'job_type' => (int) $r->job_type,
            'experience' => (string) ($r->experience ?? ''),
            'qualification' => (string) ($r->qualification ?? ''),
            'description' => (string) ($r->description ?? ''),
            'start_date' => $r->start_date,
            'end_date' => $r->end_date,
            'status' => (int) $r->status,
            'status_label' => match ((int) $r->status) {
                2 => 'Closed',
                3 => 'Cancelled',
                default => 'Open',
            },
        ];
    }

    protected function mapCandidate(object $r): array
    {
        $st = (int) $r->status;

        return [
            'id' => (int) $r->id,
            'name' => (string) $r->name,
            'email' => (string) ($r->email ?? ''),
            'phone' => (string) ($r->phone ?? ''),
            'cnic' => (string) ($r->cnic ?? ''),
            'gender' => $r->gender !== null ? (int) $r->gender : null,
            'job_id' => $r->job_id ? (int) $r->job_id : null,
            'job_title' => (string) ($r->job_title ?? ''),
            'total_experience' => (string) ($r->total_experience ?? ''),
            'expected_salary' => $r->expected_salary !== null ? (float) $r->expected_salary : null,
            'qualification' => (string) ($r->qualification ?? ''),
            'district' => (string) ($r->district ?? ''),
            'employee_id' => isset($r->employee_id) && $r->employee_id ? (int) $r->employee_id : null,
            'status' => $st,
            'stage' => match ($st) {
                -1 => 'Rejected',
                1 => 'Screening',
                2 => 'Interview',
                3 => 'Offer',
                4 => 'Hired',
                default => 'Applied',
            },
            'remarks' => (string) ($r->remarks ?? ''),
            'ref_remarks' => (string) ($r->ref_remarks ?? ''),
        ];
    }
}
