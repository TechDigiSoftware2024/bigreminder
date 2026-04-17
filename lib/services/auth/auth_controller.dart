import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/auth_user_model.dart';
import '../../providers/auth/auth_state.dart';
import '../../services/auth/auth_service.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthService service;

  AuthController(this.service) : super(AuthState()) {
    checkLoginStatus();
  }

  // ================= COMMON SAVE USER =================
  Future<void> _saveUser(AuthUserModel user) async {
    if (user.accessToken == null || user.accessToken!.isEmpty) {
      throw Exception("Token not received from server");
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("token", user.accessToken!);
    await prefs.setString("role", user.role);
    await prefs.setString("userId", user.userId);
  }

  // ================= LOGIN =================
  Future<void> login(String phone, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = await service.login(phone, password);

      // 🔥 validate + save
      await _saveUser(user);

      state = state.copyWith(
        isLoading: false,
        user: user,
        error: null,
      );

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        user: null,
        error: _mapError(e),
      );
    }
  }

  // ================= SIGNUP + AUTO LOGIN =================
  Future<void> signup({
    required String ownerName,
    required String phone,
    required String password,
    required String businessName,
    required String businessCategory,
    required String address,
    required String doc,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = await service.signupAndLogin(
        ownerName: ownerName,
        phone: phone,
        password: password,
        businessName: businessName,
        businessCategory: businessCategory,
        address: address,
        doc: doc,
      );

      // 🔥 validate + save
      await _saveUser(user);

      state = state.copyWith(
        isLoading: false,
        user: user,
        error: null,
      );

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapError(e),
      );
    }
  }

  // ================= AUTO LOGIN =================
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");
    final role = prefs.getString("role");
    final userId = prefs.getString("userId");

    print("🔍 STORED TOKEN: $token");

    if (token != null && token.isNotEmpty) {
      state = state.copyWith(
        user: AuthUserModel(
          userId: userId ?? '',
          accessToken: token,
          role: role ?? '',
        ),
      );
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    state = AuthState();
  }

  // ================= ERROR HANDLER =================
  String _mapError(dynamic error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains("socket")) return "No internet connection";
    if (msg.contains("timeout")) return "Server is slow, try again";
    if (msg.contains("already")) return "User already registered";
    if (msg.contains("invalid")) return "Invalid phone or password";
    if (msg.contains("token")) return "Authentication failed";

    return "Something went wrong";
  }
}