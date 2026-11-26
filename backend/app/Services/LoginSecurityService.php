<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Throwable;

/**
 * Login defence: progressive delay, account lockout, IP blocks, captcha gate, audit log.
 * All state lives on the master connection so it works before the tenant DB is bound.
 */
class LoginSecurityService
{
    public const FAIL_LOCK_COUNT = 3;
    public const FAIL_LOCK_MINUTES = 5;
    public const IP_BLOCK_FAILS = 10;
    public const IP_BLOCK_MINUTES = 30;
    public const CAPTCHA_AFTER_FAILS = 2;
    public const WINDOW_MINUTES = 15;

    public function __construct(protected SignupCaptcha $captcha)
    {
    }

    public function ensureTables(): void
    {
        try {
            $db = DB::connection('master');
            $db->statement(<<<'SQL'
CREATE TABLE IF NOT EXISTS `hr_login_attempts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ip` VARCHAR(64) NOT NULL,
  `subdomain` VARCHAR(100) NULL,
  `username` VARCHAR(191) NULL,
  `success` TINYINT(1) NOT NULL DEFAULT 0,
  `reason` VARCHAR(80) NULL,
  `suspicious` TINYINT(1) NOT NULL DEFAULT 0,
  `user_agent` VARCHAR(255) NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_login_ip_time` (`ip`, `created_at`),
  KEY `idx_login_acct_time` (`subdomain`, `username`, `created_at`),
  KEY `idx_login_suspicious` (`suspicious`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
SQL);
            $db->statement(<<<'SQL'
CREATE TABLE IF NOT EXISTS `hr_ip_blocks` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ip` VARCHAR(64) NOT NULL,
  `reason` VARCHAR(191) NOT NULL,
  `blocked_until` DATETIME NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ip_blocks_ip` (`ip`),
  KEY `idx_ip_blocks_until` (`blocked_until`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
SQL);
            $db->statement(<<<'SQL'
CREATE TABLE IF NOT EXISTS `hr_account_locks` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `subdomain` VARCHAR(100) NOT NULL,
  `username` VARCHAR(191) NOT NULL,
  `fail_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `locked_until` DATETIME NULL,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_acct_lock` (`subdomain`, `username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
SQL);
        } catch (Throwable $e) {
            report($e);
        }
    }

    public function clientIp(?string $fallback = null): string
    {
        $ip = request()->ip() ?: ($fallback ?: '0.0.0.0');

        return substr($ip, 0, 64);
    }

    /** @return array{blocked:bool,retry_after?:int,message?:string,captcha_required?:bool} */
    public function precheck(string $ip, string $subdomain, string $username): array
    {
        $this->ensureTables();

        $ipBlock = $this->activeIpBlock($ip);
        if ($ipBlock) {
            $retry = max(1, $ipBlock->getTimestamp() - time());

            return [
                'blocked' => true,
                'retry_after' => $retry,
                'message' => 'This network address is temporarily blocked due to suspicious login activity. Try again in '.$this->humanMinutes($retry).'.',
                'captcha_required' => true,
                'code' => 'ip_blocked',
            ];
        }

        $acct = $this->accountLockRow($subdomain, $username);
        if ($acct && !empty($acct->locked_until)) {
            $until = strtotime((string) $acct->locked_until);
            if ($until > time()) {
                $retry = max(1, $until - time());

                return [
                    'blocked' => true,
                    'retry_after' => $retry,
                    'message' => 'Too many failed attempts for this account. Locked for '.$this->humanMinutes($retry).'.',
                    'captcha_required' => true,
                    'code' => 'account_locked',
                ];
            }
        }

        $ipFails = $this->recentFailCount(ip: $ip);
        $acctFails = $this->recentFailCount(subdomain: $subdomain, username: $username);
        $fails = max($ipFails, $acctFails);
        $captchaRequired = $fails >= self::CAPTCHA_AFTER_FAILS;

        if ($fails >= 1) {
            $delay = $this->progressiveDelaySeconds($fails);
            $last = $this->lastFailAt($ip, $subdomain, $username);
            if ($last !== null) {
                $elapsed = time() - $last;
                if ($elapsed < $delay) {
                    $retry = $delay - $elapsed;

                    return [
                        'blocked' => true,
                        'retry_after' => $retry,
                        'message' => 'Please wait '.$retry.' second'.($retry === 1 ? '' : 's').' before trying again.',
                        'captcha_required' => $captchaRequired,
                        'code' => 'rate_limited',
                    ];
                }
            }
        }

        return [
            'blocked' => false,
            'captcha_required' => $captchaRequired,
            'retry_after' => 0,
        ];
    }

