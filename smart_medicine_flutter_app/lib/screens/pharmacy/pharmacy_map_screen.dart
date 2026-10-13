// Source: Google Maps Platform Code Assist
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../services/medicine_service.dart';
import '../../models/inventory_model.dart';
import '../../widgets/medical_badge.dart';

class PharmacyMapScreen extends StatefulWidget {
  final List<MedicineSearchResult> searchResults;
  final VoidCallback onToggleView;

  const PharmacyMapScreen({
    super.key,
    required this.searchResults,
    required this.onToggleView,
  });

  @override
  State<PharmacyMapScreen> createState() => _PharmacyMapScreenState();
}

class _PharmacyMapScreenState extends State<PharmacyMapScreen> {
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  
  // Default camera centered on healthcare district
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194), // San Francisco Medical District
    zoom: 13.8,
  );

  Set<Marker> _markers = {};
  InventoryModel? _selectedPharmacy;
  String? _selectedMedicineName;
  double? _selectedPrice;
  MapType _currentMapType = MapType.normal;

  // Realistic sample coordinates for nearby pharmacies
  final Map<String, LatLng> _pharmacyCoordinates = {
    'CarePlus Community Chemist': const LatLng(37.7765, -122.4180),
    'Apex 24/7 Medical Store': const LatLng(37.7820, -122.4245),
    'Apex 24/7 Pharmacy': const LatLng(37.7820, -122.4245),
    'GreenCross Wellness Pharmacy': const LatLng(37.7680, -122.4130),
    'GreenCross Medical Store': const LatLng(37.7680, -122.4130),
    'City Hospital Chemist': const LatLng(37.7890, -122.4080),
  };

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  @override
  void didUpdateWidget(covariant PharmacyMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchResults != widget.searchResults) {
      _buildMarkers();
    }
  }

  void _buildMarkers() {
    final Set<Marker> newMarkers = {};

    for (final result in widget.searchResults) {
      for (final store in result.availableStores) {
        final pos = _pharmacyCoordinates[store.pharmacyName] ??
            LatLng(
              37.7749 + (store.pharmacyName.hashCode % 100) * 0.0003,
              -122.4194 + (store.pharmacyName.hashCode % 80) * 0.0003,
            );

        final inStock = store.stockQuantity > 0;

        newMarkers.add(
          Marker(
            markerId: MarkerId('${store.pharmacyName}_${result.medicine.id}'),
            position: pos,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              inStock ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRose,
            ),
            infoWindow: InfoWindow(
              title: store.pharmacyName,
              snippet: inStock
                  ? '${store.stockQuantity} in stock • ₹${store.price.toStringAsFixed(2)}'
                  : 'Currently Out of Stock',
            ),
            onTap: () {
              setState(() {
                _selectedPharmacy = store;
                _selectedMedicineName = result.medicine.brandName;
                _selectedPrice = store.price;
              });
              _animateToLocation(pos);
            },
          ),
        );
      }
    }

    setState(() {
      _markers = newMarkers;
      // Auto select first pharmacy if available
      if (widget.searchResults.isNotEmpty &&
          widget.searchResults.first.availableStores.isNotEmpty &&
          _selectedPharmacy == null) {
        _selectedPharmacy = widget.searchResults.first.availableStores.first;
        _selectedMedicineName = widget.searchResults.first.medicine.brandName;
        _selectedPrice = _selectedPharmacy!.price;
      }
    });
  }

  Future<void> _animateToLocation(LatLng target) async {
    final controller = await _controllerCompleter.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15.2, tilt: 25.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Google Map Viewport
        GoogleMap(
          initialCameraPosition: _initialPosition,
          mapType: _currentMapType,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _controllerCompleter.complete(controller);
          },
          onTap: (_) {
            setState(() => _selectedPharmacy = null);
          },
        ),

        // 2. Top Floating Controls: View Mode Toggle & Layer Switch
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // View Toggle Badge (Map <-> List)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: widget.onToggleView,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.view_list_rounded, size: 16, color: AppColors.textSecondary),
                            SizedBox(width: 4),
                            Text('List', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.map_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Map Type Toggle & Recenter
              Row(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'map_type_btn',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 3,
                    onPressed: () {
                      setState(() {
                        _currentMapType = _currentMapType == MapType.normal
                            ? MapType.hybrid
                            : MapType.normal;
                      });
                    },
                    child: Icon(_currentMapType == MapType.normal ? Icons.layers_rounded : Icons.layers_clear_rounded),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: 'recenter_btn',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 3,
                    onPressed: () => _animateToLocation(_initialPosition.target),
                    child: const Icon(Icons.my_location_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3. Bottom Selected Pharmacy Callout Card
        if (_selectedPharmacy != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _selectedPharmacy!.pharmacyName,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, color: AppColors.primary, size: 16),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    _selectedPharmacy!.pharmacyAddress.isNotEmpty
                                        ? _selectedPharmacy!.pharmacyAddress
                                        : '0.6 km away • Open 24/7',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _selectedPharmacy = null),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.border),

                  // Stock & Price Banner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedMedicineName != null)
                            Text(
                              _selectedMedicineName!,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                            ),
                          Row(
                            children: [
                              MedicalBadge(
                                label: _selectedPharmacy!.isAvailable
                                    ? '${_selectedPharmacy!.stockQuantity} in stock'
                                    : 'Out of Stock',
                                backgroundColor: _selectedPharmacy!.isAvailable ? AppColors.successLight : AppColors.errorLight,
                                textColor: _selectedPharmacy!.isAvailable ? AppColors.successDark : AppColors.errorDark,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Updated ${_selectedPharmacy!.formattedLastUpdated}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_selectedPrice != null)
                        Text(
                          '₹${_selectedPrice!.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons: Directions, Call & Hold Reservation
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.directions_rounded, size: 16),
                        label: const Text('Directions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening Google Maps navigation to ${_selectedPharmacy!.pharmacyName}...')),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.phone_rounded, size: 16),
                        label: const Text('Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling ${_selectedPharmacy!.pharmacyName} at ${_selectedPharmacy!.pharmacyPhone}...')),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.lock_clock_rounded, size: 16),
                          label: const Text('Hold / Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.success,
                                content: Text('Stock reserved at ${_selectedPharmacy!.pharmacyName} for 2 hours!'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
