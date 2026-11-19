<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ResumeParseService;
use App\Services\TenantManager;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class CareersPortalController extends Controller
{
    protected function bindTenant(Request $request): ?\Illuminate\Http\JsonResponse
    {
        $sub = trim((string) $request->query('org', $request->input('org', 'demo')));
        $tenant = TenantManager::findBySubdomain($sub);
        if (!$tenant) {
            return response()->json(['success' => false, 'message' => 'Organization not found'], 404);
        }
        TenantManager::connect($tenant);

        return null;
    }

    public function settings(Request $request)
    {
        if ($err = $this->bindTenant($request)) {
            return $err;
        }
        $row = Schema::hasTable('hr_recruit_portal_settings')
            ? DB::table('hr_recruit_portal_settings')->orderBy('id')->first()
            : null;
        $enabled = $row ? (int) $row->enabled === 1 : true;

        return response()->json([
            'success' => true,
            'enabled' => $enabled,
            'brand_name' => (string) ($row->brand_name ?? 'Careers'),
            'welcome_text' => (string) ($row->welcome_text ?? ''),
            'fields' => json_decode((string) ($row->fields_json ?? '[]'), true) ?: ['name', 'email', 'phone', 'resume'],
            'resume_parse_enabled' => $row ? (int) ($row->resume_parse_enabled ?? 0) === 1 : false,
        ]);
    }

    public function posts(Request $request)
    {
        if ($err = $this->bindTenant($request)) {
            return $err;
        }
        if (!$this->portalEnabled()) {
            return response()->json(['success' => false, 'message' => 'Careers portal disabled'], 403);
        }
        if (!Schema::hasTable('hr_recruit_posts')) {
            return response()->json(['success' => true, 'posts' => []]);
        }
        $rows = DB::table('hr_recruit_posts')
            ->where('status', 1)
            ->where('publish_portal', 1)
            ->whereIn('job_for', [0, 2])
            ->orderByDesc('id')
            ->get(['id', 'title', 'job_type', 'locations', 'description', 'vacancies', 'opening_date', 'closing_date'])
            ->map(fn ($r) => [
                'id' => (int) $r->id,
                'title' => (string) $r->title,
                'job_type' => (string) ($r->job_type ?? ''),
                'locations' => (string) ($r->locations ?? ''),
                'description' => (string) ($r->description ?? ''),
                'vacancies' => (int) $r->vacancies,
                'opening_date' => $r->opening_date,
                'closing_date' => $r->closing_date,
            ]);

        return response()->json(['success' => true, 'posts' => $rows]);
    }

    public function postShow(Request $request, int $id)
    {
        if ($err = $this->bindTenant($request)) {
            return $err;
        }
        if (!$this->portalEnabled()) {
            return response()->json(['success' => false, 'message' => 'Careers portal disabled'], 403);
        }
        $r = DB::table('hr_recruit_posts')->where('id', $id)->where('status', 1)->where('publish_portal', 1)->first();
        if (!$r) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }

        return response()->json([
            'success' => true,
            'post' => [
                'id' => (int) $r->id,
                'title' => (string) $r->title,
                'job_type' => (string) ($r->job_type ?? ''),
                'locations' => (string) ($r->locations ?? ''),
                'description' => (string) ($r->description ?? ''),
                'qualification' => (string) ($r->qualification ?? ''),
                'experience' => (string) ($r->experience ?? ''),
                'vacancies' => (int) $r->vacancies,
            ],
        ]);
    }

    public function apply(Request $request, ResumeParseService $parser)
    {
        if ($err = $this->bindTenant($request)) {
            return $err;
        }
        if (!$this->portalEnabled()) {
            return response()->json(['success' => false, 'message' => 'Careers portal disabled'], 403);
        }
        $data = $request->validate([
            'post_id' => 'required|integer',
            'name' => 'required|string|max:191',
            'email' => 'nullable|email|max:191',
            'phone' => 'nullable|string|max:40',
            'total_experience' => 'nullable|string|max:40',
            'parse_resume' => 'nullable|boolean',
        ]);
        $post = DB::table('hr_recruit_posts')->where('id', $data['post_id'])->where('status', 1)->first();
        if (!$post) {
            return response()->json(['success' => false, 'message' => 'Post not open'], 404);
        }

        $resumePath = null;
        if ($request->hasFile('resume')) {
            $resumePath = $request->file('resume')->store('public/resumes');
        }

        $parsed = [];
        if (!empty($data['parse_resume']) && $resumePath) {
            $parsed = $parser->parse('', str_replace('public/', 'public/', $resumePath));
        }

        $name = $data['name'] ?: ($parsed['name'] ?? 'Applicant');
        $email = $data['email'] ?? ($parsed['email'] ?? null);
        $phone = $data['phone'] ?? ($parsed['phone'] ?? null);

        $candidateId = null;
        if (Schema::hasTable('hr_candidate')) {
            if ($email) {
                $existing = DB::table('hr_candidate')->where('email', $email)->first();
                if ($existing) {
                    $candidateId = (int) $existing->id;
                    DB::table('hr_candidate')->where('id', $candidateId)->update([
                        'name' => $name,
                        'phone' => $phone,
                        'job_id' => $post->legacy_job_id,
                        'total_experience' => $data['total_experience'] ?? ($parsed['experience'] ?? $existing->total_experience),
                        'status' => 0,
                    ]);
                }
            }
            if (!$candidateId) {
                $candidateId = (int) DB::table('hr_candidate')->insertGetId([
                    'name' => $name,
                    'email' => $email,
                    'phone' => $phone,
                    'job_id' => $post->legacy_job_id,
                    'total_experience' => $data['total_experience'] ?? ($parsed['experience'] ?? null),
                    'status' => 0,
                    'created_at' => now(),
                ]);
            }
            if (!empty($parsed['skills']) && Schema::hasTable('hr_recruit_candidate_skills')) {
                foreach ((array) $parsed['skills'] as $skill) {
                    if (!$skill) {
                        continue;
                    }
                    DB::table('hr_recruit_candidate_skills')->insert([
                        'candidate_id' => $candidateId,
                        'skill' => is_string($skill) ? $skill : (string) ($skill['name'] ?? ''),
                    ]);
                }
            }
        }

        $appId = null;
        if ($candidateId && Schema::hasTable('hr_recruit_applications')) {
            $appId = (int) DB::table('hr_recruit_applications')->insertGetId([
                'candidate_id' => $candidateId,
                'post_id' => (int) $post->id,
                'legacy_job_id' => $post->legacy_job_id,
                'source' => 'portal',
                'stage' => 0,
                'application_stage' => 0,
                'status' => 0,
                'activity_json' => json_encode(['resume' => $resumePath, 'parsed' => $parsed]),
                'created_at' => now(),
            ]);
        }

        return response()->json([
            'success' => true,
            'candidate_id' => $candidateId,
            'application_id' => $appId,
            'parsed' => $parsed,
            'message' => 'Application received.',
        ]);
    }

    public function indeedWebhook(Request $request)
    {
        if ($err = $this->bindTenant($request)) {
            return $err;
        }

        return $this->atsWebhook('indeed', $request);
    }

    public function checkrWebhook(Request $request)
    {
        if ($err = $this->bindTenant($request)) {
            return $err;
        }
        $payload = $request->all();
        $ext = (string) ($payload['candidate_id'] ?? $payload['id'] ?? '');
        $status = (string) ($payload['status'] ?? $payload['report']['status'] ?? 'unknown');
        if ($ext !== '' && Schema::hasTable('hr_recruit_applications')) {
            DB::table('hr_recruit_applications')
                ->where('ats_external_id', $ext)
                ->orWhere('id', (int) $ext)
                ->update(['checkr_status' => $status, 'updated_at' => now()]);
        }
        $this->logAts('checkr', 'webhook', $payload, 'ok', 'Checkr status '.$status);

        return response()->json(['success' => true]);
    }

    protected function atsWebhook(string $provider, Request $request)
    {
        $payload = $request->all();
        try {
            $name = (string) ($payload['name'] ?? $payload['applicant']['name'] ?? 'Indeed Applicant');
            $email = $payload['email'] ?? $payload['applicant']['email'] ?? null;
            $postId = (int) ($payload['post_id'] ?? $payload['job_id'] ?? 0);
            $post = $postId > 0 ? DB::table('hr_recruit_posts')->where('id', $postId)->first() : null;
            if (Schema::hasTable('hr_candidate')) {
                $cid = (int) DB::table('hr_candidate')->insertGetId([
                    'name' => $name,
                    'email' => $email,
                    'job_id' => $post->legacy_job_id ?? null,
                    'status' => 0,
                    'created_at' => now(),
                ]);
                if ($post && Schema::hasTable('hr_recruit_applications')) {
                    DB::table('hr_recruit_applications')->insert([
                        'candidate_id' => $cid,
                        'post_id' => (int) $post->id,
                        'legacy_job_id' => $post->legacy_job_id,
                        'source' => 'ats',
                        'ats_external_id' => (string) ($payload['id'] ?? ''),
                        'stage' => 0,
                        'application_stage' => 0,
                        'status' => 0,
                        'created_at' => now(),
                    ]);
                }
            }
            $this->logAts($provider, 'webhook', $payload, 'ok', 'Imported');
        } catch (\Throwable $e) {
            $this->logAts($provider, 'webhook', $payload, 'error', $e->getMessage());
        }

        return response()->json(['success' => true]);
    }

    protected function portalEnabled(): bool
    {
        if (!Schema::hasTable('hr_recruit_portal_settings')) {
            return true;
        }
        $row = DB::table('hr_recruit_portal_settings')->orderBy('id')->first();

        return !$row || (int) $row->enabled === 1;
    }

    protected function logAts(string $provider, string $action, array $payload, string $status, string $message): void
    {
        if (!Schema::hasTable('hr_recruit_ats_log')) {
            return;
        }
        DB::table('hr_recruit_ats_log')->insert([
            'provider' => $provider,
            'action' => $action,
            'payload' => json_encode($payload),
            'status' => $status,
            'message' => $message,
            'created_at' => now(),
        ]);
    }
}
