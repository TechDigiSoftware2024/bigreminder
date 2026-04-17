import 'dart:convert';
import 'package:bigreminder/api_config/api_config.dart';
import 'package:bigreminder/models/auth_user_model.dart';
import 'package:http/http.dart' as http;

class AuthService {

  // ================= LOGIN =================
  Future<AuthUserModel> login(String phone, String password) async {
    try {
      final res = await http.post(
        ApiConfig.url(ApiConfig.login),
        headers: ApiConfig.headers(),
        body: jsonEncode({
          "phone": phone,
          "password": password,
        }),
      ).timeout(const Duration(seconds: 15));

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
    required String address,
    required String doc,
  }) async {
    try {
      // 🔥 STEP 1: SIGNUP
      final res = await http.post(
        ApiConfig.url(ApiConfig.register),
        headers: ApiConfig.headers(),
        body: jsonEncode({
          "owner_name": ownerName,
          "phone": phone,
          "password": password,
          "business_name": businessName,
          "business_category": businessCategory,
          "address": address,
          "doc": doc,
        }),
      ).timeout(const Duration(seconds: 60));

      final signupData = _handleResponse(res);

      // 🧠 DEBUG (optional but useful)
      print("SIGNUP RESPONSE: $signupData");

      // 🔥 STEP 2: AUTO LOGIN (CRITICAL)
      final user = await login(phone, password);

      // 🧠 Safety check
      if (user.accessToken == null || user.accessToken!.isEmpty) {
        throw Exception("Login failed: Token not received");
      }

      return user;

    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // ================= RESPONSE =================
  Map<String, dynamic> _handleResponse(http.Response res) {
    final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    } else {
      throw Exception(
        data['message'] ??
            data['error'] ??
            "Server error (${res.statusCode})",
      );
    }
  }

  // ================= ERROR HANDLER =================
  String _handleError(dynamic error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('socket')) return "No internet connection";
    if (msg.contains('timeout')) return "Server timeout, try again";
    if (msg.contains('already')) return "User already registered";
    if (msg.contains('invalid')) return "Invalid phone or password";

    return error.toString();
  }
}