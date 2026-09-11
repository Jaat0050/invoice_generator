import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/customers/presentation/screens/customer_detail_screen.dart';
import '../features/customers/presentation/screens/customer_list_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/invoices/presentation/screens/create_invoice_wizard_screen.dart';
import '../features/invoices/presentation/screens/invoice_detail_screen.dart';
import '../features/invoices/presentation/screens/invoice_list_screen.dart';
import '../features/invoices/presentation/screens/invoice_preview_screen.dart';
import '../features/items/presentation/screens/item_list_screen.dart';
import '../features/onboarding/presentation/screens/business_setup_wizard_screen.dart';
import '../features/payments/presentation/screens/payment_history_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/settings/presentation/screens/app_settings_screen.dart';
import '../features/settings/presentation/screens/bank_upi_settings_screen.dart';
import '../features/settings/presentation/screens/business_profile_screen.dart';
import '../features/settings/presentation/screens/more_menu_screen.dart';
import '../features/templates/presentation/screens/template_selector_screen.dart';
import 'main_shell_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const BusinessSetupWizardScreen(),
      ),

      // Floating Action Route: Create Invoice Wizard
      GoRoute(
        path: '/create-invoice',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateInvoiceWizardScreen(),
      ),

      // Invoice Detail Screen
      GoRoute(
        path: '/invoices/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
          return InvoiceDetailScreen(invoiceId: id);
        },
      ),

      // Invoice PDF Preview & Share Screen
      GoRoute(
        path: '/invoices/:id/preview',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
          return InvoicePreviewScreen(invoiceId: id);
        },
      ),

      // Customer Detail & Ledger Screen
      GoRoute(
        path: '/customers/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
          return CustomerDetailScreen(customerId: id);
        },
      ),

      // Items Catalog Screen
      GoRoute(
        path: '/items',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ItemListScreen(),
      ),

      // Payment History Screen
      GoRoute(
        path: '/payments',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PaymentHistoryScreen(),
      ),

      // Reports & Analytics Screen
      GoRoute(
        path: '/reports',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ReportsScreen(),
      ),

      // Settings Sub-Routes
      GoRoute(
        path: '/business-profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const BusinessProfileScreen(),
      ),
      GoRoute(
        path: '/bank-settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const BankUpiSettingsScreen(),
      ),
      GoRoute(
        path: '/templates',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TemplateSelectorScreen(),
      ),
      GoRoute(
        path: '/app-settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AppSettingsScreen(),
      ),

      // Stateful Bottom Shell Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Branch 2: Invoices List
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/invoices',
                builder: (context, state) => const InvoiceListScreen(),
              ),
            ],
          ),

          // Branch 3: Customers List
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customers',
                builder: (context, state) => const CustomerListScreen(),
              ),
            ],
          ),

          // Branch 4: More / Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreMenuScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
