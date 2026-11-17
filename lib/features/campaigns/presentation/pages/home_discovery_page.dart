import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_footer.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/universal_navbar.dart';
import '../../../donations/presentation/widgets/donation_modal.dart';
import '../../../impact_engine/presentation/widgets/before_after_slider.dart';
import '../../../impact_engine/presentation/widgets/impact_metric_card.dart';
import '../../domain/models/project.dart';
import '../providers/campaign_providers.dart';
import '../widgets/campaign_card.dart';

class HomeDiscoveryPage extends ConsumerWidget {
  const HomeDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(filteredCampaignsProvider);
    final storiesAsync = ref.watch(impactStoriesProvider);
    final filter = ref.watch(campaignFilterProvider);

    return Scaffold(
      appBar: const UniversalNavbar(),
      body: LayoutBuilder(
        builder: (context, viewportConstraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroSection(
                        projects:
                            campaignsAsync.valueOrNull ?? const <Project>[],
                      ),
                      const SizedBox(height: 32),

                      ResponsiveConstrainedBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FilterControlBar(filter: filter),
                            const SizedBox(height: 24),
                            campaignsAsync.when(
                              data: (projects) {
                                if (projects.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(40),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceWhite,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.borderSubtle,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          filter.hasActiveFilters
                                              ? Icons.search_off_rounded
                                              : Icons.add_business_rounded,
                                          size: 52,
                                          color: AppColors.primaryEmerald,
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          filter.hasActiveFilters
                                              ? 'No campaigns match the current filter criteria.'
                                              : 'No Fundraising Campaigns Published Yet',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          filter.hasActiveFilters
                                              ? 'Try clearing your active filters or search query.'
                                              : 'Open the Admin Campaign Studio to create your first verified fundraising campaign in Cloud Firestore.',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        if (filter.hasActiveFilters)
                                          OutlinedButton(
                                            onPressed:
                                                () =>
                                                    ref
                                                        .read(
                                                          campaignFilterProvider
                                                              .notifier,
                                                        )
                                                        .clearAll(),
                                            child: const Text(
                                              'Reset All Filters',
                                            ),
                                          )
                                        else
                                          ElevatedButton.icon(
                                            onPressed:
                                                () => context.go('/admin'),
                                            icon: const Icon(
                                              Icons
                                                  .admin_panel_settings_rounded,
                                            ),
                                            label: const Text(
                                              'Create First Campaign in Admin Studio',
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }

                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    final width = constraints.maxWidth;
                                    final cols =
                                        width >= 1060
                                            ? 3
                                            : width >= 680
                                            ? 2
                                            : 1;
                                    const spacing = 20.0;
                                    final cardWidth =
                                        (width - (spacing * (cols - 1))) / cols;

                                    return Wrap(
                                      spacing: spacing,
                                      runSpacing: spacing,
                                      children:
                                          projects.map((project) {
                                            return SizedBox(
                                              width: cardWidth,
                                              child: CampaignCard(
                                                project: project,
                                                onDonateTap:
                                                    () => DonationModal.show(
                                                      context,
                                                      project,
                                                    ),
                                              ),
                                            );
                                          }).toList(),
                                    );
                                  },
                                );
                              },
                              loading:
                                  () => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(48),
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              error:
                                  (err, _) => Center(
                                    child: Text('Error loading projects: $err'),
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Proof of Impact Engine Showcase (renders when impact_stories exist in Firestore)
                      storiesAsync.when(
                        data: (stories) {
                          if (stories.isEmpty) return const SizedBox.shrink();
                          final featured = stories.first;
                          return Container(
                            color: AppColors.primarySurface.withValues(
                              alpha: 0.6,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: ResponsiveConstrainedBox(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'PROOF OF IMPACT ENGINE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryEmerald,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Before & After Geo-Audited Transformations',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ImpactMetricCard(
                                    deliverableHeadline:
                                        '${featured.formattedMetricDeliverable} — ${featured.title}',
                                    metricKey: featured.metricKey,
                                    metricValue: featured.metricValue,
                                    category: featured.sectorCategory,
                                    locationLabel:
                                        featured.locationSummary ??
                                        'Verified Site',
                                    verifiedDate: featured.publishedAt,
                                  ),
                                  const SizedBox(height: 16),
                                  BeforeAfterSlider(
                                    title: featured.title,
                                    beforeImageUrl: featured.beforeImageUrl,
                                    afterImageUrl: featured.afterImageUrl,
                                    deliverableBadgeText:
                                        featured.formattedMetricDeliverable,
                                    aspectRatio:
                                        ResponsiveLayout.isMobile(context)
                                            ? 16 / 11
                                            : 21 / 9,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                  const AppFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroSlideItem {
  final Project project;
  final String imageUrl;
  final int indexInCampaign;
  final List<String> campaignThreeImages;

  const _HeroSlideItem({
    required this.project,
    required this.imageUrl,
    required this.indexInCampaign,
    required this.campaignThreeImages,
  });
}

class _HeroSection extends StatefulWidget {
  final List<Project> projects;

  const _HeroSection({required this.projects});

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  Timer? _fadeDelayTimer;
  Timer? _autoSlideTimer;
  final PageController _pageController = PageController();
  bool _showImageSlider = false;
  int _currentSlideIndex = 0;

  @override
  void initState() {
    super.initState();
    // Wait 3 seconds showing the initial green hero section, then fade to the campaign image slider
    _fadeDelayTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showImageSlider = true;
      });
      _startAutoSlide();
    });
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(milliseconds: 3600), (_) {
      if (!mounted) return;
      final slides = _buildSlides();
      if (slides.length <= 1 || !_pageController.hasClients) return;
      final nextIndex = (_currentSlideIndex + 1) % slides.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _fadeDelayTimer?.cancel();
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Collects up to 3 images from each campaign for the hero slider.
  List<_HeroSlideItem> _buildSlides() {
    final slides = <_HeroSlideItem>[];
    for (final project in widget.projects) {
      final uniquePhotos = <String>[];
      if (project.coverImageUrl.trim().isNotEmpty) {
        uniquePhotos.add(project.coverImageUrl.trim());
      }
      for (final g in project.galleryUrls) {
        final trimmed = g.trim();
        if (trimmed.isNotEmpty && !uniquePhotos.contains(trimmed)) {
          uniquePhotos.add(trimmed);
        }
      }
      final upToThree = uniquePhotos.take(3).toList();
      for (var i = 0; i < upToThree.length; i++) {
        slides.add(
          _HeroSlideItem(
            project: project,
            imageUrl: upToThree[i],
            indexInCampaign: i,
            campaignThreeImages: upToThree,
          ),
        );
      }
    }
    return slides;
  }

  void _goToSlide(int index, int total) {
    if (total <= 0 || !_pageController.hasClients) return;
    final target = (index + total) % total;
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final slides = _buildSlides();
    final shouldShowSlider = _showImageSlider && slides.isNotEmpty;

    return Stack(
      children: [
        IgnorePointer(
          ignoring: shouldShowSlider,
          child: AnimatedOpacity(
            opacity: shouldShowSlider ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeInOut,
            child: _buildInitialHeroTextContent(context, isMobile),
          ),
        ),
        if (slides.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !shouldShowSlider,
              child: AnimatedOpacity(
                opacity: shouldShowSlider ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 850),
                curve: Curves.easeInOut,
                child: _buildHeroImageSlider(context, slides, isMobile),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitialHeroTextContent(BuildContext context, bool isMobile) {
    return Container(
      key: const ValueKey('hero_initial_text'),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF044E3A),
            AppColors.primaryEmerald,
            AppColors.primaryTeal,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 52),
      child: ResponsiveConstrainedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile) ...[
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: const [
                  _ChannelPill(
                    icon: Icons.groups_rounded,
                    label: 'Crowd Funding',
                  ),
                  _ChannelPill(
                    icon: Icons.domain_verification_rounded,
                    label: 'Corporate CSR Sponsorship',
                  ),
                  _ChannelPill(
                    icon: Icons.volunteer_activism_rounded,
                    label: 'Targeted Micro-Donations',
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
            Text(
              'Transparent Social Development.\nEvery Rupee Geo-Tagged & Milestone Audited.',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 26 : 38,
                fontWeight: FontWeight.w900,
                height: 1.18,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Text(
                'Track Target vs. Raised vs. Disbursed funds in real time across Education, Village Adoption, Afforestation, Sustainable Agriculture, and Clean Water.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: isMobile ? 14.5 : 16.5,
                  height: 1.45,
                ),
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentAmber,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.admin_panel_settings_rounded),
                    label: const Text('Admin Studio: Create Campaign'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/explore-map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70, width: 1.5),
                    ),
                    icon: const Icon(Icons.explore_rounded),
                    label: const Text('Explore Interactive Impact Map'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImageSlider(
    BuildContext context,
    List<_HeroSlideItem> slides,
    bool isMobile,
  ) {
    final safeIndex =
        _currentSlideIndex < slides.length ? _currentSlideIndex : 0;

    return Stack(
      key: const ValueKey('hero_campaign_slider'),
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: slides.length,
          onPageChanged: (idx) {
            setState(() => _currentSlideIndex = idx);
          },
          itemBuilder: (context, index) {
            final slide = slides[index];
            return GestureDetector(
              onTap: () => context.go('/project/${slide.project.id}'),
              child: AppNetworkImage(
                url: slide.imageUrl,
                fit: BoxFit.cover,
              ),
            );
          },
        ),

        // Left / Right Navigation Arrows (no text)
        if (slides.length > 1) ...[
          Positioned(
            left: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                ),
                onPressed: () => _goToSlide(safeIndex - 1, slides.length),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                ),
                onPressed: () => _goToSlide(safeIndex + 1, slides.length),
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length > 12 ? 12 : slides.length,
                (dotIdx) {
                  final isSelected =
                      (safeIndex % (slides.length > 12 ? 12 : slides.length)) ==
                      dotIdx;
                  return GestureDetector(
                    onTap: () => _goToSlide(dotIdx, slides.length),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isSelected ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChannelPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ChannelPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.accentAmberLight),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterControlBar extends ConsumerWidget {
  final dynamic filter;

  const _FilterControlBar({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(campaignFilterProvider.notifier);
    final currentFilter = ref.watch(campaignFilterProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;
          final sectorWidth = isNarrow ? constraints.maxWidth : 280.0;
          final secondaryWidth = isNarrow ? constraints.maxWidth : 230.0;

          return Wrap(
            spacing: 14,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 20,
                    color: AppColors.primaryEmerald,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Filter Campaigns:',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              // 1. Sector Dropdown
              SizedBox(
                width: sectorWidth,
                child: DropdownButtonFormField<ImpactCategory?>(
                  key: ValueKey(
                    'sector_${currentFilter.category?.value ?? "all"}',
                  ),
                  value: currentFilter.category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sector',
                    prefixIcon: Icon(Icons.category_outlined, size: 18),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<ImpactCategory?>(
                      value: null,
                      child: Text('All Sectors'),
                    ),
                    ...ImpactCategory.values.map(
                      (cat) => DropdownMenuItem<ImpactCategory?>(
                        value: cat,
                        child: Text(
                          cat.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) => notifier.setCategory(val),
                ),
              ),

              // 2. Channel Dropdown
              SizedBox(
                width: secondaryWidth,
                child: DropdownButtonFormField<FundingType?>(
                  key: ValueKey(
                    'channel_${currentFilter.fundingType?.value ?? "all"}',
                  ),
                  value: currentFilter.fundingType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Channel',
                    prefixIcon: Icon(Icons.account_tree_outlined, size: 18),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<FundingType?>(
                      value: null,
                      child: Text('All Channels'),
                    ),
                    ...FundingType.values.map(
                      (ft) => DropdownMenuItem<FundingType?>(
                        value: ft,
                        child: Text(
                          ft.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) => notifier.setFundingType(val),
                ),
              ),

              // 3. Status Dropdown
              SizedBox(
                width: secondaryWidth,
                child: DropdownButtonFormField<ProjectStatus?>(
                  key: ValueKey(
                    'status_${currentFilter.status?.value ?? "all"}',
                  ),
                  value: currentFilter.status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.verified_outlined, size: 18),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<ProjectStatus?>(
                      value: null,
                      child: Text('All Statuses'),
                    ),
                    ...ProjectStatus.values.map(
                      (st) => DropdownMenuItem<ProjectStatus?>(
                        value: st,
                        child: Text(
                          st.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) => notifier.setStatus(val),
                ),
              ),

              if (currentFilter.hasActiveFilters)
                TextButton.icon(
                  onPressed: notifier.clearAll,
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  label: const Text('Reset Filters'),
                ),
            ],
          );
        },
      ),
    );
  }
}
