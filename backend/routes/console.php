<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('hr360:schema', function () {
    $this->info('Running HR360 schema installer (bootstrap-hr.php)...');
    passthru('php '.escapeshellarg(base_path('bootstrap-hr.php')), $code);
    if ($code !== 0) {
        $this->error('Schema installer exited with code '.$code);

        return 1;
    }
    $this->info('Done. Login: organization demo / admin / admin');

    return 0;
})->purpose('Apply full HR tenant schema from database/*.sql');
