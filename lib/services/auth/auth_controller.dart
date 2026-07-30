// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/legacy.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../models/auth_models/auth_user_model.dart';
// import '../../providers/auth/auth_state.dart';
// import '../../services/auth/auth_service.dart';
//
// class AuthController extends StateNotifier<AuthState> {
//   final AuthService service;
//
//   AuthController(this.service) : super(AuthState()) {
//     checkLoginStatus();
//   }
//
//   // ================= COMMON SAVE USER =================
//   Future<void> _saveUser(AuthUserModel user) async {
//     if (user.accessToken == null || user.accessToken!.isEmpty) {
//       throw Exception("Token not received from server");
//     }
//
//     final prefs = await SharedPreferences.getInstance();
//
//     await prefs.setString("token", user.accessToken!);
//     await prefs.setString("role", user.role);
//     await prefs.setString("userId", user.userId);
//   }
//
//   // ================= LOGIN =================
//   Future<void> login(String phone, String password) async {
//     print("LOGIN START");
//
//     try {
//       state = state.copyWith(
//         isLoading: true,
//         error: null,
//       );
//
//       print("BEFORE API");
//
//       final user = await service.login(
//         phone,
//         password,
//       );
//
//       print("AFTER API");
//
//       await _saveUser(user);
//
//       state = state.copyWith(
//         isLoading: false,
//         user: user,
//         token: user.accessToken,
//         error: null,
//       );
//     } catch (e) {
//       print("LOGIN ERROR => $e");
//
//       state = state.copyWith(
//         isLoading: false,
//         user: null,
//         error: _mapError(e),
//       );
//     }
//   }
//   // ================= SIGNUP + AUTO LOGIN =================
//   Future<void> signup({
//     required String ownerName,
//     required String phone,
//     required String password,
//     required String businessName,
//     required String businessCategory,
//     required String address,
//     required String doc,
//   }) async {
//     try {
//       state = state.copyWith(isLoading: true, error: null);
//
//       final user = await service.signupAndLogin(
//         ownerName: ownerName,
//         phone: phone,
//         password: password,
//         businessName: businessName,
//         businessCategory: businessCategory,
//         address: address,
//         doc: doc,
//       );
//
//       // 🔥 validate + save
//       await _saveUser(user);
//
//       state = state.copyWith(
//         isLoading: false,
//         user: user,
//         token: user.accessToken, // 🔥 ADD THIS
//         error: null,
//       );
//
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: _mapError(e),
//       );
//     }
//   }
//
//   // ================= AUTO LOGIN =================
//   Future<void> checkLoginStatus() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     final token = prefs.getString("token");
//     final role = prefs.getString("role");
//     final userId = prefs.getString("userId");
//
//     print("🔍 STORED TOKEN: $token");
//
//     if (token != null && token.isNotEmpty) {
//       state = state.copyWith(
//         user: AuthUserModel(
//           userId: userId ?? '',
//           accessToken: token,
//           role: role ?? '',
//         ),
//         token: token, // 🔥 IMPORTANT
//       );
//     }
//   }
//
//   // ================= LOGOUT =================
//   Future<void> logout() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     await prefs.clear(); // safe now
//
//     state = AuthState();
//   }
//
//   // ================= ERROR HANDLER =================
//   String _mapError(dynamic error) {
//     final msg = error.toString().toLowerCase();
//
//     if (msg.contains("incorrect phone or password")) {
//       return "Incorrect phone or password";
//     }
//
//     if (msg.contains("socket")) {
//       return "No internet connection";
//     }
//
//     if (msg.contains("timeout")) {
//       return "Server is slow, try again";
//     }
//
//     if (msg.contains("already")) {
//       return "User already registered";
//     }
//
//     if (msg.contains("invalid")) {
//       return "Invalid phone or password";
//     }
//
//     if (msg.contains("token")) {
//       return "Authentication failed";
//     }
//
//     return error.toString().replaceFirst(
//       "Exception: ",
//       "",
//     );
//   }
//
//
//   Future<void> restoreSession() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//
//       final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
//
//       if (!isLoggedIn) {
//         state = AuthState();
//         return;
//       }
//
//       final userId = prefs.getString('user_id');
//       final role = prefs.getString('user_role');
//       final token = prefs.getString('access_token');
//
//       if (userId != null && role != null) {
//         state = state.copyWith(
//           user: AuthUserModel(
//             userId: userId,
//             role: role,
//             accessToken: token,
//           ),
//           isLoading: false,
//         );
//       } else {
//         state = AuthState();
//       }
//     } catch (e) {
//       state = AuthState();
//     }
//   }
// }
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/auth_models/auth_user_model.dart';
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
      // Clear stale error/user from any previous failed attempt
      // BEFORE starting the new request. Must use clearError/clearUser
      // flags — copyWith(error: null) is a no-op by design.
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearUser: true,
      );

      final user = await service.login(phone, password);

      await _saveUser(user);

      state = state.copyWith(
        isLoading: false,
        user: user,
        token: user.accessToken,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearUser: true,
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
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearUser: true,
      );

      final user = await service.signupAndLogin(
        ownerName: ownerName,
        phone: phone,
        password: password,
        businessName: businessName,
        businessCategory: businessCategory,
        address: address,
        doc: doc,
      );

      await _saveUser(user);

      state = state.copyWith(
        isLoading: false,
        user: user,
        token: user.accessToken,
        clearError: true,
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

    if (token != null && token.isNotEmpty) {
      state = state.copyWith(
        user: AuthUserModel(
          userId: userId ?? '',
          accessToken: token,
          role: role ?? '',
        ),
        token: token,
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

    if (msg.contains("incorrect phone or password")) {
      return "Incorrect phone or password";
    }
    if (msg.contains("socket")) {
      return "No internet connection";
    }
    if (msg.contains("timeout")) {
      return "Server is slow, try again";
    }
    if (msg.contains("already")) {
      return "User already registered";
    }
    if (msg.contains("invalid")) {
      return "Invalid phone or password";
    }
    if (msg.contains("token")) {
      return "Authentication failed";
    }

    return error.toString().replaceFirst("Exception: ", "");
  }

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (!isLoggedIn) {
        state = AuthState();
        return;
      }

      final userId = prefs.getString('user_id');
      final role = prefs.getString('user_role');
      final token = prefs.getString('access_token');

      if (userId != null && role != null) {
        state = state.copyWith(
          user: AuthUserModel(
            userId: userId,
            role: role,
            accessToken: token,
          ),
          isLoading: false,
        );
      } else {
        state = AuthState();
      }
    } catch (e) {
      state = AuthState();
    }
  }
}