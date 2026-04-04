import 'package:bigreminder/screens/Super%20Admin/super_admin.dart';
import 'package:flutter/material.dart';
import '../utils/enum_classes.dart';

List<Widget> getBottomBarScreens(AppType type) {
  switch (type) {
    case AppType.gym:
      return [
        SuperAdminHome(),
        Center(child: Text("Members")),
        Center(child: Text("Add Workout")),
        Center(child: Text("Gym Reports")),
        Center(child: Text("Gym Profile")),
      ];

    case AppType.shop:
      return [
        SuperAdminHome(),
        Center(child: Text("Orders")),
        Center(child: Text("Add Product")),
        Center(child: Text("Shop Analytics")),
         Center(child: Text("Shop Profile")),
      ];

    case AppType.institute:
      return [
        SuperAdminHome(),
        Center(child: Text("Students")),
        Center(child: Text("Add Course")),
        Center(child: Text("Institute Reports")),
        Center(child: Text("Institute Profile")),
      ];
  }
}