import 'package:flutter/material.dart';

class BusinessSubscriptionScreen extends StatefulWidget {
  const BusinessSubscriptionScreen({super.key});

  @override
  State<BusinessSubscriptionScreen> createState() =>
      _BusinessSubscriptionScreenState();
}

class _BusinessSubscriptionScreenState
    extends State<BusinessSubscriptionScreen> {

  int selectedIndex = 0;

  final List<Map<String, dynamic>> plans = [

    {
      "title": "Free",
      "subtitle": "Perfect to get started",
      "price": "₹0",
      "badge": "CURRENT",

      "customers": "10",
      "reminders": "Basic",
      "reports": "Lite",

      "icon": Icons.rocket_launch_rounded,

      "features": [
        "10 customer records",
        "Basic reminder system",
        "Expense tracking",
        "Limited notifications",
        "Revenue overview",
      ],
    },

    {
      "title": "Basic",
      "subtitle": "For growing businesses",
      "price": "₹199",
      "badge": "POPULAR",

      "customers": "500",
      "reminders": "Smart",
      "reports": "Standard",

      "icon": Icons.workspace_premium_rounded,

      "features": [
        "500 customer records",
        "Smart reminders",
        "Revenue analytics",
        "Expense reports",
        "Priority notifications",
      ],
    },

    {
      "title": "Pro",
      "subtitle": "Built for scaling teams",
      "price": "₹499",
      "badge": "MOST USED",

      "customers": "Unlimited",
      "reminders": "AI",
      "reports": "Advanced",

      "icon": Icons.auto_awesome_rounded,

      "features": [
        "Unlimited customers",
        "AI reminder automation",
        "Advanced business reports",
        "Revenue growth insights",
        "Priority support access",
      ],
    },

    {
      "title": "Premium",
      "subtitle": "Enterprise business suite",
      "price": "₹999",
      "badge": "ENTERPRISE",

      "customers": "Infinite",
      "reminders": "Realtime",
      "reports": "Enterprise",

      "icon": Icons.diamond_rounded,

      "features": [
        "Full AI business automation",
        "Realtime analytics dashboard",
        "Premium customer support",
        "Advanced revenue tracking",
        "Dedicated business insights",
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.primary,

        title: const Text(
          "Subscriptions",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
      ),

      body: Stack(
        children: [

          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primary.withOpacity(.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  "Unlock advanced reminders, analytics, notifications and smart business automation tools.",
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 10),

                ...List.generate(plans.length, (index) {

                  final plan = plans[index];
                  final isSelected = selectedIndex == index;

                  return GestureDetector(
                    onTap: (){
                      setState(() {
                        selectedIndex = index;
                      });
                    },

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),

                      margin: const EdgeInsets.only(bottom: 12),

                      decoration: BoxDecoration(

                        color: isSelected
                            ? cs.primary.withOpacity(.08)
                            : cs.surfaceContainerHighest.withOpacity(.45),

                        borderRadius: BorderRadius.circular(22),

                        border: Border.all(
                          color: isSelected
                              ? cs.primary.withOpacity(.4)
                              : cs.outline.withOpacity(.1),
                        ),

                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: cs.primary.withOpacity(.10),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                            : [],
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(14),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Row(
                              children: [

                                Container(
                                  width: 46,
                                  height: 46,

                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? cs.primary.withOpacity(.12)
                                        : cs.surface,

                                    borderRadius: BorderRadius.circular(14),
                                  ),

                                  child: Icon(
                                    plan["icon"],
                                    color: isSelected
                                        ? cs.primary
                                        : cs.onSurface,
                                    size: 22,
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                    children: [

                                      Row(
                                        children: [

                                          Text(
                                            plan["title"],
                                            style: TextStyle(
                                              color: cs.onSurface,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),

                                          const SizedBox(width: 6),

                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3,
                                            ),

                                            decoration: BoxDecoration(
                                              color: cs.primary.withOpacity(.1),
                                              borderRadius:
                                              BorderRadius.circular(20),
                                            ),

                                            child: Text(
                                              plan["badge"],
                                              style: TextStyle(
                                                color: cs.primary,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: .5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 2),

                                      Text(
                                        plan["subtitle"],
                                        style: TextStyle(
                                          color:
                                          cs.onSurface.withOpacity(.52),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),

                                  width: 20,
                                  height: 20,

                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,

                                    border: Border.all(
                                      color: isSelected
                                          ? cs.primary
                                          : cs.outline.withOpacity(.35),
                                      width: 1.8,
                                    ),
                                  ),

                                  child: isSelected
                                      ? Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: cs.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                      : null,
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.end,

                              children: [

                                Text(
                                  plan["price"],
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 3,
                                    bottom: 5,
                                  ),

                                  child: Text(
                                    "/month",
                                    style: TextStyle(
                                      color:
                                      cs.onSurface.withOpacity(.42),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [

                                _miniStat(
                                  title: "Customers",
                                  value: plan["customers"],
                                  cs: cs,
                                ),

                                const SizedBox(width: 8),

                                _miniStat(
                                  title: "Reminders",
                                  value: plan["reminders"],
                                  cs: cs,
                                ),

                                const SizedBox(width: 8),

                                _miniStat(
                                  title: "Reports",
                                  value: plan["reports"],
                                  cs: cs,
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            ...List.generate(
                              plan["features"].length,
                                  (i) {

                                return Padding(
                                  padding:
                                  const EdgeInsets.only(bottom: 8),

                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                    children: [

                                      Padding(
                                        padding:
                                        const EdgeInsets.only(top: 1),

                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 15,
                                          color: cs.primary,
                                        ),
                                      ),

                                      const SizedBox(width: 7),

                                      Expanded(
                                        child: Text(
                                          plan["features"][i],

                                          style: TextStyle(
                                            color: cs.onSurface
                                                .withOpacity(.72),

                                            fontSize: 11.5,
                                            height: 1.3,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 6),

                            Container(
                              height: 46,

                              decoration: BoxDecoration(

                                color: isSelected
                                    ? cs.primary
                                    : cs.surface,

                                borderRadius:
                                BorderRadius.circular(14),

                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : cs.outline.withOpacity(.12),
                                ),
                              ),

                              child: Center(
                                child: Text(
                                  isSelected
                                      ? "Current Plan"
                                      : "Upgrade Plan",

                                  style: TextStyle(
                                    color: isSelected
                                        ? cs.onPrimary
                                        : cs.onSurface,

                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required String title,
    required String value,
    required ColorScheme cs,
  }) {

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: cs.surface.withOpacity(.8),
          borderRadius: BorderRadius.circular(14),
        ),

        child: Column(
          children: [

            Text(
              value,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              title,
              style: TextStyle(
                color: cs.onSurface.withOpacity(.45),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}