import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/medicine_service.dart';
import 'medical_badge.dart';

class MedicineCard extends StatelessWidget {
  final MedicineSearchResult item;
  final VoidCallback onTap;

  const MedicineCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final med = item.medicine;
    final inStock = item.isAvailableAnywhere;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category badge & Prescription tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MedicalBadge(
                  label: med.category,
                  backgroundColor: AppColors.primaryLight,
                  textColor: AppColors.primaryDark,
                ),
                if (med.requiresPrescription)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: const Text(
                      'Rx Required',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC62828),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Medicine Name & Generic info
            Text(
              med.brandName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${med.genericName} • ${med.dosage}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),

            // Availability & Price Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          inStock ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 15,
                          color: inStock ? AppColors.inStock : AppColors.outOfStock,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          inStock
                              ? 'In Stock at ${item.availableStores.length} ${item.availableStores.length == 1 ? "pharmacy" : "pharmacies"}'
                              : 'Out of Stock nearby',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: inStock ? AppColors.inStock : AppColors.outOfStock,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      inStock ? 'From ₹${item.lowestPrice.toStringAsFixed(2)} / unit' : 'Check back later',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
