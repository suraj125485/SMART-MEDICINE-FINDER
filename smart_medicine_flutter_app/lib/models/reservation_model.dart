import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Schema: /reservations/{reservationId}
/// Defines 2-hour medicine hold workflow with status transitions and timestamps
enum ReservationStatus {
  pending,
  accepted,
  ready,
  completed,
  cancelled,
  expired,
}

extension ReservationStatusExtension on ReservationStatus {
  String get id {
    switch (this) {
      case ReservationStatus.pending: return 'pending';
      case ReservationStatus.accepted: return 'accepted';
      case ReservationStatus.ready: return 'ready';
      case ReservationStatus.completed: return 'completed';
      case ReservationStatus.cancelled: return 'cancelled';
      case ReservationStatus.expired: return 'expired';
    }
  }

  String get label {
    switch (this) {
      case ReservationStatus.pending: return 'Pending Chemist Hold';
      case ReservationStatus.accepted: return 'Hold Accepted (2h Active)';
      case ReservationStatus.ready: return 'Ready for Pickup';
      case ReservationStatus.completed: return 'Completed & Collected';
      case ReservationStatus.cancelled: return 'Reservation Cancelled';
      case ReservationStatus.expired: return '2-Hour Hold Expired';
    }
  }

  bool get isTerminal =>
      this == ReservationStatus.completed ||
      this == ReservationStatus.cancelled ||
      this == ReservationStatus.expired;

  bool get isActive =>
      this == ReservationStatus.pending ||
      this == ReservationStatus.accepted ||
      this == ReservationStatus.ready;

  bool canTransitionTo(ReservationStatus next) {
    if (this == next) return true;
    if (isTerminal) return false;
    switch (this) {
      case ReservationStatus.pending:
        return next == ReservationStatus.accepted || next == ReservationStatus.cancelled || next == ReservationStatus.expired;
      case ReservationStatus.accepted:
        return next == ReservationStatus.ready || next == ReservationStatus.cancelled || next == ReservationStatus.expired;
      case ReservationStatus.ready:
        return next == ReservationStatus.completed || next == ReservationStatus.cancelled || next == ReservationStatus.expired;
      default:
        return false;
    }
  }
}

class ReservationModel {
  static const Duration defaultHoldDuration = Duration(hours: 2);

  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String pharmacyId;
  final String pharmacyName;
  final String pharmacyAddress;
  final String pharmacyPhone;
  final String medicineId;
  final String medicineName;
  final String dosageForm;
  final int quantity;
  final double pricePerUnit; // In Indian Rupees (₹)
  final double totalPrice;   // In Indian Rupees (₹)
  final ReservationStatus status;
  final int holdDurationMinutes;
  final String? notes;
  final String? cancellationReason;

  // Timestamps
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime updatedAt;

