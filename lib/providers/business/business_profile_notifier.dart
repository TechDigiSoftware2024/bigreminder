import 'package:bigreminder/models/business_models/businesss_edit_profile_model.dart';
import 'package:bigreminder/services/business/business_service.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'business_profile_state.dart';

class BusinessProfileNotifier
    extends StateNotifier<BusinessProfileState> {

  BusinessProfileNotifier()
      : super(const BusinessProfileState());

  Future<void> updateProfile({
    required int businessId,
    required BusinessProfileEditModel model,
}) async {
    try {
      state = state.copyWith(
        status : BusinessProfileStatus.loading,
      );
      await BusinessService().updateBusiness(businessId: businessId, model: model);

      state = state.copyWith(
        status: BusinessProfileStatus.success,
      );
    }
    catch(e){
      state = state.copyWith(
        status: BusinessProfileStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}