    public function captchaRequiredFor(string $ip, string $subdomain, string $username): bool
    {
        $this->ensureTables();
        $ipFails = $this->recentFailCount(ip: $ip);
        $acctFails = $this->recentFailCount(subdomain: $subdomain, username: $username);

        return max($ipFails, $acctFails) >= self::CAPTCHA_AFTER_FAILS || $this->activeIpBlock($ip) !== null;
    }

    public function issueCaptcha(): array
    {
        return $this->captcha->issue('login');
    }

    public function verifyCaptcha(?string $token, ?string $answer): bool
    {
        return $this->captcha->check($token, $answer, 'login');
    }

    public function recordSuccess(string $ip, string $subdomain, string $username, ?string $userAgent = null): void
    {
        $this->ensureTables();
        $this->insertAttempt($ip, $subdomain, $username, true, 'ok', false, $userAgent);
        $this->clearAccountFails($subdomain, $username);
    }

    /** Log a blocked attempt without increasing the account fail counter. */
    public function recordBlocked(
        string $ip,
        string $subdomain,
        string $username,
        string $reason,
        ?string $userAgent = null,
    ): void {
        $this->ensureTables();
        $this->insertAttempt($ip, $subdomain, $username, false, $reason, true, $userAgent);
    }

    public function recordFailure(
        string $ip,
        string $subdomain,
        string $username,
        string $reason = 'invalid_credentials',
        ?string $userAgent = null,
    ): array {
        $this->ensureTables();
        $suspicious = $this->isSuspiciousFailure($ip, $subdomain, $username, $reason);
        $this->insertAttempt($ip, $subdomain, $username, false, $reason, $suspicious, $userAgent);

        $acctFails = $this->bumpAccountFail($subdomain, $username);
        $ipFails = $this->recentFailCount(ip: $ip);
        $locked = false;
        $retryAfter = $this->progressiveDelaySeconds(max($acctFails, $ipFails));

        if ($acctFails >= self::FAIL_LOCK_COUNT) {
            $this->lockAccount($subdomain, $username, self::FAIL_LOCK_MINUTES);
            $locked = true;
            $retryAfter = self::FAIL_LOCK_MINUTES * 60;
        }

        if ($ipFails >= self::IP_BLOCK_FAILS || $this->distinctUsernamesFromIp($ip) >= 5) {
            $this->blockIp($ip, 'Repeated failed login attempts', self::IP_BLOCK_MINUTES);
            $retryAfter = max($retryAfter, self::IP_BLOCK_MINUTES * 60);
            $suspicious = true;
        }

        return [
            'retry_after' => $retryAfter,
            'captcha_required' => true,
            'account_locked' => $locked,
            'suspicious' => $suspicious,
            'message' => $locked
                ? 'Too many failed attempts. Account locked for '.self::FAIL_LOCK_MINUTES.' minutes.'
                : 'Invalid credentials.',
        ];
    }

    /** Recent suspicious / failed activity for admins. */
    public function recentActivity(int $limit = 100): array
    {
        $this->ensureTables();
        if (!$this->hasTable('hr_login_attempts')) {
            return [];
        }

        return DB::connection('master')->table('hr_login_attempts')
            ->orderByDesc('id')
            ->limit($limit)
            ->get()
            ->map(fn ($r) => [
                'id' => (int) $r->id,
                'ip' => (string) $r->ip,
                'subdomain' => (string) ($r->subdomain ?? ''),
                'username' => (string) ($r->username ?? ''),
                'success' => (bool) $r->success,
                'reason' => (string) ($r->reason ?? ''),
                'suspicious' => (bool) $r->suspicious,
                'user_agent' => (string) ($r->user_agent ?? ''),
                'created_at' => (string) ($r->created_at ?? ''),
            ])
            ->all();
    }

