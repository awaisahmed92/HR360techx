<?php

namespace App\Services\Ats;

class JazzHrConnector implements AtsConnectorInterface
{
    public function pullJobsAndCandidates(array $config): array
    {
        if (empty($config['api_key'])) {
            return ['imported' => 0, 'message' => 'JazzHR API key missing', 'status' => 'skipped'];
        }

        // Stub matching the same interface — soft-fail friendly.
        return ['imported' => 0, 'message' => 'JazzHR pull stub completed', 'status' => 'ok'];
    }
}
