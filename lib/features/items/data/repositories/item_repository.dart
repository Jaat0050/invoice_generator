import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../models/item_model.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository();
});

class ItemRepository {
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

  Future<List<ItemModel>> getItems({String? searchQuery}) async {
    final sb = _supabase;
    _assertAuthenticated(sb);

    try {
      var query = sb!.from('items').select();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,hsn_sac.ilike.%$searchQuery%,sku.ilike.%$searchQuery%');
      }

      final res = await query.order('name', ascending: true);
      final list = res as List<dynamic>;

      return list.map((item) {
        return ItemModel(
          id: item['id'] is int ? item['id'] as int : int.tryParse(item['id'].toString()) ?? 1,
          businessId: 1,
          name: item['name'] as String,
          sku: item['sku'] as String?,
          hsnSac: item['hsn_sac'] as String?,
          unit: (item['unit'] as String?) ?? 'PCS',
          rate: (item['rate'] as num?)?.toDouble() ?? 0.0,
          taxRate: (item['tax_rate'] as num?)?.toDouble() ?? 18.0,
          itemType: (item['item_type'] as String?) ?? 'product',
          description: item['description'] as String?,
          defaultDiscount: (item['default_discount'] as num?)?.toDouble() ?? 0.0,
          isTaxInclusive: (item['is_tax_inclusive'] as bool?) ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('Supabase getItems error: $e');
      rethrow;
    }
  }

  Future<ItemModel> addItem(ItemModel item) async {
    final sb = _supabase;
    _assertAuthenticated(sb);
    final user = sb!.auth.currentUser!;

    try {
      final inserted = await sb.from('items').insert({
        'user_id': user.id,
        'name': item.name,
        'sku': item.sku,
        'hsn_sac': item.hsnSac,
        'unit': item.unit,
        'rate': item.rate,
        'tax_rate': item.taxRate,
        'item_type': item.itemType,
        'description': item.description,
        'default_discount': item.defaultDiscount,
        'is_tax_inclusive': item.isTaxInclusive,
      }).select().single();

      return ItemModel(
        id: inserted['id'] is int ? inserted['id'] as int : int.tryParse(inserted['id'].toString()) ?? 1,
        businessId: 1,
        name: inserted['name'] as String,
        sku: inserted['sku'] as String?,
        hsnSac: inserted['hsn_sac'] as String?,
        unit: (inserted['unit'] as String?) ?? 'PCS',
        rate: (inserted['rate'] as num?)?.toDouble() ?? item.rate,
        taxRate: (inserted['tax_rate'] as num?)?.toDouble() ?? item.taxRate,
        itemType: (inserted['item_type'] as String?) ?? item.itemType,
        description: inserted['description'] as String?,
        defaultDiscount: (inserted['default_discount'] as num?)?.toDouble() ?? 0.0,
        isTaxInclusive: (inserted['is_tax_inclusive'] as bool?) ?? false,
      );
    } catch (e) {
      debugPrint('Supabase addItem error: $e');
      rethrow;
    }
  }
}
