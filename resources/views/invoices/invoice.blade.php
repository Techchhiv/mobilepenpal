<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>Invoice {{ $invoice->invoice_number }}</title>
    <style>
        @page {
            margin: 25px 30px 25px 30px;
        }

        body {
            font-family: 'DejaVu Sans', Helvetica, Arial, sans-serif;
            font-size: 11px;
            color: #1e293b;
            background-color: #ffffff;
            line-height: 1.45;
            margin: 0;
            padding: 0;
        }

        .invoice-wrapper {
            width: 100%;
            padding: 10px 15px;
        }

        /* ── Header ── */
        .brand-name {
            font-size: 22px;
            font-weight: bold;
            color: #0f172a;
            letter-spacing: -0.3px;
            line-height: 1.2;
        }
        .brand-meta {
            font-size: 10px;
            color: #64748b;
            margin-top: 3px;
            line-height: 1.4;
        }

        .invoice-title {
            font-size: 22px;
            font-weight: bold;
            color: #487fff;
            letter-spacing: 0.8px;
            text-transform: uppercase;
        }
        .invoice-number {
            font-size: 12px;
            font-weight: bold;
            color: #0f172a;
            margin-top: 2px;
        }

        /* ── Status Badges ── */
        .status-badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 12px;
            font-size: 9px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-top: 4px;
        }
        .status-paid {
            background-color: #dcfce7;
            color: #15803d;
            border: 1px solid #bbf7d0;
        }
        .status-active {
            background-color: #dcfce7;
            color: #15803d;
            border: 1px solid #bbf7d0;
        }
        .status-void {
            background-color: #fee2e2;
            color: #b91c1c;
            border: 1px solid #fecaca;
        }
        .status-issued {
            background-color: #e0f2fe;
            color: #0369a1;
            border: 1px solid #bae6fd;
        }

        /* ── Divider ── */
        .divider {
            border-bottom: 1.5px solid #e2e8f0;
            margin: 16px 0 16px 0;
            width: 100%;
        }

        /* ── Section Labels ── */
        .section-label {
            font-size: 9.5px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 0.6px;
            color: #64748b;
            margin-bottom: 6px;
            border-bottom: 1px solid #f1f5f9;
            padding-bottom: 3px;
        }

        .info-item {
            margin-bottom: 3.5px;
            font-size: 10.5px;
            line-height: 1.4;
        }
        .info-item span { color: #64748b; }
        .info-item strong { color: #0f172a; }

        /* ── Items Table ── */
        .items-table {
            width: 100%;
            border-collapse: collapse;
            margin: 18px 0 16px 0;
            border: 1px solid #e2e8f0;
        }
        .items-table th {
            background-color: #f8fafc;
            color: #475569;
            font-size: 9.5px;
            text-transform: uppercase;
            font-weight: bold;
            letter-spacing: 0.5px;
            padding: 9px 10px;
            text-align: left;
            border-bottom: 1.5px solid #e2e8f0;
        }
        .items-table th:last-child { text-align: right; }
        .items-table td {
            padding: 10px 10px;
            border-bottom: 1px solid #f1f5f9;
            font-size: 11px;
            vertical-align: middle;
        }
        .items-table tr:last-child td { border-bottom: none; }

        /* ── Summary Card Boxes ── */
        .card-box {
            background-color: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 5px;
            padding: 10px 12px;
        }

        /* ── Notice Box ── */
        .notice-box {
            background-color: #eff6ff;
            border-left: 3.5px solid #487fff;
            border-radius: 0 4px 4px 0;
            padding: 9px 12px;
            margin: 16px 0 16px 0;
            font-size: 10px;
            color: #1e40af;
            line-height: 1.45;
        }

        /* ── Void Notice ── */
        .void-box {
            background-color: #fef2f2;
            border-left: 3.5px solid #ef4444;
            border-radius: 0 4px 4px 0;
            padding: 9px 12px;
            margin-bottom: 14px;
            font-size: 10.5px;
            color: #991b1b;
        }

        /* ── Footer ── */
        .footer {
            border-top: 1px solid #e2e8f0;
            padding-top: 12px;
            margin-top: 10px;
            font-size: 9px;
            color: #94a3b8;
            text-align: center;
            line-height: 1.5;
        }
    </style>
</head>
<body>

<div class="invoice-wrapper">

@php
    $logoPath = public_path('images/logo.png');
    $logoData = file_exists($logoPath) ? base64_encode(file_get_contents($logoPath)) : null;
    $logoSrc = $logoData ? 'data:image/png;base64,' . $logoData : null;
@endphp

<!-- ── Brand & Invoice Header ── -->
<table style="width: 100%; border-collapse: collapse;">
    <tr>
        <td style="width: 55%; vertical-align: top; text-align: left;">
            <table style="border-collapse: collapse;">
                <tr>
                    @if($logoSrc)
                    <td style="vertical-align: middle; padding-right: 10px;">
                        <img src="{{ $logoSrc }}" alt="Khmer PenPal" style="width: 36px; height: 36px; display: block;" />
                    </td>
                    @endif
                    <td style="vertical-align: middle;">
                        <div class="brand-name">Khmer PenPal</div>
                        <div class="brand-meta">
                            Educational Platform &bull; Phnom Penh, Cambodia<br/>
                            info@khmerpenpal.com &bull; +855 935 248 60
                        </div>
                    </td>
                </tr>
            </table>
        </td>
        <td style="width: 45%; vertical-align: top; text-align: right; padding-right: 2px;">
            <div class="invoice-title">INVOICE</div>
            <div class="invoice-number">#{{ $invoice->invoice_number }}</div>
            <div>
                <span class="status-badge status-{{ $invoice->status }}">
                    {{ strtoupper($invoice->status) }}
                </span>
            </div>
        </td>
    </tr>
</table>

<div class="divider"></div>

@if($invoice->isVoid())
<div class="void-box">
    <strong>⚠ Void Notice:</strong> This invoice has been voided.<br/>
    Reason: {{ $invoice->void_reason }} &bull; Voided on: {{ $invoice->voided_at?->format('d M Y, H:i') }}
</div>
@endif

<!-- ── Two-Column Information Section ── -->
<table style="width: 100%; border-collapse: collapse; margin-bottom: 4px;">
    <tr>
        <!-- Billed To (School) -->
        <td style="width: 50%; vertical-align: top; padding-right: 12px;">
            <div class="section-label">Billed To (School)</div>
            <div class="info-item" style="font-size: 12.5px; margin-bottom: 4px;">
                <strong>{{ $invoice->customer_name }}</strong>
            </div>
            @if($invoice->customer_email)
            <div class="info-item"><span>Email:</span> {{ $invoice->customer_email }}</div>
            @endif
            @if($invoice->customer_phone)
            <div class="info-item"><span>Phone:</span> {{ $invoice->customer_phone }}</div>
            @endif
            @if($invoice->customer_address)
            <div class="info-item"><span>Address:</span> {{ $invoice->customer_address }}</div>
            @endif
            <div class="info-item" style="margin-top: 3px;">
                <span>Account Type:</span>
                <strong>Institutional School License</strong>
            </div>
        </td>

        <!-- Invoice Details -->
        <td style="width: 50%; vertical-align: top; padding-left: 12px;">
            <div class="section-label">Invoice Summary</div>
            <div class="info-item">
                <span>Invoice Number:</span> <strong>{{ $invoice->invoice_number }}</strong>
            </div>
            <div class="info-item">
                <span>Issue Date:</span> {{ $invoice->issued_at?->format('d M Y') }}
            </div>
            @if($invoice->paid_at)
            <div class="info-item">
                <span>Settlement Date:</span> {{ $invoice->paid_at?->format('d M Y') }}
            </div>
            @endif
            <div class="info-item">
                <span>License Plan:</span> <strong>{{ ucfirst($invoice->plan) }} Subscription</strong>
            </div>
            <div class="info-item">
                <span>Billing Period:</span>
                {{ $invoice->billing_period_start?->format('d M Y') }} &mdash;
                {{ $invoice->billing_period_end?->format('d M Y') }}
            </div>
        </td>
    </tr>
</table>

<!-- ── Line Items Table ── -->
<table class="items-table">
    <thead>
        <tr>
            <th style="width: 6%;">#</th>
            <th style="width: 44%;">Description / Plan</th>
            <th style="width: 14%;">Plan Type</th>
            <th style="width: 22%;">Billing Period</th>
            <th style="width: 14%; text-align: right;">Amount</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td style="color: #64748b; font-weight: bold;">1</td>
            <td>
                <strong style="color: #0f172a; font-size: 11.5px;">{{ $invoice->description }}</strong>
                <div style="font-size: 9.5px; color: #64748b; margin-top: 2px;">
                    Institutional Standard License for {{ $invoice->customer_name }}
                </div>
            </td>
            <td><strong style="color: #0f172a;">{{ ucfirst($invoice->plan) }}</strong></td>
            <td style="color: #475569;">
                {{ $invoice->billing_period_start?->format('d M Y') }} &mdash;
                {{ $invoice->billing_period_end?->format('d M Y') }}
            </td>
            <td style="text-align: right; font-weight: bold; color: #0f172a; font-size: 12px;">
                {{ $invoice->currency }} {{ number_format($invoice->subtotal, 2) }}
            </td>
        </tr>
    </tbody>
</table>

<!-- ── Payment Info & Financial Summary Grid ── -->
<table style="width: 100%; border-collapse: collapse; margin-bottom: 6px;">
    <tr>
        <!-- Left: Payment Settlement Details -->
        <td style="width: 50%; vertical-align: top; padding-right: 10px;">
            @if($invoice->payment)
            <div class="card-box">
                <div style="font-weight: bold; color: #475569; font-size: 9px; text-transform: uppercase; letter-spacing: 0.5px; border-bottom: 1px solid #e2e8f0; padding-bottom: 3px; margin-bottom: 5px;">
                    Payment Information
                </div>
                <table style="width: 100%; border-collapse: collapse;">
                    <tr>
                        <td style="padding: 2px 0; color: #64748b; font-size: 10px; width: 42%;">Payment Method:</td>
                        <td style="padding: 2px 0; font-weight: bold; color: #0f172a; font-size: 10px;">
                            {{ strtoupper(str_replace('_', ' ', $invoice->payment->payment_method)) }}
                        </td>
                    </tr>
                    @if($invoice->payment->payment_reference)
                    <tr>
                        <td style="padding: 2px 0; color: #64748b; font-size: 10px;">Transaction Ref:</td>
                        <td style="padding: 2px 0; color: #0f172a; font-size: 10px; font-family: monospace;">
                            {{ $invoice->payment->payment_reference }}
                        </td>
                    </tr>
                    @endif
                    <tr>
                        <td style="padding: 2px 0; color: #64748b; font-size: 10px;">Amount Settled:</td>
                        <td style="padding: 2px 0; font-weight: bold; color: #16a34a; font-size: 10px;">
                            {{ $invoice->payment->currency }} {{ number_format($invoice->payment->amount, 2) }}
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 2px 0; color: #64748b; font-size: 10px;">Settlement Date:</td>
                        <td style="padding: 2px 0; color: #0f172a; font-size: 10px;">
                            {{ $invoice->payment->paid_at?->format('d M Y, H:i') }}
                        </td>
                    </tr>
                </table>
            </div>
            @else
            <div class="card-box" style="text-align: center; color: #94a3b8; font-style: italic; font-size: 10px; padding: 16px 10px;">
                Payment settled under official institutional agreement.
            </div>
            @endif
        </td>

        <!-- Right: Financial Breakdown -->
        <td style="width: 50%; vertical-align: top; padding-left: 10px;">
            <div class="card-box">
                <table style="width: 100%; border-collapse: collapse;">
                    <tr>
                        <td style="padding: 2.5px 0; color: #64748b; font-size: 10.5px;">Subtotal:</td>
                        <td style="padding: 2.5px 0; text-align: right; font-size: 10.5px; font-weight: bold; color: #0f172a;">
                            {{ $invoice->currency }} {{ number_format($invoice->subtotal, 2) }}
                        </td>
                    </tr>
                    @if($invoice->discount > 0)
                    <tr>
                        <td style="padding: 2.5px 0; color: #16a34a; font-size: 10.5px;">Discount:</td>
                        <td style="padding: 2.5px 0; text-align: right; font-size: 10.5px; color: #16a34a; font-weight: bold;">
                            - {{ $invoice->currency }} {{ number_format($invoice->discount, 2) }}
                        </td>
                    </tr>
                    @endif
                    @if($invoice->tax > 0)
                    <tr>
                        <td style="padding: 2.5px 0; color: #64748b; font-size: 10.5px;">Tax / VAT:</td>
                        <td style="padding: 2.5px 0; text-align: right; font-size: 10.5px; font-weight: bold; color: #0f172a;">
                            + {{ $invoice->currency }} {{ number_format($invoice->tax, 2) }}
                        </td>
                    </tr>
                    @endif
                    <tr>
                        <td style="padding: 6px 0 0; border-top: 1.5px solid #cbd5e1; font-size: 11px; font-weight: bold; color: #0f172a;">
                            Total Paid:
                        </td>
                        <td style="padding: 6px 0 0; border-top: 1.5px solid #cbd5e1; text-align: right; font-size: 14px; font-weight: bold; color: #487fff;">
                            {{ $invoice->currency }} {{ number_format($invoice->total, 2) }}
                        </td>
                    </tr>
                </table>
            </div>
        </td>
    </tr>
</table>

<!-- ── Notice / Terms ── -->
<div class="notice-box">
    <strong>Important Notice:</strong>
    This invoice serves as the official tax receipt for your school subscription to the Khmer PenPal Platform. Access to institutional features and student pen pal network is active for the specified billing cycle.
</div>

<!-- ── Official Document Footer ── -->
<div class="footer">
    <p><strong>Khmer PenPal Educational Platform</strong> &nbsp;&bull;&nbsp; info@khmerpenpal.com &nbsp;&bull;&nbsp; +855 935 248 60 &nbsp;&bull;&nbsp; Phnom Penh, Cambodia</p>
    <p style="margin-top: 3px;">This is a computer-generated official document and is valid without physical signature. &nbsp;&bull;&nbsp; Invoice Ref: {{ $invoice->invoice_number }}</p>
</div>

</div>

</body>
</html>
