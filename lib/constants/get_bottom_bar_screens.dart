import 'package:flutter/material.dart';
import '../utils/enum_classes.dart';

List<Widget> getBottomBarScreens(AppType type) {
  switch (type) {
    case AppType.gym:
      return const [
        Center(child: Text("Members")),
        Center(child: Text("Add Workout")),
        SizedBox(),
        Center(child: Text("Gym Reports")),
        Center(child: Text("Gym Profile")),
      ];

    case AppType.shop:
      return const [
        Center(child: Text("Orders")),
        Center(child: Text("Add Product")),
        SizedBox(),
        Center(child: Text("Shop Analytics")),
        Center(child: Text("Shop Profile")),
      ];

    case AppType.institute:
      return const [
        Center(child: Text("Students")),
        Center(child: Text("Add Course")),
        SizedBox(),
        Center(child: Text("Institute Reports")),
        Center(child: Text("Institute Profile")),
      ];

    default:
      return const [
        Center(child: Text("Home")),
        Center(child: Text("Add")),
        SizedBox(),
        Center(child: Text("Reports")),
        Center(child: Text("Profile")),
      ];
  }
}

List<String> getBottomBarLabels(AppType type) {
  switch (type) {
    case AppType.gym:
      return ["Members", "Workout"," ", "Reports", "Profile"];

    case AppType.shop:
      return ["Orders", "Products"," ", "Analytics", "Profile"];

    case AppType.institute:
      return ["Students", "Courses"," ", "Reports", "Profile"];

    default:
      return ["Home", "Add"," ", "Reports", "Profile"];
  }
}