import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine_model.dart';
import '../models/inventory_model.dart';

class MedicineSearchResult {
  final MedicineModel medicine;
  final List<InventoryModel> availableStores;
  final double lowestPrice; // In Indian Rupees (₹)
  final int totalInStockCount;

  MedicineSearchResult({
    required this.medicine,
    required this.availableStores,
    required this.lowestPrice,
    required this.totalInStockCount,
  });

  bool get isAvailableAnywhere => totalInStockCount > 0;
}

class MedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _debounceTimer;
  Completer<List<MedicineSearchResult>>? _activeCompleter;

  // Real-time debounced search query executor (400ms buffer)
  void debouncedSearch({
    required String query,
    required String? category,
    required Function(List<MedicineSearchResult>) onResults,
    required Function(bool) onLoading,
    Duration delay = const Duration(milliseconds: 400),
  }) {
    _debounceTimer?.cancel();
    onLoading(true);

    _debounceTimer = Timer(delay, () async {
      try {
        final results = await searchMedicines(query: query, category: category);
        onResults(results);
      } catch (e) {
        onResults([]);
      } finally {
        onLoading(false);
      }
    });
  }

  // Core Firestore Search method supporting 400ms debounce
  Future<List<MedicineSearchResult>> searchMedicines({
    required String query,
    String? category,
  }) async {
    final cleanQuery = query.trim().toLowerCase();
    Query<Map<String, dynamic>> medRef = _firestore.collection('medicines');

    if (category != null && category.isNotEmpty && category != 'All') {
      medRef = medRef.where('category', isEqualTo: category);
    }

    QuerySnapshot<Map<String, dynamic>> medSnapshot;

    if (cleanQuery.isEmpty) {
      medSnapshot = await medRef.limit(20).get();
    } else {
      medSnapshot = await medRef
          .where('searchKeywords', arrayContains: cleanQuery)
          .limit(20)
          .get();

      if (medSnapshot.docs.isEmpty) {
        medSnapshot = await medRef
            .where('brandName', isGreaterThanOrEqualTo: query)
            .where('brandName', isLessThanOrEqualTo: '$query\uf8ff')
            .limit(20)
            .get();
      }
    }

    final medicines = medSnapshot.docs
        .map((doc) => MedicineModel.fromFirestore(doc))
        .toList();

    final List<MedicineSearchResult> searchResults = [];

    for (final medicine in medicines) {
      final invSnapshot = await _firestore
          .collection('inventory')
          .where('medicineId', isEqualTo: medicine.id)
          .get();

      final stores = invSnapshot.docs
          .map((doc) => InventoryModel.fromFirestore(doc))
          .toList();

      double lowest = 0.0;
      int inStockTotal = 0;

      if (stores.isNotEmpty) {
        final prices = stores.where((s) => s.stockQuantity > 0).map((s) => s.price);
        if (prices.isNotEmpty) {
          lowest = prices.reduce((a, b) => a < b ? a : b);
        } else {
          lowest = stores.first.price;
        }
        inStockTotal = stores.fold(0, (sum, item) => sum + item.stockQuantity);
      }

      searchResults.add(
        MedicineSearchResult(
          medicine: medicine,
          availableStores: stores,
          lowestPrice: lowest,
          totalInStockCount: inStockTotal,
        ),
      );
    }

    return searchResults;
  }

  // Fetch individual medicine details along with pharmacy inventory
  Future<MedicineModel?> getMedicineById(String medicineId) async {
    final doc = await _firestore.collection('medicines').doc(medicineId).get();
    if (!doc.exists) return null;
    return MedicineModel.fromFirestore(doc);
  }

  // Fetch full details and live inventory stores
  Future<Map<String, dynamic>?> getMedicineDetails(String medicineId) async {
    final med = await getMedicineById(medicineId);
    if (med == null) return null;

    final invSnapshot = await _firestore
        .collection('inventory')
        .where('medicineId', isEqualTo: medicineId)
        .get();

    final stores = invSnapshot.docs
        .map((d) => InventoryModel.fromFirestore(d))
        .toList();

    return {
      'medicine': med,
      'stores': stores,
      'lowestPrice': stores.isNotEmpty ? stores.map((s) => s.price).reduce((a, b) => a < b ? a : b) : 0.0,
      'totalStock': stores.fold<int>(0, (acc, item) => acc + item.stockQuantity),
    };
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
