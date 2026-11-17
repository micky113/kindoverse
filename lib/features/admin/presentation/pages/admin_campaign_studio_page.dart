import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_footer.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/universal_navbar.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../../campaigns/data/repositories/campaign_repository.dart';
import '../../../campaigns/domain/models/milestone.dart';
import '../../../campaigns/domain/models/project.dart';
import '../../../campaigns/presentation/providers/campaign_providers.dart';
import '../../../impact_engine/domain/models/impact_story.dart';

class _MilestoneDraft {
  final TextEditingController titleCtrl;
  final TextEditingController budgetCtrl;
  final TextEditingController remarksCtrl;

  _MilestoneDraft({
    String title = '',
    String budget = '',
    String remarks = '',
  }) : titleCtrl = TextEditingController(text: title),
       budgetCtrl = TextEditingController(text: budget),
       remarksCtrl = TextEditingController(text: remarks);

  void dispose() {
    titleCtrl.dispose();
    budgetCtrl.dispose();
    remarksCtrl.dispose();
  }
}

/// Comprehensive Admin Campaign Studio (`/admin`) for creating fundraising campaigns,
/// uploading cover/gallery images to Firebase Cloud Storage, defining tranche milestones,
/// managing live Firestore campaigns, and publishing Before/After Impact Stories.
class AdminCampaignStudioPage extends ConsumerStatefulWidget {
  final String? editProjectId;

  const AdminCampaignStudioPage({super.key, this.editProjectId});

  @override
  ConsumerState<AdminCampaignStudioPage> createState() =>
      _AdminCampaignStudioPageState();
}

