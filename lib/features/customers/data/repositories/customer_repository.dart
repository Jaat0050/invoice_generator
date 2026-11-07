import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../models/customer_model.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

class CustomerRepository {
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

  Future<List<CustomerModel>> getCustomers({String? searchQuery}) async {
    final sb = _supabase;
    _assertAuthenticated(sb);

    try {
      var query = sb!.from('customers').select('*, invoices(grand_total, total_paid, balance_due)');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,company_name.ilike.%$searchQuery%,phone.ilike.%$searchQuery%');
      }

      final res = await query.order('created_at', ascending: false);
      final list = res as List<dynamic>;

      return list.map((item) {
        final invoices = (item['invoices'] as List<dynamic>?) ?? [];
        double totalSales = 0.0;
        double totalPaid = 0.0;
        double outstanding = 0.0;

        for (final inv in invoices) {
          totalSales += (inv['grand_total'] as num?)?.toDouble() ?? 0.0;
          totalPaid += (inv['total_paid'] as num?)?.toDouble() ?? 0.0;
          outstanding += (inv['balance_due'] as num?)?.toDouble() ?? 0.0;
        }

        return CustomerModel(
          id: item['id'] is int ? item['id'] as int : int.tryParse(item['id'].toString()) ?? 1,
          businessId: 1,
          name: item['name'] as String,
          companyName: item['company_name'] as String?,
          email: item['email'] as String?,
          phone: (item['phone'] as String?) ?? '',
          gstin: item['gstin'] as String?,
          billingAddress: item['billing_address'] as String?,
          billingCity: item['billing_city'] as String?,
          billingState: (item['billing_state'] as String?) ?? 'Maharashtra',
          billingStateCode: (item['billing_state_code'] as String?) ?? '27',
          billingPincode: item['billing_pincode'] as String?,
          shippingAddress: item['shipping_address'] as String?,
          totalSales: totalSales,
          totalPaid: totalPaid,
          outstandingAmount: outstanding,
          createdAt: DateTime.tryParse(item['created_at'] as String? ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Supabase getCustomers error: $e');
      rethrow;
    }
  }

  Future<CustomerModel> getCustomerById(int id) async {
    final sb = _supabase;
    _assertAuthenticated(sb);

    try {
      final item = await sb!
          .from('customers')
          .select('*, invoices(grand_total, total_paid, balance_due)')
          .eq('id', id)
          .single();

      final invoices = (item['invoices'] as List<dynamic>?) ?? [];
      double totalSales = 0.0;
      double totalPaid = 0.0;
      double outstanding = 0.0;

      for (final inv in invoices) {
        totalSales += (inv['grand_total'] as num?)?.toDouble() ?? 0.0;
        totalPaid += (inv['total_paid'] as num?)?.toDouble() ?? 0.0;
        outstanding += (inv['balance_due'] as num?)?.toDouble() ?? 0.0;
      }

      return CustomerModel(
        id: item['id'] is int ? item['id'] as int : int.tryParse(item['id'].toString()) ?? id,
        businessId: 1,
        name: item['name'] as String,
        companyName: item['company_name'] as String?,
        email: item['email'] as String?,
        phone: (item['phone'] as String?) ?? '',
        gstin: item['gstin'] as String?,
        billingAddress: item['billing_address'] as String?,
        billingCity: item['billing_city'] as String?,
        billingState: (item['billing_state'] as String?) ?? 'Maharashtra',
        billingStateCode: (item['billing_state_code'] as String?) ?? '27',
        billingPincode: item['billing_pincode'] as String?,
        shippingAddress: item['shipping_address'] as String?,
        totalSales: totalSales,
        totalPaid: totalPaid,
        outstandingAmount: outstanding,
        createdAt: DateTime.tryParse(item['created_at'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Supabase getCustomerById error: $e');
      rethrow;
    }
  }

  Future<CustomerModel> addCustomer(CustomerModel customer) async {
    final sb = _supabase;
    _assertAuthenticated(sb);
    final user = sb!.auth.currentUser!;

    try {
      final inserted = await sb.from('customers').insert({
        'user_id': user.id,
        'name': customer.name,
        'company_name': customer.companyName,
        'email': customer.email,
        'phone': customer.phone,
        'gstin': customer.gstin,
        'billing_address': customer.billingAddress,
        'billing_city': customer.billingCity,
        'billing_state': customer.billingState,
        'billing_state_code': customer.billingStateCode,
        'billing_pincode': customer.billingPincode,
        'shipping_address': customer.shippingAddress,
      }).select().single();

      return CustomerModel(
        id: inserted['id'] is int ? inserted['id'] as int : int.tryParse(inserted['id'].toString()) ?? 1,
        businessId: 1,
        name: inserted['name'] as String,
        companyName: inserted['company_name'] as String?,
        email: inserted['email'] as String?,
        phone: inserted['phone'] as String,
        gstin: inserted['gstin'] as String?,
        billingAddress: inserted['billing_address'] as String?,
        billingCity: inserted['billing_city'] as String?,
        billingState: (inserted['billing_state'] as String?) ?? 'Maharashtra',
        billingStateCode: (inserted['billing_state_code'] as String?) ?? '27',
        billingPincode: inserted['billing_pincode'] as String?,
        shippingAddress: inserted['shipping_address'] as String?,
        totalSales: 0.0,
        totalPaid: 0.0,
        outstandingAmount: 0.0,
        createdAt: DateTime.tryParse(inserted['created_at'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Supabase addCustomer error: $e');
      rethrow;
    }
  }

  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    final sb = _supabase;
    _assertAuthenticated(sb);
    final user = sb!.auth.currentUser!;

    try {
      final updated = await sb
          .from('customers')
          .update({
            'name': customer.name,
            'company_name': customer.companyName,
            'email': customer.email,
            'phone': customer.phone,
            'gstin': customer.gstin,
            'billing_address': customer.billingAddress,
            'billing_city': customer.billingCity,
            'billing_state': customer.billingState,
            'billing_state_code': customer.billingStateCode,
            'billing_pincode': customer.billingPincode,
            'shipping_address': customer.shippingAddress,
          })
          .eq('id', customer.id)
          .eq('user_id', user.id)
          .select()
          .single();

      return customer.copyWith(
        name: updated['name'] as String,
        companyName: updated['company_name'] as String?,
        email: updated['email'] as String?,
        phone: updated['phone'] as String,
        gstin: updated['gstin'] as String?,
        billingAddress: updated['billing_address'] as String?,
        billingCity: updated['billing_city'] as String?,
        billingState: (updated['billing_state'] as String?) ?? customer.billingState,
        billingStateCode: (updated['billing_state_code'] as String?) ?? customer.billingStateCode,
        billingPincode: updated['billing_pincode'] as String?,
        shippingAddress: updated['shipping_address'] as String?,
      );
    } catch (e) {
      debugPrint('Supabase updateCustomer error: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomer(int id) async {
    final sb = _supabase;
    _assertAuthenticated(sb);
    final user = sb!.auth.currentUser!;

    try {
      await sb.from('customers').delete().eq('id', id).eq('user_id', user.id);
    } catch (e) {
      debugPrint('Supabase deleteCustomer error: $e');
      rethrow;
    }
  }
}
