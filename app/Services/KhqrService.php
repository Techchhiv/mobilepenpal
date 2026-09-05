<?php

namespace App\Services;

class KhqrService
{
    /**
     * Format a Tag-Length-Value (TLV) string according to EMVCo standard.
     */
    public static function formatTlv(string $tag, string $value): string
    {
        $tagFormatted = str_pad($tag, 2, '0', STR_PAD_LEFT);
        $lenFormatted = str_pad((string) strlen($value), 2, '0', STR_PAD_LEFT);
        return $tagFormatted . $lenFormatted . $value;
    }

    /**
     * Compute CRC-16/CCITT-FALSE checksum for EMVCo QR string.
     * Polynomial: 0x1021, Initial: 0xFFFF, RefIn: False, RefOut: False, XorOut: 0x0000
     */
    public static function computeCrc16(string $data): string
    {
        $crc = 0xFFFF;
        $polynomial = 0x1021;
        $length = strlen($data);

        for ($i = 0; $i < $length; $i++) {
            $crc ^= (ord($data[$i]) << 8);
            for ($j = 0; $j < 8; $j++) {
                if (($crc & 0x8000) !== 0) {
                    $crc = (($crc << 1) ^ $polynomial) & 0xFFFF;
                } else {
                    $crc = ($crc << 1) & 0xFFFF;
                }
            }
        }

        return strtoupper(str_pad(dechex($crc), 4, '0', STR_PAD_LEFT));
    }

    /**
     * Generate standard EMVCo KHQR string for Individual Bakong Account.
     *
     * @param string $accountId Bakong Account ID (e.g. 'your_account@abab' or 'your_account@aclb')
     * @param float $amount Amount to pay (e.g. 0.10 or 2.50)
     * @param string $currency Currency code 'USD' or 'KHR'
     * @param string $merchantName Receiver / Merchant name (e.g. 'Khmer PenPal')
     * @param string $merchantCity Receiver city (e.g. 'Phnom Penh')
     * @param string|null $billNumber Unique bill reference
     * @param string|null $mobileNumber Optional payer/payee mobile number
     * @param int $expirationSeconds Expiration duration in seconds (default 600 = 10 mins)
     * @return array ['qr_string' => string, 'md5' => string, 'amount' => float, 'currency' => string]
     */
    public function generateIndividualKhqr(
        string $accountId,
        float $amount,
        string $currency = 'USD',
        string $merchantName = 'Khmer PenPal',
        string $merchantCity = 'Phnom Penh',
        ?string $billNumber = null,
        ?string $mobileNumber = null,
        int $expirationSeconds = 600,
    ): array {
        $currencyUpper = strtoupper($currency);
        $currencyCode = $currencyUpper === 'KHR' ? '116' : '840';

        $isDynamic = $amount > 0;

        // Format amount: 2 decimal places for USD, whole integer for KHR
        $formattedAmount = $currencyUpper === 'KHR'
            ? (string) round($amount)
            : number_format($amount, 2, '.', '');

        // Tag 00: Payload Format Indicator ("01")
        $payload = self::formatTlv('00', '01');

        // Tag 01: Point of Initiation Method ("12" = Dynamic QR, "11" = Static)
        $payload .= self::formatTlv('01', $isDynamic ? '12' : '11');

        // Tag 29: Merchant Account Information for Individual Account
        // Subtag 00: Bakong Account Identifier (e.g. 'name@abab')
        $tag29Value = self::formatTlv('00', trim($accountId));
        $payload .= self::formatTlv('29', $tag29Value);

        // Tag 52: Merchant Category Code ("5999" = Miscellaneous / General)
        $payload .= self::formatTlv('52', '5999');

        // Tag 53: Transaction Currency (840 = USD, 116 = KHR)
        $payload .= self::formatTlv('53', $currencyCode);

        // Tag 54: Transaction Amount (Required for dynamic QR)
        if ($isDynamic) {
            $payload .= self::formatTlv('54', $formattedAmount);
        }

        // Tag 58: Country Code ("KH")
        $payload .= self::formatTlv('58', 'KH');

        // Tag 59: Merchant / Payee Name (max 25 chars)
        $cleanName = substr(preg_replace('/[^A-Za-z0-9 _.-]/', '', $merchantName), 0, 25);
        if (empty($cleanName)) {
            $cleanName = 'Khmer PenPal';
        }
        $payload .= self::formatTlv('59', $cleanName);

        // Tag 60: Merchant City (max 15 chars)
        $cleanCity = substr(preg_replace('/[^A-Za-z0-9 ]/', '', $merchantCity), 0, 15);
        if (empty($cleanCity)) {
            $cleanCity = 'Phnom Penh';
        }
        $payload .= self::formatTlv('60', $cleanCity);

        // Tag 62: Additional Data Field Template
        $tag62Value = '';
        if ($billNumber) {
            $cleanBill = substr(preg_replace('/[^A-Za-z0-9_-]/', '', $billNumber), 0, 25);
            $tag62Value .= self::formatTlv('01', $cleanBill);
        }
        if ($mobileNumber) {
            $cleanMobile = substr(preg_replace('/[^0-9+]/', '', $mobileNumber), 0, 25);
            $tag62Value .= self::formatTlv('02', $cleanMobile);
        }
        if (! empty($tag62Value)) {
            $payload .= self::formatTlv('62', $tag62Value);
        }

        // Tag 99: Timestamp for Dynamic QR (Required by NBC Bakong standard for Dynamic KHQR)
        if ($isDynamic) {
            $nowMs = (string) round(microtime(true) * 1000);
            $expMs = (string) (round(microtime(true) * 1000) + ($expirationSeconds * 1000));
            $tag99Value = self::formatTlv('00', $nowMs) . self::formatTlv('01', $expMs);
            $payload .= self::formatTlv('99', $tag99Value);
        }

        // Tag 63: CRC-16 (Prefix "6304")
        $payloadForCrc = $payload . '6304';
        $crc = self::computeCrc16($payloadForCrc);
        $fullQrString = $payloadForCrc . $crc;

        // Bakong transaction tracking uses MD5 of the raw KHQR string
        $md5 = md5($fullQrString);

        return [
            'qr_string' => $fullQrString,
            'md5'       => $md5,
            'amount'    => (float) $formattedAmount,
            'currency'  => $currencyUpper,
        ];
    }
}
