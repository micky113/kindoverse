import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../domain/models/project.dart';
import '../providers/campaign_providers.dart';

/// Card component displaying campaign verification status, geo-tagged location,
/// Target vs. Raised vs. Disbursed ledger progress, and primary actions.
class CampaignCard extends ConsumerWidget {
  final Project project;
  final VoidCallback? onDonateTap;

  const CampaignCard({
    super.key,
    required this.project,
    this.onDonateTap,
  });

  static Color colorForCategory(ImpactCategory category) {
    switch (category) {
      case ImpactCategory.education:
        return AppColors.categoryEducation;
      case ImpactCategory.villageAdoption:
        return AppColors.categoryVillage;
      case ImpactCategory.plantation:
        return AppColors.categoryPlantation;
      case ImpactCategory.agriculture:
        return AppColors.categoryAgriculture;
      case ImpactCategory.healthWaterSanitation:
        return AppColors.categoryWaterSanitation;
      case ImpactCategory.communalWelfare:
        return AppColors.categoryCommunalWelfare;
    }
  }

  static IconData iconForCategory(ImpactCategory category) {
    switch (category) {
      case ImpactCategory.education:
        return Icons.menu_book_rounded;
      case ImpactCategory.villageAdoption:
        return Icons.holiday_village_rounded;
      case ImpactCategory.plantation:
        return Icons.park_rounded;
      case ImpactCategory.agriculture:
        return Icons.grass_rounded;
      case ImpactCategory.healthWaterSanitation:
        return Icons.water_drop_rounded;
      case ImpactCategory.communalWelfare:
        return Icons.favorite_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(activeUserProvider).role == UserRole.admin;
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final categoryColor = colorForCategory(project.category);
    final progressPct = (project.fundingProgress * 100).round();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/project/${project.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image + Category & Status Overlay
            SizedBox(
              height: 185,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    url: project.coverImageUrl,
                    fit: BoxFit.cover,
                    fallbackBuilder:
                        (_) => Container(
                          color: categoryColor.withValues(alpha: 0.15),
                          child: Icon(
                            iconForCategory(project.category),
                            size: 48,
                            color: categoryColor,
                          ),
                        ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            iconForCategory(project.category),
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            project.category.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        project.fundingType.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project.location.displayAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryEmerald,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            project.status.label.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: AppColors.verifiedBlue,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          project.organizerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${project.beneficiariesCount} Lives',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    project.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Progress Bar (Raised vs Target)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: project.fundingProgress,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceSubtle,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryEmerald,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Target vs Raised vs Disbursed Ledger Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyFmt.format(project.raisedAmount),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                          Text(
                            'raised of ${currencyFmt.format(project.targetAmount)} ($progressPct%)',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFmt.format(project.disbursedAmount),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Audited Disbursed',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/project/${project.id}'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Audit & Proof'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              onDonateTap ??
                              () => context.go('/project/${project.id}'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Fund Impact'),
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Admin Only: Edit Campaign',
                          onPressed:
                              () => context.go('/admin?edit=${project.id}'),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
