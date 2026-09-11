import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_generator/features/customers/data/models/customer_model.dart';
import 'package:invoice_generator/features/dashboard/data/models/dashboard_stats.dart';
import 'package:invoice_generator/features/payments/data/models/payment_model.dart';
import '../models/invoice_item_model.dart';
import '../models/invoice_model.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository();
});

class InvoiceRepository {
  final List<InvoiceModel> _mockInvoices = [
    InvoiceModel(
      id: 1,
      businessId: 1,
      invoiceNumber: 'INV-1001',
      referenceNumber: 'PO-2026-89',
      invoiceDate: DateTime.now().subtract(const Duration(days: 10)),
      dueDate: DateTime.now().add(const Duration(days: 5)),
      customer: const CustomerModel(
        id: 1,
        businessId: 1,
        name: 'Rahul Verma',
        companyName: 'ABC Enterprises Pvt Ltd',
        phone: '+91 98220 12345',
        gstin: '27AAACA4567D1Z2',
        billingAddress: '45, Nariman Point, Marine Drive',
        billingCity: 'Mumbai',
        billingState: 'Maharashtra',
        billingStateCode: '27',
      ),
      items: const [
        InvoiceItemModel(
          id: 1,
          description: 'MacBook Pro 16" M3 Max',
          hsnSac: '84713010',
          quantity: 2,
          unit: 'NOS',
          rate: 249900.0,
          taxableAmount: 499800.0,
          taxRate: 18.0,
          cgstAmount: 44982.0,
          sgstAmount: 44982.0,
          totalAmount: 589764.0,
        ),
      ],
      gstType: GstType.intraState,
      subtotal: 499800.0,
      taxableAmount: 499800.0,
      totalCgst: 44982.0,
      totalSgst: 44982.0,
      totalIgst: 0.0,
      roundOff: 0.0,
      grandTotal: 589764.0,
      totalPaid: 300000.0,
      balanceDue: 289764.0,
      status: InvoiceStatus.partiallyPaid,
      payments: [
        PaymentModel(
          id: 1,
          invoiceId: 1,
          amount: 300000.0,
          method: PaymentMethod.upi,
          paymentDate: DateTime.now().subtract(const Duration(days: 8)),
          transactionId: 'UPI-9832749102',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    InvoiceModel(
      id: 2,
      businessId: 1,
      invoiceNumber: 'INV-1002',
      invoiceDate: DateTime.now().subtract(const Duration(days: 25)),
      dueDate: DateTime.now().subtract(const Duration(days: 5)),
      customer: const CustomerModel(
        id: 2,
        businessId: 1,
        name: 'Priya Sharma',
        companyName: 'TechVision Infotech',
        phone: '+91 98450 98765',
        gstin: '29BBBCB8910E1Z9',
        billingAddress: '12th Cross, Indiranagar',
        billingCity: 'Bengaluru',
        billingState: 'Karnataka',
        billingStateCode: '29',
      ),
      items: const [
        InvoiceItemModel(
          id: 2,
          description: 'Cloud Infrastructure Architecture & Consulting',
          hsnSac: '998315',
          quantity: 20,
          unit: 'HRS',
          rate: 7500.0,
          taxableAmount: 150000.0,
          taxRate: 18.0,
          igstAmount: 27000.0,
          totalAmount: 177000.0,
        ),
      ],
      gstType: GstType.interState,
      subtotal: 150000.0,
      taxableAmount: 150000.0,
      totalCgst: 0.0,
      totalSgst: 0.0,
      totalIgst: 27000.0,
      roundOff: 0.0,
      grandTotal: 177000.0,
      totalPaid: 0.0,
      balanceDue: 177000.0,
      status: InvoiceStatus.overdue,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    InvoiceModel(
      id: 3,
      businessId: 1,
      invoiceNumber: 'INV-1003',
      invoiceDate: DateTime.now().subtract(const Duration(days: 2)),
      dueDate: DateTime.now().add(const Duration(days: 13)),
      customer: const CustomerModel(
        id: 3,
        businessId: 1,
        name: 'Vikram Mehta',
        companyName: 'Mehta Logistics & Supply',
        phone: '+91 99100 54321',
        gstin: '07CCCCM1122F1Z8',
        billingAddress: 'Plot 88, Okhla Industrial Area Phase 3',
        billingCity: 'New Delhi',
        billingState: 'Delhi',
        billingStateCode: '07',
      ),
      items: const [
        InvoiceItemModel(
          id: 3,
          description: 'Dell UltraSharp 27" 4K Monitor',
          hsnSac: '85285200',
          quantity: 2,
          unit: 'NOS',
          rate: 54999.0,
          taxableAmount: 109998.0,
          taxRate: 18.0,
          igstAmount: 19799.64,
          totalAmount: 129797.64,
        ),
      ],
      gstType: GstType.interState,
      subtotal: 109998.0,
      taxableAmount: 109998.0,
      totalCgst: 0.0,
      totalSgst: 0.0,
      totalIgst: 19799.64,
      roundOff: 0.36,
      grandTotal: 129798.0,
      totalPaid: 129798.0,
      balanceDue: 0.0,
      status: InvoiceStatus.paid,
      payments: [
        PaymentModel(
          id: 2,
          invoiceId: 3,
          amount: 129798.0,
          method: PaymentMethod.bankTransfer,
          paymentDate: DateTime.now().subtract(const Duration(days: 1)),
          transactionId: 'NEFT-589201934',
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  Future<List<InvoiceModel>> getInvoices({InvoiceStatus? filterStatus}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (filterStatus == null) return List.unmodifiable(_mockInvoices);
    return _mockInvoices.where((inv) => inv.status == filterStatus).toList();
  }

  Future<InvoiceModel> getInvoiceById(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockInvoices.firstWhere((inv) => inv.id == id);
  }

  Future<InvoiceModel> createInvoice(InvoiceModel invoice) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newInv = invoice.copyWith(
      id: _mockInvoices.length + 1,
      createdAt: DateTime.now(),
    );
    _mockInvoices.insert(0, newInv);
    return newInv;
  }

  Future<InvoiceModel> recordPayment({
    required int invoiceId,
    required double amount,
    required PaymentMethod method,
    String? transactionId,
    String? note,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _mockInvoices.indexWhere((inv) => inv.id == invoiceId);
    if (index == -1) throw Exception('Invoice not found');

    final invoice = _mockInvoices[index];
    final newPayment = PaymentModel(
      id: DateTime.now().millisecondsSinceEpoch,
      invoiceId: invoiceId,
      amount: amount,
      method: method,
      paymentDate: DateTime.now(),
      transactionId: transactionId,
      note: note,
      createdAt: DateTime.now(),
    );

    final updatedPayments = [...invoice.payments, newPayment];
    final updatedPaid = invoice.totalPaid + amount;
    final updatedBalance = (invoice.grandTotal - updatedPaid).clamp(0.0, double.infinity);

    InvoiceStatus newStatus = invoice.status;
    if (updatedBalance <= 0.01) {
      newStatus = InvoiceStatus.paid;
    } else if (updatedPaid > 0) {
      newStatus = InvoiceStatus.partiallyPaid;
    }

    final updatedInvoice = invoice.copyWith(
      totalPaid: updatedPaid,
      balanceDue: updatedBalance,
      status: newStatus,
      payments: updatedPayments,
    );

    _mockInvoices[index] = updatedInvoice;
    return updatedInvoice;
  }

  Future<DashboardStats> getDashboardStats() async {
    await Future.delayed(const Duration(milliseconds: 300));
    double totalSales = 0.0;
    double totalPaid = 0.0;
    double totalPending = 0.0;
    double totalOverdue = 0.0;
    int paidCount = 0;
    int unpaidCount = 0;
    int overdueCount = 0;

    for (final inv in _mockInvoices) {
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
      totalInvoicesCount: _mockInvoices.length,
      paidInvoicesCount: paidCount,
      unpaidInvoicesCount: unpaidCount,
      overdueInvoicesCount: overdueCount,
      recentInvoices: _mockInvoices.take(5).toList(),
      revenueChartData: const [
        MonthlyRevenue(month: 'May', revenue: 250000.0),
        MonthlyRevenue(month: 'Jun', revenue: 420000.0),
        MonthlyRevenue(month: 'Jul', revenue: 380000.0),
        MonthlyRevenue(month: 'Aug', revenue: 610000.0),
        MonthlyRevenue(month: 'Sep', revenue: 896562.0),
      ],
    );
  }
}
