class ItemModel {
  final int id;
  final int businessId;
  final String name;
  final String? sku;
  final String? hsnSac;
  final String unit; // 'PCS', 'NOS', 'HRS', 'BOX', 'KGS', 'MTR', 'PER', 'PAIR'
  final double rate;
  final double taxRate; // 0, 5, 12, 18, 28
  final String itemType; // 'product' or 'service'
  final String? description;
  final double defaultDiscount;
  final bool isTaxInclusive;

  const ItemModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.sku,
    this.hsnSac,
    this.unit = 'PCS',
    required this.rate,
    this.taxRate = 18.0,
    this.itemType = 'product',
    this.description,
    this.defaultDiscount = 0.0,
    this.isTaxInclusive = false,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] is int
          ? json['id'] as int
          : (int.tryParse(json['id']?.toString() ?? '') ?? json['id']?.hashCode ?? 1),
      businessId: json['business_id'] is int
          ? json['business_id'] as int
          : (int.tryParse(json['business_id']?.toString() ?? '') ?? 1),
      name: (json['name'] as String?) ?? '',
      sku: json['sku'] as String?,
      hsnSac: json['hsn_sac'] as String?,
      unit: (json['unit'] as String?) ?? 'PCS',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 18.0,
      itemType: (json['item_type'] as String?) ?? 'product',
      description: json['description'] as String?,
      defaultDiscount: (json['default_discount'] as num?)?.toDouble() ?? 0.0,
      isTaxInclusive: (json['is_tax_inclusive'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'sku': sku,
      'hsn_sac': hsnSac,
      'unit': unit,
      'rate': rate,
      'tax_rate': taxRate,
      'item_type': itemType,
      'description': description,
      'default_discount': defaultDiscount,
      'is_tax_inclusive': isTaxInclusive,
    };
  }

  ItemModel copyWith({
    int? id,
    int? businessId,
    String? name,
    String? sku,
    String? hsnSac,
    String? unit,
    double? rate,
    double? taxRate,
    String? itemType,
    String? description,
    double? defaultDiscount,
    bool? isTaxInclusive,
  }) {
    return ItemModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      hsnSac: hsnSac ?? this.hsnSac,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      taxRate: taxRate ?? this.taxRate,
      itemType: itemType ?? this.itemType,
      description: description ?? this.description,
      defaultDiscount: defaultDiscount ?? this.defaultDiscount,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
    );
  }
}
