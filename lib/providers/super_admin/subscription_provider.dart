import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/super_admin_models/subscription_model.dart';
import '../../services/super_admin/subscription_api_service.dart';
import '../../services/super_admin/subscription_service.dart';
import '../../subscription/feature_model.dart';
import '../../subscription/plan_model.dart';

class SubscriptionProvider extends ChangeNotifier {
  final api = PlanAndFeatureService();
  final subsApi = SubscriptionService();

  List<PlanModel> plans = [];
  List<FeatureModel> features = [];

  // 🔥 NEW
  SubscriptionModel? currentSubscription;
  List<SubscriptionModel> subscriptions = [];

  String token = "";

  bool isPlansLoading = false;
  bool isFeaturesLoading = false;
  bool isMappingLoading = false;

  // 🔥 NEW
  bool isSubLoading = false;
  bool isSubListLoading = false;

  // ================================
  // 🔑 TOKEN MANAGEMENT
  // ================================
  void setToken(String t) {
    token = t;
  }

  Future<void> _ensureToken() async {
    if (token.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? "";

    if (token.isEmpty) {
      throw Exception("❌ Token missing");
    }
  }

  // ================================
  // 📥 LOAD ALL PLANS
  // ================================
  Future<void> loadAll() async {
    try {
      await _ensureToken();

      isPlansLoading = true;
      notifyListeners();

      final rawPlans = await api.getPlans(token);
      plans = rawPlans.map((e) => PlanModel.fromJson(e)).toList();

    } catch (e) {
      debugPrint("❌ LOAD PLANS ERROR: $e");
    } finally {
      isPlansLoading = false;
      notifyListeners();
    }
  }

  // ================================
  // 📥 LOAD FEATURES
  // ================================
  Future<void> loadFeatures() async {
    try {
      await _ensureToken();

      isFeaturesLoading = true;
      notifyListeners();

      final raw = await api.getFeatures(token);
      features = raw.map((e) => FeatureModel.fromJson(e)).toList();

    } catch (e) {
      debugPrint("❌ FEATURE LOAD ERROR: $e");
    } finally {
      isFeaturesLoading = false;
      notifyListeners();
    }
  }

  // ================================
  // ➕ CREATE FEATURE
  // ================================
  Future<void> addFeature({
    required String key,
    required String name,
    required String description,
  }) async {
    try {
      await _ensureToken();

      await api.createFeature(
        token: token,
        key: key,
        name: name,
        description: description,
      );

      await loadFeatures();

    } catch (e) {
      debugPrint("❌ CREATE FEATURE ERROR: $e");
      rethrow;
    }
  }

  // ================================
  // ➕ CREATE PLAN
  // ================================
  Future<void> addPlanFull({
    required String name,
    required int price,
    String duration = "monthly",
    String billingCycle = "monthly",
    int durationDays = 30,
    int trialDays = 0,
    bool isActive = true,
  }) async {
    try {
      await _ensureToken();

      isPlansLoading = true;
      notifyListeners();

      await api.createPlan(
        token: token,
        name: name,
        price: price,
        duration: duration,
        billingCycle: billingCycle,
        durationDays: durationDays,
        trialDays: trialDays,
        isActive: isActive,
      );

      await loadAll();

    } catch (e) {
      debugPrint("❌ CREATE PLAN ERROR: $e");
      rethrow;
    } finally {
      isPlansLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPlan(String name, int price) async {
    await addPlanFull(name: name, price: price);
  }

  // ================================
  // 🧩 PLAN ↔ FEATURE MAPPING
  // ================================
  Map<int, Set<int>> planFeatureMap = {};

  Future<void> loadPlanFeatures(int planId) async {
    try {
      await _ensureToken();

      isMappingLoading = true;
      notifyListeners();

      final raw = await api.getPlanFeatures(token, planId);

      final set = raw.map((e) {
        final id = e['feature_id'] ?? e['id'];
        return int.tryParse(id.toString()) ?? 0;
      }).toSet();

      planFeatureMap[planId] = set;

    } catch (e) {
      debugPrint("❌ LOAD PLAN FEATURES ERROR: $e");
    } finally {
      isMappingLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFeature({
    required int planId,
    required int featureId,
  }) async {
    try {
      await _ensureToken();

      final currentSet = planFeatureMap[planId] ?? {};
      final isSelected = currentSet.contains(featureId);

      if (isSelected) {
        currentSet.remove(featureId);
      } else {
        currentSet.add(featureId);
      }

      planFeatureMap[planId] = {...currentSet};
      notifyListeners();

      if (isSelected) {
        await api.removeFeatureFromPlan(
          token: token,
          planId: planId,
          featureId: featureId,
        );
      } else {
        await api.addFeatureToPlan(
          token: token,
          planId: planId,
          featureId: featureId,
        );
      }

      await loadPlanFeatures(planId);

    } catch (e) {
      debugPrint("❌ TOGGLE FAILED: $e");
      rethrow;
    }
  }

  // =========================================================
  // 🔥 SUBSCRIPTION SECTION (same pattern as plans/features)
  // =========================================================

  Future<void> createSubscription({
    required int businessId,
    required int planId,
  }) async {
    try {
      await _ensureToken();

      isSubLoading = true;
      notifyListeners();

      currentSubscription = await subsApi.createSubscription(
        token: token,
        businessId: businessId,
        planId: planId,
      );

    } catch (e) {
      debugPrint("❌ CREATE SUB ERROR: $e");
      rethrow;
    } finally {
      isSubLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMySubscription() async {
    try {
      await _ensureToken();

      isSubLoading = true;
      notifyListeners();

      currentSubscription =
      await subsApi.getMySubscription(token);

    } catch (e) {
      debugPrint("❌ LOAD SUB ERROR: $e");
    } finally {
      isSubLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllSubscriptions({int? businessId}) async {
    try {
      await _ensureToken();

      isSubListLoading = true;
      notifyListeners();

      if (businessId != null) {
        subscriptions = await subsApi.getAllSubscriptions(
          token,
          businessId: businessId,
        );
      } else {
        subscriptions = [];
      }
    } catch (e) {
      debugPrint("❌ LOAD ALL SUB ERROR: $e");
    } finally {
      isSubListLoading = false;
      notifyListeners();
    }
  }
  Future<void> activateSubscription(int id) async {
    try {
      await _ensureToken();

      await subsApi.updateSubscription(
        token: token,
        id: id,
        status: "active",
        paymentStatus: "paid",
      );

      await loadMySubscription();

    } catch (e) {
      debugPrint("❌ ACTIVATE ERROR: $e");
    }
  }

  bool hasFeature(String key) {
    return currentSubscription?.features.contains(key) ?? false;
  }

  bool get isSubscribed =>
      currentSubscription?.status == "active";
}

// ================================
final subscriptionProvider =
ChangeNotifierProvider<SubscriptionProvider>((ref) {
  return SubscriptionProvider();
});