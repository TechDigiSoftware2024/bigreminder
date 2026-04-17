import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../models/business_list_model.dart';
import '../../../services/business/business_service.dart';
import 'business_list_details.dart';

class BusinessListPage extends StatefulWidget {
  const BusinessListPage({super.key});

  @override
  State<BusinessListPage> createState() => _BusinessListPageState();
}

class _BusinessListPageState extends State<BusinessListPage>
    with SingleTickerProviderStateMixin {
  late Future<List<Business>> future;
  late AnimationController _animController;
  final TextEditingController _searchController = TextEditingController();
  List<Business> allBusinesses = [];
  List<Business> filteredBusinesses = [];

  String searchQuery = "";
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    future = BusinessService.fetchBusinesses();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _debounce?.cancel();
    _searchController.dispose(); // ✅ important
    super.dispose();
  }

  void retry() {
    setState(() {
      future = BusinessService.fetchBusinesses();
      _animController.forward(from: 0);
    });
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        searchQuery = value.toLowerCase();

        filteredBusinesses = allBusinesses.where((b) {
          return b.name.toLowerCase().contains(searchQuery) ||
              b.category.toLowerCase().contains(searchQuery) ||
              b.id.toString().contains(searchQuery);
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: FutureBuilder<List<Business>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorView(
                retry: retry, error: snapshot.error.toString());
          }

          allBusinesses = snapshot.data ?? [];

          // first load
          if (searchQuery.isEmpty) {
            filteredBusinesses = allBusinesses;
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header()),

              /// 🔥 SEARCH BAR
              SliverToBoxAdapter(child: _searchBar()),

              /// 🔥 LIST / EMPTY STATE
              filteredBusinesses.isEmpty
                  ? const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(
                    child: Text(
                      "No results found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
                  : SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return Padding(
                      padding:
                      const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: _AnimatedCard(
                        controller: _animController,
                        delay: index * 0.08,
                        child: _BusinessCard(
                            business: filteredBusinesses[index]),
                      ),
                    );
                  },
                  childCount: filteredBusinesses.length,
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: "Search name, id, category...",
            hintStyle: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500
            ),
            prefixIcon: const Icon(Icons.search,color: Colors.grey,),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  searchQuery = "";
                  filteredBusinesses = allBusinesses;
                });
              },
            )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Businesses",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Manage your business list",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _AnimatedCard extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;

  const _AnimatedCard({
    required this.controller,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(delay.clamp(0.0, 0.9),
          (delay + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final Business business;

  const _BusinessCard({required this.business});

  @override
  Widget build(BuildContext context) {
    final isActive = business.isActive;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessDetailPage(business: business),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.blueAccent.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.store,
                color: isActive ? Colors.blueAccent : Colors.red,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    business.category,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? "Active" : "Inactive",
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Icon(Icons.arrow_forward_ios,
                    size: 12, color: Colors.grey.shade400)
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback retry;
  final String error;

  const _ErrorView({required this.retry, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(error),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: retry, child: const Text("Retry"))
        ],
      ),
    );
  }
}