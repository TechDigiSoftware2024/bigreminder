import 'dart:convert';
import 'dart:io';
import 'package:bigreminder/models/business_models/customer_list_model.dart';
import 'package:bigreminder/models/business_models/customer_list_model.dart';
import 'package:bigreminder/models/business_models/customer_list_model.dart';
import 'package:bigreminder/models/super_admin_models/create_business_model.dart';
import 'package:bigreminder/services/business/receive_payment_service.dart' as service;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../api_config/api_config.dart';
import '../../models/business_models/BusinessMonthlyGrowthModel.dart';
import '../../models/business_models/business_analysis_model.dart';
import '../../models/business_models/business_create_expense_model.dart';
import '../../models/business_models/business_customer_req_model.dart';
import '../../models/business_models/business_income_req_model.dart';
import '../../models/business_models/notification_req_model.dart';
import '../../models/business_models/receive_payment_request_model.dart';
import '../../models/business_models/receive_payment_response_model.dart';
import '../../models/super_admin_models/business_list_model.dart';
import '../../models/super_admin_models/create_business_request_model.dart';
import '../../providers/business/business_provider.dart';
import '../local_storage/local_storage.dart';
import '../notification_service.dart';

class BusinessService {
  // =========================================================
  // 🔥 BUSINESS SIDE - FETCH OWN BUSINESSES
  // =========================================================
  Future<List<Business>> fetchMyBusinesses({required String token}) async {
    try {
      /// 🔥 TOKEN VALIDATION
      if (token.isEmpty) {
        throw Exception("Invalid session. Please login again.");
      }

      final url = ApiConfig.url(ApiConfig.businessList);

      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      print("📡 BUSINESS FETCH");
      print("🔐 TOKEN: ${token.substring(0, 10)}..."); // safe print
      print("📊 STATUS: ${response.statusCode}");

      /// 🔥 SUCCESS
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          final list = decoded
              .map<Business>((e) => Business.fromJson(e))
              .toList();

          print("✅ BUSINESS COUNT: ${list.length}");
          return list;
        } else {
          throw Exception("Invalid response format (not list)");
        }
      }

      /// 🔥 AUTH ERROR
      if (response.statusCode == 401) {
        throw Exception("Session expired. Please login again.");
      }

      /// 🔥 SERVER ERROR
      if (response.statusCode >= 500) {
        throw Exception("Server error. Try again later.");
      }

