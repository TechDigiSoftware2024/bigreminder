import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/business_models/BusinessMonthlyGrowthModel.dart';


class BusinessMonthlyGrowthScreen
    extends ConsumerStatefulWidget {

  final BusinessMonthlyGrowthModel data;

  const BusinessMonthlyGrowthScreen({
    super.key,
    required this.data,
  });

  @override
  ConsumerState<BusinessMonthlyGrowthScreen>
  createState() =>
      _BusinessMonthlyGrowthScreenState();
}

class _BusinessMonthlyGrowthScreenState
    extends ConsumerState<BusinessMonthlyGrowthScreen> {

  int selectedMonths = 6;

  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final primary =
        Theme.of(context).primaryColor;

    final revenue =
        widget.data.monthlyRevenue;

    final expense =
        widget.data.monthlyExpense;

    final profit =
        widget.data.monthlyProfit;

    final currentData =
    selectedTab == 0
        ? revenue
        : selectedTab == 1
        ? expense
        : profit;

    return Scaffold(
      backgroundColor:
      const Color(0xffF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: primary,
        title: const Text(
          "Business Growth Analytics",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            /// FILTER CARD
            Container(
              padding:
              const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(20),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(.05),
                    blurRadius: 15,
                    offset:
                    const Offset(0, 4),
                  )
                ],
              ),

              child: Row(
                children: [

                  Expanded(
                    child: Text(
                      "Analytics Period",
                      style: TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Colors.grey.shade800,
                      ),
                    ),
                  ),

                  DropdownButton<int>(
                    value: selectedMonths,
                    underline:
                    const SizedBox(),

                    items: const [
                      DropdownMenuItem(
                        value: 3,
                        child:
                        Text("3 Months"),
                      ),
                      DropdownMenuItem(
                        value: 6,
                        child:
                        Text("6 Months"),
                      ),
                      DropdownMenuItem(
                        value: 12,
                        child:
                        Text("12 Months"),
                      ),
                    ],

                    onChanged: (value) {
                      setState(() {
                        selectedMonths =
                        value!;
                      });

                      /// refresh provider
                    },
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// KPI CARDS
            Row(
              children: [

                Expanded(
                  child: _metricCard(
                    title: "Revenue",
                    value: revenue.isNotEmpty
                        ? revenue.last.amountValue
                        : 0,
                    color: primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _metricCard(
                    title: "Expense",
                    value: expense.isNotEmpty
                        ? expense.last.amountValue
                        : 0,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _metricCard(
              title: "Profit",
              value: profit.isNotEmpty
                  ? profit.last.amountValue
                  : 0,
              color: Colors.green,
            ),

            const SizedBox(height: 24),

            /// TABS

            Container(
              padding:
              const EdgeInsets.all(4),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(16),
              ),

              child: Row(
                children: [

                  _tab(
                    title: "Revenue",
                    index: 0,
                    primary: primary,
                  ),

                  _tab(
                    title: "Expense",
                    index: 1,
                    primary: primary,
                  ),

                  _tab(
                    title: "Profit",
                    index: 2,
                    primary: primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// CHART

            Container(
              height: 320,
              padding:
              const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(24),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(.04),
                    blurRadius: 16,
                  ),
                ],
              ),

              child: LineChart(
                LineChartData(
                  gridData:
                  const FlGridData(
                    show: true,
                  ),

                  borderData:
                  FlBorderData(
                    show: false,
                  ),

                  titlesData:
                  FlTitlesData(
                    leftTitles:
                    const AxisTitles(
                      sideTitles:
                      SideTitles(
                        showTitles:
                        true,
                      ),
                    ),

                    bottomTitles:
                    AxisTitles(
                      sideTitles:
                      SideTitles(
                        showTitles:
                        true,

                        getTitlesWidget:
                            (value,
                            meta) {
                          final index =
                          value.toInt();

                          if (index >=
                              currentData
                                  .length) {
                            return const SizedBox();
                          }

                          return Padding(
                            padding:
                            const EdgeInsets.only(
                              top: 8,
                            ),
                            child: Text(
                              currentData[index]
                                  .month,
                              style:
                              const TextStyle(
                                fontSize:
                                10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  lineBarsData: [

                    LineChartBarData(
                      isCurved: true,

                      color: primary,

                      barWidth: 4,

                      dotData:
                      const FlDotData(
                        show: true,
                      ),

                      belowBarData:
                      BarAreaData(
                        show: true,
                        color: primary
                            .withOpacity(.12),
                      ),

                      spots:
                      currentData
                          .asMap()
                          .entries
                          .map(
                            (e) =>
                            FlSpot(
                              e.key
                                  .toDouble(),
                              e.value
                                  .amountValue,
                            ),
                      )
                          .toList(),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// DETAILS LIST

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(
                    20),
              ),

              child: ListView.separated(
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),

                itemCount:
                currentData.length,

                separatorBuilder:
                    (_, __) =>
                    Divider(
                      height: 1,
                      color: Colors.grey
                          .shade200,
                    ),

                itemBuilder:
                    (_, index) {
                  final item =
                  currentData[index];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      primary
                          .withOpacity(.1),

                      child: Icon(
                        Icons.show_chart,
                        color: primary,
                      ),
                    ),

                    title: Text(
                      item.month,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    trailing: Text(
                      "₹${item.amountValue.toStringAsFixed(0)}",
                      style:
                      TextStyle(
                        color: primary,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab({
    required String title,
    required int index,
    required Color primary,
  }) {
    final selected =
        selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },

        child: AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 250,
          ),

          padding:
          const EdgeInsets.symmetric(
            vertical: 12,
          ),

          decoration: BoxDecoration(
            color: selected
                ? primary
                : Colors.transparent,

            borderRadius:
            BorderRadius.circular(
                12),
          ),

          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.black87,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(.04),
            blurRadius: 15,
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "₹${value.toStringAsFixed(0)}",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}