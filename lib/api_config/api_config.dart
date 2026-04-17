class ApiConfig {
  // ================= BASE URL =================
  static const String baseUrl =
      "https://bizzreminderbackend.onrender.com";

  // ================= ENDPOINTS =================
  static const String login = "/api/v1/auth/login";
  static const String register = "/api/v1/auth/register-business";
  static const String businessList = "/api/v1/businesses";
  static const String businessAccess ="/api/v1/access-control";
  static const String totalUserList = "/api/v1/users";

  static Uri url(String endpoint) {
    return Uri.parse(baseUrl + endpoint);
  }

  static Map<String, String> headers({String? token}) {
    return {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty)
        "Authorization": "Bearer $token",
    };
  }
}