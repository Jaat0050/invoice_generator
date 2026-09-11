class BusinessModel {
  final int id;
  final String name;
  final String? legalName;
  final String? gstin;
  final String? pan;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String state; // e.g. "27-Maharashtra" or "Maharashtra"
  final String? stateCode; // "27"
  final String? pincode;
  final String? logoUrl;
  final String? signatureUrl;
  final String? upiId;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? bankBranch;
  final String invoicePrefix;
  final int nextInvoiceNumber;
  final String currency;

  const BusinessModel({
    required this.id,
    required this.name,
    this.legalName,
    this.gstin,
    this.pan,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state = 'Maharashtra',
    this.stateCode = '27',
    this.pincode,
    this.logoUrl,
    this.signatureUrl,
    this.upiId,
    this.bankName,
    this.bankAccountNumber,
    this.bankIfsc,
    this.bankBranch,
    this.invoicePrefix = 'INV-',
    this.nextInvoiceNumber = 1001,
    this.currency = 'INR',
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as int,
      name: json['name'] as String,
      legalName: json['legal_name'] as String?,
      gstin: json['gstin'] as String?,
      pan: json['pan'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: (json['state'] as String?) ?? 'Maharashtra',
      stateCode: (json['state_code'] as String?) ?? '27',
      pincode: json['pincode'] as String?,
      logoUrl: json['logo_url'] as String?,
      signatureUrl: json['signature_url'] as String?,
      upiId: json['upi_id'] as String?,
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankIfsc: json['bank_ifsc'] as String?,
      bankBranch: json['bank_branch'] as String?,
      invoicePrefix: (json['invoice_prefix'] as String?) ?? 'INV-',
      nextInvoiceNumber: (json['next_invoice_number'] as int?) ?? 1001,
      currency: (json['currency'] as String?) ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'legal_name': legalName,
      'gstin': gstin,
      'pan': pan,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'state_code': stateCode,
      'pincode': pincode,
      'logo_url': logoUrl,
      'signature_url': signatureUrl,
      'upi_id': upiId,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_ifsc': bankIfsc,
      'bank_branch': bankBranch,
      'invoice_prefix': invoicePrefix,
      'next_invoice_number': nextInvoiceNumber,
      'currency': currency,
    };
  }

  BusinessModel copyWith({
    int? id,
    String? name,
    String? legalName,
    String? gstin,
    String? pan,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? stateCode,
    String? pincode,
    String? logoUrl,
    String? signatureUrl,
    String? upiId,
    String? bankName,
    String? bankAccountNumber,
    String? bankIfsc,
    String? bankBranch,
    String? invoicePrefix,
    int? nextInvoiceNumber,
    String? currency,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
      pincode: pincode ?? this.pincode,
      logoUrl: logoUrl ?? this.logoUrl,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      upiId: upiId ?? this.upiId,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      bankBranch: bankBranch ?? this.bankBranch,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      currency: currency ?? this.currency,
    );
  }
}
