<?php

namespace App\Services\Ats;

use Illuminate\Support\Facades\Http;

class GreenhouseConnector implements AtsConnectorInterface
{
    public function pullJobsAndCandidates(array $config): array
    {
        $key = (string) ($config['api_key'] ?? '');
        if ($key === '') {
            return ['imported' => 0, 'message' => 'Greenhouse API key missing', 'status' => 'skipped'];
        }
        try {
            $res = Http::withBasicAuth($key, '')->timeout(20)->get('https://harvest.greenhouse.io/v1/jobs');
            if (!$res->successful()) {
                return ['imported' => 0, 'message' => 'Greenhouse HTTP '.$res->status(), 'status' => 'error'];
            }

            return ['imported' => 0, 'message' => 'Greenhouse reachable', 'status' => 'ok'];
        } catch (\Throwable $e) {
            return ['imported' => 0, 'message' => $e->getMessage(), 'status' => 'error'];
        }
    }
}
