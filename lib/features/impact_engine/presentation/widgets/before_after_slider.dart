import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Interactive Before/After split image comparison engine for Proof of Impact.
/// Supports:
/// - Smooth horizontal drag handle (Mouse & Touch)
/// - Side-by-side comparison mode toggle
/// - Fullscreen zoomable inspection modal
/// - Low-bandwidth progressive network image loading with fallback visuals
class BeforeAfterSlider extends StatefulWidget {
  final String beforeImageUrl;
  final String afterImageUrl;
  final String beforeLabel;
  final String afterLabel;
  final String? title;
  final String? deliverableBadgeText;
  final double aspectRatio;
  final double initialSplit;

  const BeforeAfterSlider({
    super.key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.beforeLabel = 'BEFORE IMPACT',
    this.afterLabel = 'AFTER IMPACT',
    this.title,
    this.deliverableBadgeText,
    this.aspectRatio = 16 / 10,
    this.initialSplit = 0.5,
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  late double _splitFraction;
  bool _isSideBySideMode = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _splitFraction = widget.initialSplit.clamp(0.05, 0.95);
  }

  void _updateSplit(double localDx, double maxWidth) {
    if (maxWidth <= 0) return;
    setState(() {
      _splitFraction = (localDx / maxWidth).clamp(0.04, 0.96);
    });
  }

  void _openZoomModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black.withValues(alpha: 0.92),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title ?? 'Proof of Impact Inspection',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Close inspection view',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: widget.aspectRatio,
                          child: _buildSplitViewport(enableRadius: true),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top toolbar with title, deliverable pill, and mode toggles
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
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
                      Icons.verified_outlined,
                      size: 20,
                      color: AppColors.primaryEmerald,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.title ?? 'Verified Visual Audit (Before vs. After)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (widget.deliverableBadgeText != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentAmberLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.deliverableBadgeText!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentAmber,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          icon: Icon(Icons.compare, size: 16),
                          label: Text('Split Slider'),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          icon: Icon(Icons.view_column_outlined, size: 16),
                          label: Text('Side-by-Side'),
                        ),
                      ],
                      selected: {_isSideBySideMode},
                      onSelectionChanged: (selection) {
                        setState(() => _isSideBySideMode = selection.first);
                      },
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => _openZoomModal(context),
                      icon: const Icon(Icons.fullscreen, size: 22),
                      tooltip: 'Inspect Fullscreen & Zoom',
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Main comparison viewport
          Padding(
            padding: const EdgeInsets.all(12),
            child: AspectRatio(
              aspectRatio: widget.aspectRatio,
              child:
                  _isSideBySideMode
                      ? _buildSideBySideViewport()
                      : _buildSplitViewport(enableRadius: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideBySideViewport() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _ImpactNetworkImage(
                  url: widget.beforeImageUrl,
                  isAfter: false,
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _StageBadge(
                    label: widget.beforeLabel,
                    backgroundColor: Colors.black.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _ImpactNetworkImage(
                  url: widget.afterImageUrl,
                  isAfter: true,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _StageBadge(
                    label: widget.afterLabel,
                    backgroundColor: AppColors.primaryEmerald,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSplitViewport({required bool enableRadius}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final splitX = width * _splitFraction;

        return MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _updateSplit(details.localPosition.dx, width),
            onHorizontalDragStart: (_) => setState(() => _isDragging = true),
            onHorizontalDragUpdate:
                (details) => _updateSplit(details.localPosition.dx, width),
            onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
            child: ClipRRect(
              borderRadius:
                  enableRadius ? BorderRadius.circular(12) : BorderRadius.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Full layer: AFTER image
                  _ImpactNetworkImage(
                    url: widget.afterImageUrl,
                    isAfter: true,
                  ),

                  // Clipped left layer: BEFORE image
                  ClipRect(
                    clipper: _LeftSplitClipper(splitX: splitX),
                    child: _ImpactNetworkImage(
                      url: widget.beforeImageUrl,
                      isAfter: false,
                    ),
                  ),

                  // Corner labels
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _StageBadge(
                      label: widget.beforeLabel,
                      backgroundColor: Colors.black.withValues(alpha: 0.72),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _StageBadge(
                      label: widget.afterLabel,
                      backgroundColor: AppColors.primaryEmerald,
                    ),
                  ),

                  // Vertical Divider Line + Draggable Handle
                  Positioned(
                    left: (splitX - 22).clamp(0.0, width - 44),
                    top: 0,
                    bottom: 0,
                    width: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 3,
                          height: height,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        AnimatedScale(
                          scale: _isDragging ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 120),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primaryEmerald,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.swap_horiz_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LeftSplitClipper extends CustomClipper<Rect> {
  final double splitX;
  const _LeftSplitClipper({required this.splitX});

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, splitX, size.height);

  @override
  bool shouldReclip(covariant _LeftSplitClipper oldClipper) =>
      oldClipper.splitX != splitX;
}

class _StageBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const _StageBadge({
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ImpactNetworkImage extends StatelessWidget {
  final String url;
  final bool isAfter;

  const _ImpactNetworkImage({
    required this.url,
    required this.isAfter,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _FallbackImpactVisual(isAfter: isAfter);
    }

    return AppNetworkImage(
      url: url,
      fit: BoxFit.cover,
      placeholderBuilder: (context) {
        return Stack(
          fit: StackFit.expand,
          children: [
            _FallbackImpactVisual(isAfter: isAfter),
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        );
      },
      fallbackBuilder: (context) {
        return _FallbackImpactVisual(isAfter: isAfter);
      },
    );
  }
}

/// High-contrast vector fallback canvas when offline or in sandboxed environments.
class _FallbackImpactVisual extends StatelessWidget {
  final bool isAfter;

  const _FallbackImpactVisual({required this.isAfter});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isAfter
                  ? const [
                    Color(0xFF065F46),
                    Color(0xFF0D9488),
                    Color(0xFF10B981),
                  ]
                  : const [
                    Color(0xFF4B5563),
                    Color(0xFF6B7280),
                    Color(0xFF9CA3AF),
                  ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAfter
                  ? Icons.park_rounded
                  : Icons.landscape_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 12),
            Text(
              isAfter
                  ? 'Verified Post-Intervention Geo-Tagged Frame'
                  : 'Baseline Pre-Intervention Geo-Tagged Frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
