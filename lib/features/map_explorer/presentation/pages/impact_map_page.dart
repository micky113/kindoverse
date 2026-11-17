import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/universal_navbar.dart';
import '../../../campaigns/domain/models/project.dart';
import '../../../campaigns/presentation/providers/campaign_providers.dart';
import '../../../campaigns/presentation/widgets/campaign_card.dart';
import '../../../donations/presentation/widgets/donation_modal.dart';

/// Interactive Progress Map View (`/explore-map`).
/// Features:
/// - Dual-pane responsive layout (Interactive Geo-Map on left/top, project cards on right/bottom)
/// - Category marker clustering with custom sector pin icons
/// - Filter controls for Sector Category, Funding Type, Region, and Project Status
/// - Geohash viewport query telemetry
class ImpactMapPage extends ConsumerStatefulWidget {
  const ImpactMapPage({super.key});

  @override
  ConsumerState<ImpactMapPage> createState() => _ImpactMapPageState();
}

class _ImpactMapPageState extends ConsumerState<ImpactMapPage> {
  bool _clusterBySector = true;
  String? _selectedRegion;

  static const List<String> _regions = [
    'All Regions',
    'Odisha',
    'Rajasthan',
    'Maharashtra',
    'Uttar Pradesh',
    'Andhra Pradesh',
    'Gujarat',
  ];

