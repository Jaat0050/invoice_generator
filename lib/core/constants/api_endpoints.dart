class ApiEndpoints {
  ApiEndpoints._();

  // Base URL (Configure for dev / staging / prod)
  static const String baseUrl = 'https://api.invoicesaas.example.com/api/v1';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String me = '/auth/me';

  // Business
  static const String business = '/business';
  static const String businessLogo = '/business/logo';
  static const String businessSignature = '/business/signature';

  // Customers
  static const String customers = '/customers';
  static String customer(int id) => '/customers/$id';
  static String customerLedger(int id) => '/customers/$id/ledger';

  // Items / Inventory
  static const String items = '/items';
  static String item(int id) => '/items/$id';

  // Invoices
  static const String invoices = '/invoices';
  static String invoice(int id) => '/invoices/$id';
  static String invoicePdf(int id) => '/invoices/$id/pdf';
  static String invoiceShare(int id) => '/invoices/$id/share';
  static String invoiceCancel(int id) => '/invoices/$id/cancel';
  static String invoiceDuplicate(int id) => '/invoices/$id/duplicate';

  // Payments
  static const String payments = '/payments';
  static String invoicePayments(int invoiceId) => '/invoices/$invoiceId/payments';
  static String payment(int id) => '/payments/$id';

  // Templates
  static const String templates = '/templates';
  static String template(String id) => '/templates/$id';

  // Dashboard & Reports
  static const String dashboardStats = '/dashboard/stats';
  static const String salesReport = '/reports/sales';
  static const String taxReport = '/reports/tax';
  static const String overdueReport = '/reports/overdue';
}
