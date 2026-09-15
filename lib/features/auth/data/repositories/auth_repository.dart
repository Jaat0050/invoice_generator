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
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      return repo.updateBusiness(updated);
    });
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
        final userModel = UserModel(
          id: user.id.hashCode,
          name: (user.userMetadata?['name'] as String?) ?? user.email?.split('@').first ?? 'Owner',
          email: user.email ?? email,
          phone: (user.userMetadata?['phone'] as String?) ?? '',
          role: 'owner',
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
    if (sb != null && currentUser != null) {
      try {
        final res = await sb
            .from('businesses')
            .select()
            .eq('user_id', currentUser.id)
            .maybeSingle();

        if (res != null) {
          _activeBusiness = BusinessModel.fromJson(res);
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
              'invoice_prefix': 'INV-',
              'next_invoice_number': 1001,
              'currency': 'INR',
            }, onConflict: 'user_id').select().maybeSingle();

            if (inserted != null) {
              _activeBusiness = BusinessModel.fromJson(inserted);
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
    final sb = _supabase;
    final currentUser = sb?.auth.currentUser;
    if (sb != null && currentUser != null) {
      try {
        await sb.from('businesses').upsert({
          'user_id': currentUser.id,
          ...updated.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      } catch (e) {
        debugPrint('Error updating business in Supabase: $e');
      }
    }

    _activeBusiness = updated;
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
