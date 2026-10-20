import 'dart:convert';

import 'package:bigreminder/api_config/api_config.dart';
import 'package:bigreminder/models/auth_models/auth_user_model.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // ================= LOGIN =================

  Future<AuthUserModel> login(
      String phone,
      String password,
      ) async {
    try {
      final res = await http
          .post(
        ApiConfig.url(ApiConfig.login),
        headers: ApiConfig.headers(),
        body: jsonEncode({
          "phone": phone,
          "password": password,
        }),
      )
          .timeout(const Duration(seconds: 15));

      final data = _handleResponse(res);

      return AuthUserModel.fromJson(data);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // ================= SIGNUP + AUTO LOGIN =================

  Future<AuthUserModel> signupAndLogin({
    required String ownerName,
    required String phone,
    required String password,
    required String businessName,
    required String businessCategory,
    int? categoryId,
    required String address,
    required String doc,
  }) async {
    final res = await http
        .post(
      ApiConfig.url(ApiConfig.register),
      headers: ApiConfig.headers(),
      body: jsonEncode({
        "owner_name": ownerName,
        "phone": phone,
        "password": password,
        "business_name": businessName,
        "business_category": businessCategory,
        if (categoryId != null) "category_id": categoryId,
        "address": address,
        "doc": doc,
      }),
    )
        .timeout(const Duration(seconds: 60));

    final signupData = _handleResponse(res);

    print("SIGNUP RESPONSE: $signupData");

    final user = await login(phone, password);

    if (user.accessToken == null || user.accessToken!.isEmpty) {
      throw Exception("Login failed: Token not received");
    }

    return user;
  }

  // ================= RESPONSE =================

  Map<String, dynamic> _handleResponse(http.Response res) {
    print("STATUS => ${res.statusCode}");
    print("BODY => ${res.body}");

    Map<String, dynamic> data = {};

    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(res.body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        throw Exception("Invalid server response");
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    final serverMessage =
        data["detail"]?.toString() ??
            data["message"]?.toString() ??
            data["error"]?.toString();

    throw Exception(
      serverMessage ?? "Server error (${res.statusCode})",
    );
  }

  // ================= ERROR HANDLER =================
  String _handleError(dynamic error) {
    final msg = error.toString();

    final lower = msg.toLowerCase();

    // ================= NETWORK =================

    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('connection')) {
      return "Please check your internet connection and try again.";
    }

    // ================= TIMEOUT =================

    if (lower.contains('timeout')) {
      return "The server is taking too long to respond. Please try again.";
    }

    // ================= SIGNUP =================

    if (lower.contains('phone already registered')) {
      return "This phone number is already registered. Please sign in instead.";
    }

    if (lower.contains('already registered')) {
      return "This account is already registered. Please sign in instead.";
    }

    // ================= LOGIN =================

    if (lower.contains('incorrect phone or password')) {
      return "The phone number or password is incorrect. Please check your details and try again.";
    }

    // ================= INVALID =================

    if (lower.contains('invalid phone')) {
      return "Please enter a valid phone number.";
    }

    if (lower.contains('invalid password')) {
      return "The password you entered is incorrect. Please try again.";
    }

    if (lower.contains('invalid')) {
      return "The information you entered is invalid. Please check your details and try again.";
    }

    // ================= USER =================

    if (lower.contains('user not found') ||
        lower.contains('no user')) {
      return "We couldn't find an account with this phone number. Please sign up first.";
    }

    if (lower.contains('disabled')) {
      return "This account has been disabled. Please contact support.";
    }

    // ================= FALLBACK =================

    return msg
        .replaceFirst('Exception: ', '')
        .trim();
  }
}