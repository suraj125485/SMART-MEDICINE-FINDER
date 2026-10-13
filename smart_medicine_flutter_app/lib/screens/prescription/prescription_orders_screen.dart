import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/prescription_model.dart';
import '../../services/prescription_service.dart';
import '../../widgets/medical_badge.dart';

class PrescriptionOrdersScreen extends StatelessWidget {
  const PrescriptionOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PrescriptionService service = PrescriptionService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_rounded),
            tooltip: 'Upload New Prescription',
            onPressed: () => Navigator.pushNamed(context, '/upload-prescription'),
          ),
        ],
      ),
      body: StreamBuilder<List<PrescriptionRequestModel>>(
        stream: service.streamPatientPrescriptions('patient_sample_uid'),
        builder: (context, snapshot) {
          // If empty, show helpful empty state or simulated cards
          final requests = snapshot.data ?? [
            PrescriptionRequestModel(
              id: 'req_101',
              patientId: 'patient_sample_uid',
              patientName: 'John Doe',
              patientPhone: '+1 (555) 321-4321',
              pharmacyId: 'pharmacy_careplus',
              pharmacyName: 'CarePlus Community Chemist',
              pharmacyAddress: '104 Healthcare Blvd',
              pharmacyPhone: '+1 (555) 234-5678',
              prescriptionImageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=800',
              status: PrescriptionStatus.reviewing,
              detectedItems: [
                PrescribedMedicineItem(
                  medicineName: 'Amoxicillin 500mg',
                  dosage: 'Capsule',
                  isAvailable: true,
                  estimatedPrice: 12.50,
                  stockCount: 18,
                ),
                PrescribedMedicineItem(
                  medicineName: 'Paracetamol 650mg',
                  dosage: 'Tablet',
                  isAvailable: true,
                  estimatedPrice: 3.50,
                  stockCount: 45,
                ),
              ],
              patientNotes: 'Urgent, picking up after office',
              createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
              updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
            ),
          ];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('No Prescriptions Uploaded Yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('Upload your doctor prescription to check availability.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Upload Prescription'),
                    onPressed: () => Navigator.pushNamed(context, '/upload-prescription'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final req = requests[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text(req.pharmacyName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          ],
                        ),
                        MedicalBadge(
                          label: req.status.label,
                          backgroundColor: req.status == PrescriptionStatus.readyForPickup ? AppColors.successLight : AppColors.primaryLight,
                          textColor: req.status == PrescriptionStatus.readyForPickup ? AppColors.successDark : AppColors.primaryDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${req.detectedItems.length} Prescribed Item(s): ${req.detectedItems.map((e) => e.medicineName).join(", ")}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sent ${req.createdAt.hour}:${req.createdAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          label: const Text('Chat with Pharmacist', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/prescription-chat',
                              arguments: {
                                'requestId': req.id,
                                'pharmacyName': req.pharmacyName,
                                'pharmacyPhone': req.pharmacyPhone,
                                'prescriptionImageUrl': req.prescriptionImageUrl,
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
