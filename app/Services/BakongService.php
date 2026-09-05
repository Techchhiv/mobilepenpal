<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

class BakongService
{
    protected string $apiUrl;
    protected ?string $apiToken;
    protected string $accountId;
    protected bool $simulationMode;

    public function __construct()
    {
        $this->apiUrl = rtrim(config('bakong.api_url', 'https://sit-api-bakong.nbc.org.kh/v1'), '/');
        $this->apiToken = config('bakong.api_token');
        $this->accountId = config('bakong.account_id', 'khmerpenpal@aclb');
        $this->simulationMode = (bool) config('bakong.simulation_mode', false);
    }

    /**
     * Check transaction status on the NBC Bakong network by MD5 hash.
     *
     * @param string $md5 32-character lowercase MD5 hash of the generated KHQR
     * @param bool $allowSimulation If true and simulationMode is active, simulate payment success
     * @return array
     */
    public function checkTransactionByMd5(string $md5, bool $allowSimulation = false): array
    {
        // Development / Testing simulation mode (when enabled or in test environment)
        if (($this->simulationMode && ($allowSimulation || empty($this->apiToken))) || (app()->environment('testing') && $allowSimulation)) {
            Log::info("Bakong: Simulating transaction verification for MD5: {$md5}");
            return [
                'status'       => 'success',
                'simulated'    => true,
                'hash'         => 'sim_' . substr(md5($md5 . time()), 0, 32),
                'from_account' => 'student_tester@aclb',
                'to_account'   => $this->accountId,
                'amount'       => null, // Will match expected checkout amount
                'currency'     => 'USD',
                'message'      => 'Transaction verified successfully (Simulation Mode)',
            ];
        }

        if (empty($this->apiToken)) {
            Log::warning("Bakong: API token not configured. Unable to check live transaction for MD5: {$md5}");
            return [
                'status'  => 'pending',
                'message' => 'Bakong API token not configured. Please set BAKONG_API_TOKEN or enable BAKONG_SIMULATION_MODE.',
            ];
        }

        $url = "{$this->apiUrl}/check_transaction_by_md5";

        try {
            $response = Http::withToken($this->apiToken)
                ->timeout(10)
                ->when(app()->isLocal(), fn($client) => $client->withoutVerifying())
                ->post($url, [
                    'md5' => $md5,
                ]);

            if ($response->successful()) {
                $json = $response->json();
                $responseCode = $json['responseCode'] ?? null;

                // NBC Bakong responseCode 0 indicates payment success
                if ($responseCode === 0) {
                    $data = $json['data'] ?? [];
                    return [
                        'status'       => 'success',
                        'simulated'    => false,
                        'hash'         => $data['hash'] ?? null,
                        'from_account' => $data['fromAccountId'] ?? null,
                        'to_account'   => $data['toAccountId'] ?? null,
                        'amount'       => isset($data['amount']) ? (float) $data['amount'] : null,
                        'currency'     => $data['currency'] ?? 'USD',
                        'raw'          => $json,
                        'message'      => 'Transaction verified on Bakong network',
                    ];
                }

                // responseCode 1 or other usually means not yet received / pending
                return [
                    'status'  => 'pending',
                    'message' => $json['responseMessage'] ?? 'Payment pending',
                    'raw'     => $json,
                ];
            }

            Log::warning("Bakong API request returned HTTP {$response->status()}", [
                'body' => $response->body(),
                'md5'  => $md5,
            ]);

            return [
                'status'  => 'pending',
                'message' => 'Pending confirmation from Bakong',
            ];
        } catch (Throwable $e) {
            Log::error('Bakong API Exception: ' . $e->getMessage(), [
                'md5' => $md5,
            ]);

            return [
                'status'  => 'pending',
                'error'   => $e->getMessage(),
                'message' => 'Network error checking payment status',
            ];
        }
    }

    public function getAccountId(): string
    {
        return $this->accountId;
    }

    public function isSimulationMode(): bool
    {
        return $this->simulationMode;
    }
}
