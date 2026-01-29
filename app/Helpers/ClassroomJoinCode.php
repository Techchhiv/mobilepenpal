<?php

namespace App\Helpers;

use Illuminate\Support\Carbon;

class ClassroomJoinCode
{
    private const ALPHABET = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
    private const EXP_BITS = 20;
    private const RAND_BITS = 30;

    public static function generate(int $schoolId, int $ttlDays = 7): string
    {
        $prefix = self::prefix($schoolId, 3);

        $expiresAt = now()->addDays($ttlDays);
        $expiresBucket = intdiv($expiresAt->getTimestamp(), 60); // minutes since epoch
        $expMask = self::maskBits($schoolId, self::EXP_BITS);

        $expBits = $expiresBucket & ((1 << self::EXP_BITS) - 1);
        $maskedExp = $expBits ^ $expMask;

        $rand = random_int(0, (1 << self::RAND_BITS) - 1);

        $payload = ($maskedExp << self::RAND_BITS) | $rand;

        $token10 = self::b32EncodeFixed($payload, 10);
        $check1  = self::checksumChar($schoolId, $prefix, $token10);

        return "{$prefix}-{$token10}{$check1}";
    }

    public static function validate(string $joinCode, int $schoolId): ?array
    {
        $code = strtoupper(trim($joinCode));

        $re = '/^[' . preg_quote(self::ALPHABET, '/') . ']{3}-[' . preg_quote(self::ALPHABET, '/') . ']{11}$/';
        if (!preg_match($re, $code)) {
            return null;
        }

        [$prefix, $rest] = explode('-', $code, 2);
        $token10 = substr($rest, 0, 10);
        $check1  = substr($rest, 10, 1);

        $expected = self::checksumChar($schoolId, $prefix, $token10);
        if ($check1 !== $expected) {
            return [
                'ok' => false,
                'expired' => false,
                'expires_at' => null,
                'reason' => 'Invalid code (checksum mismatch).',
            ];
        }

        $payload = self::b32Decode($token10);
        if ($payload === null) {
            return [
                'ok' => false,
                'expired' => false,
                'expires_at' => null,
                'reason' => 'Invalid code (decode failed).',
            ];
        }

        $maskedExp = $payload >> self::RAND_BITS;

        $expMask = self::maskBits($schoolId, self::EXP_BITS);
        $expBits = $maskedExp ^ $expMask;

        $nowBucket = intdiv(time(), 60);
        $wrap = 1 << self::EXP_BITS;
        $half = 1 << (self::EXP_BITS - 1);

        $base = $nowBucket & ~($wrap - 1);
        $candidate = $base | $expBits;

        if ($candidate < $nowBucket - $half) $candidate += $wrap;
        if ($candidate > $nowBucket + $half) $candidate -= $wrap;

        $expiresTs = ($candidate * 60) + 59;
        $expiresAt = Carbon::createFromTimestamp($expiresTs);

        $expired = now()->gt($expiresAt);

        return [
            'ok' => true,
            'expired' => $expired,
            'expires_at' => $expiresAt,
            'reason' => $expired ? 'Join code expired.' : null,
        ];
    }

    private static function prefix(int $schoolId, int $len = 3): string
    {
        $bin = hash_hmac('sha256', 'join-prefix|' . $schoolId, self::appKeyBytes(), true);
        $n = unpack('n', substr($bin, 0, 2))[1]; // 16-bit
        $n = $n & ((1 << ($len * 5)) - 1);

        return self::b32EncodeFixed($n, $len);
    }

    private static function maskBits(int $schoolId, int $bits): int
    {
        $bin = hash_hmac('sha256', 'join-mask|' . $schoolId, self::appKeyBytes(), true);
        $n = unpack('N', substr($bin, 0, 4))[1]; // 32-bit
        return $n & ((1 << $bits) - 1);
    }

    private static function checksumChar(int $schoolId, string $prefix, string $token10): string
    {
        $bin = hash_hmac('sha256', 'join-chk|' . $schoolId . '|' . $prefix . '|' . $token10, self::appKeyBytes(), true);
        $idx = ord($bin[0]) & 31;
        return self::ALPHABET[$idx];
    }

    private static function b32EncodeFixed(int $value, int $len): string
    {
        $out = '';
        for ($i = 0; $i < $len; $i++) {
            $idx = $value & 31;
            $out = self::ALPHABET[$idx] . $out;
            $value >>= 5;
        }
        return $out;
    }

    private static function b32Decode(string $str): ?int
    {
        static $map = null;
        if ($map === null) {
            $map = [];
            $alphabet = self::ALPHABET;
            for ($i = 0; $i < strlen($alphabet); $i++) {
                $map[$alphabet[$i]] = $i;
            }
        }

        $val = 0;
        $str = strtoupper($str);

        for ($i = 0; $i < strlen($str); $i++) {
            $ch = $str[$i];
            if (!isset($map[$ch])) return null;
            $val = ($val << 5) | $map[$ch];
        }

        return $val;
    }

    private static function appKeyBytes(): string
    {
        $key = (string) config('app.key');
        if (str_starts_with($key, 'base64:')) {
            return base64_decode(substr($key, 7)) ?: $key;
        }
        return $key;
    }
}
