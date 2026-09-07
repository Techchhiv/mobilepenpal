<?php

namespace App\Http\Controllers\Student\V01;

use App\Http\Resources\Student\V01\User\UserDetailResource;
use App\Models\BakongTransaction;
use App\Models\Student;
use App\Services\BakongService;
use App\Services\KhqrService;
use App\Services\SubscriptionBillingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class SubscriptionCheckoutController extends Controller
{
    protected SubscriptionBillingService $billingService;
    protected KhqrService $khqrService;
    protected BakongService $bakongService;

    public function __construct(
        SubscriptionBillingService $billingService,
        KhqrService $khqrService,
        BakongService $bakongService,
    ) {
        parent::__construct();
        $this->billingService = $billingService;
        $this->khqrService = $khqrService;
        $this->bakongService = $bakongService;
    }

    /**
     * Get active subscription pricing breakdown and Bakong payment info.
     */
    public function pricing(): JsonResponse
    {
        /** @var Student|null $student */
        $student = Auth::user();

        $monthly = $this->billingService->getPlanPricingDetails('monthly');
        $yearly = $this->billingService->getPlanPricingDetails('yearly');

        $pendingCheckout = null;
        if ($student) {
            $pendingTx = BakongTransaction::where('student_id', $student->id)
                ->where('status', BakongTransaction::STATUS_PENDING)
                ->where('expires_at', '>', now())
                ->latest()
                ->first();

            if ($pendingTx) {
                $pendingCheckout = [
                    'transaction_id'     => $pendingTx->id,
                    'plan'               => $pendingTx->plan,
                    'amount'             => (float) $pendingTx->amount,
                    'currency'           => $pendingTx->currency,
                    'qr_string'          => $pendingTx->qr_string,
                    'md5'                => $pendingTx->md5,
                    'bill_number'        => sprintf('STU-%d-%s', $student->id, substr($pendingTx->md5, 0, 6)),
                    'merchant_name'      => config('bakong.merchant_name', 'Khmer PenPal'),
                    'account_id'         => config('bakong.account_id'),
                    'expires_at'         => $pendingTx->expires_at->toIso8601String(),
                    'expires_in_seconds' => max(0, now()->diffInSeconds($pendingTx->expires_at, false)),
                    'simulation_mode'    => $this->bakongService->isSimulationMode(),
                ];
            }
        }

        $this->setResult('pricing', [
            'monthly'          => $monthly,
            'yearly'           => $yearly,
            'merchant_name'    => config('bakong.merchant_name', 'Khmer PenPal'),
            'account_id'       => config('bakong.account_id'),
            'currency'         => config('bakong.currency', 'USD'),
            'simulation_mode'  => $this->bakongService->isSimulationMode(),
            'pending_checkout' => $pendingCheckout,
        ]);

        return $this->returnResponse();
    }

    /**
     * Generate dynamic Bakong KHQR checkout for the authenticated student.
     */
    public function checkout(Request $request): JsonResponse
    {
        /** @var Student|null $student */
        $student = Auth::user();

        if (! $student) {
            return $this->returnError(__('messages.user_not_authenticated'), 401);
        }

        $request->validate([
            'plan'      => 'nullable|in:monthly,yearly',
            'force_new' => 'nullable|boolean',
        ]);

        $plan = $request->input('plan', 'monthly');
        $pricing = $this->billingService->getPlanPricingDetails($plan);
        $amount = (float) $pricing['final_price'];
        $currency = $pricing['currency'] ?? 'USD';

        // If student already has an active unexpired pending transaction for this plan with matching amount, reuse it
        $forceNew = $request->boolean('force_new');
        if (! $forceNew) {
            $existingTransaction = BakongTransaction::where('student_id', $student->id)
                ->where('plan', $plan)
                ->where('status', BakongTransaction::STATUS_PENDING)
                ->where('expires_at', '>', now())
                ->latest()
                ->first();

            if ($existingTransaction && (float) $existingTransaction->amount === (float) $amount) {
                $remainingSeconds = max(0, now()->diffInSeconds($existingTransaction->expires_at, false));
                $this->setResult('checkout', [
                    'transaction_id'     => $existingTransaction->id,
                    'plan'               => $existingTransaction->plan,
                    'amount'             => (float) $existingTransaction->amount,
                    'currency'           => $existingTransaction->currency,
                    'qr_string'          => $existingTransaction->qr_string,
                    'md5'                => $existingTransaction->md5,
                    'bill_number'        => sprintf('STU-%d-%s', $student->id, substr($existingTransaction->md5, 0, 6)),
                    'merchant_name'      => config('bakong.merchant_name', 'Khmer PenPal'),
                    'account_id'         => config('bakong.account_id'),
                    'expires_at'         => $existingTransaction->expires_at->toIso8601String(),
                    'expires_in_seconds' => $remainingSeconds,
                    'simulation_mode'    => $this->bakongService->isSimulationMode(),
                ]);

                return $this->returnResponse();
            }
        }

        $billNumber = sprintf('STU-%d-%s', $student->id, strtoupper(substr(uniqid(), -6)));
        $accountId = config('bakong.account_id');
        $merchantName = config('bakong.merchant_name', 'Khmer PenPal');
        $merchantCity = config('bakong.merchant_city', 'Phnom Penh');
        $expirationSeconds = (int) config('bakong.qr_expiration_seconds', 600);

        $khqrData = $this->khqrService->generateIndividualKhqr(
            accountId: $accountId,
            amount: $amount,
            currency: $currency,
            merchantName: $merchantName,
            merchantCity: $merchantCity,
            billNumber: $billNumber,
            mobileNumber: $student->phone ?? null,
            expirationSeconds: $expirationSeconds,
        );

        $transaction = BakongTransaction::create([
            'student_id' => $student->id,
            'plan'       => $plan,
            'amount'     => $amount,
            'currency'   => $currency,
            'qr_string'  => $khqrData['qr_string'],
            'md5'        => $khqrData['md5'],
            'status'     => BakongTransaction::STATUS_PENDING,
            'expires_at' => now()->addSeconds($expirationSeconds),
        ]);

        $this->setResult('checkout', [
            'transaction_id'     => $transaction->id,
            'plan'               => $plan,
            'amount'             => $amount,
            'currency'           => $currency,
            'qr_string'          => $khqrData['qr_string'],
            'md5'                => $khqrData['md5'],
            'bill_number'        => $billNumber,
            'merchant_name'      => $merchantName,
            'account_id'         => $accountId,
            'expires_at'         => $transaction->expires_at->toIso8601String(),
            'expires_in_seconds' => $expirationSeconds,
            'simulation_mode'    => $this->bakongService->isSimulationMode(),
        ]);

        return $this->returnResponse();
    }

    /**
     * Verify payment against the NBC Bakong network and unlock subscription upon confirmation.
     */
    public function verifyPayment(Request $request): JsonResponse
    {
        /** @var Student|null $student */
        $student = Auth::user();

        if (! $student) {
            return $this->returnError(__('messages.user_not_authenticated'), 401);
        }

        $request->validate([
            'md5'      => 'required|string|size:32',
            'simulate' => 'nullable|boolean',
        ]);

        $md5 = strtolower($request->input('md5'));

        $transaction = BakongTransaction::where('md5', $md5)
            ->where('student_id', $student->id)
            ->first();

        if (! $transaction) {
            return $this->returnError('Transaction not found', 404);
        }

        // If already completed, return success immediately
        if ($transaction->status === BakongTransaction::STATUS_COMPLETED) {
            $this->setResult('status', 'success');
            $this->setResult('message', 'Payment verified and subscription is active.');
            $this->setResult('profile', new UserDetailResource($student->fresh()));
            return $this->returnResponse();
        }

        $allowSimulate = $request->boolean('simulate');
        $bakongResult = $this->bakongService->checkTransactionByMd5($md5, $allowSimulate);

        if ($bakongResult['status'] === 'success') {
            try {
                $result = DB::transaction(function () use ($student, $transaction, $bakongResult) {
                    // Lock transaction row to prevent double activation
                    $lockedTx = BakongTransaction::where('id', $transaction->id)
                        ->lockForUpdate()
                        ->first();

                    if ($lockedTx->status === BakongTransaction::STATUS_COMPLETED) {
                        return [
                            'subscription' => $lockedTx->subscription,
                            'invoice'      => $lockedTx->invoice,
                        ];
                    }

                    $activeSub = $student->getActiveSubscription();
                    $billingData = [
                        'plan'              => $lockedTx->plan,
                        'override_price'    => (float) $lockedTx->amount,
                        'can_override'      => true,
                        'payment_method'    => 'bakong',
                        'payment_reference' => $bakongResult['hash'] ?? ('BAKONG-' . strtoupper(substr($lockedTx->md5, 0, 16))),
                        'idempotency_key'   => 'bakong_' . $lockedTx->md5,
                        'notes'             => 'Bakong KHQR payment verified. Payer: ' . ($bakongResult['from_account'] ?? 'Individual Account'),
                    ];

                    // Activate or renew
                    if ($activeSub) {
                        $activationResult = $this->billingService->renewStudent($student, $billingData);
                    } else {
                        $activationResult = $this->billingService->activateStudent($student, $billingData);
                    }

                    $lockedTx->update([
                        'status'          => BakongTransaction::STATUS_COMPLETED,
                        'bakong_hash'     => $bakongResult['hash'] ?? null,
                        'from_account'    => $bakongResult['from_account'] ?? null,
                        'invoice_id'      => $activationResult['invoice']->id ?? null,
                        'subscription_id' => $activationResult['subscription']->id ?? null,
                    ]);

                    return $activationResult;
                });

                $this->setResult('status', 'success');
                $this->setResult('message', 'Payment successful! Subscription unlocked.');
                $this->setResult('profile', new UserDetailResource($student->fresh()));
                $this->setResult('invoice_number', $result['invoice']->invoice_number ?? null);
                return $this->returnResponse();
            } catch (Throwable $e) {
                Log::error('Subscription activation failed after Bakong payment verification: ' . $e->getMessage(), [
                    'md5'        => $md5,
                    'student_id' => $student->id,
                    'exception'  => $e,
                ]);

                return $this->returnError('Failed to activate subscription. Please contact support.', 500);
            }
        }

        // Only mark as expired if payment was not received on Bakong network and time elapsed
        if ($transaction->isExpired()) {
            $transaction->update(['status' => BakongTransaction::STATUS_EXPIRED]);
            return $this->returnError('KHQR payment request has expired. Please generate a new QR.', 400);
        }

        // Still pending
        $this->setResult('status', 'pending');
        $this->setResult('message', $bakongResult['message'] ?? 'Waiting for payment confirmation...');
        return $this->returnResponse();
    }
}
