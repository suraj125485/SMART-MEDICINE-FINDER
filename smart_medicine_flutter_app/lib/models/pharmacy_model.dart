import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyModel {
  final String id;
  final String ownerUid;
  final String name;
  final String licenseNumber;
  final String pharmacistName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String pincode;
  final bool isVerified;
  final DateTime createdAt;

  PharmacyModel({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.licenseNumber,
    required this.pharmacistName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.pincode,
    this.isVerified = false,
    required this.createdAt,
  });

  factory PharmacyModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    DateTime parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.now();
    }

    return PharmacyModel(
      id: doc.id,
      ownerUid: data['ownerUid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      licenseNumber: data['licenseNumber'] as String? ?? '',
      pharmacistName: data['pharmacistName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? '',
      pincode: data['pincode'] as String? ?? '',
      isVerified: data['isVerified'] as bool? ?? false,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerUid': ownerUid,
      'name': name,
      'licenseNumber': licenseNumber,
      'pharmacistName': pharmacistName,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'pincode': pincode,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
