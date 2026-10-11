<?php

/**
 * One-time demo portraits for employees who have no photo on disk.
 * Does not run on container start. Safe to run again: existing files are kept.
 *
 * Local:
 *   php scripts/assign_demo_photos.php
 * Production API container, after the image that contains these portraits is deployed:
 *   php scripts/assign_demo_photos.php
 */

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$photoDir = null;
foreach ([
    getenv('HR360_SQL_DIR') ? rtrim((string) getenv('HR360_SQL_DIR'), '/\\').DIRECTORY_SEPARATOR.'demo_photos' : '',
    dirname(__DIR__, 2).DIRECTORY_SEPARATOR.'database'.DIRECTORY_SEPARATOR.'demo_photos',
    '/var/www/html/database-sql/demo_photos',
] as $candidate) {
    if ($candidate !== '' && is_dir($candidate) && is_file($candidate.DIRECTORY_SEPARATOR.'m00.png')) {
        $photoDir = $candidate;
        break;
    }
}
if ($photoDir === null) {
    fwrite(STDERR, "Portrait folder not found. Deploy the image that includes database/demo_photos.\n");
    exit(1);
}

if (!Schema::hasTable('employee') || !Schema::hasColumn('employee', 'profile_picture')) {
    fwrite(STDERR, "employee.profile_picture is not available in this database.\n");
    exit(1);
}

$male = glob($photoDir.DIRECTORY_SEPARATOR.'m*.png') ?: [];
$female = glob($photoDir.DIRECTORY_SEPARATOR.'f*.png') ?: [];
sort($male);
sort($female);
if ($male === [] || $female === []) {
    fwrite(STDERR, "Portrait files are missing in {$photoDir}.\n");
    exit(1);
}

$destDir = public_path('uploads/demo');
if (!is_dir($destDir) && !mkdir($destDir, 0775, true) && !is_dir($destDir)) {
    fwrite(STDERR, "Could not create {$destDir}.\n");
    exit(1);
}

$rows = DB::table('employee')->orderBy('employee_id')->get(['employee_id', 'name', 'gender', 'profile_picture']);
$assigned = 0;
$kept = 0;
$maleUsed = 0;
$femaleUsed = 0;

foreach ($rows as $row) {
    $id = (int) $row->employee_id;
    $current = trim((string) ($row->profile_picture ?? ''));
    $currentAbs = $current === '' ? '' : public_path($current);
    if ($current !== '' && $currentAbs !== '' && is_file($currentAbs)) {
        $kept++;
        continue;
    }

    $gender = (int) ($row->gender ?? 1);
    if ($gender === 2) {
        $src = $female[$femaleUsed % count($female)];
        $femaleUsed++;
    } else {
        $src = $male[$maleUsed % count($male)];
        $maleUsed++;
    }

    $rel = 'uploads/demo/photo_'.$id.'.png';
    $dest = public_path($rel);
    if (!copy($src, $dest)) {
        fwrite(STDERR, "Could not copy portrait for employee {$id}.\n");
        exit(1);
    }

    DB::table('employee')->where('employee_id', $id)->update(['profile_picture' => $rel]);
    $assigned++;
    echo "photo {$row->name} ({$id}) -> {$rel}\n";
}

echo "Assigned {$assigned} portraits. Kept {$kept} employees who already had a photo file.\n";
