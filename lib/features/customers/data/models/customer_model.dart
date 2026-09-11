class CustomerModel {
  final int id;
  final int businessId;
  final String name;
  final String? companyName;
  final String? email;
  final String phone;
  final String? gstin;
  final String? pan;
  final String? billingAddress;
  final String? billingCity;
  final String billingState;
  final String? billingStateCode;
  final String? billingPincode;
  final String? shippingAddress;
  final double totalSales;
  final double totalPaid;
  final double outstandingAmount;
  final DateTime? createdAt;

  const CustomerModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.companyName,
    this.email,
    required this.phone,
    this.gstin,
    this.pan,
    this.billingAddress,
    this.billingCity,
    this.billingState = 'Maharashtra',
    this.billingStateCode = '27',
    this.billingPincode,
    this.shippingAddress,
    this.totalSales = 0.0,
    this.totalPaid = 0.0,
    this.outstandingAmount = 0.0,
    this.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int,
      businessId: (json['business_id'] as int?) ?? 1,
      name: json['name'] as String,
      companyName: json['company_name'] as String?,
      email: json['email'] as String?,
      phone: (json['phone'] as String?) ?? '',
      gstin: json['gstin'] as String?,
      pan: json['pan'] as String?,
      billingAddress: json['billing_address'] as String?,
      billingCity: json['billing_city'] as String?,
      billingState: (json['billing_state'] as String?) ?? 'Maharashtra',
      billingStateCode: (json['billing_state_code'] as String?) ?? '27',
      billingPincode: json['billing_pincode'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (json['outstanding_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'company_name': companyName,
      'email': email,
      'phone': phone,
      'gstin': gstin,
      'pan': pan,
      'billing_address': billingAddress,
      'billing_city': billingCity,
      'billing_state': billingState,
      'billing_state_code': billingStateCode,
      'billing_pincode': billingPincode,
      'shipping_address': shippingAddress,
      'total_sales': totalSales,
      'total_paid': totalPaid,
      'outstanding_amount': outstandingAmount,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  CustomerModel copyWith({
    int? id,
    int? businessId,
    String? name,
    String? companyName,
    String? email,
    String? phone,
    String? gstin,
    String? pan,
    String? billingAddress,
    String? billingCity,
    String? billingState,
    String? billingStateCode,
    String? billingPincode,
    String? shippingAddress,
    double? totalSales,
    double? totalPaid,
    double? outstandingAmount,
    DateTime? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      billingAddress: billingAddress ?? this.billingAddress,
      billingCity: billingCity ?? this.billingCity,
      billingState: billingState ?? this.billingState,
      billingStateCode: billingStateCode ?? this.billingStateCode,
      billingPincode: billingPincode ?? this.billingPincode,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      totalSales: totalSales ?? this.totalSales,
      totalPaid: totalPaid ?? this.totalPaid,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
