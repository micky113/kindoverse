import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../campaigns/domain/models/project.dart';

/// Displays verified quantifiable deliverables alongside audit metadata
/// (e.g., "120 Saplings Planted", "1 Borewell Dug: 450 Villagers Served").
class ImpactMetricCard extends StatelessWidget {
  final String deliverableHeadline;
  final String metricKey;
  final num metricValue;
  final ImpactCategory category;
  final String locationLabel;
  final DateTime verifiedDate;

  const ImpactMetricCard({
    super.key,
    required this.deliverableHeadline,
    required this.metricKey,
    required this.metricValue,
    required this.category,
    required this.locationLabel,
    required this.verifiedDate,
  });

  IconData _iconForCategory(ImpactCategory category) {
    switch (category) {
      case ImpactCategory.education:
        return Icons.school_rounded;
      case ImpactCategory.villageAdoption:
        return Icons.holiday_village_rounded;
      case ImpactCategory.plantation:
        return Icons.forest_rounded;
      case ImpactCategory.agriculture:
        return Icons.agriculture_rounded;
      case ImpactCategory.healthWaterSanitation:
        return Icons.water_drop_rounded;
      case ImpactCategory.communalWelfare:
        return Icons.volunteer_activism_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _iconForCategory(category),
              color: AppColors.primaryEmerald,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      deliverableHeadline,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primaryTeal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.gps_fixed_rounded,
                            size: 12,
                            color: AppColors.primaryTeal,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'GPS & Ledger Audited',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Sector: ${category.label} • Location: $locationLabel',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
