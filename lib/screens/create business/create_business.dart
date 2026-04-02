import 'package:flutter/material.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_textfield.dart';

class CreateBusinessScreen extends StatelessWidget {
   CreateBusinessScreen({super.key});

  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController businessAddressController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: const CustomAppBar(
        title: "Create Business",
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [

              /// 🔵 Top Header Section
              CustomCard(
                padding:  EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "New Business",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Add your business details",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// 🔵 Form Section
              Expanded(
                child: SingleChildScrollView(
                  child: CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// Section Title
                        const Text(
                          "Business Information",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// 🔹 Business Name
                        CustomTextField(
                          controller: businessNameController,
                          hint: "Business Name",
                        ),

                        const SizedBox(height: 16),

                        /// 🔹 Category
                        CustomDropdown(
                          hint: "Select business type",
                          roles: const [
                            "Shop",
                            "Gym",
                            "Salon",
                            "Institute",
                          ],
                          onChanged: (value) {},
                        ),

                        const SizedBox(height: 16),

                        /// 🔹 Address
                        CustomTextField(
                          hint: "Enter address (optional)",
                          controller: businessAddressController,
                        ),

                        const SizedBox(height: 24),

                        /// 🔵 Button
                        CustomButton(
                          onTap: () {},
                          label: "Create Business",
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// 🔹 Bottom Note
              const Text(
                "You can add multiple businesses later",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}