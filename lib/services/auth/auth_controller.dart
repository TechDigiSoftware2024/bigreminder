import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/auth_user_model.dart';
import '../../providers/auth/auth_state.dart';
import '../../services/auth/auth_service.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthService service;

  AuthController(this.service) : super(AuthState()) {
    checkLoginStatus(); // ✅ auto login on start
  }

  // ================= LOGIN =================
  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = await service.login(email, password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isLoggedIn", true); // ✅ persist

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

  // ================= SIGNUP =================
  Future<void> signup(
      String name,
      String email,
      String password,
      String role,
      String phone,
      ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // ✅ signup returns user
      final user =
      await service.signup(name, email, password, role, phone);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isLoggedIn", true);

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
    final isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

    if (isLoggedIn) {
      state = state.copyWith(
        user: AuthUserModel(
          id: "cached",
          name: "",
          email: "",
          phone: "",
          role: "",
          status: "",
        ),
      );
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // ✅ remove login

    state = AuthState();
  }

  // ================= ERROR HANDLER =================
  String _mapError(dynamic error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains("socket")) return "No internet connection";
    if (msg.contains("timeout")) return "Server is slow, try again";
    if (msg.contains("already")) return "Email already registered";
    if (msg.contains("invalid")) return "Invalid email or password";

    return "Something went wrong";
  }
}