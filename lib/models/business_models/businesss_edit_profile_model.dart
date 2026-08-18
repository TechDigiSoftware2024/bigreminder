class BusinessProfileEditModel {
  final String name;
  final String category;
  final String address;
  final String doc;

  BusinessProfileEditModel({
    required this.name,
    required this.category,
    required this.address,
    required this.doc,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "category": category,
      "address": address,
      "doc": doc,
    };
  }
}