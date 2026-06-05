import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/business_models/query_model.dart';
import 'business_provider.dart';

final queryProvider = AsyncNotifierProvider<QueryNotifier, QueryModel?>(
  QueryNotifier.new,
);

class QueryNotifier extends AsyncNotifier<QueryModel?> {
  @override
  Future<QueryModel?> build() async {
    return null;
  }

  Future<void> createQuery({
    required String message,
    required int businessId,
    required String token,
  }) async {
    state = const AsyncLoading();

    try {
      final QueryModel result = await ref
          .read(queryServiceProvider)
          .createQuery(
        message: message,
        businessId: businessId,
        token: token,
      );

      state = AsyncData(result);

      ref.invalidate(
        queryListProvider,
      );

      await Future.delayed(
        const Duration(milliseconds: 300),
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