    public function activeBlocks(): array
    {
        $this->ensureTables();
        if (!$this->hasTable('hr_ip_blocks')) {
            return [];
        }

        return DB::connection('master')->table('hr_ip_blocks')
            ->where('blocked_until', '>', now())
            ->orderByDesc('blocked_until')
            ->get()
            ->map(fn ($r) => [
                'ip' => (string) $r->ip,
                'reason' => (string) $r->reason,
                'blocked_until' => (string) $r->blocked_until,
            ])
            ->all();
    }

    public function unblockIp(string $ip): void
    {
        $this->ensureTables();
        if (!$this->hasTable('hr_ip_blocks')) {
            return;
        }
        DB::connection('master')->table('hr_ip_blocks')->where('ip', $ip)->delete();
    }

    protected function progressiveDelaySeconds(int $fails): int
    {
        // 1st fail: 1s, 2nd: 2s, 3rd: 5s, then grows (cap 60s) until account lock.
        return match (true) {
            $fails <= 1 => 1,
            $fails === 2 => 2,
            $fails === 3 => 5,
            $fails === 4 => 10,
            $fails === 5 => 20,
            default => 60,
        };
    }

    protected function humanMinutes(int $seconds): string
    {
        $m = (int) ceil($seconds / 60);

        return $m.' minute'.($m === 1 ? '' : 's');
    }

    protected function hasTable(string $table): bool
    {
        try {
            return Schema::connection('master')->hasTable($table);
        } catch (Throwable $e) {
            return false;
        }
    }

    protected function windowStart()
    {
        return now()->subMinutes(self::WINDOW_MINUTES);
    }

    protected function activeIpBlock(string $ip): ?\DateTimeInterface
    {
        if (!$this->hasTable('hr_ip_blocks')) {
            return null;
        }
        $row = DB::connection('master')->table('hr_ip_blocks')
            ->where('ip', $ip)
            ->where('blocked_until', '>', now())
            ->first();
        if (!$row) {
            return null;
        }

        return new \DateTimeImmutable((string) $row->blocked_until);
    }

    protected function accountLockRow(string $subdomain, string $username): ?object
    {
        if (!$this->hasTable('hr_account_locks')) {
            return null;
        }

        return DB::connection('master')->table('hr_account_locks')
            ->where('subdomain', strtolower($subdomain))
            ->where('username', strtolower($username))
            ->first();
    }

    protected function recentFailCount(?string $ip = null, ?string $subdomain = null, ?string $username = null): int
    {
        if (!$this->hasTable('hr_login_attempts')) {
            return 0;
        }
        $q = DB::connection('master')->table('hr_login_attempts')
            ->where('success', 0)
            ->where('created_at', '>=', $this->windowStart());
        if ($ip !== null) {
            $q->where('ip', $ip);
        }
        if ($subdomain !== null) {
            $q->where('subdomain', strtolower($subdomain));
        }
        if ($username !== null) {
            $q->where('username', strtolower($username));
        }

        return (int) $q->count();
    }

    protected function lastFailAt(string $ip, string $subdomain, string $username): ?int
    {
        if (!$this->hasTable('hr_login_attempts')) {
            return null;
        }
        $row = DB::connection('master')->table('hr_login_attempts')
            ->where('success', 0)
            ->where(function ($q) use ($ip, $subdomain, $username) {
                $q->where('ip', $ip)
                    ->orWhere(function ($q2) use ($subdomain, $username) {
                        $q2->where('subdomain', strtolower($subdomain))
                            ->where('username', strtolower($username));
                    });
            })
            ->orderByDesc('id')
            ->first();
        if (!$row || empty($row->created_at)) {
            return null;
        }

        return strtotime((string) $row->created_at) ?: null;
    }

