import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/super_admin_models/subscription_model.dart';
import '../../../providers/business/business_provider.dart';
import '../../../providers/super_admin/subscription_provider.dart';
import '../../../services/super_admin/delete_service.dart';
import '../../../subscription/feature_model.dart';
import '../../../subscription/plan_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_dialog.dart';
import '../../../widgets/custom_list_toggle.dart';

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
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.appBarBg,
        title: const Text(
          "Subscription Management",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.appBarText,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,

          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,

          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,

          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),

          tabs: const [
            Tab(text: "Plan"),
            Tab(text: "Feature"),
            Tab(text: "Subscription"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PlansTab(),
          FeaturesTab(),
          SubscriptionsTab(),
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
      padding: const EdgeInsets.all(16),
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
                    fontSize: 18,
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
                  plan.isActive ? "ACTIVE" : "INACTIVE",
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
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          /// 🔹 PRICE
          Text(
            "₹${plan.price.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 4),

          /// 🔹 BILLING
          Text(
            "${plan.billingCycle.toUpperCase()} PLAN",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 12),

          /// 🔹 DIVIDER
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 8),

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
    padding: const EdgeInsets.all(16),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              onTap: () async {

                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) {
                    return AlertDialog(
                      title: const Text("Delete Feature"),
                      content: Text(
                        "Are you sure you want to delete '${f.name}'?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );

                if (confirmed != true) return;

                final message = await DeleteService.deleteFeature(
                  featureId: f.id,
                  token: ref.read(tokenProvider),
                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                  ),
                );

                /// Refresh list
                await ref.read(subscriptionProvider).loadFeatures();
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

        const SizedBox(height: 12),

        Divider(color: Colors.grey.shade200),

        const SizedBox(height: 8),

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
  ConsumerState<SubscriptionsTab> createState() =>
      _SubscriptionsTabState();
}

class _SubscriptionsTabState extends ConsumerState<SubscriptionsTab> {
  final searchController = TextEditingController();
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(subscriptionProvider).loadAllSubscriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(subscriptionProvider);

    if (provider.isSubListLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final subs = provider.subscriptions;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(subscriptionProvider).loadAllSubscriptions(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          Column(
            children: [

              /// 🔍 SEARCH BAR
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search by Business ID...",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),

                    /// 🔍 ICON
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey.shade600,
                    ),

                    /// ❌ CLEAR BUTTON
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        searchController.clear();
                        ref.read(subscriptionProvider)
                            .loadAllSubscriptions(businessId: null);
                      },
                    )
                        : null,

                    filled: true,
                    fillColor: Colors.grey.shade50,

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),

                    /// 🔥 FOCUS BORDER
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                  ),

                  /// 🔥 ENTER PRESS
                  onSubmitted: (value) async {
                    final id = int.tryParse(value);
                    if (id == null) return;

                    await ref
                        .read(subscriptionProvider)
                        .loadAllSubscriptions(businessId: id);
                  },

                  /// 🔥 live UI update (for clear button)
                  onChanged: (_) => setState(() {}),
                ),
              ),

              const SizedBox(height: 12),

              /// 🔹 ADD BUTTON
              Row(
                children: [
                  CustomButton(
                    label: "Add Subscription",
                    icon: Icons.add_circle_outline,
                    backgroundColor: AppColors.primaryDark,
                    textColor: Colors.white,
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (_) => const CreateSubscriptionDialog(),
                      );

                      /// 🔥 refresh with same search
                      final id = int.tryParse(searchController.text);
                      ref
                          .read(subscriptionProvider)
                          .loadAllSubscriptions(businessId: id);
                    },
                  )
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// 🔹 EMPTY
          if (subs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text("No Subscriptions Found"),
              ),
            ),

          /// 🔹 LIST
          ...subs.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _subscriptionCard(s, context, ref),
            );
          }),
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

  /// 🔥 MULTI MAP (Business → Plan)
  Map<int, int> selectedMap = {};

  int? tempSelectedBusiness;
  int? tempSelectedPlan;

  bool isBusinessExpanded = false;
  bool isPlanExpanded = false;

  final businessSearchCtrl = TextEditingController();
  final planSearchCtrl = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(subscriptionProvider).loadAll();
      final token = ref.read(tokenProvider);
      ref.read(businessControllerProvider.notifier)
          .fetchMyBusinesses(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = ref.watch(subscriptionProvider);
    final bizProvider = ref.watch(businessControllerProvider);

    final plans = subProvider.plans;
    final businesses = bizProvider.businesses;

    final filteredBusinesses = businesses.where((b) {
      final q = businessSearchCtrl.text.toLowerCase();
      return b.name.toLowerCase().contains(q) ||
          b.id.toString().contains(q);
    }).toList();

    final filteredPlans = plans.where((p) {
      final q = planSearchCtrl.text.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.price.toString().contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isBusinessExpanded || isPlanExpanded ? 600 : 450,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text(
              "Create Subscription",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            /// 🔹 BUSINESS SECTION
            _sectionHeader(
              "Businesses",
              isBusinessExpanded,
                  () {
                setState(() {
                  isBusinessExpanded = !isBusinessExpanded;
                  isPlanExpanded = false;
                });
              },
            ),

            if (isBusinessExpanded) ...[
              _searchField(businessSearchCtrl, "Search Business"),

              const SizedBox(height: 10),

              Expanded(
                child: ListView.builder(
                  itemCount: filteredBusinesses.length,
                  itemBuilder: (_, i) {
                    final b = filteredBusinesses[i];
                    return _selectCard(
                      title: b.name,
                      subtitle: "ID: ${b.id}",
                      selected: tempSelectedBusiness == b.id,
                      onTap: () {
                        setState(() => tempSelectedBusiness = b.id);
                      },
                    );
                  },
                ),
              ),
            ],

            /// 🔹 PLAN SECTION
            _sectionHeader(
              "Plans",
              isPlanExpanded,
                  () {
                setState(() {
                  isPlanExpanded = !isPlanExpanded;
                  isBusinessExpanded = false;
                });
              },
            ),

            if (isPlanExpanded) ...[
              _searchField(planSearchCtrl, "Search Plan"),

              const SizedBox(height: 10),

              Expanded(
                child: ListView.builder(
                  itemCount: filteredPlans.length,
                  itemBuilder: (_, i) {
                    final p = filteredPlans[i];

                    return _selectCard(
                      title: p.name,
                      subtitle: "₹${p.price}",
                      selected: tempSelectedPlan == p.id,
                      onTap: () {
                        setState(() => tempSelectedPlan = p.id);
                      },
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 10),

            /// 🔹 ADD PAIR BUTTON
            _btn("Add Pair", AppColors.primary, AppColors.appBarText, () {
              if (tempSelectedBusiness == null || tempSelectedPlan == null) {
                CustomDialog.showErrorSnack(
                    context, "Select business & plan first");
                return;
              }

              setState(() {
                selectedMap[tempSelectedBusiness!] = tempSelectedPlan!;
                tempSelectedBusiness = null;
                tempSelectedPlan = null;
              });
            }),

            const SizedBox(height: 10),

            /// 🔹 SELECTED LIST
            if (selectedMap.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: selectedMap.entries.map((e) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text("B:${e.key} → P:${e.value}"),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 10),

            /// 🔹 BUTTONS
            Row(
              children: [
                Expanded(
                  child: _btn("Cancel", Colors.grey.shade200,
                      Colors.black, () => Navigator.pop(context)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _btn(
                    isLoading ? "Creating..." : "Create",
                    AppColors.primary, AppColors.appBarText,
                    isLoading ? null : _handleCreate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 HEADER
  Widget _sectionHeader(String title, bool expanded, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
      onTap: onTap,
    );
  }

  Widget _searchField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _selectCard({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? Colors.blue.withOpacity(0.1) : Colors.white,
            border: Border.all(
                color: selected ? Colors.blue : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(subtitle,
                          style: TextStyle(color: Colors.grey.shade600)),
                    ]),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(String text, Color bg, Color txt, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text,
            style: TextStyle(color: txt, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _handleCreate() async {
    if (selectedMap.isEmpty) {
      CustomDialog.showErrorSnack(context, "No selections made");
      return;
    }

    setState(() => isLoading = true);

    try {
      for (var entry in selectedMap.entries) {
        await ref.read(subscriptionProvider).createSubscription(
          businessId: entry.key,
          planId: entry.value,
        );
      }

      if (!mounted) return;

      Navigator.pop(context);

      CustomDialog.showSuccessSnack(
          context, "Subscriptions created successfully");

    } catch (e) {
      CustomDialog.showErrorSnack(context, _mapErrorToMessage(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}
String _mapErrorToMessage(Object error) {
  // 👇 Clean raw message
  String message = error.toString().toLowerCase();

  // Remove common prefixes
  message = message.replaceAll("exception:", "").trim();

  // 👇 Handle real-world cases first (backend messages)
  if (message.contains("already")) {
    return "Plan is already assigned.";
  } else if (message.contains("invalid")) {
    return "Invalid input. Please check details.";
  } else if (message.contains("not found")) {
    return "Business or plan not found.";
  } else if (message.contains("timeout")) {
    return "Request timed out. Try again.";
  } else if (message.contains("socket")) {
    return "No internet connection.";
  }

  // 👇 HTTP fallback (rare but useful)
  if (message.contains("401") || message.contains("unauthorized")) {
    return "Session expired. Please login again.";
  } else if (message.contains("403")) {
    return "You don't have permission.";
  } else if (message.contains("404")) {
    return "Resource not found.";
  } else if (message.contains("500")) {
    return "Server error. Try again later.";
  }

  // 👇 FINAL FIX: instead of generic → show cleaned backend message
  if (message.isNotEmpty) {
    return message[0].toUpperCase() + message.substring(1);
  }

  return "Something went wrong. Please try again.";
}


Widget _subscriptionCard(
    SubscriptionModel s,
    BuildContext context,
    WidgetRef ref,
    ) {
  final isActive = s.status == "active";

  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isActive
            ? Colors.green.shade100
            : Colors.orange.shade100,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// 🔹 HEADER (Plan + Business)
        Row(
          children: [
            Expanded(
              child: Text(
                "BUSINESS ID: ${s.businessId}  •  PLAN ID: ${s.planId}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            _statusChip(s.status),
          ],
        ),

        const SizedBox(height: 10),

        /// 🔹 PAYMENT
        Row(
          children: [
            Icon(Icons.payments_outlined,
                size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              s.paymentStatus.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: s.paymentStatus == "paid"
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        Divider(color: Colors.grey.shade200),

        /// 🔹 DATES + AUTO
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _infoBlock(
              "Start",
              _formatDate(s.startDate),
            ),
            _infoBlock(
              "End",
              _formatDate(s.endDate),
            ),
            _infoBlock(
              "Auto Renew",
              s.autoRenew ? "YES" : "NO",
            ),
          ],
        ),

        const SizedBox(height: 12),

        /// 🔹 FEATURES (important for admin)
        if (s.features.isNotEmpty) ...[
          Text(
            "Features",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: s.features.map((featureId) {

              final allFeatures =
                  ref.watch(subscriptionProvider).features;

              final feature = allFeatures
                  .cast<FeatureModel?>()
                  .firstWhere(
                    (e) =>
                e?.key.toString() ==
                    featureId.toString(),
                orElse: () => null,
              );

              if (feature == null) {
                return const SizedBox();
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  feature.name,
                  style: const TextStyle(fontSize: 11),
                ),
              );
            }).toList(),
          )
        ],

        const SizedBox(height: 12),

        Divider(color: Colors.grey.shade200),

        /// 🔹 META INFO
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _infoBlock("ID", "#${s.id}"),
            _infoBlock("Created", _formatDateTime(s.createdAt)),
            _infoBlock("Updated", _formatDateTime(s.updatedAt)),
          ],
        ),

        const SizedBox(height: 14),

        /// 🔹 ACTION
        if (!isActive)
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              label: "Activate Subscription",
              backgroundColor: AppColors.primaryDark,
              textColor: Colors.white,
              onTap: () async {
                await ref
                    .read(subscriptionProvider)
                    .activateSubscription(s.id);
              },
            ),
          ),
      ],
    ),
  );
}
Widget _statusChip(String status) {
  final isActive = status == "active";

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: isActive
          ? Colors.green.withOpacity(0.1)
          : Colors.orange.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isActive ? Colors.green : Colors.orange,
      ),
    ),
  );
}

String _formatDate(DateTime d) {
  return "${d.day}/${d.month}/${d.year}";
}

String _formatDateTime(DateTime d) {
  return "${d.day}/${d.month} ${d.hour}:${d.minute}";
}Widget _infoBlock(String title, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.shade500,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
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
  final name = TextEditingController();
  final price = TextEditingController();

  String duration = "monthly";
  String billingCycle = "monthly";
  int durationDays = 30;
  int trialDays = 0;
  bool isActive = true;

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create Plan"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// Name
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: "Name"),
            ),

            /// Price
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Price"),
            ),

            /// Duration Type
            DropdownButtonFormField(
              value: duration,
              items: const [
                DropdownMenuItem(value: "monthly", child: Text("Monthly")),
                DropdownMenuItem(value: "yearly", child: Text("Yearly")),
                DropdownMenuItem(value: "one_time", child: Text("One Time")),
              ],
              onChanged: (val) {
                setState(() {
                  duration = val!;
                  durationDays = val == "monthly"
                      ? 30
                      : val == "yearly"
                      ? 365
                      : 0;
                });
              },
              decoration: const InputDecoration(labelText: "Duration"),
            ),

            /// Trial Days
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Trial Days"),
              onChanged: (val) {
                trialDays = int.tryParse(val) ?? 0;
              },
            ),

            /// Active Toggle
            SwitchListTile(
              title: const Text("Active"),
              value: isActive,
              onChanged: (val) {
                setState(() => isActive = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
            if (name.text.isEmpty || price.text.isEmpty) return;

            setState(() => isLoading = true);

            try {
              final provider = ref.read(subscriptionProvider);

              await provider.addPlanFull(
                name: name.text.trim(),
                price: int.parse(price.text.trim()),
                duration: duration,
                billingCycle: billingCycle,
                durationDays: durationDays,
                trialDays: trialDays,
                isActive: isActive,
              );

              Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error: $e")),
              );
            } finally {
              setState(() => isLoading = false);
            }
          },
          child: isLoading
              ? const CircularProgressIndicator()
              : const Text("Create"),
        )
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

    if (provider.isPlansLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final plans = provider.plans;

    return RefreshIndicator(
      onRefresh: () => ref.read(subscriptionProvider).loadAll(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CustomButton(
                label: "Create Plans",
                icon: Icons.add_circle_outlined,
                backgroundColor: AppColors.primaryDark,
                textColor: Colors.white,
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => CreatePlanDialog(),
                  );

                  ref.read(subscriptionProvider).loadAll();
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (plans.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text("No Plans Found"),
            )),

          ...plans.map((plan) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PlanFeatureMappingScreen(plan: plan),
                    ),
                  );
                },
                child: _planCardEnhanced(plan,context)
              ),
            );
          }),
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

    if (provider.isFeaturesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final features = provider.features;

    return RefreshIndicator(
      onRefresh: () => ref.read(subscriptionProvider).loadFeatures(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CustomButton(
                label: "Create Features",
                icon: Icons.add_circle_outlined,
                backgroundColor: AppColors.primaryDark,
                textColor: Colors.white,
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => CreateFeatureDialog(),
                  );

                  ref.read(subscriptionProvider).loadFeatures();
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (features.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text("No Features Found"),
            )),

          ...features.map((f) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _featureCardEnhanced(f,context,ref),
            );
          }),
        ],
      ),
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

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final p = ref.read(subscriptionProvider);
      await p.loadFeatures();
      await p.loadPlanFeatures(widget.plan.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(subscriptionProvider);

    /// 🔥 FIX: loading state added
    if (provider.isMappingLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final features = provider.features;
    final selected = provider.planFeatureMap[widget.plan.id] ?? {};

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        title: Text("${widget.plan.name} Features",style: TextStyle(color: AppColors.appBarText),),
      ),
      body: features.isEmpty
          ? const Center(child: Text("No Features"))
          :ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: features.length,
        itemBuilder: (_, i) {
          final f = features[i];
          final isSelected = selected.contains(f.id);

          return CustomListToggle(
            title: f.name,
            subtitle: f.id.toString(),
            value: isSelected,

            /// optional theming (keeps your earlier feel)
            onColor: AppColors.primaryDark,
            outlineColor: AppColors.primaryDark.withOpacity(0.4),

            onChanged: (val) async {
              try {
                await provider.toggleFeature(
                  planId: widget.plan.id,
                  featureId: f.id,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Failed to update feature: ${e.toString()}",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          );
        },
      )
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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
                fontSize: 20,
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
              hint: "Feature name",
            ),

            const SizedBox(height: 14),

            /// Description Field
            _buildField(
              controller: description,
              hint: "Short description",
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
                    backgroundColor: AppColors.primaryDark,
                    textColor: Colors.white,
                    onTap: isLoading ? null : _handleCreate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
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