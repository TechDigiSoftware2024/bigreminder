class ApiConfig {
  // ================= BASE URL =================
  static const String baseUrl =
      "https://sakshamdigitaltechnology.in/auth";

  // ================= ENDPOINTS =================
  static const String login = "/login";
  static const String register = "/register";

  // ================= HEADERS =================
  static Map<String, String> headers({
    String? token,
  }) {
    return {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty)
        "Authorization": "Bearer $token",
    };
  }

  // ================= FULL URL BUILDER =================
  static Uri url(String endpoint) {
    return Uri.parse("$baseUrl$endpoint");
  }
}