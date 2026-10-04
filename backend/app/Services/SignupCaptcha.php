<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use RuntimeException;

/** Short-lived image code for the public sign-up form. */
class SignupCaptcha
{
    public function issue(): array
    {
        $code = $this->code();
        $token = bin2hex(random_bytes(16));
        $this->store()->put($this->key($token), hash('sha256', $code), now()->addMinutes(10));

        $payload = [
            'token' => $token,
            'image' => 'data:image/png;base64,'.base64_encode($this->png($code)),
        ];
        if (app()->environment('testing')) {
            $payload['code'] = $code;
        }

        return $payload;
    }

    public function check(?string $token, ?string $answer): bool
    {
        $token = trim((string) $token);
        $answer = strtoupper(preg_replace('/\s+/', '', (string) $answer) ?? '');
        if ($token === '' || $answer === '') {
            return false;
        }

        $expected = $this->store()->get($this->key($token));
        if (! is_string($expected) || ! hash_equals($expected, hash('sha256', $answer))) {
            return false;
        }

        $this->store()->forget($this->key($token));

        return true;
    }

    private function store()
    {
        $name = app()->environment('testing') ? (string) config('cache.default') : 'file';

        return Cache::store($name);
    }

    private function key(string $token): string
    {
        return 'signup_captcha:'.$token;
    }

    private function code(): string
    {
        $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        $max = strlen($alphabet) - 1;
        $code = '';
        for ($i = 0; $i < 5; $i++) {
            $code .= $alphabet[random_int(0, $max)];
        }

        return $code;
    }

    private function png(string $code): string
    {
        if (! function_exists('imagecreatetruecolor')) {
            throw new RuntimeException('The captcha image library is not available.');
        }

        $image = imagecreatetruecolor(168, 56);
        $background = imagecolorallocate($image, 234, 243, 251);
        $ink = imagecolorallocate($image, 22, 51, 92);
        $line = imagecolorallocate($image, 140, 170, 210);
        imagefilledrectangle($image, 0, 0, 168, 56, $background);

        for ($i = 0; $i < 8; $i++) {
            imageline($image, random_int(0, 168), random_int(0, 56), random_int(0, 168), random_int(0, 56), $line);
        }
        for ($i = 0; $i < 40; $i++) {
            imagesetpixel($image, random_int(0, 167), random_int(0, 55), $line);
        }

        $x = 14;
        foreach (str_split($code) as $character) {
            imagestring($image, 5, $x, random_int(14, 26), $character, $ink);
            $x += 30;
        }

        ob_start();
        imagepng($image);
        $png = (string) ob_get_clean();
        imagedestroy($image);

        return $png;
    }
}
