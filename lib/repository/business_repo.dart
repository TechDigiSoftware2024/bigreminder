import '../models/business_model.dart';
import '../services/business/business_api_service.dart';

class BusinessRepo {
  final BusinessApiService api;

  BusinessRepo(this.api);

  Future<CreateBusinessModel> createBusiness({
    required String name,
    required String category,
    required String address,
  }) {
    return api.createBusiness(
      name: name,
      category: category,
      address: address,
    );
  }
}