  @override
  Widget build(BuildContext context) {
    final viewportProjectsAsync = ref.watch(viewportCampaignsProvider);
    final viewportState = ref.watch(mapViewportProvider);
    final filter = ref.watch(campaignFilterProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: const UniversalNavbar(),
      body: Column(
        children: [
          // Map Filter Header Bar (horizontally scrollable on mobile)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 20 : 12,
              vertical: isDesktop ? 12 : 8,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              border: Border(
                bottom: BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Icon(
                    Icons.travel_explore_rounded,
                    size: 20,
                    color: AppColors.primaryEmerald,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Geo-Query Filters:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Category Dropdown
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<ImpactCategory?>(
                        value: filter.category,
                        hint: const Text(
                          'All Sectors',
                          style: TextStyle(fontSize: 13),
                        ),
                        items: [
                          const DropdownMenuItem<ImpactCategory?>(
                            value: null,
                            child: Text(
                              'All Impact Sectors',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          ...ImpactCategory.values.map(
                            (c) => DropdownMenuItem<ImpactCategory?>(
                              value: c,
                              child: Text(
                                c.label,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                        onChanged:
                            (c) => ref
                                .read(campaignFilterProvider.notifier)
                                .setCategory(c),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Funding Channel Dropdown
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<FundingType?>(
                        value: filter.fundingType,
                        hint: const Text(
                          'All Channels',
                          style: TextStyle(fontSize: 13),
                        ),
                        items: [
                          const DropdownMenuItem<FundingType?>(
                            value: null,
                            child: Text(
                              'All Funding Channels',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          ...FundingType.values.map(
                            (f) => DropdownMenuItem<FundingType?>(
                              value: f,
                              child: Text(
                                f.label,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                        onChanged:
                            (f) => ref
                                .read(campaignFilterProvider.notifier)
                                .setFundingType(f),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Region Filter
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedRegion ?? 'All Regions',
                        items:
                            _regions
                                .map(
                                  (r) => DropdownMenuItem<String>(
                                    value: r,
                                    child: Text(
                                      r,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (region) {
                          setState(() => _selectedRegion = region);
                          ref
                              .read(campaignFilterProvider.notifier)
                              .setStateRegion(
                                region == 'All Regions' ? null : region,
                              );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilterChip(
                    label: const Text('Cluster by Sector'),
                    selected: _clusterBySector,
                    onSelected: (v) => setState(() => _clusterBySector = v),
                  ),
                ],
              ),
            ),
          ),

          // Dual-Pane Body: Interactive Geo Map + Project Carousel / Drawer
          Expanded(
            child: viewportProjectsAsync.when(
              data: (projects) {
                if (isDesktop) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: _InteractiveGeoCanvas(
                          projects: projects,
                          selectedProjectId: viewportState.selectedProjectId,
                          clusterBySector: _clusterBySector,
                          onSelectProject: (id) {
                            ref
                                .read(mapViewportProvider.notifier)
                                .selectProject(id);
                          },
                        ),
                      ),
                      Container(
                        width: 440,
                        decoration: const BoxDecoration(
                          color: AppColors.backgroundOffWhite,
                          border: Border(
                            left: BorderSide(color: AppColors.borderSubtle),
                          ),
                        ),
                        child: _MapProjectListPane(
                          projects: projects,
                          selectedProjectId: viewportState.selectedProjectId,
                        ),
                      ),
                    ],
                  );
                }

                // Mobile / Tablet stacked dual-pane
                return Column(
                  children: [
                    Expanded(
                      flex: 6,
                      child: _InteractiveGeoCanvas(
                        projects: projects,
                        selectedProjectId: viewportState.selectedProjectId,
                        clusterBySector: _clusterBySector,
                        onSelectProject: (id) {
                          ref
                              .read(mapViewportProvider.notifier)
                              .selectProject(id);
                        },
                      ),
                    ),
                    SizedBox(
                      height: 270,
                      child: _HorizontalMapCarousel(
                        projects: projects,
                        selectedProjectId: viewportState.selectedProjectId,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Map error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive cartographic canvas rendering geo-tagged project pins,
/// geohash cells, and sector clusters (works reliably across Web & Mobile without requiring an external Maps API key).
class _InteractiveGeoCanvas extends StatelessWidget {
  final List<Project> projects;
  final String? selectedProjectId;
  final bool clusterBySector;
  final ValueChanged<String> onSelectProject;

  const _InteractiveGeoCanvas({
    required this.projects,
    required this.selectedProjectId,
    required this.clusterBySector,
    required this.onSelectProject,
  });

  // Normalized India bounding box (Lat 8°N..35°N, Lng 68°E..92°E)
  Offset _projectToNormalized(double lat, double lng, Size size) {
    final normX = ((lng - 67.0) / (90.0 - 67.0)).clamp(0.08, 0.92);
    final normY = (1.0 - ((lat - 10.0) / (32.0 - 10.0))).clamp(0.10, 0.88);
    return Offset(normX * size.width, normY * size.height);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Topographic / Geohash Grid Canvas
            CustomPaint(
              painter: _CartographicGridPainter(),
            ),

            // Geohash Viewport Telemetry Pill
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.grid_4x4_rounded,
                      size: 16,
                      color: AppColors.primaryTeal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'GeoFlutterFire+ Viewport: ${projects.length} Active Markers',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Custom Category Pins
            ...projects.map((project) {
              final pos = _projectToNormalized(
                project.location.lat,
                project.location.lng,
                size,
              );
              final isSelected = project.id == selectedProjectId;
              final pinColor = CampaignCard.colorForCategory(project.category);

              return Positioned(
                left: pos.dx - 24,
                top: pos.dy - 24,
                child: GestureDetector(
                  onTap: () => onSelectProject(project.id),
                  child: AnimatedScale(
                    scale: isSelected ? 1.22 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryEmerald : pinColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CampaignCard.iconForCategory(project.category),
                                color: Colors.white,
                                size: 16,
                              ),
                              if (clusterBySector) ...[
                                const SizedBox(width: 5),
                                Text(
                                  project.location.village,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${project.location.geohash.substring(0, 5)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Category Legend Footer
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children:
                        ImpactCategory.values.map((c) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CampaignCard.iconForCategory(c),
                                size: 14,
                                color: CampaignCard.colorForCategory(c),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                c.label.split(' ').take(2).join(' '),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CartographicGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE6F4F1), Color(0xFFD9EFEA), Color(0xFFEBF5F3)],
          ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final gridPaint =
        Paint()
          ..color = const Color(0xFF0D9488).withValues(alpha: 0.12)
          ..strokeWidth = 1;

    const step = 64.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapProjectListPane extends StatelessWidget {
  final List<Project> projects;
  final String? selectedProjectId;

  const _MapProjectListPane({
    required this.projects,
    required this.selectedProjectId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final project = projects[index];
        final isSelected = project.id == selectedProjectId;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border:
                isSelected
                    ? Border.all(color: AppColors.primaryEmerald, width: 2.5)
                    : null,
          ),
          child: CampaignCard(
            project: project,
            onDonateTap: () => DonationModal.show(context, project),
          ),
        );
      },
    );
  }
}

class _HorizontalMapCarousel extends StatelessWidget {
  final List<Project> projects;
  final String? selectedProjectId;

  const _HorizontalMapCarousel({
    required this.projects,
    required this.selectedProjectId,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Container(
      color: AppColors.backgroundOffWhite,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        itemCount: projects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final p = projects[index];
          return SizedBox(
            width: 310,
            child: Card(
              child: InkWell(
                onTap: () => context.go('/project/${p.id}'),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.category.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CampaignCard.colorForCategory(p.category),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.location.displayAddress} • Geohash #${p.location.geohash.substring(0, 6)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      LinearProgressIndicator(
                        value: p.fundingProgress,
                        backgroundColor: AppColors.surfaceSubtle,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryEmerald,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${currencyFmt.format(p.raisedAmount)} raised',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                          TextButton(
                            onPressed: () => DonationModal.show(context, p),
                            child: const Text('Donate'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
