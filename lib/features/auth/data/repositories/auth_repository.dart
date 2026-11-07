import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/business_model.dart';
import '../models/user_model.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return ApiClient(storageService: storage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthRepository(client, storage);
});

class BusinessNotifier extends AsyncNotifier<BusinessModel> {
  @override
  Future<BusinessModel> build() async {
    final repo = ref.watch(authRepositoryProvider);
    return repo.getActiveBusiness();
  }

  Future<void> updateBusiness(BusinessModel updated) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final saved = await repo.updateBusiness(updated);
    state = AsyncValue.data(saved);
  }
}

final businessNotifierProvider =
    AsyncNotifierProvider<BusinessNotifier, BusinessModel>(BusinessNotifier.new);

class AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService storage;

  BusinessModel _activeBusiness = const BusinessModel(
    id: 1,
    name: 'My Business',
    legalName: null,
    gstin: null,
    pan: null,
    email: null,
    phone: null,
    address: null,
    city: null,
    state: 'Maharashtra',
    stateCode: '27',
    pincode: null,
    upiId: null,
    bankName: null,
    bankAccountNumber: null,
    bankIfsc: null,
    bankBranch: null,
    invoicePrefix: 'INV-',
    nextInvoiceNumber: 1001,
    currency: 'INR',
  );

  AuthRepository(this.apiClient, this.storage);

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

  Future<UserModel> login({required String email, required String password}) async {
    final sb = _supabase;
    if (sb == null) {
      throw Exception('Supabase client is not initialized or configured.');
    }

    try {
      final res = await sb.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user != null) {
        // Query business profile to inspect is_active & is_deleted
        Map<String, dynamic>? businessRow;
        try {
          businessRow = await sb
              .from('businesses')
              .select('is_active, is_deleted')
              .eq('user_id', user.id)
              .maybeSingle();
        } catch (e) {
          debugPrint('Notice querying user status: $e');
        }

        final userMeta = user.userMetadata ?? {};
        final bool isActive = (businessRow?['is_active'] as bool?) ??
            (userMeta['is_active'] as bool?) ??
            true;

        final bool isDeleted = (businessRow?['is_deleted'] as bool?) ??
            (userMeta['is_deleted'] as bool?) ??
            false;

        // Check is_deleted
        if (isDeleted) {
          await sb.auth.signOut();
          await storage.clearAll();
          throw Exception('This account has been deleted. Please contact support.');
        }

        // Check is_active
        if (!isActive) {
          await sb.auth.signOut();
          await storage.clearAll();
          throw Exception('This account is deactivated. Please contact support.');
        }

        final userModel = UserModel(
          id: user.id.hashCode,
          name: (user.userMetadata?['name'] as String?) ?? user.email?.split('@').first ?? 'Owner',
          email: user.email ?? email,
          phone: (user.userMetadata?['phone'] as String?) ?? '',
          role: 'owner',
          isActive: isActive,
          isDeleted: isDeleted,
        );
        await storage.saveTokens(accessToken: res.session?.accessToken ?? 'sb_token');
        await storage.setActiveBusinessId(1);
        await getActiveBusiness(); // refresh business
        return userModel;
      } else {
        throw Exception('User authentication failed: No user record returned');
      }
    } catch (e) {
      debugPrint('Supabase login error: $e');
      rethrow;
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String businessName,
    required String phone,
    required String state,
    required String stateCode,
  }) async {
    final sb = _supabase;
    if (sb == null) {
      throw Exception('Supabase client is not initialized or configured.');
    }

    try {
      final res = await sb.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'business_name': businessName,
          'state': state,
          'state_code': stateCode,
          'is_active': true,
          'is_deleted': false,
        },
      );

      final user = res.user;
      if (user != null) {
        final newUser = UserModel(
          id: user.id.hashCode,
          name: name,
          email: email,
          phone: phone,
          role: 'owner',
          isActive: true,
          isDeleted: false,
        );

        // If session is active immediately, insert or upsert initial business row
        if (res.session != null) {
          try {
            await sb.from('businesses').upsert({
              'user_id': user.id,
              'name': businessName,
              'email': email,
              'phone': phone,
              'state': state,
              'state_code': stateCode,
              'is_active': true,
              'is_deleted': false,
              'invoice_prefix': 'INV-',
              'next_invoice_number': 1001,
              'currency': 'INR',
            }, onConflict: 'user_id');
          } catch (e) {
            debugPrint('Business insert notice: $e');
          }
        }

        if (res.session?.accessToken != null) {
          await storage.saveTokens(accessToken: res.session!.accessToken);
        }
        await storage.setActiveBusinessId(1);
        return newUser;
      } else {
        throw Exception('Registration completed but user object was not returned. Please verify your email.');
      }
    } catch (e) {
      debugPrint('Supabase registration error: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetOtp(String email) async {
    final sb = _supabase;
    if (sb != null) {
      await sb.auth.resetPasswordForEmail(email);
      return;
    }
    throw Exception('Supabase client is not configured');
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final sb = _supabase;
    if (sb != null) {
      await sb.auth.updateUser(UserAttributes(password: newPassword));
      return;
    }
    throw Exception('Supabase client is not configured');
  }

  Future<BusinessModel> getActiveBusiness() async {
    final sb = _supabase;
    final currentUser = sb?.auth.currentUser;

    // 1. Try reading from persistent local cache first so logo/signature are never lost
    try {
      final cachedJson = await storage.getBusinessProfileJson(userId: currentUser?.id);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final local = BusinessModel.fromJson(jsonDecode(cachedJson));
        _activeBusiness = local;
      }
    } catch (_) {}

    if (sb != null && currentUser != null) {
      try {
        final res = await sb
            .from('businesses')
            .select()
            .eq('user_id', currentUser.id)
            .maybeSingle();

        if (res != null) {
          final remoteBusiness = BusinessModel.fromJson(res);

          // If account is deleted or inactive, sign out immediately
          if (remoteBusiness.isDeleted) {
            await logout();
            throw Exception('This account has been deleted. Please contact support.');
          }
          if (!remoteBusiness.isActive) {
            await logout();
            throw Exception('This account is deactivated. Please contact support.');
          }

          // Retain local logo/signature if Supabase has not yet stored them
          _activeBusiness = remoteBusiness.copyWith(
            logoUrl: (remoteBusiness.logoUrl != null && remoteBusiness.logoUrl!.trim().isNotEmpty)
                ? remoteBusiness.logoUrl
                : _activeBusiness.logoUrl,
            signatureUrl: (remoteBusiness.signatureUrl != null && remoteBusiness.signatureUrl!.trim().isNotEmpty)
                ? remoteBusiness.signatureUrl
                : _activeBusiness.signatureUrl,
          );
          await storage.saveBusinessProfileJson(jsonEncode(_activeBusiness.toJson()), userId: currentUser.id);
          return _activeBusiness;
        } else {
          // If business row does not exist yet (e.g., first login after email verification), auto-create it
          final meta = currentUser.userMetadata ?? {};
          final bName = (meta['business_name'] as String?) ?? 'My Business';
          final phone = (meta['phone'] as String?) ?? '';
          final state = (meta['state'] as String?) ?? 'Maharashtra';
          final stateCode = (meta['state_code'] as String?) ?? '27';

          try {
            final inserted = await sb.from('businesses').upsert({
              'user_id': currentUser.id,
              'name': bName,
              'email': currentUser.email,
              'phone': phone,
              'state': state,
              'state_code': stateCode,
              'is_active': true,
              'is_deleted': false,
              'invoice_prefix': 'INV-',
              'next_invoice_number': 1001,
              'currency': 'INR',
            }, onConflict: 'user_id').select().maybeSingle();

            if (inserted != null) {
              final created = BusinessModel.fromJson(inserted);
              _activeBusiness = created.copyWith(
                logoUrl: created.logoUrl ?? _activeBusiness.logoUrl,
                signatureUrl: created.signatureUrl ?? _activeBusiness.signatureUrl,
              );
              await storage.saveBusinessProfileJson(jsonEncode(_activeBusiness.toJson()), userId: currentUser.id);
              return _activeBusiness;
            }
          } catch (insertErr) {
            debugPrint('Auto-create business on first login: $insertErr');
          }
        }
      } catch (e) {
        debugPrint('Error fetching business from Supabase: $e');
      }
    }

    return _activeBusiness;
  }

  Future<BusinessModel> updateBusiness(BusinessModel updated) async {
    _activeBusiness = updated;
    final sb = _supabase;
    final currentUser = sb?.auth.currentUser;

    try {
      await storage.saveBusinessProfileJson(jsonEncode(updated.toJson()), userId: currentUser?.id);
    } catch (_) {}

    if (sb != null && currentUser != null) {
      final payload = updated.toJson();
      payload.remove('id'); // Do not pass client ID on upsert with onConflict: user_id
      payload['updated_at'] = DateTime.now().toIso8601String();

      try {
        final res = await sb.from('businesses').upsert({
          'user_id': currentUser.id,
          ...payload,
        }, onConflict: 'user_id').select().maybeSingle();

        if (res != null) {
          final fromDb = BusinessModel.fromJson(res);
          _activeBusiness = fromDb.copyWith(
            logoUrl: fromDb.logoUrl ?? updated.logoUrl,
            signatureUrl: fromDb.signatureUrl ?? updated.signatureUrl,
          );
          await storage.saveBusinessProfileJson(jsonEncode(_activeBusiness.toJson()), userId: currentUser.id);
        }
      } catch (e) {
        debugPrint('Error updating business in Supabase with all fields: $e');
        // Fallback: If logo_url or signature_url columns don't exist yet in Supabase, retry with basic fields
        try {
          final fallbackMap = Map<String, dynamic>.from(payload)
            ..remove('logo_url')
            ..remove('signature_url');
          await sb.from('businesses').upsert({
            'user_id': currentUser.id,
            ...fallbackMap,
          }, onConflict: 'user_id');
        } catch (fallbackErr) {
          debugPrint('Fallback business update failed: $fallbackErr');
        }
      }
    }

    return _activeBusiness;
  }

  Future<void> logout() async {
    final sb = _supabase;
    if (sb != null) {
      try {
        await sb.auth.signOut();
      } catch (_) {}
    }
    await storage.clearAll();
  }

  Future<bool> checkAuthStatus() async {
    final sb = _supabase;
    if (sb != null) {
      return sb.auth.currentSession != null;
    }
    return await storage.isLoggedIn();
  }
}
