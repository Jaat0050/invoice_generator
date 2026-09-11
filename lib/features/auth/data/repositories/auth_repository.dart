import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    name: 'Apex Solutions Pvt Ltd',
    legalName: 'Apex Solutions Private Limited',
    gstin: '27AABCA1234F1Z5',
    pan: 'AABCA1234F',
    email: 'billing@apexsolutions.com',
    phone: '+91 98765 43210',
    address: 'Suite 402, Trade Tower, Bandra Kurla Complex',
    city: 'Mumbai',
    state: 'Maharashtra',
    stateCode: '27',
    pincode: '400051',
    upiId: 'apexsolutions@icici',
    bankName: 'HDFC Bank',
    bankAccountNumber: '50200012345678',
    bankIfsc: 'HDFC0001234',
    bankBranch: 'BKC Branch',
    invoicePrefix: 'INV-',
    nextInvoiceNumber: 1004,
    currency: 'INR',
  );

  AuthRepository(this.apiClient, this.storage);

  Future<UserModel> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    const mockUser = UserModel(
      id: 1,
      name: 'Mukund Sharma',
      email: 'mukund@example.com',
      phone: '+91 98765 43210',
      role: 'owner',
    );
    await storage.saveTokens(accessToken: 'mock_jwt_token_12345');
    await storage.setActiveBusinessId(1);
    return mockUser;
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
    await Future.delayed(const Duration(milliseconds: 600));

    final newUser = UserModel(
      id: 2,
      name: name,
      email: email,
      phone: phone,
      role: 'owner',
    );

    _activeBusiness = _activeBusiness.copyWith(
      name: businessName,
      email: email,
      phone: phone,
      state: state,
      stateCode: stateCode,
    );

    await storage.saveTokens(accessToken: 'mock_jwt_token_new_user');
    await storage.setActiveBusinessId(1);
    return newUser;
  }

  Future<void> sendPasswordResetOtp(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<BusinessModel> getActiveBusiness() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _activeBusiness;
  }

  Future<BusinessModel> updateBusiness(BusinessModel updated) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _activeBusiness = updated;
    return _activeBusiness;
  }

  Future<void> logout() async {
    await storage.clearAll();
  }

  Future<bool> checkAuthStatus() async {
    return await storage.isLoggedIn();
  }
}
