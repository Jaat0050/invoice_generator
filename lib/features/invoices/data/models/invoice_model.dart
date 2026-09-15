import 'package:invoice_generator/features/customers/data/models/customer_model.dart';
import 'package:invoice_generator/features/payments/data/models/payment_model.dart';
import 'invoice_item_model.dart';

enum InvoiceStatus { draft, unpaid, partiallyPaid, paid, overdue, cancelled }
enum GstType { intraState, interState }

class InvoiceModel {
  final int id;
  final int businessId;
  final String invoiceNumber;
  final String? referenceNumber;
  final String? poNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final CustomerModel customer;
  final List<InvoiceItemModel> items;
  final GstType gstType;
  final double subtotal;
  final double totalDiscount;
  final double taxableAmount;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double roundOff;
  final double grandTotal;
  final double totalPaid;
  final double balanceDue;
  final InvoiceStatus status;
  final String? notes;
  final String? termsAndConditions;
  final String templateId;
  final Map<String, dynamic>? templateConfig;
  final String? pdfUrl;
  final List<PaymentModel> payments;
  final DateTime? createdAt;

  const InvoiceModel({
    required this.id,
    required this.businessId,
    required this.invoiceNumber,
    this.referenceNumber,
    this.poNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.customer,
    required this.items,
    this.gstType = GstType.intraState,
    required this.subtotal,
    this.totalDiscount = 0.0,
    required this.taxableAmount,
    this.totalCgst = 0.0,
    this.totalSgst = 0.0,
    this.totalIgst = 0.0,
    this.roundOff = 0.0,
    required this.grandTotal,
    this.totalPaid = 0.0,
    required this.balanceDue,
    this.status = InvoiceStatus.unpaid,
    this.notes,
    this.termsAndConditions,
    this.templateId = 'classic',
    this.templateConfig,
    this.pdfUrl,
    this.payments = const [],
    this.createdAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] is int
          ? json['id'] as int
          : (int.tryParse(json['id']?.toString() ?? '') ?? json['id']?.hashCode ?? 1),
      businessId: json['business_id'] is int
          ? json['business_id'] as int
          : (int.tryParse(json['business_id']?.toString() ?? '') ?? 1),
      invoiceNumber: (json['invoice_number'] as String?) ?? 'INV-1001',
      referenceNumber: json['reference_number'] as String?,
      poNumber: json['po_number'] as String?,
      invoiceDate: DateTime.tryParse(json['invoice_date'] as String? ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(json['due_date'] as String? ?? '') ?? DateTime.now().add(const Duration(days: 15)),
      customer: CustomerModel.fromJson(json['customer'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => InvoiceItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      gstType: (json['gst_type'] as String?) == 'inter_state' ? GstType.interState : GstType.intraState,
      subtotal: (json['subtotal'] as num).toDouble(),
      totalDiscount: (json['total_discount'] as num?)?.toDouble() ?? 0.0,
      taxableAmount: (json['taxable_amount'] as num).toDouble(),
      totalCgst: (json['total_cgst'] as num?)?.toDouble() ?? 0.0,
      totalSgst: (json['total_sgst'] as num?)?.toDouble() ?? 0.0,
      totalIgst: (json['total_igst'] as num?)?.toDouble() ?? 0.0,
      roundOff: (json['round_off'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num).toDouble(),
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (json['balance_due'] as num).toDouble(),
      status: _parseStatus(json['status'] as String?),
      notes: json['notes'] as String?,
      termsAndConditions: json['terms_and_conditions'] as String?,
      templateId: (json['template_id'] as String?) ?? 'classic',
      templateConfig: json['template_config'] as Map<String, dynamic>?,
      pdfUrl: json['pdf_url'] as String?,
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'invoice_number': invoiceNumber,
      'reference_number': referenceNumber,
      'po_number': poNumber,
      'invoice_date': invoiceDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'customer': customer.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      'gst_type': gstType == GstType.interState ? 'inter_state' : 'intra_state',
      'subtotal': subtotal,
      'total_discount': totalDiscount,
      'taxable_amount': taxableAmount,
      'total_cgst': totalCgst,
      'total_sgst': totalSgst,
      'total_igst': totalIgst,
      'round_off': roundOff,
      'grand_total': grandTotal,
      'total_paid': totalPaid,
      'balance_due': balanceDue,
      'status': status.name,
      'notes': notes,
      'terms_and_conditions': termsAndConditions,
      'template_id': templateId,
      'template_config': templateConfig,
      'pdf_url': pdfUrl,
      'payments': payments.map((e) => e.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static InvoiceStatus _parseStatus(String? str) {
    switch (str?.toLowerCase()) {
      case 'paid':
        return InvoiceStatus.paid;
      case 'partially_paid':
      case 'partiallypaid':
        return InvoiceStatus.partiallyPaid;
      case 'unpaid':
        return InvoiceStatus.unpaid;
      case 'overdue':
        return InvoiceStatus.overdue;
      case 'draft':
        return InvoiceStatus.draft;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      default:
        return InvoiceStatus.unpaid;
    }
  }

  InvoiceModel copyWith({
    int? id,
    int? businessId,
    String? invoiceNumber,
    String? referenceNumber,
    String? poNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    CustomerModel? customer,
    List<InvoiceItemModel>? items,
    GstType? gstType,
    double? subtotal,
    double? totalDiscount,
    double? taxableAmount,
    double? totalCgst,
    double? totalSgst,
    double? totalIgst,
    double? roundOff,
    double? grandTotal,
    double? totalPaid,
    double? balanceDue,
    InvoiceStatus? status,
    String? notes,
    String? termsAndConditions,
    String? templateId,
    Map<String, dynamic>? templateConfig,
    String? pdfUrl,
    List<PaymentModel>? payments,
    DateTime? createdAt,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      poNumber: poNumber ?? this.poNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      gstType: gstType ?? this.gstType,
      subtotal: subtotal ?? this.subtotal,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      totalCgst: totalCgst ?? this.totalCgst,
      totalSgst: totalSgst ?? this.totalSgst,
      totalIgst: totalIgst ?? this.totalIgst,
      roundOff: roundOff ?? this.roundOff,
      grandTotal: grandTotal ?? this.grandTotal,
      totalPaid: totalPaid ?? this.totalPaid,
      balanceDue: balanceDue ?? this.balanceDue,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      templateId: templateId ?? this.templateId,
      templateConfig: templateConfig ?? this.templateConfig,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
