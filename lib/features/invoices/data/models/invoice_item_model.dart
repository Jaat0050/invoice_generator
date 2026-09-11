class InvoiceItemModel {
  final int? id;
  final int? itemId;
  final String description;
  final String? hsnSac;
  final double quantity;
  final String unit;
  final double rate;
  final double discountPercent;
  final double discountAmount;
  final double taxableAmount;
  final double taxRate;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalAmount;

  const InvoiceItemModel({
    this.id,
    this.itemId,
    required this.description,
    this.hsnSac,
    required this.quantity,
    this.unit = 'PCS',
    required this.rate,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    required this.taxableAmount,
    this.taxRate = 18.0,
    this.cgstAmount = 0.0,
    this.sgstAmount = 0.0,
    this.igstAmount = 0.0,
    required this.totalAmount,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: json['id'] as int?,
      itemId: json['item_id'] as int?,
      description: json['description'] as String,
      hsnSac: json['hsn_sac'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: (json['unit'] as String?) ?? 'PCS',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxableAmount: (json['taxable_amount'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 18.0,
      cgstAmount: (json['cgst_amount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json['sgst_amount'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json['igst_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      'description': description,
      'hsn_sac': hsnSac,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'taxable_amount': taxableAmount,
      'tax_rate': taxRate,
      'cgst_amount': cgstAmount,
      'sgst_amount': sgstAmount,
      'igst_amount': igstAmount,
      'total_amount': totalAmount,
    };
  }

  InvoiceItemModel copyWith({
    int? id,
    int? itemId,
    String? description,
    String? hsnSac,
    double? quantity,
    String? unit,
    double? rate,
    double? discountPercent,
    double? discountAmount,
    double? taxableAmount,
    double? taxRate,
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? totalAmount,
  }) {
    return InvoiceItemModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      description: description ?? this.description,
      hsnSac: hsnSac ?? this.hsnSac,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      taxRate: taxRate ?? this.taxRate,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}
