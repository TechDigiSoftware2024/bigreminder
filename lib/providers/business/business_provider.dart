import 'package:bigreminder/api_config/api_config.dart';
import 'package:bigreminder/models/business_models/customer_list_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/business_models/business_create_expense_model.dart';
import '../../models/business_models/business_dashboard_model.dart';
import '../../models/business_models/business_model.dart';
import '../../models/super_admin_models/create_business_model.dart';
import '../../models/super_admin_models/create_business_request_model.dart';
import '../../services/business/business_service.dart';
import '../../services/business/business_state.dart';
import '../../services/business/dashboard_service.dart';
import '../../services/business/fetch_business_list.dart';
import '../../services/notification_service.dart';
import '../auth/auth_provider.dart';

// ================= CONTROLLER =================
class BusinessController extends StateNotifier<BusinessState> {
  final BusinessService service;

  BusinessController(this.service) : super(const BusinessState());

  // =========================================================
  // 🔥 FETCH MY BUSINESSES (LOGIN FLOW)
  // =========================================================
  Future<void> fetchMyBusinesses(String token) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final list = await service.fetchMyBusinesses(token: token);

      /// 🔥 SAVE FIRST BUSINESS ID (CRITICAL FIX)
      if (list.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();

        final firstBusinessId = list.first.id;

        await prefs.setInt("businessId", firstBusinessId);

        print("✅ SAVED BUSINESS ID: $firstBusinessId");
      } else {
        /// ❗ No business case
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove("businessId");

        print("⚠️ No businesses found");
      }

      /// 🔥 UPDATE STATE
      state = state.copyWith(
        isLoading: false,
        businesses: list,
      );

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      rethrow;
    }
  }
  // ================= DELETE =================
  Future<void> deleteBusinessById(int businessId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      await deleteBusiness(token: token, businessId: businessId);

      state = state.copyWith(
        isLoading: false,
        message: "Business deleted successfully",
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ================= CREATE BUSINESS =================
  Future<void> createBusiness({
    required String name,
    required String category,
    required String address,
    required String doc,
    required int userId,
    required int planId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      final requestModel = CreateBusinessRequestModel(
        name: name,
        category: category,
        address: address,
        doc: doc,
        userId: userId,
        planId: planId,
      );

      final BusinessModel business = await service.createBusinessApi(
        token: token,
        model: requestModel,
      );

      // 🔥 Save businessId
      await prefs.setInt("businessId", business.id);

      print("🔥 Business ID: ${business.id}");

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        message: "Business created successfully",
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

//✅ PROVIDERS (clean setup)

final businessServiceProvider = Provider<BusinessService>((ref) {
  return BusinessService();
});

final businessControllerProvider =
    StateNotifierProvider<BusinessController, BusinessState>((ref) {
      final service = ref.read(businessServiceProvider);
      return BusinessController(service);
    });

//✅ TOKEN PROVIDER

final tokenProvider = Provider<String>((ref) {
  final token = ref.watch(authControllerProvider).token;

  if (token == null || token.isEmpty) {
    throw Exception("Token missing");
  }

  return token;
});

final businessIdProvider = Provider<int>((ref) {
  final state = ref.watch(businessControllerProvider);

  if (state.businesses.isNotEmpty) {
    return state.businesses.first.id;
  }

  throw Exception("BusinessId missing in state");
});



final customerProvider = FutureProvider<List<CustomerResponseModel>>((ref) async {
  final prefs = await SharedPreferences.getInstance();

  final token = prefs.getString("token") ?? "";
  final businessId = prefs.getInt("businessId") ?? 0;

  return BusinessService().fetchCustomers(
    token: token,
    businessId: businessId,
  );
});


final dashboardProvider =
FutureProvider.family<BusinessDashboardModel, int>((ref, businessId) async {

  final token = ref.watch(tokenProvider);

  final data = await fetchDashboard(
    token: token,
    businessId: businessId,
  );

  return BusinessDashboardModel.fromJson(data);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    baseUrl: ApiConfig.baseUrl,
    ref: ref,
  );
});


final incomeServiceProvider = Provider<IncomeService>((ref) {
  return IncomeService(ref);
});

final customerCountProvider = FutureProvider<int>((ref) async {
  final customers = await ref.watch(customerProvider.future);
  return customers.length;
});

// ✅ ADD THIS
final createExpenseProvider =
StateNotifierProvider<CreateExpenseNotifier, AsyncValue<void>>(
      (ref) => CreateExpenseNotifier(ref),
);

// ✅ YOUR NOTIFIER
class CreateExpenseNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  CreateExpenseNotifier(this.ref) : super(const AsyncData(null));

  Future<void> createExpense({
    required BusinessExpenseModel expense,
  }) async {
    state = const AsyncLoading();

    try {
      final token = ref.read(tokenProvider);

      await ref.read(businessServiceProvider).createExpense(
        token: token,
        expense: expense,
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}