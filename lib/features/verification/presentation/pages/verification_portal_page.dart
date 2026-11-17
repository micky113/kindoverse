import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_footer.dart';
import '../../../../core/widgets/universal_navbar.dart';
import '../../../campaigns/domain/models/milestone.dart';
import '../../../campaigns/domain/models/project.dart';
import '../../../campaigns/presentation/providers/campaign_providers.dart';

/// Submission portal for Field Officers to submit GPS-stamped milestone updates
/// (with real file picker upload to Firebase Storage) and Admin Tranche Approval dashboard.
class VerificationPortalPage extends ConsumerStatefulWidget {
  const VerificationPortalPage({super.key});

  @override
  ConsumerState<VerificationPortalPage> createState() =>
      _VerificationPortalPageState();
}

class _VerificationPortalPageState
    extends ConsumerState<VerificationPortalPage> {
  String? _selectedProjectId;
  bool _isUploadingBefore = false;
  bool _isUploadingAfter = false;
  final _titleController = TextEditingController();
  final _budgetController = TextEditingController();
  final _remarksController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _beforeUrlController = TextEditingController();
  final _afterUrlController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _budgetController.dispose();
    _remarksController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _beforeUrlController.dispose();
    _afterUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadMilestonePhoto(
    String projectId,
    String stage,
  ) async {
    setState(() {
      if (stage == 'before') {
        _isUploadingBefore = true;
      } else {
        _isUploadingAfter = true;
      }
    });

    try {
      final url = await ref
          .read(impactStorageServiceProvider)
          .pickAndUploadImage(
            folderPath: 'projects/$projectId/milestones',
            customMetadata: {
              'projectId': projectId,
              'stage': stage,
              'gpsLat': _latController.text.trim(),
              'gpsLng': _lngController.text.trim(),
            },
          );
      if (url != null && mounted) {
        setState(() {
          if (stage == 'before') {
            _beforeUrlController.text = url;
          } else {
            _afterUrlController.text = url;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryEmerald,
            content: Text(
              'Uploaded $stage proof image to Firebase Storage!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorRed,
            content: Text('Upload failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingBefore = false;
          _isUploadingAfter = false;
        });
      }
    }
  }

  Future<void> _submitFieldUpdate(Project project) async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Please enter a milestone title.'),
        ),
      );
      return;
    }

    final budget = num.tryParse(_budgetController.text.trim()) ?? 0;
    final lat =
        double.tryParse(_latController.text.trim()) ?? project.location.lat;
    final lng =
        double.tryParse(_lngController.text.trim()) ?? project.location.lng;

    await ref.read(campaignRepositoryProvider).submitFieldMilestoneProof(
      projectId: project.id,
      milestoneTitle: _titleController.text.trim(),
      targetBudget: budget,
      beforeImageUrl: _beforeUrlController.text.trim(),
      afterImageUrl: _afterUrlController.text.trim(),
      remarks: _remarksController.text.trim(),
      gpsLat: lat,
      gpsLng: lng,
    );

    if (!mounted) return;
    _titleController.clear();
    _budgetController.clear();
    _remarksController.clear();
    _beforeUrlController.clear();
    _afterUrlController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primaryEmerald,
        content: Text(
          'Field Milestone Proof saved to Cloud Firestore! Queued for Admin Clearance.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaignsAsync = ref.watch(filteredCampaignsProvider);
    final activeUser = ref.watch(activeUserProvider);

    return Scaffold(
      appBar: const UniversalNavbar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: ResponsiveConstrainedBox(
                child: campaignsAsync.when(
                  data: (projects) {
                    if (projects.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.add_business_rounded,
                              size: 52,
                              color: AppColors.primaryEmerald,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No Fundraising Campaigns Created Yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create a campaign in the Admin Campaign Studio first to submit field milestone updates and approve tranche disbursements.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/admin'),
                              icon: const Icon(
                                Icons.admin_panel_settings_rounded,
                              ),
                              label: const Text('Open Admin Campaign Studio'),
                            ),
                          ],
                        ),
                      );
                    }

                    final currentProject = projects.firstWhere(
                      (p) => p.id == _selectedProjectId,
                      orElse: () => projects.first,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryTeal.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Field Officer & Admin Audit Portal (Active Role: ${activeUser.role.label})',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryEmerald,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Upload geo-tagged Before/After milestone proofs to Firebase Storage and approve tranche disbursements.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              DropdownButton<String>(
                                value: currentProject.id,
                                items:
                                    projects
                                        .map(
                                          (p) => DropdownMenuItem<String>(
                                            value: p.id,
                                            child: Text(
                                              p.title.length > 36
                                                  ? '${p.title.substring(0, 36)}...'
                                                  : p.title,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (val) => setState(
                                      () => _selectedProjectId = val,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        ResponsiveLayout(
                          mobile: Column(
                            children: [
                              _buildFieldSubmissionForm(currentProject),
                              const SizedBox(height: 24),
                              _AdminClearanceDashboard(project: currentProject),
                            ],
                          ),
                          desktop: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildFieldSubmissionForm(
                                  currentProject,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 6,
                                child: _AdminClearanceDashboard(
                                  project: currentProject,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldSubmissionForm(Project project) {
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
          const Row(
            children: [
              Icon(Icons.add_a_photo_outlined, color: AppColors.primaryEmerald),
              SizedBox(width: 8),
              Text(
                'Field Officer Proof Submission',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Milestone Title *',
              hintText: 'e.g., Phase 1: Borewell Drilling & Casing Pipe',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Tranche Budget Request (INR) *',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latController,
                  decoration: InputDecoration(
                    labelText: 'GPS Latitude',
                    hintText: project.location.lat.toString(),
                    prefixIcon: const Icon(Icons.my_location_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _lngController,
                  decoration: InputDecoration(
                    labelText: 'GPS Longitude',
                    hintText: project.location.lng.toString(),
                    prefixIcon: const Icon(Icons.my_location_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _beforeUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Before Photo URL (Firebase Storage)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed:
                    _isUploadingBefore
                        ? null
                        : () => _pickAndUploadMilestonePhoto(
                          project.id,
                          'before',
                        ),
                tooltip: 'Select & Upload Before Photo to Firebase Storage',
                icon: const Icon(Icons.upload_file_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _afterUrlController,
                  decoration: const InputDecoration(
                    labelText: 'After Photo URL (Firebase Storage)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed:
                    _isUploadingAfter
                        ? null
                        : () =>
                            _pickAndUploadMilestonePhoto(project.id, 'after'),
                tooltip: 'Select & Upload After Photo to Firebase Storage',
                icon: const Icon(Icons.upload_file_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarksController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Field Audit Notes & Vendor Voucher Reference',
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _submitFieldUpdate(project),
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Submit Geo-Tagged Milestone to Firestore'),
          ),
        ],
      ),
    );
  }
}

class _AdminClearanceDashboard extends ConsumerWidget {
  final Project project;

  const _AdminClearanceDashboard({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(projectMilestonesProvider(project.id));
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.primaryEmerald,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Admin Tranche Clearance & Disbursement Queue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          milestonesAsync.when(
            data: (milestones) {
              if (milestones.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No milestones submitted for this campaign yet.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                );
              }

              return Column(
                children:
                    milestones.map((m) {
                      final isPending = m.status == MilestoneStatus.pending;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isPending
                                  ? AppColors.accentAmberLight.withValues(
                                    alpha: 0.45,
                                  )
                                  : AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isPending
                                    ? AppColors.accentAmber
                                    : AppColors.borderSubtle,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isPending
                                            ? AppColors.accentAmber
                                            : AppColors.primaryEmerald,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    m.status.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tranche Budget: ${currencyFmt.format(m.targetBudget)} • GPS: ${m.gpsLat?.toStringAsFixed(4) ?? "N/A"}, ${m.gpsLng?.toStringAsFixed(4) ?? "N/A"}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (m.remarks.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                m.remarks,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                            if (isPending) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await ref
                                        .read(campaignRepositoryProvider)
                                        .approveMilestone(
                                          projectId: project.id,
                                          milestoneId: m.id,
                                        );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor:
                                            AppColors.primaryEmerald,
                                        content: Text(
                                          'Milestone "${m.title}" verified & ${currencyFmt.format(m.targetBudget)} released!',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.verified_rounded,
                                    size: 17,
                                  ),
                                  label: const Text(
                                    'Approve Proof & Release Tranche',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}
