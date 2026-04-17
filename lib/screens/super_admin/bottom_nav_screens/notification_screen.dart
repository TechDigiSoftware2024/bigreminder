import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();

  String selectedAudience = "All Users";

  void sendNotification() {
    HapticFeedback.mediumImpact();

    // TODO: integrate FCM
    print("Send: ${titleController.text} - ${bodyController.text}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        title: const Text(
          "Broadcast Notification",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 HEADER
            const Text(
              "Send notification to users",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              "Create and broadcast updates instantly",
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 20),

            /// 🔹 INPUT CARD
            _card(
              child: Column(
                children: [
                  _inputField(
                    controller: titleController,
                    label: "Notification Title",
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    controller: bodyController,
                    label: "Message",
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 AUDIENCE SELECTOR
            const Text(
              "Audience",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            _card(
              child: DropdownButtonFormField<String>(
                value: selectedAudience,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                items: const [
                  DropdownMenuItem(value: "All Users", child: Text("All Users")),
                  DropdownMenuItem(value: "Active Users", child: Text("Active Users")),
                  DropdownMenuItem(value: "Premium Users", child: Text("Premium Users")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedAudience = value!;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 PREVIEW CARD
            const Text(
              "Preview",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            _card(
              child: Row(
                children: [
                  Container(
                    decoration : BoxDecoration(
                  color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(8)
              ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(Icons.notifications_on_outlined, color: AppColors.iconColor),
                      )),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleController.text.isEmpty
                              ? "Notification Title"
                              : titleController.text,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bodyController.text.isEmpty
                              ? "Your message will appear here"
                              : bodyController.text,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// 🔹 SEND BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Send Notification",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 INFO / WARNING
            _card(
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Notifications will be delivered instantly. Avoid sending too frequently.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= CARD =================
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  /// ================= INPUT =================
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),

        // 👇 default (unfocused)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.5),
            width: 1.5,
          ),
        ),

        // 👇 focused state (important)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),

        // optional (clean UX)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}