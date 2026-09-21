<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('hr360:schema {--check} {--force} {--capture=} {--new=} {--file=}', function () {
    $flags = [];
    foreach (['check', 'force'] as $flag) {
        if ($this->option($flag)) {
            $flags[] = '--'.$flag;
        }
    }
    foreach (['capture', 'new', 'file'] as $option) {
        $value = $this->option($option);
        if ($value !== null && $value !== '') {
            $flags[] = '--'.$option.'='.$value;
        }
    }

    passthru('php '.escapeshellarg(base_path('bootstrap-hr.php')).($flags ? ' '.implode(' ', $flags) : ''), $code);

    return $code === 0 ? 0 : 1;
})->purpose('Apply / verify the HR schema from database/*.sql (--check, --force, --capture=name, --new=name)');
