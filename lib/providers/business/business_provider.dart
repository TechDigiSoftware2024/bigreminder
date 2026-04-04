import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../api_config/api_config.dart';
import '../../models/business_model.dart';
import '../../repository/business_repo.dart';
import '../../services/business/business_api_service.dart';

/// 🔌 Repository Provider
final businessRepositoryProvider = Provider(
      (ref) => BusinessRepo(
    BusinessApiService(ApiConfig.baseUrl),
  ),
);

/// ⚡ Notifier Provider
final businessProvider = StateNotifierProvider<
    BusinessNotifier, AsyncValue<CreateBusinessModel?>>((ref) {
  final repo = ref.watch(businessRepositoryProvider);
  return BusinessNotifier(repo);
});

/// 🧠 Notifier
class BusinessNotifier
    extends StateNotifier<AsyncValue<CreateBusinessModel?>> {
  final BusinessRepo repo;

  BusinessNotifier(this.repo) : super(const AsyncData(null));

  Future<void> createBusiness({
    required String name,
    required String category,
    required String address,
  }) async {
    state = const AsyncLoading();

    try {
      final response = await repo.createBusiness(
        name: name,
        category: category,
        address: address,
      );

      state = AsyncData(response);
    } catch (e, st) {
      state = AsyncError(
        e.toString().replaceAll("Exception: ", ""),
        st,
      );
    }
  }
}