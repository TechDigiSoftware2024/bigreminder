import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth/auth_service.dart';
import '../../services/business/business_state.dart';

class BusinessController extends StateNotifier<BusinessState> {
  BusinessController() : super(const BusinessState());

  Future<void> createBusiness({
    required String ownerName,
    required String phone,
    required String password,
    required String businessName,
    required String businessCategory,
    required String address,
    required String doc,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null, isSuccess: false);

      // 🔥 Signup + Auto Login
      final user = await AuthService().signupAndLogin(
        ownerName: ownerName,
        phone: phone,
        password: password,
        businessName: businessName,
        businessCategory: businessCategory,
        address: address,
        doc: doc,
      );

      // ✅ STEP 1: TOKEN SAVE (CRITICAL)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", user.accessToken ?? "");

      // Optional: userId bhi save karo
      if (user.userId != null) {
        await prefs.setString("userId", user.userId.toString());
      }

      // ✅ STEP 2: SUCCESS STATE
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        message: "Business created successfully",
      );

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isSuccess: false,
      );
    }
  }
}

