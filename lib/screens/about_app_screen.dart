import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About Biz Reminder",style: TextStyle(fontSize: 17,fontWeight: FontWeight.w500),),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 36,
              child: Icon(
                Icons.business_center_rounded,
                size: 34,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Biz Reminder",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "Version 1.0.0",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              "Biz Reminder is an all-in-one business management application built to help small and growing businesses manage customers, appointments, reminders, billing, income, expenses, and daily operations from a single platform.\n\n"
                  "Designed with simplicity, reliability, and performance in mind, Biz Reminder helps business owners stay organized, improve customer relationships, and manage their business more efficiently.",
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 24),

            const Divider(),

            const ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Icon(Icons.verified_user_outlined, size: 22),
              title: Text(
                "Secure & Reliable",
                style: TextStyle(fontSize: 14),
              ),
            ),

            const ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Icon(Icons.notifications_active_outlined, size: 22),
              title: Text(
                "Smart Reminder System",
                style: TextStyle(fontSize: 14),
              ),
            ),

            const ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Icon(Icons.receipt_long_outlined, size: 22),
              title: Text(
                "Billing & Invoice Management",
                style: TextStyle(fontSize: 14),
              ),
            ),

            const ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Icon(Icons.people_outline, size: 22),
              title: Text(
                "Customer Management",
                style: TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              "Made for modern businesses",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "© 2026 Biz Reminder",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}