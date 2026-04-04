import 'dart:convert';
import 'package:bigreminder/api_config/api_config.dart';
import 'package:bigreminder/models/auth_user_model.dart';
import 'package:http/http.dart' as http;

class AuthService {

  // ================= LOGIN =================
  Future<AuthUserModel> login(String email, String password) async {
    try {
      final res = await http
          .post(
        ApiConfig.url(ApiConfig.login),
        headers: ApiConfig.headers(),
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      )
          .timeout(const Duration(seconds: 15));

      final data = _handleResponse(res);

      return AuthUserModel.fromJson(data); // ✅ FIX
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // ================= SIGNUP =================
  Future<AuthUserModel> signup(
      String name,
      String email,
      String password,
      String role,
      String phone,
      ) async {
    try {
      final res = await http
          .post(
        ApiConfig.url(ApiConfig.register),
        headers: ApiConfig.headers(),
        body: jsonEncode({
          "name": name,
          "email": email,
          "phone": phone,
          "password": password,
          "role": role,
        }),
      )
          .timeout(const Duration(seconds: 15));

      final data = _handleResponse(res);

      return AuthUserModel.fromJson(data); // ✅ FIX
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

    if (msg.contains('socket')) {
      return "No internet connection";
    }
    if (msg.contains('timeout')) {
      return "Server timeout, try again";
    }
    if (msg.contains('already')) {
      return "Email already registered";
    }
    if (msg.contains('invalid')) {
      return "Invalid email or password";
    }

    return "Something went wrong";
  }
}