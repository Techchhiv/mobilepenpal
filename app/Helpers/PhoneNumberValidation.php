<?php

namespace App\Helpers;

use libphonenumber\PhoneNumberUtil;
use libphonenumber\NumberParseException;

function isValidPhone(string $phone): bool
{
    $phoneUtil = PhoneNumberUtil::getInstance();

    try {
        $numberProto = $phoneUtil->parse($phone, 'KH');
        return $phoneUtil->isValidNumber($numberProto);
    } catch (NumberParseException $e) {
        return false;
    }
}

function isKhmerPhone(string $phone): bool
{
    return isValidPhone($phone);
}
