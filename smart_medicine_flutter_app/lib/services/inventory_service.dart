import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _inventoryCollection =>
      _firestore.collection('inventory');

  /// Updates stock quantity and adjusts availability
  Future<void> updateStockQuantity({
    required String inventoryId,
    required int newQuantity,
  }) async {
    final clamped = newQuantity < 0 ? 0 : newQuantity;
    await _inventoryCollection.doc(inventoryId).update({
      'stockQuantity': clamped,
      'isAvailable': clamped > 0,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Updates price in Indian Rupees (₹)
  Future<void> updatePrice({
    required String inventoryId,
    required double newPrice,
  }) async {
    await _inventoryCollection.doc(inventoryId).update({
      'price': newPrice,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Atomically increments or decrements stock
  Future<bool> adjustStock({
    required String inventoryId,
    required int delta,
  }) async {
    return await _firestore.runTransaction<bool>((tx) async {
      final docRef = _inventoryCollection.doc(inventoryId);
      final snap = await tx.get(docRef);
      if (!snap.exists) return false;

      final current = (snap.data()?['stockQuantity'] as num?)?.toInt() ?? 0;
      final updated = current + delta;
      if (updated < 0) return false;

      tx.update(docRef, {
        'stockQuantity': updated,
        'isAvailable': updated > 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  /// Streams real-time inventory items for a specific medicine
  Stream<List<InventoryModel>> streamInventoryForMedicine(String medicineId) {
    return _inventoryCollection
        .where('medicineId', isEqualTo: medicineId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => InventoryModel.fromFirestore(d)).toList());
  }
}
