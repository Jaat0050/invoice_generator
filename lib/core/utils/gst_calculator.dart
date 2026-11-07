enum GstSupplyType {
  intraState, // CGST + SGST
  interState, // IGST
}

class LineItemCalculation {
  final double quantity;
  final double rate;
  final double grossAmount;
  final double discountAmount;
  final double taxableAmount;
  final double taxRate;
  final double cgstRate;
  final double cgstAmount;
  final double sgstRate;
  final double sgstAmount;
  final double igstRate;
  final double igstAmount;
  final double totalAmount;

  const LineItemCalculation({
    required this.quantity,
    required this.rate,
    required this.grossAmount,
    required this.discountAmount,
    required this.taxableAmount,
    required this.taxRate,
    required this.cgstRate,
    required this.cgstAmount,
    required this.sgstRate,
    required this.sgstAmount,
    required this.igstRate,
    required this.igstAmount,
    required this.totalAmount,
  });
}

class InvoiceTotalsCalculation {
  final double subtotal; // Sum of taxable amounts
  final double totalDiscount;
  final double taxableAmount;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double totalTax;
  final double exactTotal;
  final double roundOff;
  final double grandTotal;
  final double totalPaid;
  final double balanceDue;

  const InvoiceTotalsCalculation({
    required this.subtotal,
    required this.totalDiscount,
    required this.taxableAmount,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalIgst,
    required this.totalTax,
    required this.exactTotal,
    required this.roundOff,
    required this.grandTotal,
    required this.totalPaid,
    required this.balanceDue,
  });
}

class GstCalculator {
  GstCalculator._();

  /// Calculates a single line item given quantity, rate, discount and tax rate.
  static LineItemCalculation calculateLineItem({
    required double quantity,
    required double rate,
    double discountPercent = 0.0,
    double discountFixed = 0.0,
    required double taxRate,
    required GstSupplyType supplyType,
    bool isGst = true,
  }) {
    final gross = quantity * rate;
    
    // Discount Calculation: if discountPercent is specified (>0), use percent, otherwise fixed
    double discount = 0.0;
    if (discountPercent > 0) {
      discount = gross * (discountPercent / 100);
    } else {
      discount = discountFixed;
    }
    if (discount > gross) discount = gross;

    final taxable = gross - discount;

    double effectiveTaxRate = isGst ? taxRate : 0.0;
    double cgstRate = 0.0;
    double cgstAmount = 0.0;
    double sgstRate = 0.0;
    double sgstAmount = 0.0;
    double igstRate = 0.0;
    double igstAmount = 0.0;

    if (isGst && effectiveTaxRate > 0) {
      if (supplyType == GstSupplyType.intraState) {
        cgstRate = effectiveTaxRate / 2;
        sgstRate = effectiveTaxRate / 2;
        cgstAmount = taxable * (cgstRate / 100);
        sgstAmount = taxable * (sgstRate / 100);
      } else {
        igstRate = effectiveTaxRate;
        igstAmount = taxable * (igstRate / 100);
      }
    }

    final totalAmount = taxable + cgstAmount + sgstAmount + igstAmount;

    return LineItemCalculation(
      quantity: quantity,
      rate: rate,
      grossAmount: gross,
      discountAmount: discount,
      taxableAmount: taxable,
      taxRate: effectiveTaxRate,
      cgstRate: cgstRate,
      cgstAmount: cgstAmount,
      sgstRate: sgstRate,
      sgstAmount: sgstAmount,
      igstRate: igstRate,
      igstAmount: igstAmount,
      totalAmount: totalAmount,
    );
  }

  /// Calculates complete invoice totals including taxes, extra invoice discounts, round-off, and balance due.
  static InvoiceTotalsCalculation calculateInvoiceTotals({
    required List<LineItemCalculation> items,
    double invoiceDiscount = 0.0,
    double totalPaid = 0.0,
    bool enableRoundOff = true,
  }) {
    double subtotal = 0.0;
    double totalLineDiscounts = 0.0;
    double taxableSum = 0.0;
    double totalCgst = 0.0;
    double totalSgst = 0.0;
    double totalIgst = 0.0;

    for (final item in items) {
      subtotal += item.grossAmount;
      totalLineDiscounts += item.discountAmount;
      taxableSum += item.taxableAmount;
      totalCgst += item.cgstAmount;
      totalSgst += item.sgstAmount;
      totalIgst += item.igstAmount;
    }

    final totalDiscount = totalLineDiscounts + invoiceDiscount;
    final totalTax = totalCgst + totalSgst + totalIgst;
    final exactTotal = taxableSum + totalTax - invoiceDiscount;

    double grandTotal = exactTotal;
    double roundOff = 0.0;

    if (enableRoundOff) {
      grandTotal = exactTotal.roundToDouble();
      roundOff = grandTotal - exactTotal;
    }

    final balanceDue = (grandTotal - totalPaid).clamp(0.0, double.infinity);

    return InvoiceTotalsCalculation(
      subtotal: subtotal,
      totalDiscount: totalDiscount,
      taxableAmount: taxableSum,
      totalCgst: totalCgst,
      totalSgst: totalSgst,
      totalIgst: totalIgst,
      totalTax: totalTax,
      exactTotal: exactTotal,
      roundOff: roundOff,
      grandTotal: grandTotal,
      totalPaid: totalPaid,
      balanceDue: balanceDue,
    );
  }

  /// Helper to determine whether two state codes or state names constitute Intra-State or Inter-State supply.
  static GstSupplyType determineSupplyType({
    required String? businessState,
    required String? customerBillingState,
  }) {
    if (businessState == null ||
        customerBillingState == null ||
        businessState.trim().isEmpty ||
        customerBillingState.trim().isEmpty) {
      return GstSupplyType.intraState;
    }

    final cState = customerBillingState.trim().toLowerCase();
    if (cState == 'none' ||
        cState == 'n/a' ||
        cState == 'not applicable' ||
        cState.startsWith('none') ||
        cState.contains('not applicable')) {
      return GstSupplyType.intraState;
    }

    final bState = businessState.trim().toLowerCase();
    return (bState == cState) ? GstSupplyType.intraState : GstSupplyType.interState;
  }
}
