import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineModel {
  final String id;
  final String brandName;
  final String genericName;
  final String category;
  final String dosage;
  final String manufacturer;
  final String description;
  final bool requiresPrescription;
  final List<String> searchKeywords;
  final DateTime createdAt;

  MedicineModel({
    required this.id,
    required this.brandName,
    required this.genericName,
    required this.category,
    required this.dosage,
    required this.manufacturer,
    required this.description,
    required this.requiresPrescription,
    required this.searchKeywords,
    required this.createdAt,
  });

  factory MedicineModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.now();
    }

    final rawKeywords = data['searchKeywords'] as List<dynamic>? ?? [];
    final keywords = rawKeywords.map((e) => e.toString()).toList();

    return MedicineModel(
      id: doc.id,
      brandName: data['brandName'] as String? ?? '',
      genericName: data['genericName'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      dosage: data['dosage'] as String? ?? '',
      manufacturer: data['manufacturer'] as String? ?? '',
      description: data['description'] as String? ?? '',
      requiresPrescription: data['requiresPrescription'] as bool? ?? false,
      searchKeywords: keywords,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'brandName': brandName,
      'genericName': genericName,
      'category': category,
      'dosage': dosage,
      'manufacturer': manufacturer,
      'description': description,
      'requiresPrescription': requiresPrescription,
      'searchKeywords': searchKeywords,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
