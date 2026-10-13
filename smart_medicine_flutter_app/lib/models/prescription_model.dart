import 'package:cloud_firestore/cloud_firestore.dart';

enum PrescriptionStatus {
  pending,
  reviewing,
  accepted,
  readyForPickup,
  rejected,
  completed,
}

extension PrescriptionStatusExtension on PrescriptionStatus {
  String get label {
    switch (this) {
      case PrescriptionStatus.pending:
        return 'Pending Store Review';
      case PrescriptionStatus.reviewing:
        return 'Pharmacist Reviewing';
      case PrescriptionStatus.accepted:
        return 'Accepted & Preparing';
      case PrescriptionStatus.readyForPickup:
        return 'Ready for Pickup';
      case PrescriptionStatus.rejected:
        return 'Declined / Out of Stock';
      case PrescriptionStatus.completed:
        return 'Completed';
    }
  }

  static PrescriptionStatus fromString(String val) {
    switch (val) {
      case 'reviewing':
        return PrescriptionStatus.reviewing;
      case 'accepted':
        return PrescriptionStatus.accepted;
      case 'readyForPickup':
        return PrescriptionStatus.readyForPickup;
      case 'rejected':
        return PrescriptionStatus.rejected;
      case 'completed':
        return PrescriptionStatus.completed;
      default:
        return PrescriptionStatus.pending;
    }
  }
}

class PrescribedMedicineItem {
  final String medicineName;
  final String dosage;
  final bool isAvailable;
  final double estimatedPrice;
  final int stockCount;
  final String? alternativeSubstitute;

  PrescribedMedicineItem({
    required this.medicineName,
    required this.dosage,
    required this.isAvailable,
    required this.estimatedPrice,
    required this.stockCount,
    this.alternativeSubstitute,
  });

  factory PrescribedMedicineItem.fromMap(Map<String, dynamic> map) {
    return PrescribedMedicineItem(
      medicineName: map['medicineName'] as String? ?? 'Medicine',
      dosage: map['dosage'] as String? ?? '',
      isAvailable: map['isAvailable'] as bool? ?? false,
      estimatedPrice: (map['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      stockCount: (map['stockCount'] as num?)?.toInt() ?? 0,
      alternativeSubstitute: map['alternativeSubstitute'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineName': medicineName,
      'dosage': dosage,
      'isAvailable': isAvailable,
      'estimatedPrice': estimatedPrice,
      'stockCount': stockCount,
      'alternativeSubstitute': alternativeSubstitute,
    };
  }
}

class SelectedPharmacyModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double rating;
  final String distance;
  final bool isVerified;
  final String operatingHours;

  SelectedPharmacyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.rating,
    required this.distance,
    required this.isVerified,
    required this.operatingHours,
  });

  factory SelectedPharmacyModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SelectedPharmacyModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Verified Pharmacy',
      address: data['address'] as String? ?? 'Address not specified',
      phone: data['phone'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 4.8,
      distance: data['distance'] as String? ?? '0.8 km away',
      isVerified: data['isVerified'] as bool? ?? true,
      operatingHours: data['operatingHours'] as String? ?? 'Open 8:00 AM - 10:00 PM',
    );
  }
}

class PrescriptionRequestModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String pharmacyId;
  final String pharmacyName;
  final String pharmacyAddress;
  final String pharmacyPhone;
  final String prescriptionImageUrl;
  final PrescriptionStatus status;
  final List<PrescribedMedicineItem> detectedItems;
  final String patientNotes;
  final double? quotedTotal;
  final String? pharmacistNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PrescriptionRequestModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.pharmacyPhone,
    required this.prescriptionImageUrl,
    required this.status,
    required this.detectedItems,
    required this.patientNotes,
    this.quotedTotal,
    this.pharmacistNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrescriptionRequestModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final itemsList = (data['detectedItems'] as List<dynamic>? ?? [])
        .map((e) => PrescribedMedicineItem.fromMap(e as Map<String, dynamic>))
        .toList();

    return PrescriptionRequestModel(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? 'Patient',
      patientPhone: data['patientPhone'] as String? ?? '',
      pharmacyId: data['pharmacyId'] as String? ?? '',
      pharmacyName: data['pharmacyName'] as String? ?? 'Neighborhood Pharmacy',
      pharmacyAddress: data['pharmacyAddress'] as String? ?? '',
      pharmacyPhone: data['pharmacyPhone'] as String? ?? '',
      prescriptionImageUrl: data['prescriptionImageUrl'] as String? ?? '',
      status: PrescriptionStatusExtension.fromString(data['status'] as String? ?? 'pending'),
      detectedItems: itemsList,
      patientNotes: data['patientNotes'] as String? ?? '',
      quotedTotal: (data['quotedTotal'] as num?)?.toDouble(),
      pharmacistNotes: data['pharmacistNotes'] as String?,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'pharmacyAddress': pharmacyAddress,
      'pharmacyPhone': pharmacyPhone,
      'prescriptionImageUrl': prescriptionImageUrl,
      'status': status.name,
      'detectedItems': detectedItems.map((e) => e.toMap()).toList(),
      'patientNotes': patientNotes,
      'quotedTotal': quotedTotal,
      'pharmacistNotes': pharmacistNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class PrescriptionChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // 'customer' | 'pharmacy'
  final String text;
  final DateTime timestamp;
  final String? attachmentUrl;
  final bool isPriceQuote;
  final double? quotedAmount;

  PrescriptionChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    this.attachmentUrl,
    this.isPriceQuote = false,
    this.quotedAmount,
  });

  factory PrescriptionChatMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PrescriptionChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderRole: data['senderRole'] as String? ?? 'customer',
      text: data['text'] as String? ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      attachmentUrl: data['attachmentUrl'] as String?,
      isPriceQuote: data['isPriceQuote'] as bool? ?? false,
      quotedAmount: (data['quotedAmount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'attachmentUrl': attachmentUrl,
      'isPriceQuote': isPriceQuote,
      'quotedAmount': quotedAmount,
    };
  }
}
