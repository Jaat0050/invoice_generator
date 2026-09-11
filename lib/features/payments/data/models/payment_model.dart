enum PaymentMethod { upi, bankTransfer, cash, cheque, card, online }

class PaymentModel {
  final int id;
  final int invoiceId;
  final double amount;
  final PaymentMethod method;
  final DateTime paymentDate;
  final String? transactionId;
  final String? note;
  final DateTime? createdAt;

  const PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.amount,
    this.method = PaymentMethod.upi,
    required this.paymentDate,
    this.transactionId,
    this.note,
    this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int,
      invoiceId: json['invoice_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      method: _parseMethod(json['method'] as String?),
      paymentDate: DateTime.tryParse(json['payment_date'] as String? ?? '') ?? DateTime.now(),
      transactionId: json['transaction_id'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'amount': amount,
      'method': method.name,
      'payment_date': paymentDate.toIso8601String(),
      'transaction_id': transactionId,
      'note': note,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static PaymentMethod _parseMethod(String? str) {
    switch (str?.toLowerCase()) {
      case 'upi':
        return PaymentMethod.upi;
      case 'bank_transfer':
      case 'banktransfer':
        return PaymentMethod.bankTransfer;
      case 'cash':
        return PaymentMethod.cash;
      case 'cheque':
        return PaymentMethod.cheque;
      case 'card':
        return PaymentMethod.card;
      default:
        return PaymentMethod.upi;
    }
  }
}
