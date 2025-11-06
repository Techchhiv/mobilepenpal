<?php

namespace App\Helpers;

class ChangePhoneNumberFormat
{
    private const COUNTRY_CODE = '+855';

    public static function toLocalKhmerFormat(string $phone): string
    {
        $phone = preg_replace('/[^\d+]/', '', $phone);

        if (strpos($phone, self::COUNTRY_CODE) === 0) {
            $phone = '0' . substr($phone, strlen(self::COUNTRY_CODE));
        }

        if (strpos($phone, '855') === 0 && strlen($phone) > 9) {
            $phone = '0' . substr($phone, 3);
        }

        return $phone;
    }

    public static function toE164GlobalFormat(string $phone): string
    {
        $phone = preg_replace('/[^\d+]/', '', $phone);

        if (strpos($phone, '+') === 0) {
            return $phone;
        }

        if (strpos($phone, '0') === 0) {
            $phone = substr($phone, 1);
        }

        return self::COUNTRY_CODE . $phone;
    }
}
