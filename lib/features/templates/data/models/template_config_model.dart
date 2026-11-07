class TemplateConfigModel {
  final String templateId; // 'classic', 'modern', 'gst_detailed', 'minimal'
  final int primaryColorHex; // Color integer
  final bool showLogo;
  final bool showGstin;
  final bool showCustomerGstin;
  final bool showSupplyDetails;
  final bool showHsnSac;
  final bool showBankDetails;
  final bool showUpiQr;
  final bool showSignature;
  final bool showTerms;
  final bool showPaymentDueAlert;

  const TemplateConfigModel({
    this.templateId = 'classic',
    this.primaryColorHex = 0xFF4F46E5, // Default Indigo
    this.showLogo = true,
    this.showGstin = true,
    this.showCustomerGstin = true,
    this.showSupplyDetails = true,
    this.showHsnSac = true,
    this.showBankDetails = true,
    this.showUpiQr = true,
    this.showSignature = true,
    this.showTerms = true,
    this.showPaymentDueAlert = true,
  });

  factory TemplateConfigModel.fromJson(Map<String, dynamic> json) {
    return TemplateConfigModel(
      templateId: (json['template_id'] as String?) ?? 'classic',
      primaryColorHex: (json['primary_color_hex'] as int?) ?? 0xFF4F46E5,
      showLogo: (json['show_logo'] as bool?) ?? true,
      showGstin: (json['show_gstin'] as bool?) ?? true,
      showCustomerGstin: (json['show_customer_gstin'] as bool?) ?? true,
      showSupplyDetails: (json['show_supply_details'] as bool?) ?? true,
      showHsnSac: (json['show_hsn_sac'] as bool?) ?? true,
      showBankDetails: (json['show_bank_details'] as bool?) ?? true,
      showUpiQr: (json['show_upi_qr'] as bool?) ?? true,
      showSignature: (json['show_signature'] as bool?) ?? true,
      showTerms: (json['show_terms'] as bool?) ?? true,
      showPaymentDueAlert: (json['show_payment_due_alert'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'template_id': templateId,
      'primary_color_hex': primaryColorHex,
      'show_logo': showLogo,
      'show_gstin': showGstin,
      'show_customer_gstin': showCustomerGstin,
      'show_supply_details': showSupplyDetails,
      'show_hsn_sac': showHsnSac,
      'show_bank_details': showBankDetails,
      'show_upi_qr': showUpiQr,
      'show_signature': showSignature,
      'show_terms': showTerms,
      'show_payment_due_alert': showPaymentDueAlert,
    };
  }

  TemplateConfigModel copyWith({
    String? templateId,
    int? primaryColorHex,
    bool? showLogo,
    bool? showGstin,
    bool? showCustomerGstin,
    bool? showSupplyDetails,
    bool? showHsnSac,
    bool? showBankDetails,
    bool? showUpiQr,
    bool? showSignature,
    bool? showTerms,
    bool? showPaymentDueAlert,
  }) {
    return TemplateConfigModel(
      templateId: templateId ?? this.templateId,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      showLogo: showLogo ?? this.showLogo,
      showGstin: showGstin ?? this.showGstin,
      showCustomerGstin: showCustomerGstin ?? this.showCustomerGstin,
      showSupplyDetails: showSupplyDetails ?? this.showSupplyDetails,
      showHsnSac: showHsnSac ?? this.showHsnSac,
      showBankDetails: showBankDetails ?? this.showBankDetails,
      showUpiQr: showUpiQr ?? this.showUpiQr,
      showSignature: showSignature ?? this.showSignature,
      showTerms: showTerms ?? this.showTerms,
      showPaymentDueAlert: showPaymentDueAlert ?? this.showPaymentDueAlert,
    );
  }
}
