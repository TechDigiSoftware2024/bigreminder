import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

 class BusinessStaff extends StatefulWidget {
   const BusinessStaff({super.key});

   @override
   State<BusinessStaff> createState() => _BusinessStaffState();
 }

 class _BusinessStaffState extends State<BusinessStaff> {
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       body: Column(
         crossAxisAlignment: CrossAxisAlignment.center,
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Center(
             child: Text("STAFF",style: TextStyle(
                 fontWeight: FontWeight.bold, fontSize:25,
                 color: AppColors.primaryDark
             ),),
           )
         ],
       ),
     );
   }
 }
