import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final UserRole role;
  final bool isVerified;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    required this.role,
    this.isVerified = false,
    required this.createdAt,
  });

  // Factory constructor to deserialize from Cloud Firestore document snapshot
  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    // Parse role safely with fallback to customer
    final roleStr = data['role'] as String? ?? 'customer';
    UserRole parsedRole;
    if (roleStr == 'pharmacy') {
      parsedRole = UserRole.pharmacy;
    } else if (roleStr == 'admin') {
      parsedRole = UserRole.admin;
    } else {
      parsedRole = UserRole.customer;
    }

    DateTime parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.now();
    }

    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String?,
      role: parsedRole,
      isVerified: data['isVerified'] as bool? ?? false,
      createdAt: parsedDate,
    );
  }

  // Convert to Map for Firestore write operations
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'role': role.id,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': FieldValue.serverTimestamp(),
    };
  }
}
