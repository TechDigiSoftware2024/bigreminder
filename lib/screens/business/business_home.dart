import 'package:flutter/material.dart';

  class BusinessHome extends StatefulWidget {
    const BusinessHome({super.key});

    @override
    State<BusinessHome> createState() => _BusinessHomeState();
  }

  class _BusinessHomeState extends State<BusinessHome> {
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text("BUSINESS DASHBOARD",style: TextStyle(
                fontWeight: FontWeight.bold, fontSize:44,
              ),),
            )
          ],
        ),
      );
    }
  }
