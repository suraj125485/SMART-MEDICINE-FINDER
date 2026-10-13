import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/prescription_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/prescription_service.dart';
import '../../widgets/medical_badge.dart';

class MyPrescriptionsScreen extends StatelessWidget {
  const MyPrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prescriptionService = PrescriptionService();
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final customerId = user?.uid ?? 'guest_patient_1';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_rounded),
            tooltip: 'Upload New Prescription',
            onPressed: () {
              Navigator.pushNamed(context, '/upload-prescription');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<PrescriptionModel>>(
          stream: prescriptionService.streamCustomerPrescriptions(customerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final list = snapshot.data ?? [];

            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Prescriptions Uploaded Yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Upload a doctor prescription to check medicine availability across neighborhood pharmacies.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Upload Doctor Prescription'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/upload-prescription');
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = list[index];

                Color statusBg;
                Color statusColor;

                switch (item.status) {
                  case PrescriptionStatus.available:
                  case PrescriptionStatus.readyForPickup:
                    statusBg = AppColors.inStockLight;
                    statusColor = AppColors.inStock;
                    break;
                  case PrescriptionStatus.unavailable:
                  case PrescriptionStatus.rejected:
                    statusBg = AppColors.outOfStockLight;
                    statusColor = AppColors.outOfStock;
                    break;
                  case PrescriptionStatus.partiallyAvailable:
                    statusBg = AppColors.lowStockLight;
                    statusColor = AppColors.lowStock;
                    break;
                  default:
                    statusBg = AppColors.primaryLight;
                    statusColor = AppColors.primaryDark;
                }

                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/prescription-chat',
                      arguments: item,
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.pharmacyName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            MedicalBadge(
                              label: item.status.label,
                              backgroundColor: statusBg,
                              textColor: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.pharmacyAddress,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Submitted on ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            Row(
                              children: const [
                                Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Chat with Pharmacist',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
