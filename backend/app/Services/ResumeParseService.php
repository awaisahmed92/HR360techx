<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;

class ResumeParseService
{
    /**
     * Parse resume text (or light file extract) via OpenAI-compatible API when configured.
     *
     * @return array{name?:string,email?:string,phone?:string,skills?:array,experience?:string,raw?:string}
     */
    public function parse(string $text, ?string $path = null): array
    {
        if ($text === '' && $path) {
            $full = storage_path('app/'.$path);
            if (is_file($full)) {
                $text = @file_get_contents($full) ?: '';
                // Strip non-printable for binary PDFs; caller can still edit manually.
                $text = preg_replace('/[^\P{C}\n\r\t]+/u', ' ', $text) ?? $text;
                $text = substr($text, 0, 12000);
            }
        }
        $settings = Schema::hasTable('hr_recruit_portal_settings')
            ? DB::table('hr_recruit_portal_settings')->orderBy('id')->first()
            : null;
        if (!$settings || !(int) ($settings->resume_parse_enabled ?? 0) || empty($settings->ai_api_key)) {
            return $this->heuristic($text);
        }
        $base = rtrim((string) ($settings->ai_base_url ?: 'https://api.openai.com/v1'), '/');
        try {
            $res = Http::withToken((string) $settings->ai_api_key)
                ->timeout(45)
                ->post($base.'/chat/completions', [
                    'model' => 'gpt-4o-mini',
                    'messages' => [
                        ['role' => 'system', 'content' => 'Extract candidate name, email, phone, skills (array), experience summary from resume. Reply JSON only.'],
                        ['role' => 'user', 'content' => substr($text, 0, 10000)],
                    ],
                    'temperature' => 0.1,
                ]);
            if ($res->successful()) {
                $content = (string) data_get($res->json(), 'choices.0.message.content', '');
                $content = trim(preg_replace('/^```json|```$/m', '', $content) ?? $content);
                $json = json_decode($content, true);
                if (is_array($json)) {
                    return [
                        'name' => (string) ($json['name'] ?? ''),
                        'email' => (string) ($json['email'] ?? ''),
                        'phone' => (string) ($json['phone'] ?? ''),
                        'skills' => is_array($json['skills'] ?? null) ? $json['skills'] : [],
                        'experience' => (string) ($json['experience'] ?? ''),
                        'raw' => $content,
                    ];
                }
            }
        } catch (\Throwable) {
            // fall through to heuristic
        }

        return $this->heuristic($text);
    }

    protected function heuristic(string $text): array
    {
        $email = null;
        $phone = null;
        if (preg_match('/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i', $text, $m)) {
            $email = $m[0];
        }
        if (preg_match('/(\+?\d[\d\s\-()]{8,}\d)/', $text, $m)) {
            $phone = trim($m[1]);
        }
        $firstLine = trim(explode("\n", $text)[0] ?? '');

        return [
            'name' => strlen($firstLine) < 80 ? $firstLine : '',
            'email' => $email ?? '',
            'phone' => $phone ?? '',
            'skills' => [],
            'experience' => '',
            'raw' => '',
        ];
    }
}
