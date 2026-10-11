<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class UploadController extends Controller
{
    public function companyLogo(Request $request)
    {
        $request->validate(
            ['file' => 'required|file|max:2048'],
            ['file.max' => 'Picture size must not be more than 2 MB.']
        );
        try {
            $path = $this->store($request, 'logo');
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
        if (!$path) {
            return response()->json(['success' => false, 'message' => 'Upload failed.'], 500);
        }
        if (Schema::hasTable('company')) {
            $row = DB::table('company')->first();
            if ($row) {
                $upd = [];
                if (Schema::hasColumn('company', 'hr_logo')) {
                    $upd['hr_logo'] = $path;
                }
                if (Schema::hasColumn('company', 'logo')) {
                    $upd['logo'] = $path;
                }
                if ($upd !== []) {
                    DB::table('company')->where('id', $row->id)->update($upd);
                }
            }
        }

        return response()->json([
            'success' => true,
            'path' => $path,
            'url' => $this->publicUrl($request, $path),
            'message' => 'Company logo updated.',
        ]);
    }

    public function employeePhoto(Request $request, int $id)
    {
        $request->validate(
            ['file' => 'required|file|max:2048'],
            ['file.max' => 'Picture size must not be more than 2 MB.']
        );
        $emp = DB::table('employee')->where('employee_id', $id)->first();
        if (!$emp) {
            return response()->json(['success' => false, 'message' => 'Employee not found.'], 404);
        }
        try {
            $path = $this->store($request, 'photo_'.$id);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
        if (!$path) {
            return response()->json(['success' => false, 'message' => 'Upload failed.'], 500);
        }
        DB::table('employee')->where('employee_id', $id)->update(['profile_picture' => $path]);

        return response()->json([
            'success' => true,
            'path' => $path,
            'url' => $this->publicUrl($request, $path),
            'message' => 'Photo updated.',
        ]);
    }

    public function showEmployeePhoto(int $id)
    {
        $emp = DB::table('employee')->where('employee_id', $id)->first();
        $path = trim((string) ($emp->profile_picture ?? ''));
        $abs = $path === '' ? '' : public_path($path);
        if (!$emp || $path === '' || !is_file($abs)) {
            return response()->json(['success' => false, 'message' => 'Photo not found.'], 404);
        }

        return response()->file($abs);
    }

    protected function store(Request $request, string $prefix): ?string
    {
        $claims = $request->attributes->get('hr_claims') ?? [];
        $sub = preg_replace('/[^a-z0-9_-]/i', '', (string) ($claims['subdomain'] ?? 'demo')) ?: 'demo';
        $file = $request->file('file');
        if (!$file) {
            return null;
        }
        $ext = strtolower($file->getClientOriginalExtension() ?: 'jpg');
        $name = $prefix.'_'.time().'.'.$ext;
        $extOk = in_array($ext, ['jpg', 'jpeg', 'png', 'gif', 'webp'], true);
        if (!$extOk) {
            throw new \RuntimeException('Use a JPG, PNG, GIF, or WebP image.');
        }
        $relDir = 'uploads/'.$sub;
        $absDir = public_path($relDir);
        if (!is_dir($absDir) && !@mkdir($absDir, 0775, true) && !is_dir($absDir)) {
            throw new \RuntimeException('The upload folder could not be created.');
        }
        if (!is_writable($absDir)) {
            throw new \RuntimeException('The upload folder is not writable.');
        }
        $file->move($absDir, $name);

        return $relDir.'/'.$name;
    }

    protected function publicUrl(Request $request, string $path): string
    {
        // Prefer APP_URL; fall back to request root (XAMPP: .../backend/public)
        $base = rtrim((string) config('app.url'), '/');
        if ($base === '' || str_contains($base, 'localhost') === false && !str_starts_with($base, 'http')) {
            $base = rtrim($request->getSchemeAndHttpHost().$request->getBasePath(), '/');
        }
        // When served under /HR360techx/backend/public, getBasePath already includes it
        return $base.'/'.ltrim($path, '/');
    }
}
