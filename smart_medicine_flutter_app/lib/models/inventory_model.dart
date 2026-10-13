import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Schema: /inventory/{inventoryId}
/// Fields:
/// - pharmacyId: String (Chemist store identifier)
/// - medicineId: String (Catalog medicine foreign key)
/// - price: double (Price in Indian Rupees ₹)
/// - stockQuantity: int (Current shelf stock count)
/// - lastUpdated: Timestamp (Server timestamp of latest inventory check)
class InventoryModel {
  final String id;
  final String pharmacyId;
  final String medicineId;
  final double price; // In Indian Rupees (₹)
  final int stockQuantity;
  final DateTime lastUpdated;
  final String pharmacyName;
  final String pharmacyAddress;
  final String pharmacyPhone;
  final bool isAvailable;

  const InventoryModel({
    required this.id,
    required this.pharmacyId,
    required this.medicineId,
    required this.price,
    required this.stockQuantity,
    required this.lastUpdated,
    this.pharmacyName = 'Verified Chemist',
    this.pharmacyAddress = '',
    this.pharmacyPhone = '',
    this.isAvailable = true,
  });

  factory InventoryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime parsedDate;
    if (data['lastUpdated'] is Timestamp) {
      parsedDate = (data['lastUpdated'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.now();
    }

    final priceVal = (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0;
    final stockVal = (data['stockQuantity'] is num) ? (data['stockQuantity'] as num).toInt() : 0;

    return InventoryModel(
      id: doc.id,
      pharmacyId: data['pharmacyId'] as String? ?? '',
      medicineId: data['medicineId'] as String? ?? '',
      price: priceVal,
      stockQuantity: stockVal,
      lastUpdated: parsedDate,
      pharmacyName: data['pharmacyName'] as String? ?? 'Verified Chemist',
      pharmacyAddress: data['pharmacyAddress'] as String? ?? '',
      pharmacyPhone: data['pharmacyPhone'] as String? ?? '',
      isAvailable: data['isAvailable'] as bool? ?? (stockVal > 0),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pharmacyId': pharmacyId,
      'medicineId': medicineId,
      'price': price,
      'stockQuantity': stockQuantity,
      'isAvailable': stockQuantity > 0,
      'pharmacyName': pharmacyName,
      'pharmacyAddress': pharmacyAddress,
      'pharmacyPhone': pharmacyPhone,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  bool get isInStock => stockQuantity > 0;
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= 5;
  String get formattedPrice => '₹${price.toStringAsFixed(2)}';

  String get formattedLastUpdated {
    final difference = DateTime.now().difference(lastUpdated);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
