class BusinessAccess {
  final int businessId;
  bool reminderEnabled;
  bool incomeEnabled;
  bool expenseEnabled;
  bool customersEnabled;
  bool supportQueriesEnabled;
  int maxCustomers;

  BusinessAccess({
    required this.businessId,
    required this.reminderEnabled,
    required this.incomeEnabled,
    required this.expenseEnabled,
    required this.customersEnabled,
    required this.supportQueriesEnabled,
    required this.maxCustomers,
  });

  factory BusinessAccess.fromJson(Map<String, dynamic> json) {
    return BusinessAccess(
      businessId: json['business_id'] ?? 0,
      reminderEnabled: json['reminder_enabled'] ?? false,
      incomeEnabled: json['income_enabled'] ?? false,
      expenseEnabled: json['expense_enabled'] ?? false,
      customersEnabled: json['customers_enabled'] ?? false,
      supportQueriesEnabled: json['support_queries_enabled'] ?? false,
      maxCustomers: json['max_customers'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "business_id": businessId,
      "reminder_enabled": reminderEnabled,
      "income_enabled": incomeEnabled,
      "expense_enabled": expenseEnabled,
      "customers_enabled": customersEnabled,
      "support_queries_enabled": supportQueriesEnabled,
      "max_customers": maxCustomers,
    };
  }
}