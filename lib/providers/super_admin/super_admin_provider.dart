import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

import '../../api_config/api_config.dart';
import '../../models/business_models/query_model.dart';
import '../business/business_provider.dart';

/// ================= USERS =================

final userProvider = FutureProvider<List<dynamic>>((ref) async {
  final token = ref.read(tokenProvider);

  final response = await http.get(
    ApiConfig.url(ApiConfig.totalUserList),
    headers: ApiConfig.headers(token: token),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data is List) return data;
    if (data["data"] != null) return data["data"];

    return [];
  }

  throw Exception("Failed to load users");
});

/// ================= BUSINESSES =================

final businessListProvider = FutureProvider<List<dynamic>>((ref) async {
  final token = ref.read(tokenProvider);

  final response = await http.get(
    ApiConfig.url(ApiConfig.businessList),
    headers: ApiConfig.headers(token: token),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data is List) return data;
    if (data["data"] != null) return data["data"];

    return [];
  }

  throw Exception("Failed to load businesses");
});

/// ================= QUERIES =================

final adminQueryProvider = FutureProvider<List<QueryModel>>((ref) async {
  final token = ref.read(tokenProvider);

  return ref.read(queryServiceProvider).getAllQueries(token: token);
});

/// ================= REPLY QUERY =================

final replyToQueryProvider =
    StateNotifierProvider<ReplyToQueryNotifier, AsyncValue<void>>(
      (ref) => ReplyToQueryNotifier(ref),
    );

class ReplyToQueryNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ReplyToQueryNotifier(this.ref) : super(const AsyncData(null));

  Future<void> sendReply({
    required int queryId,
    required String response,
    required String status,
  }) async {
    state = const AsyncLoading();

    try {
      final token = ref.read(tokenProvider);

      await ref
          .read(queryServiceProvider)
          .updateQuery(
            queryId: queryId,
            status: status,
            adminResponse: response,
            token: token,
          );

      ref.invalidate(adminQueryProvider);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);

      rethrow;
    }
  }
}
