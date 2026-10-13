import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../models/prescription_model.dart';
import '../../services/prescription_service.dart';
import '../../widgets/medical_badge.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  State<UploadPrescriptionScreen> createState() => _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  final PrescriptionService _prescriptionService = PrescriptionService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _notesController = TextEditingController();

  File? _selectedImage;
  bool _isLoadingStores = true;
  bool _isCheckingAvailability = false;
  bool _isSubmitting = false;

  List<SelectedPharmacyModel> _pharmacies = [];
  SelectedPharmacyModel? _chosenPharmacy;
  List<PrescribedMedicineItem> _detectedMedicines = [];
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacies() async {
    final stores = await _prescriptionService.getAvailablePharmacies();
    setState(() {
      _pharmacies = stores;
      if (stores.isNotEmpty) {
        _chosenPharmacy = stores.first;
      }
      _isLoadingStores = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _hasScanned = false;
          _detectedMedicines = [];
        });
        // Auto trigger smart availability scan
        _runSmartAvailabilityCheck();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access camera/gallery: $e')),
        );
      }
    }
  }

  Future<void> _runSmartAvailabilityCheck() async {
    if (_chosenPharmacy == null) return;
    setState(() => _isCheckingAvailability = true);

    // Simulated OCR detection of prescription items (or plug Google ML Kit OCR)
    final detectedNames = [
      'Amoxicillin 500mg',
      'Paracetamol 650mg',
      'Cetirizine 10mg',
    ];

    // Check live availability against chosen pharmacy's inventory
    final items = await _prescriptionService.checkPrescriptionAvailability(
      pharmacyId: _chosenPharmacy!.id,
      detectedMedicineNames: detectedNames,
    );

    setState(() {
      _detectedMedicines = items;
      _hasScanned = true;
      _isCheckingAvailability = false;
    });
  }

  Future<void> _submitPrescriptionOrder() async {
    if (_chosenPharmacy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pharmacy store first.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // In production: upload image to Firebase Storage; during dev demo fallback to placeholder
      String imageUrl = 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=800';
      if (_selectedImage != null) {
        try {
          imageUrl = await _prescriptionService.uploadPrescriptionImage(
            imageFile: _selectedImage!,
            userId: 'patient_sample_uid',
          );
        } catch (_) {
          // If storage bucket isn't initialized yet in local test
          imageUrl = 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=800';
        }
      }

      final request = PrescriptionRequestModel(
        id: '',
        patientId: 'patient_sample_uid',
        patientName: 'John Doe',
        patientPhone: '+1 (555) 321-4321',
        pharmacyId: _chosenPharmacy!.id,
        pharmacyName: _chosenPharmacy!.name,
        pharmacyAddress: _chosenPharmacy!.address,
        pharmacyPhone: _chosenPharmacy!.phone,
        prescriptionImageUrl: imageUrl,
        status: PrescriptionStatus.pending,
        detectedItems: _detectedMedicines.isNotEmpty
            ? _detectedMedicines
            : [
                PrescribedMedicineItem(
                  medicineName: 'Doctor Rx Upload',
                  dosage: 'As per image',
                  isAvailable: true,
                  estimatedPrice: 24.50,
                  stockCount: 1,
                )
              ],
        patientNotes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final requestId = await _prescriptionService.submitPrescription(request: request);

      if (mounted) {
        setState(() => _isSubmitting = false);
        // Show success snackbar confirming store phone alert
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Prescription sent to ${_chosenPharmacy!.name}! Store alerted via notification.'),
                ),
              ],
            ),
          ),
        );

        // Navigate to Prescription Chat screen with pharmacist
        Navigator.pushReplacementNamed(
          context,
          '/prescription-chat',
          arguments: {
            'requestId': requestId,
            'pharmacyName': _chosenPharmacy!.name,
            'pharmacyPhone': _chosenPharmacy!.phone,
            'prescriptionImageUrl': imageUrl,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send prescription: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upload Doctor Prescription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'My Prescriptions',
            onPressed: () => Navigator.pushNamed(context, '/prescription-orders'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1: Select Pharmacy Store
              const Text(
                '1. Select Pharmacy Store',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose which verified pharmacy receives your prescription and alerts.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),

              if (_isLoadingStores)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<SelectedPharmacyModel>(
                      isExpanded: true,
                      value: _chosenPharmacy,
                      items: _pharmacies.map((store) {
                        return DropdownMenuItem(
                          value: store,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Text(store.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified_rounded, color: AppColors.primary, size: 14),
                                      ],
                                    ),
                                    Text('${store.distance} • ${store.operatingHours}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newStore) {
                        setState(() {
                          _chosenPharmacy = newStore;
                          if (_hasScanned) {
                            _runSmartAvailabilityCheck();
                          }
                        });
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Step 2: Image Upload Card
              const Text(
                '2. Upload Prescription Image',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ensure the doctor\'s signature and medicine names are clearly visible.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    if (_selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.file(_selectedImage!, height: 190, width: double.infinity, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                                  onPressed: () => _pickImage(ImageSource.gallery),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.document_scanner_rounded, color: AppColors.primary, size: 32),
                            ),
                            const SizedBox(height: 8),
                            const Text('No prescription selected', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                            const Text('Take a photo or choose from your gallery', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.camera_alt_rounded, size: 18),
                            label: const Text('Camera'),
                            onPressed: () => _pickImage(ImageSource.camera),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.photo_library_rounded, size: 18),
                            label: const Text('Gallery'),
                            onPressed: () => _pickImage(ImageSource.gallery),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Step 3: Real-Time Availability Check breakdown
              if (_isCheckingAvailability)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Checking medicine inventory at selected pharmacy...',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_hasScanned)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '3. Prescription Availability Check',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        MedicalBadge(
                          label: '${_chosenPharmacy?.name.split(" ").first} Stock',
                          backgroundColor: AppColors.successLight,
                          textColor: AppColors.successDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: _detectedMedicines.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  item.isAvailable ? Icons.check_circle_rounded : Icons.warning_rounded,
                                  color: item.isAvailable ? AppColors.success : AppColors.warning,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.medicineName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                      Text(
                                        item.isAvailable ? 'In Stock (${item.stockCount} units available)' : 'Low/Alternate needed',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: item.isAvailable ? AppColors.successDark : AppColors.warning,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '~$${item.estimatedPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Step 4: Patient Notes
              const Text(
                '4. Notes for Pharmacist (Optional)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Please check if generic substitute is available, pickup at 5 PM...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),

              const SizedBox(height: 24),

              // Action Button: Send to Store & Alert Store Phone
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    _isSubmitting
                        ? 'Sending & Alerting Store...'
                        : 'Send to ${_chosenPharmacy?.name.split(" ").first ?? "Pharmacy"} & Chat',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  onPressed: _isSubmitting ? null : _submitPrescriptionOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
