class ApiConfig {
  // ================= BASE URL =================
  static const String baseUrl = "https://sakshamdigitaltechnology.in";

  // ================= ENDPOINTS =================
  static const String login = "/api/v1/auth/login";

  static const String register = "/api/v1/auth/register-business";

  static const String businessList = "/api/v1/businesses";

  static const String businessAccess = "/api/v1/access-control";

  static const String totalUserList = "/api/v1/users";

  static const String bills = "/api/v1/bills";

  static const String subscriptions = "/api/v1/subscriptions";

  static const String products = "/api/v1/products";

  static String businessTrends(int businessId, int months) => "$baseUrl/api/v1/dashboard/business/$businessId/trends?months=$months";
  static const String addCustomer = "/api/v1/customers";

  static const String purchases = "/api/v1/bills";

  static const String createQuery = "$baseUrl/api/v1/queries";

  /// Record Payment Endpoint
  static String recordPayment(int purchaseId) => "$baseUrl$purchases/$purchaseId/record-payment";

  static Uri url(String endpoint) {
    return Uri.parse(baseUrl + endpoint);
  }

  static Map<String, String> headers({String? token}) {
    return {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }
}
