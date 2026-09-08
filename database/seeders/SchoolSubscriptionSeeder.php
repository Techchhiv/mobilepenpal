<?php

namespace Database\Seeders;

use App\Models\Invoice;
use App\Models\Payment;
use App\Models\School;
use App\Models\Subscription;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Spatie\Permission\Models\Role;

class SchoolSubscriptionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * Seeds sample schools, school-admin users, subscriptions, invoices, and payments
     * covering all subscription reminder tiers:
     * 1. ITC (SCH-QI8AJ1) -> Warning Tier (~24 days remaining)
     * 2. Sisowath High School (SCH-SISOWATH) -> Critical Tier (~5 days remaining)
     * 3. Western International School (SCH-WESTERN) -> Expired Tier (expired 12 days ago, 0 days left)
     * 4. Hope Community School (SCH-HOPE) -> Normal Tier (~123 days remaining)
     * 5. Bright Future School (SCH-BRIGHT) -> None Tier (no subscriptions)
     */
    public function run(): void
    {
        $today = Carbon::today();

        // Ensure school-admin role exists for 'api' and 'web' guards
        Role::firstOrCreate(['name' => 'school-admin', 'guard_name' => 'api']);
        Role::firstOrCreate(['name' => 'school-admin', 'guard_name' => 'web']);

        $schoolsData = [
            // ── 1. ITC (Warning Tier: ~24 days left) ──────────────────────────
            [
                'school' => [
                    'name' => 'ITC',
                    'slug' => 'itc',
                    'school_key' => 'SCH-QI8AJ1',
                    'admin_email' => 'itc@gmail.com',
                    'is_active' => true,
                ],
                'admin' => [
                    'name' => 'ITC Admin',
                    'email' => 'itc@gmail.com',
                    'password' => 'password123',
                ],
                'subscriptions' => [
                    [
                        'idempotency_key' => 'SEED-SUB-ITC-PAST',
                        'plan' => 'yearly',
                        'amount' => 1200.00,
                        'start_date' => $today->copy()->subYears(2)->addDays(24)->toDateString(),
                        'end_date' => $today->copy()->subYear()->addDays(23)->toDateString(),
                        'active' => false,
                        'invoice' => [
                            'invoice_number' => 'INV-2025-0012',
                            'description' => 'ITC Yearly Subscription (2024-2025)',
                            'subtotal' => 1200.00,
                            'tax' => 0.00,
                            'total' => 1200.00,
                            'status' => 'paid',
                            'issued_at' => $today->copy()->subYears(2)->addDays(24)->setTime(9, 0),
                            'paid_at' => $today->copy()->subYears(2)->addDays(25)->setTime(10, 30),
                            'payment' => [
                                'amount' => 1200.00,
                                'payment_method' => 'bank_transfer',
                                'payment_reference' => 'FT-20250101-9988',
                                'status' => 'completed',
                            ],
                        ],
                    ],
                    [
                        'idempotency_key' => 'SEED-SUB-ITC-CURRENT',
                        'plan' => 'yearly',
                        'amount' => 1200.00,
                        'start_date' => $today->copy()->subYear()->addDays(24)->toDateString(),
                        'end_date' => $today->copy()->addDays(24)->toDateString(),
                        'active' => true,
                        'invoice' => [
                            'invoice_number' => 'INV-2026-0038',
                            'description' => 'ITC Yearly Subscription (2025-2026)',
                            'subtotal' => 1200.00,
                            'tax' => 0.00,
                            'total' => 1200.00,
                            'status' => 'paid',
                            'issued_at' => $today->copy()->subYear()->addDays(24)->setTime(9, 0),
                            'paid_at' => $today->copy()->subYear()->addDays(25)->setTime(14, 15),
                            'payment' => [
                                'amount' => 1200.00,
                                'payment_method' => 'aba',
                                'payment_reference' => 'ABA-KHQR-2025-4421',
                                'status' => 'completed',
                            ],
                        ],
                    ],
                ],
            ],

            // ── 2. Sisowath High School (Critical Tier: ~5 days left) ─────────
            [
                'school' => [
                    'name' => 'Sisowath High School',
                    'slug' => 'sisowath-high-school',
                    'school_key' => 'SCH-SISOWATH',
                    'admin_email' => 'sisowath@school.com',
                    'is_active' => true,
                ],
                'admin' => [
                    'name' => 'Sisowath Admin',
                    'email' => 'sisowath@school.com',
                    'password' => 'password123',
                ],
                'subscriptions' => [
                    [
                        'idempotency_key' => 'SEED-SUB-SISOWATH-CURRENT',
                        'plan' => 'monthly',
                        'amount' => 150.00,
                        'start_date' => $today->copy()->subMonth()->addDays(5)->toDateString(),
                        'end_date' => $today->copy()->addDays(5)->toDateString(),
                        'active' => true,
                        'invoice' => [
                            'invoice_number' => 'INV-2026-0091',
                            'description' => 'Sisowath Monthly Subscription',
                            'subtotal' => 150.00,
                            'tax' => 0.00,
                            'total' => 150.00,
                            'status' => 'paid',
                            'issued_at' => $today->copy()->subMonth()->addDays(5)->setTime(8, 30),
                            'paid_at' => $today->copy()->subMonth()->addDays(5)->setTime(9, 10),
                            'payment' => [
                                'amount' => 150.00,
                                'payment_method' => 'aba',
                                'payment_reference' => 'ABA-KHQR-2026-8871',
                                'status' => 'completed',
                            ],
                        ],
                    ],
                ],
            ],

            // ── 3. Western International School (Expired Tier: ended 12 days ago) ─
            [
                'school' => [
                    'name' => 'Western International School',
                    'slug' => 'western-international-school',
                    'school_key' => 'SCH-WESTERN',
                    'admin_email' => 'western@school.com',
                    'is_active' => true,
                ],
                'admin' => [
                    'name' => 'Western Admin',
                    'email' => 'western@school.com',
                    'password' => 'password123',
                ],
                'subscriptions' => [
                    [
                        'idempotency_key' => 'SEED-SUB-WESTERN-EXPIRED',
                        'plan' => 'yearly',
                        'amount' => 1500.00,
                        'start_date' => $today->copy()->subYear()->subDays(12)->toDateString(),
                        'end_date' => $today->copy()->subDays(12)->toDateString(),
                        'active' => false,
                        'invoice' => [
                            'invoice_number' => 'INV-2025-0044',
                            'description' => 'Western International School Yearly Plan',
                            'subtotal' => 1500.00,
                            'tax' => 0.00,
                            'total' => 1500.00,
                            'status' => 'paid',
                            'issued_at' => $today->copy()->subYear()->subDays(12)->setTime(10, 0),
                            'paid_at' => $today->copy()->subYear()->subDays(11)->setTime(11, 45),
                            'payment' => [
                                'amount' => 1500.00,
                                'payment_method' => 'bank_transfer',
                                'payment_reference' => 'FT-2025-08-1122',
                                'status' => 'completed',
                            ],
                        ],
                    ],
                ],
            ],

            // ── 4. Hope Community School (Normal Tier: ~123 days left) ─────────
            [
                'school' => [
                    'name' => 'Hope Community School',
                    'slug' => 'hope-community-school',
                    'school_key' => 'SCH-HOPE',
                    'admin_email' => 'hope@school.com',
                    'is_active' => true,
                ],
                'admin' => [
                    'name' => 'Hope Admin',
                    'email' => 'hope@school.com',
                    'password' => 'password123',
                ],
                'subscriptions' => [
                    [
                        'idempotency_key' => 'SEED-SUB-HOPE-CURRENT',
                        'plan' => 'yearly',
                        'amount' => 1200.00,
                        'start_date' => $today->copy()->subDays(242)->toDateString(),
                        'end_date' => $today->copy()->addDays(123)->toDateString(),
                        'active' => true,
                        'invoice' => [
                            'invoice_number' => 'INV-2026-0005',
                            'description' => 'Hope Community School Annual Plan',
                            'subtotal' => 1200.00,
                            'tax' => 0.00,
                            'total' => 1200.00,
                            'status' => 'paid',
                            'issued_at' => $today->copy()->subDays(242)->setTime(8, 0),
                            'paid_at' => $today->copy()->subDays(242)->setTime(8, 30),
                            'payment' => [
                                'amount' => 1200.00,
                                'payment_method' => 'cash',
                                'payment_reference' => 'CASH-REC-0051',
                                'status' => 'completed',
                            ],
                        ],
                    ],
                ],
            ],

            // ── 5. Bright Future School (None Tier: no subscriptions) ─────────
            [
                'school' => [
                    'name' => 'Bright Future School',
                    'slug' => 'bright-future-school',
                    'school_key' => 'SCH-BRIGHT',
                    'admin_email' => 'bright@school.com',
                    'is_active' => true,
                ],
                'admin' => [
                    'name' => 'Bright Admin',
                    'email' => 'bright@school.com',
                    'password' => 'password123',
                ],
                'subscriptions' => [],
            ],
        ];

        foreach ($schoolsData as $item) {
            $school = School::updateOrCreate(
                ['school_key' => $item['school']['school_key']],
                $item['school']
            );

            $user = User::updateOrCreate(
                ['email' => $item['admin']['email']],
                [
                    'name' => $item['admin']['name'],
                    'password' => Hash::make($item['admin']['password']),
                    'school_id' => $school->id,
                    'email_verified_at' => now(),
                ]
            );

            if (method_exists($user, 'assignRole')) {
                try {
                    $user->assignRole('school-admin');
                } catch (\Throwable $e) {
                    // Role assignment fallback
                }
            }

            $seededSubIds = [];
            foreach ($item['subscriptions'] as $subData) {
                // 1. Search by unique idempotency_key
                $sub = null;
                if (!empty($subData['idempotency_key'])) {
                    $sub = Subscription::where('idempotency_key', $subData['idempotency_key'])->first();
                }

                // 2. Fallback: match by school_id, plan, and active state to adopt unkeyed rows
                if (!$sub) {
                    $sub = Subscription::where('school_id', $school->id)
                        ->where('plan', $subData['plan'])
                        ->where('active', $subData['active'])
                        ->first();
                }

                if (!$sub) {
                    $sub = new Subscription();
                }

                $sub->fill([
                    'school_id' => $school->id,
                    'student_id' => null,
                    'plan' => $subData['plan'],
                    'amount' => $subData['amount'],
                    'start_date' => $subData['start_date'],
                    'end_date' => $subData['end_date'],
                    'active' => $subData['active'],
                    'idempotency_key' => $subData['idempotency_key'] ?? null,
                ]);
                $sub->save();
                $seededSubIds[] = $sub->id;

                if (isset($subData['invoice'])) {
                    $invData = $subData['invoice'];
                    $invoice = Invoice::updateOrCreate(
                        ['invoice_number' => $invData['invoice_number']],
                        [
                            'subscription_id' => $sub->id,
                            'customer_type' => 'school',
                            'school_id' => $school->id,
                            'customer_name' => $school->name,
                            'customer_email' => $school->admin_email,
                            'description' => $invData['description'],
                            'plan' => $subData['plan'],
                            'billing_period_start' => $subData['start_date'],
                            'billing_period_end' => $subData['end_date'],
                            'subtotal' => $invData['subtotal'],
                            'discount' => 0.00,
                            'tax' => $invData['tax'],
                            'total' => $invData['total'],
                            'currency' => 'USD',
                            'status' => $invData['status'],
                            'issued_at' => $invData['issued_at'],
                            'paid_at' => $invData['paid_at'],
                            'created_by' => $user->id,
                            'idempotency_key' => 'SEED-INV-' . $invData['invoice_number'],
                        ]
                    );

                    if (isset($invData['payment'])) {
                        $payData = $invData['payment'];
                        Payment::updateOrCreate(
                            ['invoice_id' => $invoice->id],
                            [
                                'amount' => $payData['amount'],
                                'currency' => 'USD',
                                'payment_method' => $payData['payment_method'],
                                'payment_reference' => $payData['payment_reference'],
                                'status' => $payData['status'],
                                'paid_at' => $invData['paid_at'],
                                'recorded_by' => $user->id,
                            ]
                        );
                    }
                }
            }

            // Clean up any extra duplicate subscriptions for this school so it never accumulates duplicates
            Subscription::where('school_id', $school->id)
                ->whereNotIn('id', $seededSubIds)
                ->delete();
        }

        $this->command->info('✅ SchoolSubscriptionSeeder completed successfully with sample schools, subscriptions, and invoices.');
    }
}

