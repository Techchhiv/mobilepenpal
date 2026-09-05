class BakongCheckoutModel {
  final int transactionId;
  final String plan;
  final double amount;
  final String currency;
  final String qrString;
  final String md5;
  final String billNumber;
  final String merchantName;
  final String accountId;
  final DateTime? expiresAt;
  final int expiresInSeconds;
  final bool simulationMode;

  BakongCheckoutModel({
    required this.transactionId,
    required this.plan,
    required this.amount,
    required this.currency,
    required this.qrString,
    required this.md5,
    required this.billNumber,
    required this.merchantName,
    required this.accountId,
    this.expiresAt,
    this.expiresInSeconds = 600,
    this.simulationMode = false,
  });

  factory BakongCheckoutModel.fromJson(Map<String, dynamic> json) {
    return BakongCheckoutModel(
      transactionId: json['transaction_id'] is int
          ? json['transaction_id']
          : int.tryParse(json['transaction_id']?.toString() ?? '0') ?? 0,
      plan: json['plan']?.toString() ?? 'monthly',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency']?.toString() ?? 'USD',
      qrString: json['qr_string']?.toString() ?? '',
      md5: json['md5']?.toString() ?? '',
      billNumber: json['bill_number']?.toString() ?? '',
      merchantName: json['merchant_name']?.toString() ?? 'Khmer PenPal',
      accountId: json['account_id']?.toString() ?? '',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      expiresInSeconds: json['expires_in_seconds'] is int
          ? json['expires_in_seconds']
          : int.tryParse(json['expires_in_seconds']?.toString() ?? '600') ?? 600,
      simulationMode: json['simulation_mode'] == true,
    );
  }
}
