import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../models/business_models/create_purchase_response_model.dart';
import '../../utils/receipt_generator.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final CreatePurchaseResponseModel bill;
  final String businessName;
  final String? businessAddress;
  final String? businessPhone;
  final String? customerName;
  final bool isThermal;

  const ReceiptPreviewScreen({
    super.key,
    required this.bill,
    required this.businessName,
    this.businessAddress,
    this.businessPhone,
    this.customerName,
    this.isThermal = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Receipt Preview",style: TextStyle(fontSize: 17,fontWeight: FontWeight.bold),),
      ),
      body: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Card(
          elevation: 6,
          margin: EdgeInsets.zero,
          child: PdfPreview(
            pdfFileName: "Receipt_${bill.billNumber}.pdf",

            build: (format) async {
              final pdf = await ReceiptGenerator.buildReceiptPdf(
                bill: bill,
                businessName: businessName,
                businessAddress: businessAddress,
                businessPhone: businessPhone,
                isThermal: isThermal,
              );

              return pdf.save();
            },

            loadingWidget: const Center(
              child: CircularProgressIndicator(),
            ),

            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,

            allowPrinting: true,
            allowSharing: true,

            maxPageWidth: 420,

            scrollViewDecoration: BoxDecoration(
              color: Colors.grey.shade100,
            ),
          ),
        ),
      ),
    );
  }
}