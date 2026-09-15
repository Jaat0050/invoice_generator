import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import 'package:invoice_generator/features/customers/data/models/customer_model.dart';
import 'package:invoice_generator/features/dashboard/data/models/dashboard_stats.dart';
import 'package:invoice_generator/features/payments/data/models/payment_model.dart';
import '../models/invoice_item_model.dart';
import '../models/invoice_model.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository();
});

class InvoiceRepository {
  SupabaseClient? get _supabase {
    if (SupabaseConfig.isConfigured) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void _assertAuthenticated(SupabaseClient? sb) {
    if (sb == null) {
      throw const AuthException('Supabase backend is not initialized.');
    }
    final session = sb.auth.currentSession;
    final user = sb.auth.currentUser;
    if (session == null || session.isExpired || user == null) {
      throw const AuthException('Session expired or inactive. Please log in to continue.');
    }
  }

  Future<List<InvoiceModel>> getInvoices({InvoiceStatus? filterStatus}) async {
    final sb = _supabase;
    _assertAuthenticated(sb);

    try {
      var query = sb!.from('invoices').select('*, invoice_items(*), payments(*)');
      if (filterStatus != null) {
        query = query.eq('status', filterStatus.name);
      }

      final res = await query.order('created_at', ascending: false);
      final list = res as List<dynamic>;

      return list.map((item) => _mapSupabaseInvoice(item)).toList();
    } catch (e) {
      debugPrint('Supabase getInvoices error: $e');
      rethrow;
    }
  }

  Future<InvoiceModel> getInvoiceById(int id) async {
    final sb = _supabase;
    _assertAuthenticated(sb);

    try {
      final res = await sb!
          .from('invoices')
          .select('*, invoice_items(*), payments(*)')
          .eq('id', id)
          .single();

      return _mapSupabaseInvoice(res);
    } catch (e) {
      debugPrint('Supabase getInvoiceById error: $e');
      rethrow;
    }
  }

  Future<InvoiceModel> createInvoice(InvoiceModel invoice) async {
    final sb = _supabase;
    _assertAuthenticated(sb);
    final user = sb!.auth.currentUser!;
      try {
        // 1. Insert Invoice row
        final invRes = await sb.from('invoices').insert({
          'user_id': user.id,
          'invoice_number': invoice.invoiceNumber,
          'reference_number': invoice.referenceNumber,
          'po_number': invoice.poNumber,
          'invoice_date': invoice.invoiceDate.toIso8601String(),
          'due_date': invoice.dueDate.toIso8601String(),
          'customer_id': invoice.customer.id > 0 ? invoice.customer.id : null,
          'customer_snapshot': invoice.customer.toJson(),
          'gst_type': invoice.gstType.name,
          'subtotal': invoice.subtotal,
          'total_discount': invoice.totalDiscount,
          'taxable_amount': invoice.taxableAmount,
          'total_cgst': invoice.totalCgst,
          'total_sgst': invoice.totalSgst,
          'total_igst': invoice.totalIgst,
          'round_off': invoice.roundOff,
          'grand_total': invoice.grandTotal,
          'total_paid': invoice.totalPaid,
          'balance_due': invoice.balanceDue,
          'status': invoice.status.name,
          'notes': invoice.notes,
          'terms_and_conditions': invoice.termsAndConditions,
          'template_id': invoice.templateId,
          'template_config': invoice.templateConfig,
        }).select().single();

        final invoiceId = invRes['id'] is int ? invRes['id'] as int : int.parse(invRes['id'].toString());

        // 2. Insert Invoice Line Items
        if (invoice.items.isNotEmpty) {
          final itemsToInsert = invoice.items.map((item) {
            return {
              'invoice_id': invoiceId,
              'item_id': item.itemId,
              'description': item.description,
              'hsn_sac': item.hsnSac,
              'quantity': item.quantity,
              'unit': item.unit,
              'rate': item.rate,
              'discount_rate': item.discountPercent,
              'discount_amount': item.discountAmount,
              'taxable_amount': item.taxableAmount,
              'tax_rate': item.taxRate,
              'cgst_amount': item.cgstAmount,
              'sgst_amount': item.sgstAmount,
              'igst_amount': item.igstAmount,
              'total_amount': item.totalAmount,
            };
          }).toList();

          await sb.from('invoice_items').insert(itemsToInsert);
        }

        // 3. Update business next_invoice_number
        try {
          final nextNumMatch = RegExp(r'\d+').firstMatch(invoice.invoiceNumber);
          if (nextNumMatch != null) {
            final nextNum = (int.tryParse(nextNumMatch.group(0) ?? '') ?? 1000) + 1;
            await sb.from('businesses').update({'next_invoice_number': nextNum}).eq('user_id', user.id);
          }
        } catch (_) {}

        return getInvoiceById(invoiceId);
      } catch (e) {
        debugPrint('Supabase createInvoice error: $e');
        rethrow;
      }
  }

  Future<InvoiceModel> recordPayment({
    required int invoiceId,
    required double amount,
    required PaymentMethod method,
    String? transactionId,
    String? note,
  }) async {
    final sb = _supabase;
    _assertAuthenticated(sb);
    final user = sb!.auth.currentUser!;

    try {
      // 1. Insert Payment
      await sb.from('payments').insert({
        'user_id': user.id,
        'invoice_id': invoiceId,
        'amount': amount,
        'method': method.name,
        'payment_date': DateTime.now().toIso8601String(),
        'transaction_id': transactionId,
        'note': note,
      });

      // 2. Get current invoice
      final inv = await getInvoiceById(invoiceId);
      final newTotalPaid = inv.totalPaid + amount;
      final newBalanceDue = (inv.grandTotal - newTotalPaid).clamp(0.0, double.infinity);
      final newStatus = newBalanceDue <= 0.01 ? 'paid' : 'partiallyPaid';

      // 3. Update Invoice
      await sb.from('invoices').update({
        'total_paid': newTotalPaid,
        'balance_due': newBalanceDue,
        'status': newStatus,
      }).eq('id', invoiceId);

      return getInvoiceById(invoiceId);
    } catch (e) {
      debugPrint('Supabase recordPayment error: $e');
      rethrow;
    }
  }

  Future<DashboardStats> getDashboardStats() async {
    final invoices = await getInvoices();
    double totalSales = 0.0;
    double totalPaid = 0.0;
    double totalPending = 0.0;
    double totalOverdue = 0.0;
    int paidCount = 0;
    int unpaidCount = 0;
    int overdueCount = 0;

    for (final inv in invoices) {
      totalSales += inv.grandTotal;
      totalPaid += inv.totalPaid;
      if (inv.status == InvoiceStatus.overdue) {
        totalOverdue += inv.balanceDue;
        overdueCount++;
      } else if (inv.status != InvoiceStatus.paid && inv.status != InvoiceStatus.cancelled) {
        totalPending += inv.balanceDue;
        unpaidCount++;
      } else if (inv.status == InvoiceStatus.paid) {
        paidCount++;
      }
    }

    return DashboardStats(
      totalSales: totalSales,
      totalPaid: totalPaid,
      totalPending: totalPending,
      totalOverdue: totalOverdue,
      totalInvoicesCount: invoices.length,
      paidInvoicesCount: paidCount,
      unpaidInvoicesCount: unpaidCount,
      overdueInvoicesCount: overdueCount,
      recentInvoices: invoices.take(5).toList(),
      revenueChartData: invoices.isEmpty
          ? const []
          : [
              MonthlyRevenue(month: 'May', revenue: totalSales * 0.15),
              MonthlyRevenue(month: 'Jun', revenue: totalSales * 0.25),
              MonthlyRevenue(month: 'Jul', revenue: totalSales * 0.20),
              MonthlyRevenue(month: 'Aug', revenue: totalSales * 0.35),
              MonthlyRevenue(month: 'Sep', revenue: totalSales),
            ],
    );
  }

  InvoiceModel _mapSupabaseInvoice(Map<String, dynamic> item) {
    final customerJson = item['customer_snapshot'] as Map<String, dynamic>? ?? {};
    final customer = CustomerModel.fromJson(customerJson);

    final rawItems = (item['invoice_items'] as List<dynamic>?) ?? [];
    final items = rawItems.map((i) {
      return InvoiceItemModel(
        id: i['id'] is int ? i['id'] as int : int.tryParse(i['id'].toString()),
        itemId: i['item_id'] is int ? i['item_id'] as int : int.tryParse(i['item_id']?.toString() ?? ''),
        description: (i['description'] as String?) ?? '',
        hsnSac: i['hsn_sac'] as String?,
        quantity: (i['quantity'] as num?)?.toDouble() ?? 1.0,
        unit: (i['unit'] as String?) ?? 'PCS',
        rate: (i['rate'] as num?)?.toDouble() ?? 0.0,
        discountPercent: (i['discount_rate'] as num?)?.toDouble() ?? 0.0,
        discountAmount: (i['discount_amount'] as num?)?.toDouble() ?? 0.0,
        taxableAmount: (i['taxable_amount'] as num?)?.toDouble() ?? 0.0,
        taxRate: (i['tax_rate'] as num?)?.toDouble() ?? 18.0,
        cgstAmount: (i['cgst_amount'] as num?)?.toDouble() ?? 0.0,
        sgstAmount: (i['sgst_amount'] as num?)?.toDouble() ?? 0.0,
        igstAmount: (i['igst_amount'] as num?)?.toDouble() ?? 0.0,
        totalAmount: (i['total_amount'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    final rawPayments = (item['payments'] as List<dynamic>?) ?? [];
    final payments = rawPayments.map((p) => PaymentModel.fromJson(p)).toList();

    return InvoiceModel(
      id: item['id'] is int ? item['id'] as int : int.tryParse(item['id'].toString()) ?? 1,
      businessId: 1,
      invoiceNumber: item['invoice_number'] as String,
      referenceNumber: item['reference_number'] as String?,
      poNumber: item['po_number'] as String?,
      invoiceDate: DateTime.tryParse(item['invoice_date'] as String? ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(item['due_date'] as String? ?? '') ?? DateTime.now(),
      customer: customer,
      items: items,
      gstType: item['gst_type'] == 'interState' ? GstType.interState : GstType.intraState,
      subtotal: (item['subtotal'] as num?)?.toDouble() ?? 0.0,
      totalDiscount: (item['total_discount'] as num?)?.toDouble() ?? 0.0,
      taxableAmount: (item['taxable_amount'] as num?)?.toDouble() ?? 0.0,
      totalCgst: (item['total_cgst'] as num?)?.toDouble() ?? 0.0,
      totalSgst: (item['total_sgst'] as num?)?.toDouble() ?? 0.0,
      totalIgst: (item['total_igst'] as num?)?.toDouble() ?? 0.0,
      roundOff: (item['round_off'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (item['grand_total'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (item['total_paid'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (item['balance_due'] as num?)?.toDouble() ?? 0.0,
      status: _parseInvoiceStatus(item['status'] as String?),
      notes: item['notes'] as String?,
      termsAndConditions: item['terms_and_conditions'] as String?,
      templateId: (item['template_id'] as String?) ?? 'classic',
      templateConfig: (item['template_config'] as Map<String, dynamic>?) ?? {},
      pdfUrl: item['pdf_url'] as String?,
      payments: payments,
      createdAt: DateTime.tryParse(item['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  InvoiceStatus _parseInvoiceStatus(String? status) {
    switch (status) {
      case 'paid':
        return InvoiceStatus.paid;
      case 'partiallyPaid':
        return InvoiceStatus.partiallyPaid;
      case 'overdue':
        return InvoiceStatus.overdue;
      case 'draft':
        return InvoiceStatus.draft;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      case 'unpaid':
      default:
        return InvoiceStatus.unpaid;
    }
  }
}
