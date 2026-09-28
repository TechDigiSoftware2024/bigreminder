import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/auth_models/auth_user_model.dart';
import '../../providers/auth/auth_state.dart';
import '../../services/auth/auth_service.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthService service;

  AuthController(this.service) : super(const AuthState());

  // ============================================================
  // STORAGE KEYS
  // ============================================================

  static const String _tokenKey = 'token';
  static const String _roleKey = 'role';
  static const String _userIdKey = 'userId';
  static const String _businessIdKey = 'businessId';
  static const String _appTypeKey = 'appType';
  static const String _businessCategoryKey = 'businessCategory';

  // ============================================================
  // SAVE USER
  // ============================================================

  Future<void> _saveUser(AuthUserModel user) async {
    final token = user.accessToken;

    if (token == null || token.isEmpty) {
      throw Exception('Token not received from server');
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, user.role);
    await prefs.setString(_userIdKey, user.userId);
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login(
      String phone,
      String password,
      ) async {
    try {
      debugPrint('LOGIN START');

      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearUser: true,
      );

      final user = await service.login(
        phone,
        password,
      );

      await _saveUser(user);

      // Force a new state object so AuthGate always rebuilds immediately.
      state = AuthState(
        isLoading: false,
        user: user,
        token: user.accessToken,
        error: null,
      );

      debugPrint('LOGIN SUCCESS role=${user.role} tokenOk=${user.hasValidToken}');
    } catch (e, st) {
      debugPrint('LOGIN ERROR => $e\n$st');

      state = state.copyWith(
        isLoading: false,
        clearUser: true,
        clearToken: true,
        error: _mapError(e),
      );
    } finally {
      // Never leave the Sign In button spinning.
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  // ============================================================
  // SIGNUP + AUTO LOGIN
  // ============================================================

  /// When [replaceSession] is false (Super Admin creating a business), the
  /// new owner is registered and their token is written to prefs for the
  /// create-business API — but AuthGate keeps the current admin session.
  Future<AuthUserModel?> signup({
    required String ownerName,
    required String phone,
    required String password,
    required String businessName,
    required String businessCategory,
    required String address,
    required String doc,
    bool replaceSession = true,
  }) async {
    final preservedUser = state.user;
    final preservedToken = state.token;

    try {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearUser: replaceSession,
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

      if (!replaceSession) {
        // Business create reads token from SharedPreferences.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, user.accessToken ?? '');

        state = state.copyWith(
          isLoading: false,
          user: preservedUser,
          token: preservedToken,
          clearError: true,
        );
        return user;
      }

      await _saveUser(user);

      state = state.copyWith(
        isLoading: false,
        user: user,
        token: user.accessToken,
        clearError: true,
      );
      return user;
    } catch (e) {
      debugPrint('SIGNUP ERROR => $e');

      state = state.copyWith(
        isLoading: false,
        error: _mapError(e),
        user: replaceSession ? null : preservedUser,
        token: replaceSession ? null : preservedToken,
        clearUser: replaceSession,
        clearToken: replaceSession,
      );
      return null;
    }
  }

  /// Writes the current auth user back to prefs (after admin create used the
  /// new owner's token temporarily).
  Future<void> persistCurrentSession() async {
    final user = state.user;
    if (user == null || !user.hasValidToken) return;
    await _saveUser(user);
  }

  // ============================================================
  // RESTORE SESSION
  // ============================================================

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString(_tokenKey);
      final role = prefs.getString(_roleKey);
      final userId = prefs.getString(_userIdKey);

      debugPrint('RESTORE TOKEN => $token');
      debugPrint('RESTORE ROLE => $role');
      debugPrint('RESTORE USER ID => $userId');

      if (token == null || token.isEmpty) {
        // Do NOT wipe an in-flight / just-completed login.
        // Constructor+AuthGate both used to call restore; a late empty
        // read would clear state after login and block navigation.
        if (state.user != null && state.user!.hasValidToken) {
          debugPrint('RESTORE SKIP clear — live session already present');
          return;
        }
        state = const AuthState();
        return;
      }

      if (role == null || role.isEmpty) {
        if (state.user != null && state.user!.hasValidToken) {
          debugPrint('RESTORE SKIP clear — live session already present');
          return;
        }
        state = const AuthState();
        return;
      }

      // Prefer keeping a fresher in-memory session (e.g. right after login).
      if (state.user != null &&
          state.user!.hasValidToken &&
          state.token == token) {
        state = state.copyWith(isLoading: false, clearError: true);
        return;
      }

      final user = AuthUserModel(
        userId: userId ?? '',
        accessToken: token,
        role: role,
      );

      state = state.copyWith(
        user: user,
        token: token,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      debugPrint('RESTORE SESSION ERROR => $e');

      if (state.user != null && state.user!.hasValidToken) return;
      state = const AuthState();
    }
  }

  // ============================================================
  // CHECK LOGIN STATUS
  // ============================================================

  Future<void> checkLoginStatus() async {
    await restoreSession();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      debugPrint('LOGOUT START');

      final prefs = await SharedPreferences.getInstance();

      // ----------------------------------------------------------
      // Remove authentication data
      // ----------------------------------------------------------

      await prefs.remove(_tokenKey);
      await prefs.remove(_roleKey);
      await prefs.remove(_userIdKey);

      // ----------------------------------------------------------
      // Remove business/session data
      // ----------------------------------------------------------

      await prefs.remove(_businessIdKey);
      await prefs.remove(_appTypeKey);
      await prefs.remove(_businessCategoryKey);

      // ----------------------------------------------------------
      // IMPORTANT
      // Update Riverpod immediately
      // ----------------------------------------------------------

      state = AuthState();

      debugPrint('LOGOUT SUCCESS');
    } catch (e) {
      debugPrint('LOGOUT ERROR => $e');

      // Even if SharedPreferences fails,
      // force the application into logged-out state.
      state = AuthState();


      rethrow;
    }
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  String _mapError(dynamic error) {
    final msg = error.toString();
    final lower = msg.toLowerCase();

    // LOGIN
    if (lower.contains('incorrect phone or password')) {
      return 'The phone number or password is incorrect. '
          'Please check your details and try again.';
    }

    // SIGNUP
    if (lower.contains('phone already registered')) {
      return 'This phone number is already registered. '
          'Please sign in instead.';
    }

    if (lower.contains('already registered')) {
      return 'This account is already registered. '
          'Please sign in instead.';
    }

    // NETWORK
    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('connection')) {
      return 'Please check your internet connection and try again.';
    }

    // TIMEOUT
    if (lower.contains('timeout')) {
      return 'The server is taking too long to respond. '
          'Please try again.';
    }

    // INVALID
    if (lower.contains('invalid phone')) {
      return 'Please enter a valid phone number.';
    }

    if (lower.contains('invalid password')) {
      return 'The password you entered is incorrect. '
          'Please try again.';
    }

    if (lower.contains('invalid')) {
      return 'The information you entered is invalid. '
          'Please check your details.';
    }

    // TOKEN
    if (lower.contains('token')) {
      return 'Authentication failed. Please try again.';
    }

    return msg
        .replaceFirst('Exception: ', '')
        .trim();
  }
}