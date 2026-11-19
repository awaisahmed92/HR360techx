<?php

namespace App\Services\Ats;

interface AtsConnectorInterface
{
    /** @return array{imported:int,message:string,status:string} */
    public function pullJobsAndCandidates(array $config): array;
}
