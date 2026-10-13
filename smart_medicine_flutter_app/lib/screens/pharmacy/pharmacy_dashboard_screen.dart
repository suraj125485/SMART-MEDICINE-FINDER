import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/inventory_model.dart';
import '../../models/reservation_model.dart';
import '../../services/inventory_service.dart';
import '../../services/reservation_service.dart';

/// ============================================================================
/// PHARMACY OWNER DASHBOARD & STOCK MANAGER
/// Route: `/pharmacy-dashboard`
/// ============================================================================

class PharmacyDashboardScreen extends StatefulWidget {
  final String pharmacyId;
  final String pharmacyName;

  const PharmacyDashboardScreen({
    super.key,
    this.pharmacyId = 'pharm_apollo_cp',
    this.pharmacyName = 'Apollo 24x7 Pharmacy',
  });

  @override
  State<PharmacyDashboardScreen> createState() => _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InventoryService _inventoryService = InventoryService();
  final ReservationService _reservationService = ReservationService();

  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Low Stock', 'Out of Stock'
  bool _isStoreOnline = true;

  // Local state for stock management (synced with Firestore)
  List<Map<String, dynamic>> _stockItems = [
    {
      'id': 'inv_dolo_650',
      'medicineId': 'med_dolo_650',
      'brandName': 'Dolo 650mg',
      'genericName': 'Paracetamol',
      'category': 'Pain Relief',
      'dosageForm': 'Strip of 15 Tablets',
      'stockQuantity': 38,
      'price': 32.50,
      'batchNo': 'DOL-2026-X8',
      'expiryDate': '11/2027',
      'isAvailable': true,
    },
    {
      'id': 'inv_amox_500',
      'medicineId': 'med_amox_500',
      'brandName': 'Augmentin 625 Duo',
      'genericName': 'Amoxicillin + Clavulanic Acid',
      'category': 'Antibiotics',
      'dosageForm': 'Strip of 10 Tablets',
      'stockQuantity': 4, // Low stock trigger
      'price': 168.00,
      'batchNo': 'AUG-2025-M2',
      'expiryDate': '08/2026',
      'isAvailable': true,
    },
    {
      'id': 'inv_glyco_500',
      'medicineId': 'med_glyco_500',
      'brandName': 'Glycomet-GP 1 Forte',
      'genericName': 'Metformin + Glimepiride',
      'category': 'Diabetes',
      'dosageForm': 'Strip of 15 Tablets',
      'stockQuantity': 19,
      'price': 115.50,
      'batchNo': 'GLY-2026-A1',
      'expiryDate': '04/2027',
      'isAvailable': true,
    },
    {
      'id': 'inv_pantocid_40',
      'medicineId': 'med_pantocid_40',
      'brandName': 'Pantocid 40mg',
      'genericName': 'Pantoprazole Gastro-resistant',
      'category': 'Gastroenterology',
      'dosageForm': 'Strip of 15 Tablets',
      'stockQuantity': 0, // Out of stock
      'price': 142.00,
      'batchNo': 'PAN-2025-C9',
      'expiryDate': '12/2026',
      'isAvailable': false,
    },
  ];

  // Incoming Reservations Queue
  List<Map<String, dynamic>> _reservations = [
    {
      'id': 'RES-8824',
      'patientName': 'Rahul Verma',
      'patientPhone': '+91 98765 43210',
      'medicineName': 'Paracetamol 650mg (Dolo)',
      'quantity': 2,
      'totalPrice': 65.00,
      'status': 'accepted', // 2-hour hold active
      'pickupCode': 'HOLD-849',
      'minutesRemaining': 84,
      'time': '10:15 AM',
    },
    {
      'id': 'RES-8825',
      'patientName': 'Priya Sharma',
      'patientPhone': '+91 98112 34567',
      'medicineName': 'Augmentin 625 Duo',
      'quantity': 1,
      'totalPrice': 168.00,
      'status': 'pending',
      'pickupCode': 'HOLD-912',
      'minutesRemaining': 120,
      'time': '11:02 AM',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _adjustStock(int index, int delta) {
    setState(() {
      final current = _stockItems[index]['stockQuantity'] as int;
      final updated = (current + delta).clamp(0, 9999);
      _stockItems[index]['stockQuantity'] = updated;
      _stockItems[index]['isAvailable'] = updated > 0;
    });
  }

  void _toggleAvailability(int index) {
    setState(() {
      final isAvail = _stockItems[index]['isAvailable'] as bool;
      if (isAvail) {
        _stockItems[index]['stockQuantity'] = 0;
        _stockItems[index]['isAvailable'] = false;
      } else {
        _stockItems[index]['stockQuantity'] = 10;
        _stockItems[index]['isAvailable'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(widget.pharmacyName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Stock'),
            Tab(icon: Icon(Icons.timer), text: 'Holds (2h)'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Rx Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Stock Tab with Quick Adjusters
          ListView.builder(
            itemCount: _stockItems.length,
            itemBuilder: (ctx, i) {
              final item = _stockItems[i];
              return ListTile(
                title: Text(item['brandName'], style: const TextStyle(color: Colors.white)),
                subtitle: Text('₹${item['price']} • Stock: ${item['stockQuantity']} units'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white),
                      onPressed: () => _adjustStock(i, -1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () => _adjustStock(i, 1),
                    ),
                  ],
                ),
              );
            },
          ),
          const Center(child: Text('Holds Queue', style: TextStyle(color: Colors.white))),
          const Center(child: Text('Prescription Queue', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
