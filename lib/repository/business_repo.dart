import '../models/business_models/business_customer_req_model.dart';
import '../models/business_models/businesss_edit_profile_model.dart';
import '../models/business_models/receive_payment_request_model.dart';
import '../models/business_models/receive_payment_response_model.dart';
import '../services/business/business_service.dart';
import '../services/local_storage/local_storage.dart';

class BusinessRepository {
  final BusinessService service;

  BusinessRepository(this.service);

  Future<ReceivePaymentResponse> receivePayment({
    required ReceivePaymentRequest request,
  }) async {
    final token = await TokenStorage.getToken();

    return service.receivePayment(
      request: request,
      token: token ?? "",
    );
  }

  Future<void> updateBusiness({
  required int businessId,
  required BusinessProfileEditModel model,
  }) async {
  await updateBusiness(
  businessId: businessId,
  model: model,
  );
  }

  Future<String> updateCustomer({
    required int customerId,
    required UpdateCustomerRequestModel request,
  }) async {
    final token = await TokenStorage.getToken();

    return service.updateCustomer(
      token: token ?? "",
      customerId: customerId,
      request: request,
    );
  }
  Future<void> deleteCustomer(int customerId) async {
    final token = await TokenStorage.getToken();

    await service.deleteCustomer(
      token: token ?? "",
      customerId: customerId,
    );
  }
}