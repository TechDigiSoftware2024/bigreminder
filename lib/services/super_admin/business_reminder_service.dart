import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config/api_config.dart';
import '../../models/super_admin_models/business_create_reminder.dart';

class SuperReminderService {

  /// ================= CREATE REMINDER =================
  Future<BusinessReminderModel> createReminder({
    required String message,
    required DateTime scheduledAt,
    required String targetGender,
    required int businessId,
    required String token,
  }) async {

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/reminders',
      ),
      headers: ApiConfig.headers(
        token: token,
      ),
      body: jsonEncode({
        "message": message,
        "scheduled_at": scheduledAt.toIso8601String(),
        "target_gender": targetGender,
        "business_id": businessId,
      }),
    );

    print("===============");
    print("CREATE REMINDER");
    print("STATUS => ${response.statusCode}");
    print("BODY => ${response.body}");
    print("===============");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return BusinessReminderModel.fromJson(data);
    }

    throw Exception(response.body);
  }

  /// ================= GET ALL REMINDERS =================
  Future<List<BusinessReminderModel>> getReminders({
    required String token,
    required int businessId, // ✅ ADD THIS PARAMETER
  }) async {

    // ✅ ADD business_id AS QUERY PARAMETER
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/reminders',
    ).replace(queryParameters: {
      'business_id': businessId.toString(),
    });

    final response = await http.get(
      uri,
      headers: ApiConfig.headers(
        token: token,
      ),
    );

    print("===============");
    print("GET REMINDERS");
    print("BUSINESS ID => $businessId");
    print("URL => $uri");
    print("STATUS => ${response.statusCode}");
    print("BODY => ${response.body}");
    print("===============");

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => BusinessReminderModel.fromJson(e))
          .toList();
    }

    throw Exception(response.body);
  }

  /// ================= GET BY ID =================
  Future<BusinessReminderModel> getReminderById({
    required int reminderId,
    required String token,
    required int businessId, // ✅ ADD THIS PARAMETER
  }) async {

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/reminders/$reminderId',
    ).replace(queryParameters: {
      'business_id': businessId.toString(),
    });

    final response = await http.get(
      uri,
      headers: ApiConfig.headers(
        token: token,
      ),
    );

    print("===============");
    print("GET REMINDER");
    print("ID => $reminderId");
    print("BUSINESS ID => $businessId");
    print("STATUS => ${response.statusCode}");
    print("BODY => ${response.body}");
    print("===============");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return BusinessReminderModel.fromJson(data);
    }

    throw Exception(response.body);
  }

  /// ================= UPDATE REMINDER =================
  Future<BusinessReminderModel> updateReminder({
    required int reminderId,
    required String message,
    required DateTime scheduledAt,
    required String targetGender,
    required int businessId,
    required String token,
  }) async {

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/reminders/$reminderId',
    ).replace(queryParameters: {
      'business_id': businessId.toString(),
    });

    final response = await http.put(
      uri,
      headers: ApiConfig.headers(
        token: token,
      ),
      body: jsonEncode({
        "message": message,
        "scheduled_at": scheduledAt.toIso8601String(),
        "target_gender": targetGender,
        "business_id": businessId,
      }),
    );

    print("===============");
    print("UPDATE REMINDER");
    print("ID => $reminderId");
    print("BUSINESS ID => $businessId");
    print("STATUS => ${response.statusCode}");
    print("BODY => ${response.body}");
    print("===============");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return BusinessReminderModel.fromJson(data);
    }

    throw Exception(response.body);
  }

  /// ================= DELETE REMINDER =================
  Future<void> deleteReminder({
    required int reminderId,
    required String token,
    required int businessId, // ✅ ADD THIS PARAMETER
  }) async {

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/reminders/$reminderId',
    ).replace(queryParameters: {
      'business_id': businessId.toString(),
    });

    final response = await http.delete(
      uri,
      headers: ApiConfig.headers(
        token: token,
      ),
    );

    print("===============");
    print("DELETE REMINDER");
    print("ID => $reminderId");
    print("BUSINESS ID => $businessId");
    print("STATUS => ${response.statusCode}");
    print("BODY => ${response.body}");
    print("===============");

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(response.body);
    }
  }
}