class _AdminCampaignStudioPageState
    extends ConsumerState<AdminCampaignStudioPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// Non-null when editing an existing campaign in Admin Studio.
  Project? _editingProject;

  // Campaign Creation Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _organizerController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _beneficiariesController = TextEditingController();
  final _villageController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _latController = TextEditingController(text: '20.5937');
  final _lngController = TextEditingController(text: '78.9629');
  final _coverImageUrlController = TextEditingController();

  ImpactCategory _selectedCategory = ImpactCategory.education;
  FundingType _selectedFundingType = FundingType.crowdfunding;
  ProjectStatus _selectedStatus = ProjectStatus.active;
  bool _organizerVerified = true;
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 45));
  final List<String> _galleryUrls = [];
  final List<_MilestoneDraft> _milestoneDrafts = [_MilestoneDraft()];

  bool _isUploadingCover = false;
  bool _isUploadingGallery = false;
  bool _isSubmittingCampaign = false;

  // Impact Story Form Controllers
  final _storyTitleController = TextEditingController();
  final _storyMetricKeyController = TextEditingController(
    text: 'beneficiaries_impacted',
  );
  final _storyMetricValueController = TextEditingController();
  final _storyLocationController = TextEditingController();
  final _storyBeforeUrlController = TextEditingController();
  final _storyAfterUrlController = TextEditingController();
  ImpactCategory _storyCategory = ImpactCategory.plantation;
  String? _storyLinkedProjectId;
  bool _isUploadingStoryBefore = false;
  bool _isUploadingStoryAfter = false;
  bool _isPublishingStory = false;

  static const Map<String, List<double>> _stateCoordinatePresets = {
    'Odisha': [20.9517, 85.0985],
    'Maharashtra': [19.7515, 75.7139],
    'Rajasthan': [27.0238, 74.2179],
    'Karnataka': [15.3173, 75.7139],
    'Uttar Pradesh': [26.8467, 80.9462],
    'Gujarat': [22.2587, 71.1924],
    'Tamil Nadu': [11.1271, 78.6569],
    'Andhra Pradesh': [15.9129, 79.7400],
    'Madhya Pradesh': [22.9734, 78.6569],
    'Assam': [26.2006, 92.9376],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() async {
      // Activate Admin role when entering the Admin Studio
      ref.read(activeUserProvider.notifier).switchRole(UserRole.admin);
      if (widget.editProjectId != null && widget.editProjectId!.isNotEmpty) {
        await _loadProjectForEdit(widget.editProjectId!);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AdminCampaignStudioPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editProjectId != null &&
        widget.editProjectId!.isNotEmpty &&
        widget.editProjectId != oldWidget.editProjectId) {
      _loadProjectForEdit(widget.editProjectId!);
    }
  }

  Future<void> _loadProjectForEdit(String projectId) async {
    try {
      final project =
          await ref
              .read(campaignRepositoryProvider)
              .watchProjectById(projectId)
              .first;
      if (project != null && mounted) {
        _startEditingCampaign(project);
      }
    } catch (_) {}
  }

  void _startEditingCampaign(Project project) {
    setState(() {
      _editingProject = project;
      _titleController.text = project.title;
      _descriptionController.text = project.description;
      _organizerController.text = project.organizerName;
      _targetAmountController.text = project.targetAmount.toString();
      _beneficiariesController.text = project.beneficiariesCount.toString();
      _villageController.text = project.location.village;
      _districtController.text = project.location.district;
      _stateController.text = project.location.state;
      _latController.text = project.location.lat.toString();
      _lngController.text = project.location.lng.toString();
      _coverImageUrlController.text = project.coverImageUrl;
      _selectedCategory = project.category;
      _selectedFundingType = project.fundingType;
      _selectedStatus = project.status;
      _organizerVerified = project.organizerVerified;
      _selectedDeadline =
          project.deadline ?? DateTime.now().add(const Duration(days: 45));
      _galleryUrls
        ..clear()
        ..addAll(project.galleryUrls);
    });
    _tabController.animateTo(0);
  }

  void _cancelEditing() {
    setState(() {
      _editingProject = null;
      _titleController.clear();
      _descriptionController.clear();
      _organizerController.clear();
      _targetAmountController.clear();
      _beneficiariesController.clear();
      _villageController.clear();
      _districtController.clear();
      _stateController.clear();
      _coverImageUrlController.clear();
      _galleryUrls.clear();
    });
    if (widget.editProjectId != null) {
      context.go('/admin');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _organizerController.dispose();
    _targetAmountController.dispose();
    _beneficiariesController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _coverImageUrlController.dispose();
    for (final m in _milestoneDrafts) {
      m.dispose();
    }
    _storyTitleController.dispose();
    _storyMetricKeyController.dispose();
    _storyMetricValueController.dispose();
    _storyLocationController.dispose();
    _storyBeforeUrlController.dispose();
    _storyAfterUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadCoverImage() async {
    setState(() => _isUploadingCover = true);
    try {
      final url = await ref
          .read(impactStorageServiceProvider)
          .pickAndUploadImage(
            folderPath: 'projects/covers',
            customMetadata: {'category': _selectedCategory.value},
          );
      if (url != null && mounted) {
        setState(() => _coverImageUrlController.text = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primaryEmerald,
            content: Text('Cover image uploaded to Firebase Storage!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorRed,
            content: Text('Cover upload failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _pickAndUploadGalleryImage() async {
    setState(() => _isUploadingGallery = true);
    try {
      final url = await ref
          .read(impactStorageServiceProvider)
          .pickAndUploadImage(folderPath: 'projects/gallery');
      if (url != null && mounted) {
        setState(() => _galleryUrls.add(url));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primaryEmerald,
            content: Text('Gallery photo uploaded to Firebase Storage!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorRed,
            content: Text('Gallery upload failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingGallery = false);
    }
  }

  Future<void> _submitNewCampaign() async {
    if (ref.read(activeUserProvider).role != UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text(
            'Access Denied: Only Admin / Verifier can create or edit campaigns.',
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmittingCampaign = true);
    try {
      final isEditing = _editingProject != null;
      final now = DateTime.now();
      final slug = _titleController.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      final projectId =
          isEditing
              ? _editingProject!.id
              : 'proj-${slug.isEmpty ? "campaign" : slug.substring(0, slug.length > 24 ? 24 : slug.length)}-${now.millisecondsSinceEpoch.toString().substring(8)}';

      final lat = double.tryParse(_latController.text.trim()) ?? 20.5937;
      final lng = double.tryParse(_lngController.text.trim()) ?? 78.9629;
      final targetAmount =
          num.tryParse(_targetAmountController.text.trim()) ?? 100000;
      final beneficiaries =
          int.tryParse(_beneficiariesController.text.trim()) ?? 1;

      final location = ProjectLocation.fromCoordinates(
        lat: lat,
        lng: lng,
        village: _villageController.text.trim(),
        district: _districtController.text.trim(),
        state: _stateController.text.trim(),
      );

      final project = Project(
        id: projectId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        fundingType: _selectedFundingType,
        targetAmount: targetAmount,
        raisedAmount: isEditing ? _editingProject!.raisedAmount : 0,
        disbursedAmount: isEditing ? _editingProject!.disbursedAmount : 0,
        location: location,
        status: _selectedStatus,
        coverImageUrl: _coverImageUrlController.text.trim(),
        galleryUrls: List<String>.from(_galleryUrls),
        beneficiariesCount: beneficiaries,
        organizerName:
            _organizerController.text.trim().isEmpty
                ? 'Kindoverse Verified Partner'
                : _organizerController.text.trim(),
        organizerVerified: _organizerVerified,
        createdAt: isEditing ? _editingProject!.createdAt : now,
        deadline: _selectedDeadline,
      );

      if (isEditing) {
        await ref
            .read(campaignRepositoryProvider)
            .updateCampaign(project: project);
      } else {
        final milestones = <Milestone>[];
        for (var i = 0; i < _milestoneDrafts.length; i++) {
          final draft = _milestoneDrafts[i];
          final mTitle = draft.titleCtrl.text.trim();
          if (mTitle.isEmpty) continue;
          final mBudget = num.tryParse(draft.budgetCtrl.text.trim()) ?? 0;
          milestones.add(
            Milestone(
              id: 'ms-${i + 1}-${now.millisecondsSinceEpoch}',
              projectId: projectId,
              title: mTitle,
              targetBudget: mBudget,
              status: MilestoneStatus.pending,
              proofBeforeUrls: const [],
              proofAfterUrls: const [],
              remarks: draft.remarksCtrl.text.trim(),
              gpsLat: lat,
              gpsLng: lng,
            ),
          );
        }

        await ref
            .read(campaignRepositoryProvider)
            .createCampaign(project: project, initialMilestones: milestones);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryEmerald,
          content: Text(
            isEditing
                ? 'Campaign "${project.title}" updated in Cloud Firestore!'
                : 'Campaign "${project.title}" published to Cloud Firestore!',
          ),
        ),
      );

      // Clear form for next entry
      _titleController.clear();
      _descriptionController.clear();
      _targetAmountController.clear();
      _beneficiariesController.clear();
      _villageController.clear();
      _districtController.clear();
      _coverImageUrlController.clear();
      setState(() {
        _editingProject = null;
        _galleryUrls.clear();
        for (final m in _milestoneDrafts) {
          m.dispose();
        }
        _milestoneDrafts
            ..clear()
            ..add(_MilestoneDraft());
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorRed,
            content: Text('Error saving campaign: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingCampaign = false);
    }
  }

  Future<void> _publishImpactStory() async {
    if (_storyTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Please enter an Impact Story title.'),
        ),
      );
      return;
    }

    setState(() => _isPublishingStory = true);
    try {
      final now = DateTime.now();
      final story = ImpactStory(
        id: 'story-${now.millisecondsSinceEpoch}',
        projectId: _storyLinkedProjectId ?? '',
        sectorCategory: _storyCategory,
        title: _storyTitleController.text.trim(),
        beforeImageUrl: _storyBeforeUrlController.text.trim(),
        afterImageUrl: _storyAfterUrlController.text.trim(),
        metricKey:
            _storyMetricKeyController.text.trim().isEmpty
                ? 'beneficiaries_impacted'
                : _storyMetricKeyController.text.trim(),
        metricValue:
            num.tryParse(_storyMetricValueController.text.trim()) ?? 100,
        locationSummary: _storyLocationController.text.trim(),
        publishedAt: now,
      );

      await ref.read(campaignRepositoryProvider).publishImpactStory(story);
      if (!mounted) return;
      _storyTitleController.clear();
      _storyMetricValueController.clear();
      _storyBeforeUrlController.clear();
      _storyAfterUrlController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primaryEmerald,
          content: Text('Before/After Impact Story published to Firestore!'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorRed,
            content: Text('Failed to publish story: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishingStory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      appBar: const UniversalNavbar(),
      body: Column(
        children: [
          Container(
            color: AppColors.surfaceWhite,
            child: ResponsiveConstrainedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: isMobile ? 14 : 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.primaryEmerald,
                          size: isMobile ? 22 : 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Fundraising Campaign Studio',
                              style: TextStyle(
                                fontSize: isMobile ? 17.5 : 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Create verified fundraising campaigns, upload media to Firebase Storage, and manage live Firestore documents.',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabController,
                    isScrollable: isMobile,
                    tabAlignment: isMobile ? TabAlignment.start : null,
                    labelColor: AppColors.primaryEmerald,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primaryEmerald,
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.add_business_rounded),
                        text:
                            isMobile
                                ? '1. Create Campaign'
                                : '1. Create Fundraising Campaign',
                      ),
                      Tab(
                        icon: const Icon(Icons.layers_outlined),
                        text:
                            isMobile
                                ? '2. Manage Campaigns & Stories'
                                : '2. Manage Live Campaigns & Impact Stories',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreateCampaignTab(),
                _buildManageCampaignsAndStoriesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCampaignTab() {
    final previewLat = double.tryParse(_latController.text.trim()) ?? 20.5937;
    final previewLng = double.tryParse(_lngController.text.trim()) ?? 78.9629;
    final previewLocation = ProjectLocation.fromCoordinates(
      lat: previewLat,
      lng: previewLng,
      village: _villageController.text.trim(),
      district: _districtController.text.trim(),
      state: _stateController.text.trim(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: ResponsiveConstrainedBox(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_editingProject != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentAmberLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accentAmber),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_note_rounded,
                            color: AppColors.accentAmber,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Admin Edit Mode: "${_editingProject!.title}"',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: _cancelEditing,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Cancel Edit'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              // Section 1: Core Campaign Identity & Classification
              _StudioCard(
                title: '1. Campaign Identity & Impact Classification',
                icon: Icons.campaign_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Campaign Title *',
                        hintText:
                            'e.g., Solar Drinking Water Filtration Kiosk for 300 Households',
                      ),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Please enter a campaign title'
                                  : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Detailed Mission & Deliverable Description *',
                        hintText:
                            'Describe the problem, intervention plan, beneficiaries, and measurable deliverables...',
                      ),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Please enter a campaign description'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: 340,
                          child: DropdownButtonFormField<ImpactCategory>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Target Impact Sector *',
                            ),
                            items:
                                ImpactCategory.values
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c.label),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedCategory = v);
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: 280,
                          child: DropdownButtonFormField<FundingType>(
                            value: _selectedFundingType,
                            decoration: const InputDecoration(
                              labelText: 'Primary Funding Channel *',
                            ),
                            items:
                                FundingType.values
                                    .map(
                                      (f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f.label),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedFundingType = v);
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<ProjectStatus>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Initial Status *',
                            ),
                            items:
                                ProjectStatus.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s.label),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedStatus = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 2: Financial Goal, Beneficiaries & Organizer
              _StudioCard(
                title: '2. Financial Target, Beneficiaries & Organizer Verification',
                icon: Icons.account_balance_wallet_outlined,
                child: Column(
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: 250,
                          child: TextFormField(
                            controller: _targetAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Target Amount (INR) *',
                              prefixIcon: Icon(Icons.currency_rupee_rounded),
                            ),
                            validator: (v) {
                              final parsed = num.tryParse(v?.trim() ?? '');
                              if (parsed == null || parsed <= 0) {
                                return 'Enter a valid amount';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                          width: 230,
                          child: TextFormField(
                            controller: _beneficiariesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Beneficiaries Count *',
                              prefixIcon: Icon(Icons.groups_2_outlined),
                            ),
                            validator: (v) {
                              final parsed = int.tryParse(v?.trim() ?? '');
                              if (parsed == null || parsed <= 0) {
                                return 'Enter count';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                          width: 320,
                          child: TextFormField(
                            controller: _organizerController,
                            decoration: const InputDecoration(
                              labelText: 'Implementing NGO / Organizer Name *',
                              prefixIcon: Icon(Icons.verified_user_outlined),
                            ),
                            validator:
                                (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Enter organizer name'
                                        : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _organizerVerified,
                            onChanged:
                                (v) => setState(() => _organizerVerified = v),
                            title: const Text(
                              'Display 80G / CSR Verified Organizer Badge',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDeadline,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 3),
                              ),
                            );
                            if (picked != null) {
                              setState(() => _selectedDeadline = picked);
                            }
                          },
                          icon: const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                          ),
                          label: Text(
                            'Deadline: ${DateFormat('dd MMM yyyy').format(_selectedDeadline)}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 3: Geo-Location & Geohash Indexing
              _StudioCard(
                title: '3. Geo-Tagging & Map Geohash Indexing',
                icon: Icons.location_on_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick State Coordinate Presets (Click to auto-fill state & center coordinates):',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _stateCoordinatePresets.entries.map((entry) {
                            return ActionChip(
                              label: Text(entry.key),
                              onPressed: () {
                                setState(() {
                                  _stateController.text = entry.key;
                                  _latController.text = entry.value[0].toString();
                                  _lngController.text = entry.value[1].toString();
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: 240,
                          child: TextFormField(
                            controller: _villageController,
                            decoration: const InputDecoration(
                              labelText: 'Village / Ward / Town *',
                            ),
                            validator:
                                (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                          ),
                        ),
                        SizedBox(
                          width: 240,
                          child: TextFormField(
                            controller: _districtController,
                            decoration: const InputDecoration(
                              labelText: 'District *',
                            ),
                            validator:
                                (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                          ),
                        ),
                        SizedBox(
                          width: 240,
                          child: TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: 'State *',
                            ),
                            validator:
                                (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                          ),
                        ),
                        SizedBox(
                          width: 170,
                          child: TextFormField(
                            controller: _latController,
                            onChanged: (_) => setState(() {}),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Latitude *',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 170,
                          child: TextFormField(
                            controller: _lngController,
                            onChanged: (_) => setState(() {}),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Longitude *',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Computed GeoFlutterFire+ Geohash: #${previewLocation.geohash} (${previewLat.toStringAsFixed(4)}° N, ${previewLng.toStringAsFixed(4)}° E)',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 4: Firebase Cloud Storage Media Upload
              _StudioCard(
                title: '4. Campaign Cover & Gallery Media (Firebase Cloud Storage)',
                icon: Icons.cloud_upload_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 560;
                        final urlField = TextFormField(
                          controller: _coverImageUrlController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText:
                                'Cover Image URL (Upload via button or paste URL) *',
                          ),
                          validator:
                              (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Please upload or provide a cover image URL'
                                      : null,
                        );
                        final uploadBtn = ElevatedButton.icon(
                          onPressed:
                              _isUploadingCover
                                  ? null
                                  : _pickAndUploadCoverImage,
                          icon:
                              _isUploadingCover
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(Icons.upload_file_rounded),
                          label: Text(
                            _isUploadingCover
                                ? 'Uploading...'
                                : 'Upload Cover Image',
                          ),
                        );

                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              urlField,
                              const SizedBox(height: 10),
                              uploadBtn,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: urlField),
                            const SizedBox(width: 12),
                            uploadBtn,
                          ],
                        );
                      },
                    ),
                    if (_coverImageUrlController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 160,
                          width: 300,
                          child: AppNetworkImage(
                            url: _coverImageUrlController.text.trim(),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed:
                              _isUploadingGallery
                                  ? null
                                  : _pickAndUploadGalleryImage,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                            _isUploadingGallery
                                ? 'Uploading Gallery Photo...'
                                : 'Add Gallery Image to Storage (${_galleryUrls.length})',
                          ),
                        ),
                      ],
                    ),
                    if (_galleryUrls.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(_galleryUrls.length, (idx) {
                          final gUrl = _galleryUrls[idx];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 140,
                                  height: 100,
                                  child: AppNetworkImage(
                                    url: gUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _galleryUrls.removeAt(idx));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.65,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 5: Initial Tranche Milestones Builder
              _StudioCard(
                title: '5. Tranche-Linked Audit Milestones',
                icon: Icons.flag_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...List.generate(_milestoneDrafts.length, (idx) {
                      final draft = _milestoneDrafts[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: draft.titleCtrl,
                                    decoration: InputDecoration(
                                      labelText:
                                          'Milestone #${idx + 1} Title (e.g., Phase 1: Site Survey & Civil Works)',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: draft.budgetCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Tranche Budget (INR)',
                                    ),
                                  ),
                                ),
                                if (_milestoneDrafts.length > 1)
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        final removed = _milestoneDrafts
                                            .removeAt(idx);
                                        removed.dispose();
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.errorRed,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: draft.remarksCtrl,
                              decoration: const InputDecoration(
                                labelText:
                                    'Expected Audit Deliverables & Verification Criteria',
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _milestoneDrafts.add(_MilestoneDraft()));
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Add Another Milestone Tranche'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSubmittingCampaign ? null : _submitNewCampaign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                  ),
                  icon:
                      _isSubmittingCampaign
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Icon(
                            _editingProject != null
                                ? Icons.save_rounded
                                : Icons.rocket_launch_rounded,
                          ),
                  label: Text(
                    _isSubmittingCampaign
                        ? (_editingProject != null
                            ? 'Saving Campaign Changes...'
                            : 'Publishing Campaign to Cloud Firestore...')
                        : (_editingProject != null
                            ? 'Save Campaign Changes to Firestore'
                            : 'Publish Fundraising Campaign to Firestore'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManageCampaignsAndStoriesTab() {
    final campaignsAsync = ref.watch(
      StreamProvider<List<Project>>((ref) {
        return ref
            .watch(campaignRepositoryProvider)
            .watchCampaigns(const CampaignFilter());
      }),
    );
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: ResponsiveConstrainedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StudioCard(
              title: 'Live Firestore Campaigns (`projects` collection)',
              icon: Icons.folder_special_outlined,
              child: campaignsAsync.when(
                data: (projects) {
                  if (projects.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No campaigns in Cloud Firestore yet. Use Tab 1 ("Create Fundraising Campaign") to add your first campaign!',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return Column(
                    children:
                        projects.map((p) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 64,
                                height: 48,
                                child: AppNetworkImage(
                                  url: p.coverImageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(
                              p.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${p.category.label} • ${p.location.displayAddress} • Target: ${currencyFmt.format(p.targetAmount)} • Gallery: ${p.galleryUrls.length} photo(s)',
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                DropdownButton<ProjectStatus>(
                                  value: p.status,
                                  items:
                                      ProjectStatus.values
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(
                                                s.label,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (next) {
                                    if (next != null) {
                                      ref
                                          .read(campaignRepositoryProvider)
                                          .updateProjectStatus(
                                            projectId: p.id,
                                            status: next,
                                          );
                                    }
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Edit Campaign (Admin Only)',
                                  onPressed: () => _startEditingCampaign(p),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: AppColors.primaryEmerald,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Open Campaign Page',
                                  onPressed:
                                      () => context.go('/project/${p.id}'),
                                  icon: const Icon(Icons.open_in_new_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Delete Campaign from Firestore',
                                  onPressed: () async {
                                    await ref
                                        .read(campaignRepositoryProvider)
                                        .deleteCampaign(p.id);
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ),
            const SizedBox(height: 24),

            // Publish Before/After Impact Story Card
            _StudioCard(
              title: 'Publish Before/After Impact Story (`impact_stories`)',
              icon: Icons.compare_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _storyTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Impact Story Headline *',
                      hintText:
                          'e.g., 15,000 Native Saplings Restored Degraded Panchayat Land',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 300,
                        child: DropdownButtonFormField<ImpactCategory>(
                          value: _storyCategory,
                          decoration: const InputDecoration(
                            labelText: 'Sector Category',
                          ),
                          items:
                              ImpactCategory.values
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.label),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _storyCategory = v);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: TextField(
                          controller: _storyMetricKeyController,
                          decoration: const InputDecoration(
                            labelText: 'Deliverable Metric Key',
                            hintText: 'e.g., trees_planted',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _storyMetricValueController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Metric Value (e.g. 1500)',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: TextField(
                          controller: _storyLocationController,
                          decoration: const InputDecoration(
                            labelText: 'Location Summary',
                            hintText: 'Village, District, State',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _storyBeforeUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Before Image URL',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed:
                            _isUploadingStoryBefore
                                ? null
                                : () async {
                                  setState(
                                    () => _isUploadingStoryBefore = true,
                                  );
                                  try {
                                    final url = await ref
                                        .read(impactStorageServiceProvider)
                                        .pickAndUploadImage(
                                          folderPath: 'projects/stories_before',
                                        );
                                    if (url != null && mounted) {
                                      setState(
                                        () =>
                                            _storyBeforeUrlController.text =
                                                url,
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(
                                        () => _isUploadingStoryBefore = false,
                                      );
                                    }
                                  }
                                },
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Upload Before Photo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _storyAfterUrlController,
                          decoration: const InputDecoration(
                            labelText: 'After Image URL',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed:
                            _isUploadingStoryAfter
                                ? null
                                : () async {
                                  setState(() => _isUploadingStoryAfter = true);
                                  try {
                                    final url = await ref
                                        .read(impactStorageServiceProvider)
                                        .pickAndUploadImage(
                                          folderPath: 'projects/stories_after',
                                        );
                                    if (url != null && mounted) {
                                      setState(
                                        () =>
                                            _storyAfterUrlController.text = url,
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(
                                        () => _isUploadingStoryAfter = false,
                                      );
                                    }
                                  }
                                },
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Upload After Photo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isPublishingStory ? null : _publishImpactStory,
                    icon: const Icon(Icons.publish_rounded),
                    label: Text(
                      _isPublishingStory
                          ? 'Publishing...'
                          : 'Publish Before/After Impact Story',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

class _StudioCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _StudioCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryEmerald, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
