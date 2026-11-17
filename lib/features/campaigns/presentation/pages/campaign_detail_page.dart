import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_footer.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/universal_navbar.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../../donations/presentation/widgets/donation_modal.dart';
import '../../../impact_engine/presentation/widgets/before_after_slider.dart';
import '../../domain/models/milestone.dart';
import '../../domain/models/project.dart';
import '../providers/campaign_providers.dart';

class CampaignDetailPage extends ConsumerWidget {
  final String projectId;

  const CampaignDetailPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectByIdProvider(projectId));
    final milestonesAsync = ref.watch(projectMilestonesProvider(projectId));
    final donationsAsync = ref.watch(projectDonationsProvider(projectId));

    return Scaffold(
      appBar: const UniversalNavbar(),
      body: projectAsync.when(
        data: (project) {
          if (project == null) {
            return const Center(child: Text('Campaign not found.'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: ResponsiveConstrainedBox(
                    child: ResponsiveLayout(
                      mobile: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CampaignHeaderContent(project: project),
                          const SizedBox(height: 20),
                          _FundingLedgerSidebar(project: project),
                          const SizedBox(height: 24),
                          _MilestonesAndProofSection(
                            project: project,
                            milestonesAsync: milestonesAsync,
                          ),
                          const SizedBox(height: 24),
                          _DonorAuditLedgerCard(donationsAsync: donationsAsync),
                        ],
                      ),
                      desktop: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _CampaignHeaderContent(project: project),
                                const SizedBox(height: 28),
                                _MilestonesAndProofSection(
                                  project: project,
                                  milestonesAsync: milestonesAsync,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 28),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _FundingLedgerSidebar(project: project),
                                const SizedBox(height: 24),
                                _DonorAuditLedgerCard(
                                  donationsAsync: donationsAsync,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const AppFooter(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _CampaignHeaderContent extends ConsumerWidget {
  final Project project;

  const _CampaignHeaderContent({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final isAdmin = ref.watch(activeUserProvider).role == UserRole.admin;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: isMobile ? 210 : 300,
            child: AppNetworkImage(
              url: project.coverImageUrl,
              fit: BoxFit.cover,
              fallbackBuilder:
                  (_) => Container(
                    color: AppColors.primaryLight,
                    child: const Icon(
                      Icons.landscape_rounded,
                      size: 64,
                      color: AppColors.primaryEmerald,
                    ),
                  ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(project.category.label),
                      backgroundColor: AppColors.primarySurface,
                    ),
                    Chip(
                      label: Text(project.fundingType.label),
                      backgroundColor: AppColors.accentAmberLight,
                    ),
                    Chip(
                      avatar: const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: AppColors.verifiedBlue,
                      ),
                      label: Text(project.organizerName),
                    ),
                    if (isAdmin)
                      ActionChip(
                        avatar: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        backgroundColor: AppColors.primaryEmerald,
                        label: const Text(
                          'Edit Campaign (Admin)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed:
                            () => context.go('/admin?edit=${project.id}'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  project.title,
                  style: TextStyle(
                    fontSize: isMobile ? 21 : 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.primaryTeal,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${project.location.displayAddress} (${project.location.lat.toStringAsFixed(4)}° N, ${project.location.lng.toStringAsFixed(4)}° E • Geohash #${project.location.geohash})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  project.description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (project.galleryUrls.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            size: 18,
                            color: AppColors.primaryEmerald,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Campaign Field Gallery (${project.galleryUrls.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed:
                            () => context.go('/gallery?folder=${project.id}'),
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: const Text('Open Folder in Gallery'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        project.galleryUrls.map((imgUrl) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              showDialog<void>(
                                context: context,
                                builder:
                                    (ctx) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: const EdgeInsets.all(24),
                                      child: Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 960,
                                                maxHeight: 720,
                                              ),
                                              child: AppNetworkImage(
                                                url: imgUrl,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: IconButton.filled(
                                              onPressed:
                                                  () => Navigator.of(ctx).pop(),
                                              icon: const Icon(Icons.close),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 180,
                                height: 130,
                                child: AppNetworkImage(
                                  url: imgUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FundingLedgerSidebar extends StatelessWidget {
  final Project project;

  const _FundingLedgerSidebar({required this.project});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final pct = (project.fundingProgress * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'VERIFIED FUND TRACKING LEDGER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryTeal,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            currencyFmt.format(project.raisedAmount),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryEmerald,
            ),
          ),
          Text(
            'raised of ${currencyFmt.format(project.targetAmount)} target ($pct%)',
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: project.fundingProgress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceSubtle,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryEmerald,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatColumn(
                  label: 'Audited Disbursed',
                  value: currencyFmt.format(project.disbursedAmount),
                ),
                _StatColumn(
                  label: 'Beneficiaries',
                  value: '${project.beneficiariesCount} Lives',
                ),
                _StatColumn(
                  label: 'Days Left',
                  value: '${project.daysLeft}d',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => DonationModal.show(context, project),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.volunteer_activism_rounded),
            label: const Text('Contribute & Claim 80G Receipt'),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _MilestonesAndProofSection extends StatelessWidget {
  final Project project;
  final AsyncValue<List<Milestone>> milestonesAsync;

  const _MilestonesAndProofSection({
    required this.project,
    required this.milestonesAsync,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return milestonesAsync.when(
      data: (milestones) {
        final firstWithProof =
            milestones.isNotEmpty ? milestones.first : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (firstWithProof != null &&
                firstWithProof.proofBeforeUrls.isNotEmpty &&
                firstWithProof.proofAfterUrls.isNotEmpty) ...[
              BeforeAfterSlider(
                title: 'Field Milestone Visual Audit: ${firstWithProof.title}',
                beforeImageUrl: firstWithProof.proofBeforeUrls.first,
                afterImageUrl: firstWithProof.proofAfterUrls.first,
                deliverableBadgeText:
                    '${project.beneficiariesCount} Beneficiaries Impacted',
              ),
              const SizedBox(height: 24),
            ],
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tranche-Linked Milestone Audit Trail',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...milestones.map((m) {
                    final isDone = m.status == MilestoneStatus.completed;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDone
                                  ? AppColors.primarySurface.withValues(
                                    alpha: 0.5,
                                  )
                                  : AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isDone
                                    ? AppColors.primaryTeal.withValues(
                                      alpha: 0.4,
                                    )
                                    : AppColors.borderSubtle,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isDone
                                      ? Icons.check_circle_rounded
                                      : Icons.schedule_rounded,
                                  color:
                                      isDone
                                          ? AppColors.primaryEmerald
                                          : AppColors.accentAmber,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    m.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Text(
                                  currencyFmt.format(m.targetBudget),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryEmerald,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              m.remarks,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading milestones: $e'),
    );
  }
}

class _DonorAuditLedgerCard extends StatelessWidget {
  final AsyncValue<List<dynamic>> donationsAsync;

  const _DonorAuditLedgerCard({required this.donationsAsync});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Verified Contributions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          donationsAsync.when(
            data: (donations) {
              return Column(
                children:
                    donations.take(6).map((d) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: const Icon(
                            Icons.verified_user_outlined,
                            color: AppColors.primaryEmerald,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          d.publicDonorName,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'Gateway Ref: ${d.paymentGatewayRef}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        trailing: Text(
                          currencyFmt.format(d.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                      );
                    }).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
