<?php

namespace Tests\Feature;

use App\Models\Invoice;
use App\Models\School;
use App\Models\Subscription;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class SchoolSubscriptionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // Ensure school-admin role exists
        Role::firstOrCreate(['name' => 'school-admin', 'guard_name' => 'web']);
        Role::firstOrCreate(['name' => 'school-admin', 'guard_name' => 'api']);
    }

    private function createSchoolAdmin($attributes = []): array
    {
        $school = School::create([
            'name' => 'Test School ' . uniqid(),
            'school_key' => 'SCH-' . strtoupper(uniqid()),
            'admin_email' => 'admin_' . uniqid() . '@school.com',
            'is_active' => true,
        ]);

        $user = User::create([
            'name' => 'School Admin',
            'email' => $school->admin_email,
            'password' => bcrypt('password'),
            'school_id' => $school->id,
        ]);

        return [$school, $user];
    }

    public function test_school_admin_dashboard_returns_active_subscription_with_correct_days_left(): void
    {
        [$school, $user] = $this->createSchoolAdmin();
        $today = Carbon::today();

        Subscription::create([
            'school_id' => $school->id,
            'plan' => 'yearly',
            'amount' => 100.00,
            'start_date' => $today->copy()->subDays(10)->toDateString(),
            'end_date' => $today->copy()->addDays(45)->toDateString(),
            'active' => true,
        ]);

        $this->actingAs($user, 'api');

        $response = $this->getJson('/api/school/dashboard');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.subscription.has_subscription', true)
            ->assertJsonPath('data.subscription.is_active', true)
            ->assertJsonPath('data.subscription.is_expired', false)
            ->assertJsonPath('data.subscription.status', 'active')
            ->assertJsonPath('data.subscription.plan', 'yearly')
            ->assertJsonPath('data.subscription.days_left', 45);
    }

    public function test_school_admin_dashboard_returns_expiring_soon_status_within_30_days(): void
    {
        [$school, $user] = $this->createSchoolAdmin();
        $today = Carbon::today();

        Subscription::create([
            'school_id' => $school->id,
            'plan' => 'monthly',
            'amount' => 10.00,
            'start_date' => $today->copy()->subDays(10)->toDateString(),
            'end_date' => $today->copy()->addDays(20)->toDateString(),
            'active' => true,
        ]);

        $this->actingAs($user, 'api');

        $response = $this->getJson('/api/school/dashboard');

        $response->assertOk()
            ->assertJsonPath('data.subscription.status', 'expiring_soon')
            ->assertJsonPath('data.subscription.days_left', 20);
    }

    public function test_school_admin_dashboard_returns_critical_status_within_7_days(): void
    {
        [$school, $user] = $this->createSchoolAdmin();
        $today = Carbon::today();

        Subscription::create([
            'school_id' => $school->id,
            'plan' => 'monthly',
            'amount' => 10.00,
            'start_date' => $today->copy()->subDays(25)->toDateString(),
            'end_date' => $today->copy()->addDays(5)->toDateString(),
            'active' => true,
        ]);

        $this->actingAs($user, 'api');

        $response = $this->getJson('/api/school/dashboard');

        $response->assertOk()
            ->assertJsonPath('data.subscription.status', 'critical')
            ->assertJsonPath('data.subscription.days_left', 5);
    }

    public function test_school_admin_dashboard_returns_expired_status_and_never_negative_days(): void
    {
        [$school, $user] = $this->createSchoolAdmin();
        $today = Carbon::today();

        Subscription::create([
            'school_id' => $school->id,
            'plan' => 'monthly',
            'amount' => 10.00,
            'start_date' => $today->copy()->subDays(40)->toDateString(),
            'end_date' => $today->copy()->subDays(10)->toDateString(),
            'active' => true,
        ]);

        $this->actingAs($user, 'api');

        $response = $this->getJson('/api/school/dashboard');

        $response->assertOk()
            ->assertJsonPath('data.subscription.has_subscription', true)
            ->assertJsonPath('data.subscription.is_active', false)
            ->assertJsonPath('data.subscription.is_expired', true)
            ->assertJsonPath('data.subscription.status', 'expired')
            ->assertJsonPath('data.subscription.days_left', 0);
    }

    public function test_school_admin_dashboard_returns_none_status_when_no_subscription_exists(): void
    {
        [$school, $user] = $this->createSchoolAdmin();

        $this->actingAs($user, 'api');

        $response = $this->getJson('/api/school/dashboard');

        $response->assertOk()
            ->assertJsonPath('data.subscription.has_subscription', false)
            ->assertJsonPath('data.subscription.is_active', false)
            ->assertJsonPath('data.subscription.status', 'none')
            ->assertJsonPath('data.subscription.days_left', 0);
    }

    public function test_school_admin_can_access_subscription_billing_page_endpoint(): void
    {
        [$school, $user] = $this->createSchoolAdmin();
        $today = Carbon::today();

        $sub = Subscription::create([
            'school_id' => $school->id,
            'plan' => 'yearly',
            'amount' => 100.00,
            'start_date' => $today->copy()->subDays(5)->toDateString(),
            'end_date' => $today->copy()->addDays(360)->toDateString(),
            'active' => true,
        ]);

        Invoice::create([
            'invoice_number' => 'INV-TEST-001',
            'subscription_id' => $sub->id,
            'school_id' => $school->id,
            'customer_type' => 'school',
            'customer_name' => $school->name,
            'customer_email' => $school->admin_email,
            'plan' => 'yearly',
            'billing_period_start' => $sub->start_date->toDateString(),
            'billing_period_end' => $sub->end_date->toDateString(),
            'subtotal' => 100.00,
            'tax' => 0.00,
            'total' => 100.00,
            'currency' => 'USD',
            'status' => 'paid',
            'issued_at' => now(),
            'paid_at' => now(),
        ]);

        $this->actingAs($user, 'api');

        $response = $this->getJson('/api/school/subscription');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.current_subscription.has_subscription', true)
            ->assertJsonPath('data.current_subscription.plan', 'yearly')
            ->assertJsonCount(1, 'data.subscriptions')
            ->assertJsonCount(1, 'data.invoices')
            ->assertJsonPath('data.invoices.0.invoice_number', 'INV-TEST-001');
    }

    public function test_school_admin_cannot_access_other_school_invoice(): void
    {
        [$schoolA, $userA] = $this->createSchoolAdmin();
        [$schoolB, $userB] = $this->createSchoolAdmin();
        $today = Carbon::today();

        $invoiceB = Invoice::create([
            'invoice_number' => 'INV-SCHOOL-B',
            'school_id' => $schoolB->id,
            'customer_type' => 'school',
            'customer_name' => $schoolB->name,
            'customer_email' => $schoolB->admin_email,
            'plan' => 'monthly',
            'billing_period_start' => $today->toDateString(),
            'billing_period_end' => $today->copy()->addMonth()->toDateString(),
            'subtotal' => 5.00,
            'tax' => 0.00,
            'total' => 5.00,
            'currency' => 'USD',
            'status' => 'paid',
            'issued_at' => now(),
        ]);

        $this->actingAs($userA, 'api');

        // School A attempts to access School B's invoice
        $response = $this->getJson('/api/school/invoices/' . $invoiceB->id);
        $response->assertNotFound();

        // School A attempts to download School B's invoice PDF
        $responsePdf = $this->getJson('/api/school/invoices/' . $invoiceB->id . '/pdf');
        $responsePdf->assertNotFound();
    }

    public function test_school_admin_can_download_own_invoice_pdf(): void
    {
        [$school, $user] = $this->createSchoolAdmin();
        $today = Carbon::today();

        $invoice = Invoice::create([
            'invoice_number' => 'INV-OWN-PDF-001',
            'school_id' => $school->id,
            'customer_type' => 'school',
            'customer_name' => $school->name,
            'customer_email' => $school->admin_email,
            'plan' => 'yearly',
            'billing_period_start' => $today->toDateString(),
            'billing_period_end' => $today->copy()->addYear()->toDateString(),
            'subtotal' => 100.00,
            'tax' => 0.00,
            'total' => 100.00,
            'currency' => 'USD',
            'status' => 'paid',
            'issued_at' => now(),
        ]);

        $this->actingAs($user, 'api');

        $response = $this->get('/api/school/invoices/' . $invoice->id . '/pdf');
        $response->assertOk();
        $response->assertHeader('content-type', 'application/pdf');
    }
}
