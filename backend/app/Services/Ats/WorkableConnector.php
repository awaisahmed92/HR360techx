<?php

namespace App\Services\Ats;

use Illuminate\Support\Facades\Http;

class WorkableConnector implements AtsConnectorInterface
{
    public function pullJobsAndCandidates(array $config): array
    {
        $key = (string) ($config['api_key'] ?? '');
        $subdomain = (string) ($config['subdomain'] ?? '');
        if ($key === '' || $subdomain === '') {
            return ['imported' => 0, 'message' => 'Workable API key/subdomain missing', 'status' => 'skipped'];
        }
        try {
            $res = Http::withToken($key)->timeout(20)->get("https://{$subdomain}.workable.com/spi/v3/jobs");
            if (!$res->successful()) {
                return ['imported' => 0, 'message' => 'Workable HTTP '.$res->status(), 'status' => 'error'];
            }

            return ['imported' => 0, 'message' => 'Workable reachable; import mapped by admin sync', 'status' => 'ok'];
        } catch (\Throwable $e) {
            return ['imported' => 0, 'message' => $e->getMessage(), 'status' => 'error'];
        }
    }
}