      throw Exception("Unexpected error: ${response.statusCode}");
    } catch (e) {
      print("❌ BUSINESS FETCH ERROR: $e");
      rethrow;
    }
  }


  Future<Map<String, dynamic>> fetchDashboard({
    required String token,
    required int businessId,
  }) async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/v1/dashboard/business/$businessId",
    );

    final response = await http.get(
      url,
      headers: ApiConfig.headers(token: token),
    );

    print("🚀 DASHBOARD API");
    print("👉 BUSINESS ID: $businessId");
    print("📊 STATUS: ${response.statusCode}");
    print("📦 BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Dashboard fetch failed");
    }
  }
  Future<BusinessMonthlyGrowthModel>
  fetchBusinessTrends({
    required String token,
    required int businessId,
    required int months,
  }) async {
    final response = await http.get(
      Uri.parse(
        ApiConfig.businessTrends(
          businessId,
          months,
        ),
      ),
      headers: ApiConfig.headers(
        token: token,
      ),
    );

    if (response.statusCode == 200) {
      return BusinessMonthlyGrowthModel.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      "Failed to fetch trends",
    );
  }
  static Future<BusinessAnalysisModel> getBusinessAnalysis({
    required String token,
    required int businessId,
    required int months,
  }) async {
    final response = await http.get(
      Uri.parse(ApiConfig.businessTrends(businessId, months)),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      return BusinessAnalysisModel.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception("Failed to load Business Analysis");
  }

  Future<ReceivePaymentResponse> receivePayment({
    required ReceivePaymentRequest request,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          ApiConfig.recordPayment(
            request.purchaseId,
          ),
        ),
        headers: ApiConfig.headers(
          token: token,
        ),
        body: jsonEncode({
          "received_amount":
          request.receivedAmount,
        }),
      );

      final data =
      jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return ReceivePaymentResponse
            .fromJson(data);
      }

      throw Exception(
        data["message"] ??
            "Failed to record payment",
      );
    } catch (e) {
      throw Exception(
        "Receive Payment Error: $e",
      );
    }
  }
  Future<BusinessModel> createBusinessApi({
    required String token,
    required CreateBusinessRequestModel model,
  }) async {
    final response = await http.post(
      ApiConfig.url(ApiConfig.businessList),
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(model.toJson()),
    );

    print("📤 REQUEST: ${model.toJson()}");
    print("📥 RESPONSE: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return BusinessModel.fromJson(json);
    } else {
      throw Exception("Failed: ${response.body}");
    }
  }

  static Future<List<Business>> fetchBusinesses() async {
    final token = await TokenStorage.getToken();

    final response = await http.get(
      ApiConfig.url(ApiConfig.businessList),
      headers: ApiConfig.headers(token: token),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Business.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized - Token expired");
    } else {
      throw Exception("Error: ${response.statusCode}");
    }
  }
  Future<CustomerResponseModel> getCustomerById({
    required String token,
    required int customerId,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}${ApiConfig.addCustomer}/$customerId");

    final response = await http.get(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      // Some APIs wrap the object in {"success":true,"data":{...}} —
      // handle both shapes safely.
      final data = decoded is Map && decoded.containsKey('data')
          ? decoded['data']
          : decoded;
      return CustomerResponseModel.fromJson(data);
    }

    throw Exception(
      "Failed to load customer (${response.statusCode}): ${response.body}",
    );
  }
  Future<List<CustomerResponseModel>> fetchCustomers({
    required String token,
    required int businessId,
  }) async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/v1/customers?business_id=$businessId",
      );

      final response = await http.get(
        url,
        headers: ApiConfig.headers(token: token),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        return data.map((e) => CustomerResponseModel.fromJson(e)).toList();
      }

      switch (response.statusCode) {
        case 401:
          throw "Session expired. Please login again.";

        case 403:
          throw "You don't have access to add customers.";

        case 404:
          throw "Customers not found.";

        case 500:
          throw "Server error. Try again later.";

        default:
          throw "Unable to load customers.";
      }
    } catch (e) {
      if (e.toString().contains("SocketException")) {
        throw "No internet connection.";
      }

      throw e.toString();
    }
  }
  Future<String> updateCustomer({
    required String token,
    required int customerId,
    required UpdateCustomerRequestModel request,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse(
          "${ApiConfig.baseUrl}/api/v1/customers/$customerId",
        ),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data["message"] ??
            "Customer updated successfully";
      }

      throw data["detail"] ??
          data["message"] ??
          "Failed to update customer";
    } catch (e) {
      throw e.toString();
    }
  }
  Future<void> deleteCustomer({
    required String token,
    required int customerId,
  }) async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/v1/customers/$customerId",
      );

      final response = await http.delete(
        url,
        headers: ApiConfig.headers(token: token),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        return;
      }

      switch (response.statusCode) {
        case 401:
          throw "Session expired. Please login again.";

        case 403:
          throw "You don't have permission to delete this customer.";

        case 404:
          throw "Customer not found.";

        case 500:
          throw "Server error. Try again later.";

        default:
          throw "Unable to delete customer.";
      }
    } catch (e) {
      if (e.toString().contains("SocketException")) {
        throw "No internet connection.";
      }

      throw e.toString();
    }
  }
  Future<void> addCustomer({
    required int businessId,
    required String name,
    required String phone,
    required String pendingAmount,
    required String token,

    // ✅ Optional fields
    String? gender,
    String? email,
    String? fcmToken,
  }) async {
    try {
      final body = {
        "name": name,
        "phone": phone,
        "pending_amount": pendingAmount,
        "business_id": businessId,

        // ✅ Optional fields
        if (gender != null && gender.isNotEmpty) "gender": gender,
        if (email != null && email.isNotEmpty) "email": email,
        if (pendingAmount.isNotEmpty) "pending_amount": pendingAmount,
        if (fcmToken != null && fcmToken.isNotEmpty) "fcm_token": fcmToken,
      };

      final response = await http
          .post(
        ApiConfig.url(ApiConfig.addCustomer),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      // ✅ Success
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      // ✅ Show backend message directly
      final errorMessage = data["detail"] ?? data["message"] ?? data["error"];

      if (errorMessage != null) {
        throw Exception(errorMessage.toString());
      }

      // ✅ Fallback errors
      switch (response.statusCode) {
        case 401:
          throw Exception("Session expired. Please login again");

        case 404:
          throw Exception("Business not found");

        case 409:
          throw Exception("Customer already exists");

        case 500:
          throw Exception("Server error. Try again later");

        default:
          throw Exception("Failed to add customer");
      }
    } on SocketException {
      throw Exception("No internet connection");
    } on FormatException {
      throw Exception("Invalid server response");
    } catch (e) {
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> createExpense({
    required String token,
    required BusinessExpenseModel expense,
  }) async {
    try {
      final response = await http.post(
        ApiConfig.url("/api/v1/expenses"),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode(expense.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw Exception("Failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("Expense creation failed: $e");
    }
  }
}

class IncomeService {
  final Ref ref;
  IncomeService(this.ref);

  Future<void> addIncome(BusinessIncomeRequest request) async {
    final token = ref.read(tokenProvider);

    try {
      final res = await http.post(
        ApiConfig.url("/api/v1/income"),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode(request.toJson()),
      );

      _handleResponse(res);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError("No internet connection. Please try again.");
    }
  }

  void _handleResponse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    String? msg;
    try {
      final data = jsonDecode(res.body);
      if (data is Map) {
        final m = data["message"];
        final e = data["error"];
        final d = data["detail"];
        if (m != null && m.toString().trim().isNotEmpty) {
          msg = m.toString();
        } else if (e != null && e.toString().trim().isNotEmpty) {
          msg = e.toString();
        } else if (d != null && d.toString().trim().isNotEmpty) {
          msg = d.toString();
        }
      }
    } catch (_) {}

    if (msg != null) throw AppError(msg);

    switch (res.statusCode) {
      case 400:
        throw AppError("Invalid input. Please check amount/source.");
      case 401:
        throw AppError("Session expired. Please login again.");
      case 403:
        throw AppError("You are not allowed to perform this action.");
      case 404:
        throw AppError("Service not found.");
      case 500:
        throw AppError("Server error. Try again later.");
      default:
        throw AppError("Something went wrong.");
    }
  }
}
