<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>Invoice {{ $invoice->invoice_number }}</title>
    <style>
        @page {
            margin: 0px;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'DejaVu Sans', Arial, sans-serif;
            font-size: 11px;
            color: #1a1a2e;
            background-color: #ffffff;
            padding: 0;
            margin: 0;
        }

        /* ── Header ── */
        .brand-name {
            font-size: 20px;
            font-weight: bold;
            letter-spacing: 0.5px;
            color: #ffffff;
            line-height: 1.1;
        }
        .brand-tagline {
            font-size: 9px;
            color: #a0aec0;
            margin-top: 3px;
        }

        .invoice-title {
            font-size: 22px;
            font-weight: bold;
            color: #e94560;
            letter-spacing: 1px;
        }
        .invoice-number {
            font-size: 11px;
            color: #cbd5e0;
            margin-top: 2px;
        }

        /* ── Status Badge ── */
        .status-badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 10px;
            font-size: 9px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .status-paid   { background-color: #38a169; color: #ffffff; }
        .status-void   { background-color: #e53e3e; color: #ffffff; }
        .status-issued { background-color: #dd6b20; color: #ffffff; }

        /* ── Body ── */
        .body {
            padding: 20px 28px;
        }

        .section-label {
            font-size: 9px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: #718096;
            margin-bottom: 6px;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 3px;
        }
        .info-item {
            margin-bottom: 3px;
            font-size: 10.5px;
            line-height: 1.4;
        }
        .info-item span { color: #718096; }
        .info-item strong { color: #1a1a2e; }

        /* ── Items Table ── */
        .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 18px;
        }
        .items-table th {
            background-color: #1a1a2e;
            color: #ffffff;
            font-size: 9.5px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            padding: 8px 10px;
            text-align: left;
        }
        .items-table th:last-child { text-align: right; }
        .items-table td {
            padding: 9px 10px;
            border-bottom: 1px solid #edf2f7;
            font-size: 10.5px;
            vertical-align: middle;
        }
        .items-table tr:last-child td { border-bottom: 2px solid #e2e8f0; }

        /* ── Void Notice ── */
        .void-notice {
            background-color: #fff5f5;
            border: 1px solid #feb2b2;
            border-radius: 5px;
            padding: 8px 12px;
            color: #c53030;
            margin-bottom: 16px;
            font-size: 10.5px;
        }
        .void-notice strong { font-size: 11px; }
        .void-notice p { margin-top: 2px; }

        /* ── Notes ── */
        .notes-section {
            background-color: #fffff0;
            border-left: 3px solid #ecc94b;
            border-radius: 0 4px 4px 0;
            padding: 8px 12px;
            margin-bottom: 18px;
            font-size: 10px;
            color: #744210;
        }
        .notes-section strong { display: block; margin-bottom: 2px; }

        /* ── Footer ── */
        .footer {
            border-top: 1px solid #e2e8f0;
            padding-top: 12px;
            font-size: 9.5px;
            color: #a0aec0;
            text-align: center;
        }
    </style>
</head>
<body>

@php
    $logoPath = public_path('images/logo.png');
    $logoData = file_exists($logoPath) ? base64_encode(file_get_contents($logoPath)) : null;
    $logoSrc = $logoData ? 'data:image/png;base64,' . $logoData : null;
@endphp

<!-- ── Top Full-Bleed Header ── -->
<table style="width: 100%; border-collapse: collapse; background-color: #1a1a2e; margin: 0; padding: 0;">
    <tr>
        <td style="padding: 20px 28px; vertical-align: middle; width: 55%; text-align: left;">
            <table style="border-collapse: collapse; margin: 0; padding: 0;">
                <tr>
                    @if($logoSrc)
                    <td style="vertical-align: middle; padding-right: 10px;">
                        <img src="{{ $logoSrc }}" alt="Khmer PenPal" style="width: 40px; height: 40px; display: block;" />
                    </td>
                    @endif
                    <td style="vertical-align: middle;">
                        <div class="brand-name">Khmer PenPal</div>
                        <div class="brand-tagline">Learning Through Connection</div>
                    </td>
                </tr>
            </table>
        </td>
        <td style="padding: 20px 28px; vertical-align: middle; text-align: right; width: 45%;">
            <div class="invoice-title">INVOICE</div>
            <div class="invoice-number">{{ $invoice->invoice_number }}</div>
            <div style="margin-top: 4px;">
                <span class="status-badge status-{{ $invoice->status }}">
                    {{ strtoupper($invoice->status) }}
                </span>
            </div>
        </td>
    </tr>
</table>

<div class="body">

    @if($invoice->isVoid())
    <div class="void-notice">
        <strong>⚠ This invoice has been voided</strong>
        <p>Reason: {{ $invoice->void_reason }}</p>
        <p>Voided on: {{ $invoice->voided_at?->format('d M Y, H:i') }}</p>
    </div>
    @endif

    <!-- ── Two-Column Info Grid ── -->
    <table style="width: 100%; border-collapse: collapse; margin-bottom: 18px;">
        <tr>
            <td style="width: 50%; vertical-align: top; padding-right: 14px;">
                <div class="section-label">Billed To</div>
                <div class="info-item"><strong>{{ $invoice->customer_name }}</strong></div>
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
                    <span>Customer Type:</span>
                    <strong>{{ ucfirst($invoice->customer_type) }}</strong>
                </div>
            </td>
            <td style="width: 50%; vertical-align: top; padding-left: 14px;">
                <div class="section-label">Invoice Details</div>
                <div class="info-item"><span>Invoice No:</span> <strong>{{ $invoice->invoice_number }}</strong></div>
                <div class="info-item"><span>Issue Date:</span> {{ $invoice->issued_at?->format('d M Y') }}</div>
                @if($invoice->paid_at)
                <div class="info-item"><span>Payment Date:</span> {{ $invoice->paid_at?->format('d M Y') }}</div>
                @endif
                <div class="info-item"><span>Plan:</span> <strong>{{ ucfirst($invoice->plan) }}</strong></div>
                <div class="info-item">
                    <span>Billing Period:</span>
                    {{ $invoice->billing_period_start?->format('d M Y') }} –
                    {{ $invoice->billing_period_end?->format('d M Y') }}
                </div>
            </td>
        </tr>
    </table>

    <!-- ── Line Items ── -->
    <table class="items-table">
        <thead>
            <tr>
                <th style="width: 6%;">#</th>
                <th style="width: 40%;">Description</th>
                <th style="width: 14%;">Plan</th>
                <th style="width: 25%;">Billing Period</th>
                <th style="width: 15%; text-align: right;">Amount</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>1</td>
                <td><strong>{{ $invoice->description }}</strong></td>
                <td>{{ ucfirst($invoice->plan) }}</td>
                <td>
                    {{ $invoice->billing_period_start?->format('d M Y') }} –
                    {{ $invoice->billing_period_end?->format('d M Y') }}
                </td>
                <td style="text-align: right; font-weight: bold;">
                    {{ $invoice->currency }} {{ number_format($invoice->subtotal, 2) }}
                </td>
            </tr>
        </tbody>
    </table>

    <!-- ── Payment Info & Totals Grid ── -->
    <table style="width: 100%; border-collapse: collapse; margin-bottom: 18px;">
        <tr>
            <td style="width: 54%; vertical-align: top; padding-right: 14px;">
                @if($invoice->payment)
                <div style="background-color: #f7fafc; border: 1px solid #e2e8f0; border-radius: 5px; padding: 10px 12px;">
                    <div style="font-weight: bold; color: #2d3748; margin-bottom: 5px; font-size: 9.5px; text-transform: uppercase; letter-spacing: 0.5px; border-bottom: 1px solid #edf2f7; padding-bottom: 3px;">
                        Payment Information
                    </div>
                    <table style="width: 100%; border-collapse: collapse;">
                        <tr>
                            <td style="padding: 2px 0; color: #718096; font-size: 10px; width: 42%;">Method:</td>
                            <td style="padding: 2px 0; font-weight: bold; color: #1a1a2e; font-size: 10px;">{{ strtoupper(str_replace('_', ' ', $invoice->payment->payment_method)) }}</td>
                        </tr>
                        @if($invoice->payment->payment_reference)
                        <tr>
                            <td style="padding: 2px 0; color: #718096; font-size: 10px;">Reference:</td>
                            <td style="padding: 2px 0; color: #1a1a2e; font-size: 10px;">{{ $invoice->payment->payment_reference }}</td>
                        </tr>
                        @endif
                        <tr>
                            <td style="padding: 2px 0; color: #718096; font-size: 10px;">Amount Paid:</td>
                            <td style="padding: 2px 0; font-weight: bold; color: #1a1a2e; font-size: 10px;">{{ $invoice->payment->currency }} {{ number_format($invoice->payment->amount, 2) }}</td>
                        </tr>
                        <tr>
                            <td style="padding: 2px 0; color: #718096; font-size: 10px;">Date:</td>
                            <td style="padding: 2px 0; color: #1a1a2e; font-size: 10px;">{{ $invoice->payment->paid_at?->format('d M Y, H:i') }}</td>
                        </tr>
                        @if($invoice->payment->notes)
                        <tr>
                            <td style="padding: 2px 0; color: #718096; font-size: 10px;">Notes:</td>
                            <td style="padding: 2px 0; color: #718096; font-size: 10px;">{{ $invoice->payment->notes }}</td>
                        </tr>
                        @endif
                    </table>
                </div>
                @endif
            </td>
            <td style="width: 46%; vertical-align: top;">
                <div style="background-color: #f7fafc; border: 1px solid #e2e8f0; border-radius: 5px; padding: 10px 12px;">
                    <table style="width: 100%; border-collapse: collapse;">
                        <tr>
                            <td style="padding: 3px 0; color: #718096; font-size: 10.5px;">Subtotal:</td>
                            <td style="padding: 3px 0; text-align: right; font-size: 10.5px; font-weight: bold; color: #1a1a2e;">{{ $invoice->currency }} {{ number_format($invoice->subtotal, 2) }}</td>
                        </tr>
                        @if($invoice->discount > 0)
                        <tr>
                            <td style="padding: 3px 0; color: #38a169; font-size: 10.5px;">Discount:</td>
                            <td style="padding: 3px 0; text-align: right; font-size: 10.5px; color: #38a169; font-weight: bold;">- {{ $invoice->currency }} {{ number_format($invoice->discount, 2) }}</td>
                        </tr>
                        @endif
                        @if($invoice->tax > 0)
                        <tr>
                            <td style="padding: 3px 0; color: #718096; font-size: 10.5px;">Tax / VAT:</td>
                            <td style="padding: 3px 0; text-align: right; font-size: 10.5px; font-weight: bold; color: #1a1a2e;">+ {{ $invoice->currency }} {{ number_format($invoice->tax, 2) }}</td>
                        </tr>
                        @endif
                        <tr>
                            <td style="padding: 6px 0 0; border-top: 2px solid #1a1a2e; font-size: 11.5px; font-weight: bold; color: #1a1a2e;">Total Paid:</td>
                            <td style="padding: 6px 0 0; border-top: 2px solid #1a1a2e; text-align: right; font-size: 13.5px; font-weight: bold; color: #e94560;">{{ $invoice->currency }} {{ number_format($invoice->total, 2) }}</td>
                        </tr>
                    </table>
                </div>
            </td>
        </tr>
    </table>

    <!-- ── Notes / Terms ── -->
    <div class="notes-section">
        <strong>Important Notice:</strong>
        This invoice serves as the official receipt for your subscription to Khmer PenPal. Access to premium features is active for the specified billing period.
    </div>

    <!-- ── Footer ── -->
    <div class="footer">
        <p><strong>Khmer PenPal</strong> &nbsp;|&nbsp; info@khmerpenpal.com &nbsp;|&nbsp; +855 935 248 60</p>
        <p style="margin-top: 3px;">This is a computer-generated invoice and is valid without a signature. &nbsp;|&nbsp; Invoice Ref: {{ $invoice->invoice_number }}</p>
    </div>

</div>

</body>
</html>
