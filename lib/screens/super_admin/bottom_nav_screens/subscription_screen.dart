import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/super_admin_models/subscription_model.dart';
import '../../../providers/business/business_provider.dart';
import '../../../providers/super_admin/subscription_provider.dart';
import '../../../services/super_admin/delete_service.dart';
import '../../../subscription/feature_model.dart';
import '../../../subscription/plan_model.dart';
import '../../../theme/super_admin_colors.dart';
import '../../../widgets/custom_button.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/custom_dialog.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: SuperAdminColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: SuperAdminColors.primaryDark,
        title: const Text(
          'Plans & Billing',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 20 : 14,
              14,
              isDesktop ? 20 : 14,
              0,
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: SuperAdminColors.primaryDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade700,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(height: 40, text: 'Plans'),
                  Tab(height: 40, text: 'Features'),
                  Tab(height: 40, text: 'Subscriptions'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                PlansTab(),
                FeaturesTab(),
                SubscriptionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// ======================= PLANS TAB ===================== //
//////////////////////////////////////////////////////////////
// class PlansTab extends ConsumerStatefulWidget {
//   const PlansTab({super.key});
//
//   @override
//   ConsumerState<PlansTab> createState() => _PlansTabState();
// }
//
// class _PlansTabState extends ConsumerState<PlansTab> {
//
//   @override
//   void initState() {
//     super.initState();
//
//     Future.microtask(() {
//       ref.read(subscriptionProvider).loadAll();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = ref.watch(subscriptionProvider);
//
//     if (provider.isPlansLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     final plans = provider.plans;
//
//     return RefreshIndicator(
//       onRefresh: () => ref.read(subscriptionProvider).loadAll(),
//       child: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//
//           /// 🔹 HEADER ACTION
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 "Plans",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               ElevatedButton.icon(
//                 onPressed: () async {
//                   await showDialog(
//                     context: context,
//                     builder: (_) => const CreatePlanDialog(),
//                   );
//
//                   ref.read(subscriptionProvider).loadAll();
//                 },
//                 icon: const Icon(Icons.add),
//                 label: const Text("Create"),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 16),
//
//           /// 🔹 EMPTY STATE
//           if (plans.isEmpty)
//             const Center(
//               child: Padding(
//                 padding: EdgeInsets.only(top: 40),
//                 child: Text("No Plans Found"),
//               ),
//             ),
//
//           /// 🔹 PLAN LIST
//           ...plans.map((plan) {
//             return Padding(
//               padding: const EdgeInsets.only(bottom: 12),
//               child: _planCardEnhanced(plan,context),
//             );
//           }).toList(),
//         ],
//       ),
//     );
//   }
// }

Widget _planCardEnhanced(PlanModel plan, BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlanFeatureMappingScreen(plan: plan),
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: plan.isActive ? Colors.green.shade100 : Colors.red.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔹 TOP ROW (Name + Status)
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: plan.isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  plan.isActive ? "Active" : "Inactive",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: plan.isActive ? Colors.green : Colors.red,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              InkWell(
                onTap: () {
                  // Delete action
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          /// 🔹 PRICE
          Text(
            AppFormatters.currency(plan.price),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 4),

          /// 🔹 BILLING
          Text(
            "${plan.billingCycle.toUpperCase()} PLAN",
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),

          /// 🔹 DIVIDER
          Divider(color: Colors.grey.shade200),

          /// 🔹 DETAILS ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              /// Duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Duration",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${plan.durationDays} days",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              /// Trial
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Trial",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${plan.trialDays} days",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              /// ID (admin useful)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Plan ID",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "#${plan.id}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
//////////////////////////////////////////////////////////////
/// ===================== FEATURES TAB ==================== ///
//////////////////////////////////////////////////////////////
//
// class FeaturesTab extends ConsumerStatefulWidget {
//   const FeaturesTab({super.key});
//
//   @override
//   ConsumerState<FeaturesTab> createState() => _FeaturesTabState();
// }
//
// class _FeaturesTabState extends ConsumerState<FeaturesTab> {
//
//   @override
//   void initState() {
//     super.initState();
//
//     Future.microtask(() {
//       ref.read(subscriptionProvider).loadFeatures();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = ref.watch(subscriptionProvider);
//
//     if (provider.isFeaturesLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     final features = provider.features;
//
//     return RefreshIndicator(
//       onRefresh: () => ref.read(subscriptionProvider).loadFeatures(),
//       child: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//
//           /// 🔹 HEADER (same style as plans)
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 "Features",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               ElevatedButton.icon(
//                 onPressed: () async {
//                   await showDialog(
//                     context: context,
//                     builder: (_) => const CreateFeatureDialog(),
//                   );
//
//                   ref.read(subscriptionProvider).loadFeatures();
//                 },
//                 icon: const Icon(Icons.add),
//                 label: const Text("Create"),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 16),
//
//           /// 🔹 EMPTY STATE
//           if (features.isEmpty)
//             const Center(
//               child: Padding(
//                 padding: EdgeInsets.only(top: 40),
//                 child: Text("No Features Found"),
//               ),
//             ),
//
//           /// 🔹 FEATURE LIST
//           ...features.map((f) {
//             return Padding(
//               padding: const EdgeInsets.only(bottom: 12),
//               child: _featureCardEnhanced(f),
//             );
//           }).toList(),
//         ],
//       ),
//     );
//   }
// }
Widget _featureCardEnhanced(
FeatureModel f,
BuildContext context,
WidgetRef ref,) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(
        color: f.isActive ? Colors.green.shade100 : Colors.red.shade100,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// 🔹 TOP ROW (name + status)
        Row(
          children: [
            Expanded(
              child: Text(
                f.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: f.isActive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                f.isActive ? "ACTIVE" : "INACTIVE",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: f.isActive ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 10),

            InkWell(
              onTap: () {
                CustomDialog.showConfirmDialog(
                  context: context,
                  title: "Delete Feature",
                  message:
                  "This action cannot be undone.\n'${f.name}' will be permanently removed.",
                  confirmLabel: 'Delete',
                  isDestructive: true,
                  icon: Icons.delete_outline_rounded,
                  onConfirm: () async {
                    try {
                      final message =
                      await DeleteService.deleteFeature(
                        featureId: f.id,
                        token: ref.read(tokenProvider),
                      );

                      if (!context.mounted) return;

                      CustomDialog.showSuccessSnack(
                        context,
                        message,
                      );

                      await ref
                          .read(subscriptionProvider)
                          .loadFeatures();
                    } catch (e) {
                      if (!context.mounted) return;

                      CustomDialog.showErrorSnack(
                        context,
                        e.toString(),
                      );
                    }
                  },
                );
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

  //
  //       Text(
  //         f.key,
  //         style: const TextStyle(fontSize: 13),
  //       ),
  // const SizedBox(height: 10),

        /// 🔹 DESCRIPTION
        Text(
          f.description.isEmpty ? "No description" : f.description,
          style: const TextStyle(fontSize: 13),
        ),

        Divider(color: Colors.grey.shade200),


        /// 🔹 BOTTOM INFO (same layout as plan)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            /// Feature ID
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Feature ID",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "#${f.id}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            /// Created date
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Created",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${f.createdAt.day}/${f.createdAt.month}/${f.createdAt.year}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
//////////////////////////////////////////////////////////////
/// ================== SUBSCRIPTIONS TAB ================== ///
//////////////////////////////////////////////////////////////

class SubscriptionsTab extends ConsumerStatefulWidget {
  const SubscriptionsTab({super.key});

  @override
  ConsumerState<SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends ConsumerState<SubscriptionsTab> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(subscriptionProvider).loadAllSubscriptions();
      ref.read(subscriptionProvider).loadAll();
      final token = ref.read(tokenProvider);
      ref.read(businessControllerProvider.notifier).fetchMyBusinesses(token);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshSubs() async {
    final id = int.tryParse(searchController.text.trim());
    await ref.read(subscriptionProvider).loadAllSubscriptions(businessId: id);
  }

  Future<void> _openCreateDialog() async {
    await showDialog(
      context: context,
      builder: (_) => const CreateSubscriptionDialog(),
    );
    if (!mounted) return;
    await _refreshSubs();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(subscriptionProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final subs = provider.subscriptions;

    if (provider.isSubListLoading && subs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final listPanel = _SubscriptionsListPanel(
      subs: subs,
      searchController: searchController,
      onSearchChanged: () => setState(() {}),
      onSearchSubmit: (value) async {
        final id = int.tryParse(value.trim());
        if (id == null && value.trim().isNotEmpty) return;
        await ref
            .read(subscriptionProvider)
            .loadAllSubscriptions(businessId: id);
      },
      onClearSearch: () async {
        searchController.clear();
        setState(() {});
        await ref
            .read(subscriptionProvider)
            .loadAllSubscriptions(businessId: null);
      },
      onRefresh: _refreshSubs,
      showMobileFabPadding: !isDesktop,
    );

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// Left — compact subscription list (~1/3)
            Expanded(
              flex: 3,
              child: listPanel,
            ),
            const SizedBox(width: 12),
            /// Center + Right — pickers + assign panel
            Expanded(
              flex: 7,
              child: _CreateSubscriptionForm(
                onCreated: _refreshSubs,
                layout: _AssignLayout.split,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: listPanel,
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            backgroundColor: SuperAdminColors.primaryDark,
            foregroundColor: Colors.white,
            onPressed: _openCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Subscription'),
          ),
        ),
      ],
    );
  }
}

class _SubscriptionsListPanel extends ConsumerWidget {
  final List<SubscriptionModel> subs;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onSearchSubmit;
  final Future<void> Function() onClearSearch;
  final Future<void> Function() onRefresh;
  final bool showMobileFabPadding;

  const _SubscriptionsListPanel({
    required this.subs,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmit,
    required this.onClearSearch,
    required this.onRefresh,
    this.showMobileFabPadding = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subscriptions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${subs.length} total',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: onRefresh,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: SuperAdminColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: searchController,
            keyboardType: TextInputType.number,
            onChanged: (_) => onSearchChanged(),
            onSubmitted: onSearchSubmit,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Business ID…',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 20, color: Colors.grey.shade600),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: onClearSearch,
                    )
                  : null,
              filled: true,
              fillColor: SuperAdminColors.surfaceMuted,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: SuperAdminColors.primaryDark,
                  width: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: RefreshIndicator(
              color: SuperAdminColors.primaryDark,
              onRefresh: onRefresh,
              child: subs.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.22,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.subscriptions_outlined,
                                  size: 32,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No subscriptions',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pick business & plan in center',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: showMobileFabPadding ? 72 : 8,
                      ),
                      itemCount: subs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _subscriptionCard(subs[i], context, ref),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateSubscriptionDialog extends ConsumerStatefulWidget {
  const CreateSubscriptionDialog({super.key});

  @override
  ConsumerState<CreateSubscriptionDialog> createState() =>
      _CreateSubscriptionDialogState();
}

class _CreateSubscriptionDialogState
    extends ConsumerState<CreateSubscriptionDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: CustomDialog.dialogWidth(
          context,
          desktop: CustomDialog.formWideWidth,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 680),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _CreateSubscriptionForm(
              onCreated: () => Navigator.pop(context),
              onCancel: () => Navigator.pop(context),
              showCancel: true,
            ),
          ),
        ),
      ),
    );
  }
}

enum _AssignLayout { stacked, split }

/// Shared assign-subscription form for desktop split panel and mobile dialog.
class _CreateSubscriptionForm extends ConsumerStatefulWidget {
  final FutureOr<void> Function() onCreated;
  final VoidCallback? onCancel;
  final bool showCancel;
  final _AssignLayout layout;

  const _CreateSubscriptionForm({
    required this.onCreated,
    this.onCancel,
    this.showCancel = false,
    this.layout = _AssignLayout.stacked,
  });

  @override
  ConsumerState<_CreateSubscriptionForm> createState() =>
      _CreateSubscriptionFormState();
}

class _CreateSubscriptionFormState
    extends ConsumerState<_CreateSubscriptionForm> {
  final Map<int, int> selectedMap = {};
  int? tempSelectedBusiness;
  int? tempSelectedPlan;
  final businessSearchCtrl = TextEditingController();
  final planSearchCtrl = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(subscriptionProvider).loadAll();
      final token = ref.read(tokenProvider);
      ref.read(businessControllerProvider.notifier).fetchMyBusinesses(token);
    });
  }

  @override
  void dispose() {
    businessSearchCtrl.dispose();
    planSearchCtrl.dispose();
    super.dispose();
  }

  void _addPair() {
    if (tempSelectedBusiness == null || tempSelectedPlan == null) {
      CustomDialog.showErrorSnack(context, 'Select a business and a plan');
      return;
    }
    setState(() {
      selectedMap[tempSelectedBusiness!] = tempSelectedPlan!;
      tempSelectedBusiness = null;
      tempSelectedPlan = null;
      businessSearchCtrl.clear();
      planSearchCtrl.clear();
    });
  }

  Future<void> _handleCreate() async {
    if (selectedMap.isEmpty) {
      if (tempSelectedBusiness != null && tempSelectedPlan != null) {
        selectedMap[tempSelectedBusiness!] = tempSelectedPlan!;
      } else {
        CustomDialog.showErrorSnack(context, 'Add at least one assignment');
        return;
      }
    }

    // Friendly pre-check against loaded subscriptions
    final existing = ref.read(subscriptionProvider).subscriptions;
    for (final entry in selectedMap.entries) {
      final hit = existing.where((s) => s.businessId == entry.key).toList();
      if (hit.isNotEmpty) {
        CustomDialog.showErrorSnack(
          context,
          'Business #${entry.key} already has a subscription'
          '${hit.first.status.isNotEmpty ? " (${hit.first.status})" : ""}. '
          'Edit or delete it before assigning again.',
        );
        return;
      }
    }

    setState(() => isLoading = true);
    try {
      for (final entry in selectedMap.entries) {
        await ref.read(subscriptionProvider).createSubscription(
              businessId: entry.key,
              planId: entry.value,
            );
      }
      if (!mounted) return;
      final count = selectedMap.length;
      setState(() {
        selectedMap.clear();
        tempSelectedBusiness = null;
        tempSelectedPlan = null;
      });
      CustomDialog.showSuccessSnack(
        context,
        count == 1
            ? 'Subscription assigned'
            : '$count subscriptions assigned',
      );
      await widget.onCreated();
    } catch (e) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(context, _mapErrorToMessage(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  BoxDecoration get _panelDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final subProvider = ref.watch(subscriptionProvider);
    final bizProvider = ref.watch(businessControllerProvider);
    final plans = subProvider.plans;
    final businesses = bizProvider.businesses;

    final filteredBusinesses = businesses.where((b) {
      final q = businessSearchCtrl.text.toLowerCase();
      if (q.isEmpty) return true;
      return b.name.toLowerCase().contains(q) || b.id.toString().contains(q);
    }).toList();

    final filteredPlans = plans.where((p) {
      final q = planSearchCtrl.text.toLowerCase();
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.price.toString().contains(q);
    }).toList();

    String businessLabel(int id) {
      try {
        return businesses.firstWhere((b) => b.id == id).name;
      } catch (_) {
        return 'Business #$id';
      }
    }

    String planLabel(int id) {
      try {
        final p = plans.firstWhere((x) => x.id == id);
        return '${p.name} · ${AppFormatters.currency(p.price)}';
      } catch (_) {
        return 'Plan #$id';
      }
    }

    final canAdd =
        tempSelectedBusiness != null && tempSelectedPlan != null && !isLoading;
    final canCreate = !isLoading &&
        (selectedMap.isNotEmpty ||
            (tempSelectedBusiness != null && tempSelectedPlan != null));

    final businessPanel = _pickerPanel(
      title: 'Business',
      count: filteredBusinesses.length,
      searchCtrl: businessSearchCtrl,
      searchHint: 'Search business…',
      child: bizProvider.isLoading && businesses.isEmpty
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : filteredBusinesses.isEmpty
              ? Center(
                  child: Text(
                    'No businesses',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredBusinesses.length,
                  itemBuilder: (_, i) {
                    final b = filteredBusinesses[i];
                    final selected = tempSelectedBusiness == b.id;
                    final queued = selectedMap.containsKey(b.id);
                    return _selectTile(
                      title: b.name,
                      subtitle: 'ID ${b.id}',
                      selected: selected,
                      trailing: queued
                          ? Icon(
                              Icons.playlist_add_check_rounded,
                              size: 18,
                              color: Colors.green.shade600,
                            )
                          : null,
                      onTap: isLoading
                          ? null
                          : () => setState(() => tempSelectedBusiness = b.id),
                    );
                  },
                ),
    );

    final planPanel = _pickerPanel(
      title: 'Plan',
      count: filteredPlans.length,
      searchCtrl: planSearchCtrl,
      searchHint: 'Search plan…',
      child: filteredPlans.isEmpty
          ? Center(
              child: Text(
                'No plans',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            )
          : ListView.builder(
              itemCount: filteredPlans.length,
              itemBuilder: (_, i) {
                final p = filteredPlans[i];
                final selected = tempSelectedPlan == p.id;
                return _selectTile(
                  title: p.name,
                  subtitle:
                      '${AppFormatters.currency(p.price)} · ${p.billingCycle}',
                  selected: selected,
                  onTap: isLoading
                      ? null
                      : () => setState(() => tempSelectedPlan = p.id),
                );
              },
            ),
    );

    final rightPanel = _buildAssignSide(
      businessLabel: businessLabel,
      planLabel: planLabel,
      canAdd: canAdd,
      canCreate: canCreate,
    );

    if (widget.layout == _AssignLayout.split) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: _panelDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select & Search',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Business on top, plan below',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: businessPanel),
                  const SizedBox(height: 10),
                  Expanded(child: planPanel),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 300,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: _panelDecoration,
              child: rightPanel,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: SuperAdminColors.primaryDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.link_rounded,
                color: SuperAdminColors.primaryDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign Subscription',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Link a business to a plan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Column(
            children: [
              Expanded(child: businessPanel),
              const SizedBox(height: 10),
              Expanded(child: planPanel),
            ],
          ),
        ),
        const SizedBox(height: 10),
        rightPanel,
      ],
    );
  }

  Widget _buildAssignSide({
    required String Function(int) businessLabel,
    required String Function(int) planLabel,
    required bool canAdd,
    required bool canCreate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.layout == _AssignLayout.split) ...[
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: SuperAdminColors.primaryDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: SuperAdminColors.primaryDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Review & create',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SuperAdminColors.primaryLight.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: SuperAdminColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CURRENT PICK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              _pickChip(
                icon: Icons.storefront_outlined,
                label: tempSelectedBusiness == null
                    ? 'Pick business'
                    : businessLabel(tempSelectedBusiness!),
                active: tempSelectedBusiness != null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Center(
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              _pickChip(
                icon: Icons.workspace_premium_outlined,
                label: tempSelectedPlan == null
                    ? 'Pick plan'
                    : planLabel(tempSelectedPlan!),
                active: tempSelectedPlan != null,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: OutlinedButton.icon(
                  onPressed: canAdd ? _addPair : null,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add to queue'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SuperAdminColors.primaryDark,
                    side: BorderSide(
                      color: canAdd
                          ? SuperAdminColors.primaryDark
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Queue (${selectedMap.length})',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        if (widget.layout == _AssignLayout.split)
          Expanded(
            child: selectedMap.isEmpty
                ? Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: SuperAdminColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      'No items queued yet',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  )
                : ListView(
                    children: selectedMap.entries.map((e) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                        decoration: BoxDecoration(
                          color:
                              SuperAdminColors.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: SuperAdminColors.success
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${businessLabel(e.key)}\n→ ${planLabel(e.value)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade800,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              icon: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.green.shade800,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () => setState(
                                        () => selectedMap.remove(e.key),
                                      ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          )
        else if (selectedMap.isNotEmpty)
          SizedBox(
            height: 72,
            child: ListView(
              children: selectedMap.entries.map((e) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                  decoration: BoxDecoration(
                    color: SuperAdminColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${businessLabel(e.key)} → ${planLabel(e.value)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.green.shade800,
                        ),
                        onPressed: isLoading
                            ? null
                            : () => setState(() => selectedMap.remove(e.key)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (widget.showCancel) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              flex: widget.showCancel ? 2 : 1,
              child: SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: canCreate ? _handleCreate : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: SuperAdminColors.primaryDark,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        SuperAdminColors.primaryDark.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          selectedMap.isEmpty
                              ? 'Assign'
                              : 'Assign ${selectedMap.length}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pickChip({
    required IconData icon,
    required String label,
    required bool active,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? SuperAdminColors.primaryDark
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: active
                ? SuperAdminColors.primaryDark
                : Colors.grey.shade500,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active
                    ? SuperAdminColors.textPrimary
                    : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerPanel({
    required String title,
    required int count,
    required TextEditingController searchCtrl,
    required String searchHint,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: SuperAdminColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: TextField(
              controller: searchCtrl,
              enabled: !isLoading,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: searchHint,
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, size: 18),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 32,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? SuperAdminColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? SuperAdminColors.primary
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  trailing,
                  const SizedBox(width: 4),
                ],
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: SuperAdminColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
String _mapErrorToMessage(Object error) {
  String message = error.toString().toLowerCase();
  message = message
      .replaceAll('exception:', '')
      .replaceAll('❌', '')
      .trim();

  // Duplicate / already assigned (common when re-assigning)
  if (message.contains('already') ||
      message.contains('duplicate') ||
      message.contains('unique') ||
      message.contains('exists') ||
      message.contains('conflict') ||
      message.contains('409')) {
    return 'This business already has a subscription. Edit or remove the existing one first.';
  }

  if (message.contains('invalid') || message.contains('422')) {
    return 'Invalid details. Please check business and plan.';
  }
  if (message.contains('not found') || message.contains('404')) {
    return 'Business or plan not found.';
  }
  if (message.contains('timeout')) {
    return 'Request timed out. Please try again.';
  }
  if (message.contains('socket') || message.contains('network')) {
    return 'No internet connection. Check your network.';
  }
  if (message.contains('401') || message.contains('unauthorized')) {
    return 'Session expired. Please login again.';
  }
  if (message.contains('403') || message.contains('permission')) {
    return "You don't have permission to do this.";
  }

  // Backend often returns 500 for duplicate assign
  if (message.contains('500') ||
      message.contains('internal server') ||
      message.contains('internal error') ||
      message.contains('server error')) {
    return 'Could not assign subscription. This business may already have one — edit or delete it, then try again.';
  }

  // Prefer a short cleaned backend message when useful
  final cleaned = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  if (cleaned.isNotEmpty &&
      cleaned.length < 120 &&
      !cleaned.toLowerCase().contains('html') &&
      !cleaned.contains('{')) {
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  return 'Something went wrong. Please try again.';
}


Widget _subscriptionCard(
    SubscriptionModel s,
    BuildContext context,
    WidgetRef ref,
    ) {
  final isActive = s.status == "active";

  return Container(
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isActive
            ? Colors.green.shade100
            : Colors.orange.shade100,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Biz #${s.businessId}  ·  Plan #${s.planId}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            _statusChip(s.status),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.payments_outlined,
                size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              s.paymentStatus.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: s.paymentStatus == "paid"
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '#${s.id}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _infoBlock("Start", _formatDate(s.startDate)),
            _infoBlock("End", _formatDate(s.endDate)),
            _infoBlock("Renew", s.autoRenew ? "YES" : "NO"),
          ],
        ),
        if (s.features.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: s.features.take(4).map((featureId) {
              final allFeatures =
                  ref.watch(subscriptionProvider).features;
              final feature = allFeatures
                  .cast<FeatureModel?>()
                  .firstWhere(
                    (e) =>
                        e?.key.toString() == featureId.toString(),
                    orElse: () => null,
                  );
              if (feature == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  feature.name,
                  style: const TextStyle(fontSize: 10),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!isActive) ...[
              SizedBox(
                height: 28,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(subscriptionProvider)
                          .activateSubscription(s.id);
                      if (context.mounted) {
                        CustomDialog.showSuccessSnack(
                          context,
                          'Subscription activated',
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        CustomDialog.showErrorSnack(
                          context,
                          _mapErrorToMessage(e),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: SuperAdminColors.primaryDark,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Activate',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            SizedBox(
              height: 28,
              child: OutlinedButton(
                onPressed: () =>
                    _showEditSubscriptionDialog(context, ref, s),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SuperAdminColors.primaryDark,
                  side: const BorderSide(
                    color: SuperAdminColors.primaryDark,
                  ),
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 28,
              width: 28,
              child: IconButton(
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                onPressed: () =>
                    _confirmDeleteSubscription(context, ref, s),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.08),
                  foregroundColor: Colors.red,
                  minimumSize: const Size(28, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<void> _confirmDeleteSubscription(
  BuildContext context,
  WidgetRef ref,
  SubscriptionModel s,
) async {
  final ok = await CustomDialog.showConfirm(
    context: context,
    title: 'Delete subscription?',
    message:
        'Remove subscription #${s.id} for business ${s.businessId}?',
    confirmLabel: 'Delete',
    isDestructive: true,
    icon: Icons.delete_outline_rounded,
  );
  if (!ok || !context.mounted) return;

  try {
    await ref.read(subscriptionProvider).deleteSubscription(s.id);
    if (context.mounted) {
      CustomDialog.showSuccessSnack(context, 'Subscription deleted');
    }
  } catch (e) {
    if (context.mounted) {
      CustomDialog.showErrorSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

Future<void> _showEditSubscriptionDialog(
  BuildContext context,
  WidgetRef ref,
  SubscriptionModel s,
) async {
  String status = s.status.isNotEmpty ? s.status : 'pending';
  String paymentStatus =
      s.paymentStatus.isNotEmpty ? s.paymentStatus : 'pending';
  bool autoRenew = s.autoRenew;
  int selectedPlanId = s.planId;
  bool saving = false;

  final plans = ref.read(subscriptionProvider).plans;
  if (plans.isEmpty) {
    await ref.read(subscriptionProvider).loadAll();
  }

  if (!context.mounted) return;

  await showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final availablePlans = ref.watch(subscriptionProvider).plans;
          final planExists =
              availablePlans.any((p) => p.id == selectedPlanId);

          InputDecoration fieldDecoration({
            String? hint,
            IconData? icon,
          }) {
            return InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              prefixIcon: icon == null
                  ? null
                  : Icon(icon, size: 18, color: SuperAdminColors.primaryDark),
              filled: true,
              fillColor: SuperAdminColors.surfaceMuted,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: SuperAdminColors.primaryDark,
                  width: 1.4,
                ),
              ),
            );
          }

          Widget sectionLabel(String text) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            );
          }

          Widget choiceChipGroup({
            required List<({String value, String label, Color color})> options,
            required String selected,
            required ValueChanged<String> onSelect,
          }) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((o) {
                final active = selected == o.value;
                return InkWell(
                  onTap: saving ? null : () => onSelect(o.value),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? o.color.withValues(alpha: 0.14)
                          : SuperAdminColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? o.color : Colors.grey.shade300,
                        width: active ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: active ? o.color : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          o.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active ? o.color : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }

          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: SizedBox(
              width: CustomDialog.dialogWidth(
                ctx,
                desktop: CustomDialog.formWideWidth,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 680),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 10, 14),
                    decoration: BoxDecoration(
                      color: SuperAdminColors.primaryDark.withValues(alpha: 0.06),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: SuperAdminColors.primaryDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Edit Subscription',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Update plan, status & billing',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed:
                              saving ? null : () => Navigator.pop(ctx),
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Summary strip
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: SuperAdminColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _editMetaCell(
                                    'Subscription',
                                    '#${s.id}',
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 28,
                                  color: Colors.grey.shade300,
                                ),
                                Expanded(
                                  child: _editMetaCell(
                                    'Business',
                                    '#${s.businessId}',
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 28,
                                  color: Colors.grey.shade300,
                                ),
                                Expanded(
                                  child: _editMetaCell(
                                    'Ends',
                                    '${s.endDate.day}/${s.endDate.month}/${s.endDate.year}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          sectionLabel('Plan'),
                          DropdownButtonFormField<int>(
                            value: planExists ? selectedPlanId : null,
                            isExpanded: true,
                            decoration: fieldDecoration(
                              hint: 'Select plan',
                              icon: Icons.workspace_premium_outlined,
                            ),
                            items: availablePlans
                                .map(
                                  (p) => DropdownMenuItem<int>(
                                    value: p.id,
                                    child: Text(
                                      '${p.name}  ·  ${AppFormatters.currency(p.price)}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: saving
                                ? null
                                : (v) {
                                    if (v == null) return;
                                    setDialogState(() => selectedPlanId = v);
                                  },
                          ),
                          if (!planExists) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Current plan #${s.planId} not in list — pick a plan above.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          sectionLabel('Status'),
                          choiceChipGroup(
                            selected: status,
                            onSelect: (v) =>
                                setDialogState(() => status = v),
                            options: const [
                              (
                                value: 'pending',
                                label: 'Pending',
                                color: Color(0xFFF59E0B),
                              ),
                              (
                                value: 'active',
                                label: 'Active',
                                color: Color(0xFF16A34A),
                              ),
                              (
                                value: 'expired',
                                label: 'Expired',
                                color: Color(0xFF64748B),
                              ),
                              (
                                value: 'cancelled',
                                label: 'Cancelled',
                                color: Color(0xFFDC2626),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          sectionLabel('Payment'),
                          choiceChipGroup(
                            selected: paymentStatus,
                            onSelect: (v) =>
                                setDialogState(() => paymentStatus = v),
                            options: const [
                              (
                                value: 'pending',
                                label: 'Pending',
                                color: Color(0xFFF59E0B),
                              ),
                              (
                                value: 'paid',
                                label: 'Paid',
                                color: Color(0xFF16A34A),
                              ),
                              (
                                value: 'failed',
                                label: 'Failed',
                                color: Color(0xFFDC2626),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          /// Auto renew card
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: autoRenew
                                  ? SuperAdminColors.primaryLight
                                      .withValues(alpha: 0.55)
                                  : SuperAdminColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: autoRenew
                                    ? SuperAdminColors.primary
                                        .withValues(alpha: 0.35)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Auto renew',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                autoRenew
                                    ? 'Renews automatically at period end'
                                    : 'Will not renew automatically',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              value: autoRenew,
                              activeThumbColor: SuperAdminColors.primaryDark,
                              onChanged: saving
                                  ? null
                                  : (v) =>
                                      setDialogState(() => autoRenew = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// Footer actions
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                saving ? null : () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade800,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    if (selectedPlanId <= 0) {
                                      CustomDialog.showErrorSnack(
                                        ctx,
                                        'Please select a plan',
                                      );
                                      return;
                                    }
                                    setDialogState(() => saving = true);
                                    try {
                                      await ref
                                          .read(subscriptionProvider)
                                          .updateSubscription(
                                            subscriptionId: s.id,
                                            planId: selectedPlanId,
                                            status: status,
                                            paymentStatus: paymentStatus,
                                            autoRenew: autoRenew,
                                          );
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (context.mounted) {
                                        CustomDialog.showSuccessSnack(
                                          context,
                                          'Subscription updated',
                                        );
                                      }
                                    } catch (e) {
                                      setDialogState(() => saving = false);
                                      if (ctx.mounted) {
                                        CustomDialog.showErrorSnack(
                                          ctx,
                                          _mapErrorToMessage(e),
                                        );
                                      }
                                    }
                                  },
                            icon: saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 18),
                            label: Text(
                              saving ? 'Saving…' : 'Save changes',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: SuperAdminColors.primaryDark,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: SuperAdminColors
                                  .primaryDark
                                  .withValues(alpha: 0.5),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
          );
        },
      );
    },
  );
}

Widget _editMetaCell(String label, String value) {
  return Column(
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

Widget _statusChip(String status) {
  final isActive = status == "active";

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: isActive
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.orange.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      status.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: isActive ? Colors.green : Colors.orange,
      ),
    ),
  );
}

String _formatDate(DateTime d) {
  return "${d.day}/${d.month}/${d.year}";
}

Widget _infoBlock(String title, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 9,
          color: Colors.grey.shade500,
        ),
      ),
      const SizedBox(height: 1),
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    ],
  );
}
//////////////////////////////////////////////////////////////
/// ===================== DIALOGS ========================= ///
//////////////////////////////////////////////////////////////

class CreatePlanDialog extends ConsumerStatefulWidget {
  const CreatePlanDialog({super.key});

  @override
  ConsumerState<CreatePlanDialog> createState() =>
      _CreatePlanDialogState();
}

class _CreatePlanDialogState extends ConsumerState<CreatePlanDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: CustomDialog.dialogWidth(
          context,
          desktop: CustomDialog.formWidth,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 640),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _CreatePlanForm(
              onCreated: () => Navigator.pop(context),
              onCancel: () => Navigator.pop(context),
              showCancel: true,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared create-plan form used on desktop right panel and mobile dialog.
class _CreatePlanForm extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  final VoidCallback? onCancel;
  final bool showCancel;

  const _CreatePlanForm({
    required this.onCreated,
    this.onCancel,
    this.showCancel = false,
  });

  @override
  ConsumerState<_CreatePlanForm> createState() => _CreatePlanFormState();
}

class _CreatePlanFormState extends ConsumerState<_CreatePlanForm> {
  final name = TextEditingController();
  final price = TextEditingController();
  final trialCtrl = TextEditingController(text: '0');

  String duration = 'monthly';
  String billingCycle = 'monthly';
  int durationDays = 30;
  int trialDays = 0;
  bool isActive = true;
  bool isLoading = false;

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    trialCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (name.text.trim().isEmpty || price.text.trim().isEmpty) {
      CustomDialog.showErrorSnack(context, 'Enter plan name and price');
      return;
    }

    final parsedPrice = int.tryParse(price.text.trim());
    if (parsedPrice == null || parsedPrice < 0) {
      CustomDialog.showErrorSnack(context, 'Enter a valid price');
      return;
    }

    setState(() => isLoading = true);

    try {
      await ref.read(subscriptionProvider).addPlanFull(
            name: name.text.trim(),
            price: parsedPrice,
            duration: duration,
            billingCycle: billingCycle,
            durationDays: durationDays,
            trialDays: trialDays,
            isActive: isActive,
          );

      if (!mounted) return;
      name.clear();
      price.clear();
      trialCtrl.text = '0';
      setState(() {
        duration = 'monthly';
        billingCycle = 'monthly';
        durationDays = 30;
        trialDays = 0;
        isActive = true;
      });
      CustomDialog.showSuccessSnack(context, 'Plan created');
      widget.onCreated();
    } catch (e) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  InputDecoration _decoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 20, color: SuperAdminColors.primaryDark),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SuperAdminColors.primaryDark, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: SuperAdminColors.primaryDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_card_rounded,
                color: SuperAdminColors.primaryDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Set pricing and billing details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plan name',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: name,
                  enabled: !isLoading,
                  decoration: _decoration(
                    'e.g. Starter, Pro',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Price (₹)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: price,
                  enabled: !isLoading,
                  keyboardType: TextInputType.number,
                  decoration: _decoration(
                    'Enter amount',
                    icon: Icons.currency_rupee,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Billing cycle',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: ValueKey(duration),
                  initialValue: duration,
                  isExpanded: true,
                  onChanged: isLoading
                      ? null
                      : (val) {
                          if (val == null) return;
                          setState(() {
                            duration = val;
                            billingCycle = val;
                            durationDays = val == 'monthly'
                                ? 30
                                : val == 'yearly'
                                    ? 365
                                    : 0;
                          });
                        },
                  decoration: _decoration(
                    'Select cycle',
                    icon: Icons.calendar_month_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                    DropdownMenuItem(value: 'one_time', child: Text('One Time')),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Trial days',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: trialCtrl,
                  enabled: !isLoading,
                  keyboardType: TextInputType.number,
                  onChanged: (val) => trialDays = int.tryParse(val) ?? 0,
                  decoration: _decoration(
                    '0 for no trial',
                    icon: Icons.timelapse_rounded,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Active plan',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Customers can subscribe when active',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  value: isActive,
                  activeThumbColor: SuperAdminColors.primaryDark,
                  onChanged: isLoading
                      ? null
                      : (val) => setState(() => isActive = val),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (widget.showCancel) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: widget.showCancel ? 2 : 1,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: SuperAdminColors.primaryDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      SuperAdminColors.primaryDark.withValues(alpha: 0.55),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Plan',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

//////////////////////////////////////////////////////////////
/// ======================= PLANS TAB ===================== ///
//////////////////////////////////////////////////////////////

class PlansTab extends ConsumerStatefulWidget {
  const PlansTab({super.key});

  @override
  ConsumerState<PlansTab> createState() => _PlansTabState();
}

class _PlansTabState extends ConsumerState<PlansTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(subscriptionProvider).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(subscriptionProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final plans = provider.plans;

    if (provider.isPlansLoading && plans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6,
              child: _PlansListPanel(
                plans: plans,
                onRefresh: () => ref.read(subscriptionProvider).loadAll(),
                onCreateMobile: null,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 380,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _CreatePlanForm(
                  onCreated: () {},
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: _PlansListPanel(
              plans: plans,
              onRefresh: () => ref.read(subscriptionProvider).loadAll(),
              onCreateMobile: () async {
                await showDialog(
                  context: context,
                  builder: (_) => const CreatePlanDialog(),
                );
                ref.read(subscriptionProvider).loadAll();
              },
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            backgroundColor: SuperAdminColors.primaryDark,
            foregroundColor: Colors.white,
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => const CreatePlanDialog(),
              );
              ref.read(subscriptionProvider).loadAll();
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Plan'),
          ),
        ),
      ],
    );
  }
}

class _PlansListPanel extends StatelessWidget {
  final List<PlanModel> plans;
  final Future<void> Function() onRefresh;
  final VoidCallback? onCreateMobile;

  const _PlansListPanel({
    required this.plans,
    required this.onRefresh,
    this.onCreateMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Plans',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tap a plan to manage features',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: onRefresh,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: SuperAdminColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: plans.isEmpty
                ? Center(
                    child: Text(
                      'No plans yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.only(
                      bottom: onCreateMobile != null ? 72 : 8,
                    ),
                    itemCount: plans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _planCardEnhanced(plans[i], context),
                  ),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// ===================== FEATURES TAB ==================== ///
//////////////////////////////////////////////////////////////

class FeaturesTab extends ConsumerStatefulWidget {
  const FeaturesTab({super.key});

  @override
  ConsumerState<FeaturesTab> createState() => _FeaturesTabState();
}

class _FeaturesTabState extends ConsumerState<FeaturesTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(subscriptionProvider).loadFeatures();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(subscriptionProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final features = provider.features;

    if (provider.isFeaturesLoading && features.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = _FeaturesListPanel(
      features: features,
      onRefresh: () => ref.read(subscriptionProvider).loadFeatures(),
      showMobileFabPadding: !isDesktop,
    );

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 6, child: list),
            const SizedBox(width: 16),
            SizedBox(
              width: 380,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _CreateFeaturePanel(
                  onCreated: () {},
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: list,
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            backgroundColor: SuperAdminColors.primaryDark,
            foregroundColor: Colors.white,
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => const CreateFeatureDialog(),
              );
              ref.read(subscriptionProvider).loadFeatures();
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Feature'),
          ),
        ),
      ],
    );
  }
}

class _FeaturesListPanel extends ConsumerWidget {
  final List features;
  final Future<void> Function() onRefresh;
  final bool showMobileFabPadding;

  const _FeaturesListPanel({
    required this.features,
    required this.onRefresh,
    this.showMobileFabPadding = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Features',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Features you can map to plans',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: onRefresh,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: SuperAdminColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: features.isEmpty
                ? Center(
                    child: Text(
                      'No features yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.only(
                      bottom: showMobileFabPadding ? 72 : 8,
                    ),
                    itemCount: features.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _featureCardEnhanced(features[i], context, ref),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CreateFeaturePanel extends ConsumerStatefulWidget {
  final VoidCallback onCreated;

  const _CreateFeaturePanel({required this.onCreated});

  @override
  ConsumerState<_CreateFeaturePanel> createState() =>
      _CreateFeaturePanelState();
}

class _CreateFeaturePanelState extends ConsumerState<_CreateFeaturePanel> {
  final name = TextEditingController();
  final description = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  String _generateKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  InputDecoration _decoration(String hint, {IconData? icon, int maxLines = 1}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 20, color: SuperAdminColors.primaryDark),
      alignLabelWithHint: maxLines > 1,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: maxLines > 1 ? 14 : 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: SuperAdminColors.primaryDark,
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> _handleCreate() async {
    if (name.text.trim().isEmpty) {
      CustomDialog.showErrorSnack(context, 'Enter feature name');
      return;
    }

    setState(() => isLoading = true);
    try {
      await ref.read(subscriptionProvider).addFeature(
            name: name.text.trim(),
            key: _generateKey(name.text),
            description: description.text.trim(),
          );
      if (!mounted) return;
      name.clear();
      description.clear();
      CustomDialog.showSuccessSnack(context, 'Feature created');
      widget.onCreated();
    } catch (e) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: SuperAdminColors.primaryDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.extension_outlined,
                color: SuperAdminColors.primaryDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Feature',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Add a feature for plan mapping',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Feature name',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: name,
          enabled: !isLoading,
          decoration: _decoration(
            'e.g. Reminders, Analytics',
            icon: Icons.badge_outlined,
          ),
        ),
        const SizedBox(height: 12),
        const Text('Description',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: description,
          enabled: !isLoading,
          maxLines: 3,
          decoration: _decoration(
            'Short description',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleCreate,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: SuperAdminColors.primaryDark,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  SuperAdminColors.primaryDark.withValues(alpha: 0.55),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Create Feature',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}

//////////////////////////////////////////////////////////////
/// ================= PLAN ↔ FEATURE MAPPING ============== ///
//////////////////////////////////////////////////////////////

class PlanFeatureMappingScreen extends ConsumerStatefulWidget {
  final PlanModel plan;

  const PlanFeatureMappingScreen({super.key, required this.plan});

  @override
  ConsumerState<PlanFeatureMappingScreen> createState() =>
      _PlanFeatureMappingScreenState();
}

class _PlanFeatureMappingScreenState
    extends ConsumerState<PlanFeatureMappingScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _ready = false;
  int? _busyFeatureId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final p = ref.read(subscriptionProvider);
      await p.loadFeatures();
      await p.loadPlanFeatures(widget.plan.id);
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleFeature(FeatureModel feature) async {
    if (_busyFeatureId != null) return;
    setState(() => _busyFeatureId = feature.id);
    try {
      await ref.read(subscriptionProvider).toggleFeature(
            planId: widget.plan.id,
            featureId: feature.id,
          );
    } catch (e) {
      if (!mounted) return;
      CustomDialog.showErrorSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _busyFeatureId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(subscriptionProvider);
    final features = provider.features;
    final selected = provider.planFeatureMap[widget.plan.id] ?? <int>{};
    final query = _searchController.text.trim().toLowerCase();
    final visible = features.where((feature) {
      if (query.isEmpty) return true;
      return feature.name.toLowerCase().contains(query) ||
          feature.key.toLowerCase().contains(query) ||
          feature.description.toLowerCase().contains(query);
    }).toList();
    final enabledCount =
        features.where((feature) => selected.contains(feature.id)).length;

    return Scaffold(
      backgroundColor: SuperAdminColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: SuperAdminColors.primaryDark,
        foregroundColor: Colors.white,
        title: Text(
          widget.plan.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: _PlanFeatureSummary(
                    enabledCount: enabledCount,
                    totalCount: features.length,
                    priceLabel: AppFormatters.currency(widget.plan.price),
                    cycleLabel: widget.plan.billingCycle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: SuperAdminColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search features',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: SuperAdminColors.textHint,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: SuperAdminColors.primaryDark,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: SuperAdminColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: SuperAdminColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: SuperAdminColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: features.isEmpty
                      ? const Center(
                          child: Text(
                            'No features yet',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: SuperAdminColors.textSecondary,
                            ),
                          ),
                        )
                      : visible.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching features',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: SuperAdminColors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                              itemCount: visible.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                final feature = visible[index];
                                final isOn = selected.contains(feature.id);
                                return _PlanFeatureToggleTile(
                                  feature: feature,
                                  isOn: isOn,
                                  isBusy: _busyFeatureId == feature.id,
                                  onChanged: _busyFeatureId == null
                                      ? (_) => _toggleFeature(feature)
                                      : null,
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}

class _PlanFeatureSummary extends StatelessWidget {
  final int enabledCount;
  final int totalCount;
  final String priceLabel;
  final String cycleLabel;

  const _PlanFeatureSummary({
    required this.enabledCount,
    required this.totalCount,
    required this.priceLabel,
    required this.cycleLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SuperAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan features',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: SuperAdminColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Turn a feature on to include it in this plan.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: SuperAdminColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryChip('$enabledCount of $totalCount on'),
              _summaryChip(priceLabel),
              if (cycleLabel.trim().isNotEmpty)
                _summaryChip(cycleLabel.toUpperCase()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SuperAdminColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: SuperAdminColors.primaryDark,
        ),
      ),
    );
  }
}

class _PlanFeatureToggleTile extends StatelessWidget {
  final FeatureModel feature;
  final bool isOn;
  final bool isBusy;
  final ValueChanged<bool>? onChanged;

  const _PlanFeatureToggleTile({
    required this.feature,
    required this.isOn,
    required this.isBusy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final detail = feature.description.trim().isNotEmpty
        ? feature.description.trim()
        : feature.key.replaceAll('_', ' ');

    return Material(
      color: isOn ? SuperAdminColors.surfaceMuted : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onChanged == null ? null : () => onChanged!(!isOn),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isOn
                  ? SuperAdminColors.primary.withValues(alpha: 0.45)
                  : SuperAdminColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: isOn
                      ? SuperAdminColors.primary
                      : SuperAdminColors.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOn ? Icons.check_rounded : Icons.extension_outlined,
                  color: isOn ? Colors.white : SuperAdminColors.grey500,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: SuperAdminColors.textPrimary,
                      ),
                    ),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                          color: SuperAdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isBusy)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    Transform.scale(
                      scale: 0.86,
                      child: Switch(
                        value: isOn,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: onChanged,
                        activeThumbColor: Colors.white,
                        activeTrackColor: SuperAdminColors.primary,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: SuperAdminColors.grey400,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateFeatureDialog extends ConsumerStatefulWidget {
  const CreateFeatureDialog({super.key});

  @override
  ConsumerState<CreateFeatureDialog> createState() =>
      _CreateFeatureDialogState();
}

class _CreateFeatureDialogState
    extends ConsumerState<CreateFeatureDialog> {
  final name = TextEditingController();
  final description = TextEditingController();

  bool isLoading = false;

  String _generateKey(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox(
        width: CustomDialog.dialogWidth(
          context,
          desktop: CustomDialog.formWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title
              const Text(
                "Create Feature",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Add a new feature to your plan",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              /// Name Field
              _buildField(
                controller: name,
                label: 'Feature name',
                hint: 'e.g. Reminders, Analytics',
                icon: Icons.badge_outlined,
              ),

              const SizedBox(height: 14),

              /// Description Field
              _buildField(
                controller: description,
                label: 'Description',
                hint: 'Short description',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),

              const SizedBox(height: 22),

              /// Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: "Cancel",
                      backgroundColor: Colors.grey.shade200,
                      textColor: Colors.black87,
                      onTap: isLoading
                          ? null
                          : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      label: isLoading ? "Creating..." : "Create",
                      backgroundColor: SuperAdminColors.primaryDark,
                      isLoading: isLoading,
                      onTap: isLoading ? null : _handleCreate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: !isLoading,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 20, color: SuperAdminColors.primaryDark),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: maxLines > 1 ? 14 : 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: SuperAdminColors.primaryDark,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleCreate() async {
    if (name.text.trim().isEmpty ||
        description.text.trim().isEmpty) {
      return;
    }

    setState(() => isLoading = true);

    try {
      await ref.read(subscriptionProvider).addFeature(
        key: _generateKey(name.text), // 🔥 backend same
        name: name.text.trim(),
        description: description.text.trim(),
      );

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}