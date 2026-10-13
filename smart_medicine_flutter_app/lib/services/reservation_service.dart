import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_model.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reservationsCollection =>
      _firestore.collection('reservations');

  CollectionReference<Map<String, dynamic>> get _inventoryCollection =>
      _firestore.collection('inventory');

  /// Creates a new medicine reservation and atomically holds stock from inventory
  Future<ReservationModel> createReservation({
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
    Duration holdDuration = ReservationModel.defaultHoldDuration,
  }) async {
    final reservationDoc = _reservationsCollection.doc();
    final reservationId = reservationDoc.id;

    final reservation = ReservationModel.create(
      id: reservationId,
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
      notes: notes,
      holdDuration: holdDuration,
    );

    // Atomically decrement inventory stock and write reservation document
    await _firestore.runTransaction((transaction) async {
      final inventoryQuery = await _inventoryCollection
          .where('pharmacyId', isEqualTo: pharmacyId)
          .where('medicineId', isEqualTo: medicineId)
          .limit(1)
          .get();

      if (inventoryQuery.docs.isNotEmpty) {
        final invDocRef = inventoryQuery.docs.first.reference;
        final invSnap = await transaction.get(invDocRef);
        final currentStock = (invSnap.data()?['stockQuantity'] as num?)?.toInt() ?? 0;

        if (currentStock >= quantity) {
          final newStock = currentStock - quantity;
          transaction.update(invDocRef, {
            'stockQuantity': newStock,
            'isAvailable': newStock > 0,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }

      transaction.set(reservationDoc, reservation.toFirestore());
    });

    return reservation;
  }

  /// Transition: Chemist accepts the hold request, activating the 2-hour hold timer
  Future<void> acceptReservation({
    required String reservationId,
    Duration holdDuration = ReservationModel.defaultHoldDuration,
  }) async {
    final now = DateTime.now();
    await _reservationsCollection.doc(reservationId).update({
      'status': ReservationStatus.accepted.id,
      'acceptedAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(holdDuration)),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  /// Transition: Chemist packages the medicine and marks ready at counter
  Future<void> markReservationReady({
    required String reservationId,
    String? pickupCode,
  }) async {
    final now = DateTime.now();
    final updateData = <String, dynamic>{
      'status': ReservationStatus.ready.id,
      'readyAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
    if (pickupCode != null) updateData['pickupCode'] = pickupCode;
    await _reservationsCollection.doc(reservationId).update(updateData);
  }

  /// Transition: Patient arrives at pharmacy, verifies code, pays in ₹ and collects medicine
  Future<void> completeReservation({required String reservationId}) async {
    final now = DateTime.now();
    await _reservationsCollection.doc(reservationId).update({
      'status': ReservationStatus.completed.id,
      'completedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  /// Transition: Cancel reservation and restore held stock to inventory
  Future<void> cancelReservation({
    required String reservationId,
    required String reason,
    bool restoreStock = true,
  }) async {
    final now = DateTime.now();
    await _firestore.runTransaction((transaction) async {
      final docRef = _reservationsCollection.doc(reservationId);
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final pharmacyId = data['pharmacyId'] as String? ?? '';
      final medicineId = data['medicineId'] as String? ?? '';
      final quantity = (data['quantity'] as num?)?.toInt() ?? 1;

      transaction.update(docRef, {
        'status': ReservationStatus.cancelled.id,
        'cancellationReason': reason,
        'cancelledAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      if (restoreStock && pharmacyId.isNotEmpty && medicineId.isNotEmpty) {
        final invQuery = await _inventoryCollection
            .where('pharmacyId', isEqualTo: pharmacyId)
            .where('medicineId', isEqualTo: medicineId)
            .limit(1)
            .get();

        if (invQuery.docs.isNotEmpty) {
          final invRef = invQuery.docs.first.reference;
          final invSnap = await transaction.get(invRef);
          final currStock = (invSnap.data()?['stockQuantity'] as num?)?.toInt() ?? 0;
          transaction.update(invRef, {
            'stockQuantity': currStock + quantity,
            'isAvailable': true,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  /// Real-time stream of patient reservations
  Stream<List<ReservationModel>> streamPatientReservations(String patientId) {
    return _reservationsCollection
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ReservationModel.fromFirestore(doc)).toList());
  }
}
