import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/app_user.dart';
import '../../features/campaigns/domain/models/project.dart';
import '../../features/campaigns/presentation/providers/campaign_providers.dart';
import '../responsive/responsive_layout.dart';
import '../theme/app_theme.dart';

/// Universal responsive navigation bar with official Kindoverse logo, dynamic RBAC role state,
/// Admin Studio link, campaign sector discovery dropdown, search input, and primary CTA.
class UniversalNavbar extends ConsumerWidget implements PreferredSizeWidget {
  const UniversalNavbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(92);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(activeUserProvider);
    final filter = ref.watch(campaignFilterProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isWideDesktop = screenWidth >= 1320;
    final isMobile = ResponsiveLayout.isMobile(context);
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      height: isMobile ? 74 : 92,
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : (isMobile ? 12 : 16),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Official Kindoverse Brand Logo (Responsive sizing for mobile & desktop)
            Flexible(
              flex: isMobile ? 1 : 0,
              child: InkWell(
                onTap: () => context.go('/'),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? 150 : 220,
                    ),
                    child: Image.asset(
                      'assets/images/kindoverse_logo.png',
                      height: isMobile ? 54 : 82,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: isMobile ? 8 : 18),

            if (!isMobile)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NavButton(
                        label: 'Campaigns',
                        icon: Icons.grid_view_rounded,
                        isActive: currentPath == '/',
                        onTap: () => context.go('/'),
                      ),
                      const SizedBox(width: 4),
                      _NavButton(
                        label: 'Gallery',
                        icon: Icons.folder_special_outlined,
                        isActive: currentPath.startsWith('/gallery'),
                        onTap: () => context.go('/gallery'),
                      ),
                      const SizedBox(width: 4),
                      _NavButton(
                        label: 'Impact Map',
                        icon: Icons.map_outlined,
                        isActive: currentPath.startsWith('/explore-map'),
                        onTap: () => context.go('/explore-map'),
                      ),
                      const SizedBox(width: 4),
                      _NavButton(
                        label: 'Field Audit',
                        icon: Icons.fact_check_outlined,
                        isActive: currentPath.startsWith(
                          '/verification-portal',
                        ),
                        onTap: () => context.go('/verification-portal'),
                      ),
                      const SizedBox(width: 4),
                      _NavButton(
                        label: 'Admin Studio',
                        icon: Icons.admin_panel_settings_outlined,
                        isActive: currentPath.startsWith('/admin'),
                        onTap: () => context.go('/admin'),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<ImpactCategory?>(
                        tooltip: 'Filter by Impact Sector',
                        onSelected: (cat) {
                          ref
                              .read(campaignFilterProvider.notifier)
                              .setCategory(cat);
                          if (currentPath != '/' &&
                              !currentPath.startsWith('/gallery') &&
                              !currentPath.startsWith('/explore-map')) {
                            context.go('/');
                          }
                        },
                        itemBuilder:
                            (ctx) => [
                              const PopupMenuItem<ImpactCategory?>(
                                value: null,
                                child: Text('All Impact Sectors'),
                              ),
                              const PopupMenuDivider(),
                              ...ImpactCategory.values.map(
                                (c) => PopupMenuItem<ImpactCategory?>(
                                  value: c,
                                  child: Text(c.label),
                                ),
                              ),
                            ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                filter.category?.label ?? 'Impact Sectors',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Spacer(),

            if (isWideDesktop) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 190,
                height: 38,
                child: TextField(
                  onChanged:
                      (val) => ref
                          .read(campaignFilterProvider.notifier)
                          .setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search village, state...',
                    hintStyle: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 17,
                      color: AppColors.textMuted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    filled: true,
                    fillColor: AppColors.surfaceSubtle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(width: isMobile ? 6 : 10),

            PopupMenuButton<UserRole>(
              tooltip: 'Select Donor / User Type',
              onSelected:
                  (role) =>
                      ref.read(activeUserProvider.notifier).switchRole(role),
              itemBuilder:
                  (ctx) =>
                      UserRole.values
                          .map(
                            (role) => CheckedPopupMenuItem<UserRole>(
                              value: role,
                              checked: user.role == role,
                              child: Text(role.label),
                            ),
                          )
                          .toList(),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 14,
                      color: AppColors.primaryEmerald,
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? 96 : 160,
                      ),
                      child: Text(
                        user.role.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: AppColors.primaryEmerald,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(width: isMobile ? 4 : 8),

            if (!isMobile)
              ElevatedButton.icon(
                onPressed: () => context.go('/admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentAmber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text('Create Campaign'),
              )
            else
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.textPrimary,
                ),
                onSelected: (route) => context.go(route),
                itemBuilder:
                    (ctx) => const [
                      PopupMenuItem(
                        value: '/',
                        child: ListTile(
                          leading: Icon(Icons.grid_view_rounded),
                          title: Text('Explore Campaigns'),
                          dense: true,
                        ),
                      ),
                      PopupMenuItem(
                        value: '/gallery',
                        child: ListTile(
                          leading: Icon(Icons.folder_special_outlined),
                          title: Text('Campaign Gallery (Folders)'),
                          dense: true,
                        ),
                      ),
                      PopupMenuItem(
                        value: '/explore-map',
                        child: ListTile(
                          leading: Icon(Icons.map_outlined),
                          title: Text('Impact Map'),
                          dense: true,
                        ),
                      ),
                      PopupMenuItem(
                        value: '/verification-portal',
                        child: ListTile(
                          leading: Icon(Icons.fact_check_outlined),
                          title: Text('Field & Tranche Audit'),
                          dense: true,
                        ),
                      ),
                      PopupMenuItem(
                        value: '/admin',
                        child: ListTile(
                          leading: Icon(Icons.admin_panel_settings_outlined),
                          title: Text('Admin Studio (Create Campaign)'),
                          dense: true,
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

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor:
            isActive ? AppColors.primaryEmerald : AppColors.textSecondary,
        backgroundColor:
            isActive ? AppColors.primarySurface : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