  const ReservationModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.pharmacyPhone,
    required this.medicineId,
    required this.medicineName,
    required this.dosageForm,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.status,
    this.holdDurationMinutes = 120,
    this.notes,
    this.cancellationReason,
    required this.createdAt,
    required this.expiresAt,
    this.acceptedAt,
    this.readyAt,
    this.completedAt,
    this.cancelledAt,
    required this.updatedAt,
  });

  /// Creates a new 2-hour hold reservation
  factory ReservationModel.create({
    required String id,
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String pharmacyId,
    required String pharmacyName,
    required String pharmacyAddress,
    required String pharmacyPhone,
    required String medicineId,
    required String medicineName,
    required String dosageForm,
    required int quantity,
    required double pricePerUnit,
    String? notes,
  }) {
    final now = DateTime.now();
    return ReservationModel(
      id: id,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      pharmacyAddress: pharmacyAddress,
      pharmacyPhone: pharmacyPhone,
      medicineId: medicineId,
      medicineName: medicineName,
      dosageForm: dosageForm,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      totalPrice: quantity * pricePerUnit,
      status: ReservationStatus.pending,
      notes: notes,
      createdAt: now,
      expiresAt: now.add(defaultHoldDuration),
      updatedAt: now,
    );
  }

  factory ReservationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ReservationModel.fromMap(data, id: doc.id);
  }

  factory ReservationModel.fromMap(Map<String, dynamic> data, {String id = ''}) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? fallback;
      return fallback;
    }
    final created = parseDate(data['createdAt'], DateTime.now());
    final expiry = parseDate(data['expiresAt'], created.add(defaultHoldDuration));

    return ReservationModel(
      id: id.isNotEmpty ? id : (data['id'] as String? ?? ''),
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      patientPhone: data['patientPhone'] as String? ?? '',
      pharmacyId: data['pharmacyId'] as String? ?? '',
      pharmacyName: data['pharmacyName'] as String? ?? 'Verified Chemist',
      pharmacyAddress: data['pharmacyAddress'] as String? ?? '',
      pharmacyPhone: data['pharmacyPhone'] as String? ?? '',
      medicineId: data['medicineId'] as String? ?? '',
      medicineName: data['medicineName'] as String? ?? '',
      dosageForm: data['dosageForm'] as String? ?? 'Unit',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      pricePerUnit: (data['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: ReservationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ReservationStatus.pending,
      ),
      holdDurationMinutes: (data['holdDurationMinutes'] as num?)?.toInt() ?? 120,
      notes: data['notes'] as String?,
      cancellationReason: data['cancellationReason'] as String?,
      createdAt: created,
      expiresAt: expiry,
      acceptedAt: data['acceptedAt'] != null ? parseDate(data['acceptedAt'], created) : null,
      readyAt: data['readyAt'] != null ? parseDate(data['readyAt'], created) : null,
      completedAt: data['completedAt'] != null ? parseDate(data['completedAt'], created) : null,
      cancelledAt: data['cancelledAt'] != null ? parseDate(data['cancelledAt'], created) : null,
      updatedAt: parseDate(data['updatedAt'], created),
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
      'medicineId': medicineId,
      'medicineName': medicineName,
      'dosageForm': dosageForm,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'totalPrice': totalPrice,
      'status': status.id,
      'holdDurationMinutes': holdDurationMinutes,
      if (notes != null) 'notes': notes,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      if (readyAt != null) 'readyAt': Timestamp.fromDate(readyAt!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt!),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // State transitions
  ReservationModel accept([DateTime? timestamp]) => copyWith(
    status: ReservationStatus.accepted,
    acceptedAt: timestamp ?? DateTime.now(),
    expiresAt: (timestamp ?? DateTime.now()).add(defaultHoldDuration),
    updatedAt: timestamp ?? DateTime.now(),
  );

  ReservationModel markReady([DateTime? timestamp]) => copyWith(
    status: ReservationStatus.ready,
    readyAt: timestamp ?? DateTime.now(),
    updatedAt: timestamp ?? DateTime.now(),
  );

  ReservationModel complete([DateTime? timestamp]) => copyWith(
    status: ReservationStatus.completed,
    completedAt: timestamp ?? DateTime.now(),
    updatedAt: timestamp ?? DateTime.now(),
  );

  ReservationModel cancel({String? reason, DateTime? timestamp}) => copyWith(
    status: ReservationStatus.cancelled,
    cancelledAt: timestamp ?? DateTime.now(),
    cancellationReason: reason,
    updatedAt: timestamp ?? DateTime.now(),
  );

  bool get isExpired => DateTime.now().isAfter(expiresAt) && status != ReservationStatus.completed;
  Duration get remainingTime => isExpired ? Duration.zero : expiresAt.difference(DateTime.now());
  String get formattedPricePerUnit => '₹${pricePerUnit.toStringAsFixed(2)}';
  String get formattedTotalPrice => '₹${totalPrice.toStringAsFixed(2)}';

  ReservationModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? pharmacyId,
    String? pharmacyName,
    String? pharmacyAddress,
    String? pharmacyPhone,
    String? medicineId,
    String? medicineName,
    String? dosageForm,
    int? quantity,
    double? pricePerUnit,
    double? totalPrice,
    ReservationStatus? status,
    int? holdDurationMinutes,
    String? notes,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    DateTime? readyAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? updatedAt,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyAddress: pharmacyAddress ?? this.pharmacyAddress,
      pharmacyPhone: pharmacyPhone ?? this.pharmacyPhone,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      dosageForm: dosageForm ?? this.dosageForm,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      holdDurationMinutes: holdDurationMinutes ?? this.holdDurationMinutes,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      readyAt: readyAt ?? this.readyAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