    protected function insertAttempt(
        string $ip,
        string $subdomain,
        string $username,
        bool $success,
        string $reason,
        bool $suspicious,
        ?string $userAgent,
    ): void {
        if (!$this->hasTable('hr_login_attempts')) {
            return;
        }
        DB::connection('master')->table('hr_login_attempts')->insert([
            'ip' => $ip,
            'subdomain' => strtolower(substr($subdomain, 0, 100)),
            'username' => strtolower(substr($username, 0, 191)),
            'success' => $success ? 1 : 0,
            'reason' => substr($reason, 0, 80),
            'suspicious' => $suspicious ? 1 : 0,
            'user_agent' => substr((string) $userAgent, 0, 255),
            'created_at' => now(),
        ]);
    }

    protected function bumpAccountFail(string $subdomain, string $username): int
    {
        if (!$this->hasTable('hr_account_locks')) {
            return $this->recentFailCount(subdomain: $subdomain, username: $username);
        }
        $sub = strtolower($subdomain);
        $user = strtolower($username);
        $row = $this->accountLockRow($sub, $user);
        if (!$row) {
            DB::connection('master')->table('hr_account_locks')->insert([
                'subdomain' => $sub,
                'username' => $user,
                'fail_count' => 1,
                'locked_until' => null,
                'updated_at' => now(),
            ]);

            return 1;
        }
        $count = (int) $row->fail_count + 1;
        // Reset window if last lock expired long ago
        if (!empty($row->locked_until) && strtotime((string) $row->locked_until) < time() - 60) {
            $count = 1;
        }
        DB::connection('master')->table('hr_account_locks')
            ->where('id', $row->id)
            ->update(['fail_count' => $count, 'updated_at' => now()]);

        return $count;
    }

    protected function lockAccount(string $subdomain, string $username, int $minutes): void
    {
        if (!$this->hasTable('hr_account_locks')) {
            return;
        }
        $sub = strtolower($subdomain);
        $user = strtolower($username);
        DB::connection('master')->table('hr_account_locks')->updateOrInsert(
            ['subdomain' => $sub, 'username' => $user],
            [
                'fail_count' => self::FAIL_LOCK_COUNT,
                'locked_until' => now()->addMinutes($minutes),
                'updated_at' => now(),
            ],
        );
    }

    protected function clearAccountFails(string $subdomain, string $username): void
    {
        if (!$this->hasTable('hr_account_locks')) {
            return;
        }
        DB::connection('master')->table('hr_account_locks')
            ->where('subdomain', strtolower($subdomain))
            ->where('username', strtolower($username))
            ->delete();
    }

    protected function blockIp(string $ip, string $reason, int $minutes): void
    {
        if (!$this->hasTable('hr_ip_blocks')) {
            return;
        }
        DB::connection('master')->table('hr_ip_blocks')->updateOrInsert(
            ['ip' => $ip],
            [
                'reason' => substr($reason, 0, 191),
                'blocked_until' => now()->addMinutes($minutes),
                'created_at' => now(),
            ],
        );
    }

    protected function distinctUsernamesFromIp(string $ip): int
    {
        if (!$this->hasTable('hr_login_attempts')) {
            return 0;
        }

        return (int) DB::connection('master')->table('hr_login_attempts')
            ->where('ip', $ip)
            ->where('success', 0)
            ->where('created_at', '>=', $this->windowStart())
            ->distinct()
            ->count('username');
    }

    protected function isSuspiciousFailure(string $ip, string $subdomain, string $username, string $reason): bool
    {
        if (in_array($reason, ['ip_blocked', 'account_locked', 'rate_limited'], true)) {
            return true;
        }
        if ($this->distinctUsernamesFromIp($ip) >= 3) {
            return true;
        }
        if ($this->recentFailCount(ip: $ip) >= 5) {
            return true;
        }

        return false;
    }
}
