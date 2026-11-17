import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_footer.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/universal_navbar.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../../campaigns/domain/models/project.dart';
import '../../../campaigns/presentation/providers/campaign_providers.dart';
import '../../../campaigns/presentation/widgets/campaign_card.dart';
import '../../domain/models/gallery_folder.dart';

/// Dedicated Campaign Media Gallery page organizing photos into browsable
/// folders (both custom-created folders and campaign folders) with a
/// "New Folder" creator, multi-image uploader, folder dropdown switcher,
/// and full-screen lightbox viewer.
class CampaignGalleryPage extends ConsumerStatefulWidget {
  final String? initialFolderProjectId;

  const CampaignGalleryPage({super.key, this.initialFolderProjectId});

  @override
  ConsumerState<CampaignGalleryPage> createState() =>
      _CampaignGalleryPageState();
}

class _CampaignGalleryPageState extends ConsumerState<CampaignGalleryPage> {
  String? _selectedFolderId;
  String _searchQuery = '';
  bool _showAllPhotosFlat = false;

  @override
  void initState() {
    super.initState();
    _selectedFolderId = widget.initialFolderProjectId;
  }

  @override
  void didUpdateWidget(covariant CampaignGalleryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFolderProjectId != oldWidget.initialFolderProjectId) {
      setState(() {
        _selectedFolderId = widget.initialFolderProjectId;
      });
    }
  }

  Future<void> _showCreateFolderDialog(BuildContext context) async {
    final createdFolder = await showDialog<GalleryFolder>(
      context: context,
      builder: (ctx) => const _CreateGalleryFolderDialog(),
    );

    if (createdFolder != null && mounted) {
      setState(() {
        _selectedFolderId = createdFolder.id;
        _showAllPhotosFlat = false;
      });
    }
  }

  Future<void> _showAddPhotosToFolderDialog(
    BuildContext context,
    List<GalleryFolder> folders, {
    GalleryFolder? preselectedFolder,
  }) async {
    if (folders.isEmpty) {
      await _showCreateFolderDialog(context);
      return;
    }

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => _AddPhotosToFolderDialog(
            folders: folders,
            initialFolder: preselectedFolder ?? folders.first,
          ),
    );
  }

  void _openLightbox(
    BuildContext context, {
    required GalleryFolder folder,
    required int initialIndex,
  }) {
    if (folder.imageUrls.isEmpty) return;
    showDialog<void>(
      context: context,
      builder:
          (ctx) => _GalleryLightboxDialog(
            folder: folder,
            initialIndex: initialIndex,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaignsAsync = ref.watch(filteredCampaignsProvider);
    final customFoldersAsync = ref.watch(customGalleryFoldersProvider);
    final filter = ref.watch(campaignFilterProvider);
    final activeUser = ref.watch(activeUserProvider);
    final canManagePhotos =
        activeUser.role == UserRole.admin ||
        activeUser.role == UserRole.partnerNgo;
    final isMobile = ResponsiveLayout.isMobile(context);

    final projects = campaignsAsync.valueOrNull ?? const <Project>[];
    final customFoldersRaw =
        customFoldersAsync.valueOrNull ?? const <GalleryFolder>[];

    // Apply impact sector filter if active on custom folders too
    final customFolders =
        filter.category == null
            ? customFoldersRaw
            : customFoldersRaw
                .where((f) => f.category == filter.category)
                .toList();

    final allFolders = <GalleryFolder>[
      ...customFolders,
      ...projects.map(GalleryFolder.fromProject),
    ];

    final isLoading =
        campaignsAsync.isLoading &&
        customFoldersAsync.isLoading &&
        allFolders.isEmpty;

    final selectedFolder =
        _selectedFolderId == null
            ? null
            : allFolders.where((f) => f.id == _selectedFolderId).firstOrNull;

    final totalPhotosCount = allFolders.fold<int>(
      0,
      (sum, f) => sum + f.imageUrls.length,
    );

    return Scaffold(
      appBar: const UniversalNavbar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Banner & Folder Switcher Bar
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: isMobile ? 20 : 28),
              child: ResponsiveConstrainedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 14,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.folder_special_rounded,
                                color: AppColors.primaryEmerald,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Campaign Media Gallery',
                                    style: TextStyle(
                                      fontSize: isMobile ? 20 : 26,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${allFolders.length} Folders • $totalPhotosCount Verified Photos',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Folder Dropdown Selector
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.borderSubtle,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: selectedFolder?.id,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.primaryEmerald,
                                  ),
                                  hint: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.folder_open_rounded,
                                        size: 18,
                                        color: AppColors.primaryEmerald,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'All Folders',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.folder_copy_outlined,
                                            size: 17,
                                            color: AppColors.primaryEmerald,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'All Folders',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...allFolders.map((f) {
                                      final count = f.imageUrls.length;
                                      final shortTitle =
                                          f.name.length > 34
                                              ? '${f.name.substring(0, 34)}...'
                                              : f.name;
                                      return DropdownMenuItem<String?>(
                                        value: f.id,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              f.isCampaignFolder
                                                  ? Icons.folder_rounded
                                                  : Icons.folder_special_rounded,
                                              size: 17,
                                              color:
                                                  f.isCampaignFolder
                                                      ? AppColors.accentAmber
                                                      : AppColors.primaryEmerald,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '$shortTitle ($count)',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (folderId) {
                                    setState(() {
                                      _selectedFolderId = folderId;
                                      if (folderId != null) {
                                        _showAllPhotosFlat = false;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),

                            // New Folder Button
                            OutlinedButton.icon(
                              onPressed: () => _showCreateFolderDialog(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(
                                Icons.create_new_folder_outlined,
                                size: 18,
                              ),
                              label: const Text('New Folder'),
                            ),

                            // Add Photos to Folder Button
                            ElevatedButton.icon(
                              onPressed:
                                  () => _showAddPhotosToFolderDialog(
                                    context,
                                    allFolders,
                                    preselectedFolder: selectedFolder,
                                  ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryEmerald,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 18,
                              ),
                              label: const Text('Add Images to Folder'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search & View Mode Bar
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: isMobile ? double.infinity : 340,
                          height: 42,
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText:
                                  'Search folders by name, sector, or location...',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceSubtle,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        if (selectedFolder == null)
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: false,
                                icon: Icon(Icons.folder_rounded, size: 17),
                                label: Text('Folders'),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                icon: Icon(Icons.grid_on_rounded, size: 17),
                                label: Text('All Photos'),
                              ),
                            ],
                            selected: {_showAllPhotosFlat},
                            onSelectionChanged: (selection) {
                              setState(() {
                                _showAllPhotosFlat = selection.first;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Main Gallery Body
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: ResponsiveConstrainedBox(
                child:
                    isLoading
                        ? const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator()),
                        )
                        : Builder(
                          builder: (context) {
                            final query = _searchQuery.trim().toLowerCase();
                            final filteredFolders =
                                query.isEmpty
                                    ? allFolders
                                    : allFolders.where((f) {
                                      return f.name.toLowerCase().contains(
                                            query,
                                          ) ||
                                          f.locationLabel
                                              .toLowerCase()
                                              .contains(query) ||
                                          f.category.label
                                              .toLowerCase()
                                              .contains(query) ||
                                          f.description.toLowerCase().contains(
                                            query,
                                          );
                                    }).toList();

                            if (allFolders.isEmpty) {
                              return _buildEmptyGalleryState(context);
                            }

                            // 1. Inside a Specific Folder View
                            if (selectedFolder != null) {
                              return _buildOpenedFolderView(
                                context,
                                folder: selectedFolder,
                                allFolders: allFolders,
                                canManagePhotos: canManagePhotos,
                              );
                            }

                            // 2. All Photos Flat Stream View
                            if (_showAllPhotosFlat) {
                              return _buildAllPhotosFlatGrid(
                                context,
                                folders: filteredFolders,
                              );
                            }

                            // 3. Default Folders Grid View
                            return _buildFoldersGrid(
                              context,
                              folders: filteredFolders,
                            );
                          },
                        ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGalleryState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.create_new_folder_outlined,
            size: 56,
            color: AppColors.primaryEmerald,
          ),
          const SizedBox(height: 14),
          const Text(
            'No Gallery Folders Created Yet',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new folder and upload campaign images, or launch a campaign in the Admin Studio.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showCreateFolderDialog(context),
                icon: const Icon(Icons.create_new_folder_rounded),
                label: const Text('Create New Folder & Add Images'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/admin'),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Open Admin Studio'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersGrid(
    BuildContext context, {
    required List<GalleryFolder> folders,
  }) {
    if (folders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No folders match your search.',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount =
        width >= 1100
            ? 3
            : width >= 700
            ? 2
            : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: folders.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 325,
      ),
      itemBuilder: (context, index) {
        final folder = folders[index];
        return _GalleryFolderCard(
          folder: folder,
          onOpenFolder: () {
            setState(() {
              _selectedFolderId = folder.id;
            });
          },
        );
      },
    );
  }

  Widget _buildOpenedFolderView(
    BuildContext context, {
    required GalleryFolder folder,
    required List<GalleryFolder> allFolders,
    required bool canManagePhotos,
  }) {
    final photos = folder.imageUrls;
    final categoryColor = CampaignCard.colorForCategory(folder.category);
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount =
        width >= 1100
            ? 4
            : width >= 760
            ? 3
            : width >= 480
            ? 2
            : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Breadcrumb & Folder Action Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedFolderId = null),
                    icon: const Icon(Icons.arrow_back_rounded, size: 17),
                    label: const Text('All Folders'),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.folder_open_rounded,
                          size: 16,
                          color: AppColors.primaryEmerald,
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Text(
                            folder.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              folder.category.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${photos.length} ${photos.length == 1 ? "Photo" : "Photos"} in Folder',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        folder.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (folder.locationLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              folder.locationLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (folder.description.isNotEmpty &&
                          !folder.isCampaignFolder) ...[
                        const SizedBox(height: 4),
                        Text(
                          folder.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (folder.isCampaignFolder)
                        OutlinedButton.icon(
                          onPressed:
                              () => context.go(
                                '/project/${folder.linkedProjectId}',
                              ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('View Campaign Page'),
                        )
                      else if (canManagePhotos)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.errorRed,
                          ),
                          onPressed: () async {
                            await ref
                                .read(campaignRepositoryProvider)
                                .deleteCustomGalleryFolder(folder.id);
                            if (mounted) {
                              setState(() => _selectedFolderId = null);
                            }
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                          ),
                          label: const Text('Delete Folder'),
                        ),
                      ElevatedButton.icon(
                        onPressed:
                            () => _showAddPhotosToFolderDialog(
                              context,
                              allFolders,
                              preselectedFolder: folder,
                            ),
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 17,
                        ),
                        label: const Text('Add Images to This Folder'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (photos.isEmpty)
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                const Text(
                  'This folder has no images yet.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Click "Add Images to This Folder" to upload photos from your device or paste an image URL.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed:
                      () => _showAddPhotosToFolderDialog(
                        context,
                        allFolders,
                        preselectedFolder: folder,
                      ),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Add Images Now'),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: photos.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) {
              final imageUrl = photos[index];
              final isCover = folder.isCampaignFolder && index == 0;

              return Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
                child: InkWell(
                  onTap:
                      () => _openLightbox(
                        context,
                        folder: folder,
                        initialIndex: index,
                      ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(url: imageUrl, fit: BoxFit.cover),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isCover
                                    ? AppColors.primaryEmerald
                                    : Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isCover ? 'Cover Image' : 'Photo #${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      if (canManagePhotos && !isCover)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.65,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            tooltip: 'Remove photo from folder',
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              if (folder.isCampaignFolder) {
                                await ref
                                    .read(campaignRepositoryProvider)
                                    .removePhotoFromCampaignGallery(
                                      projectId: folder.linkedProjectId!,
                                      imageUrl: imageUrl,
                                    );
                              } else {
                                await ref
                                    .read(campaignRepositoryProvider)
                                    .removePhotoFromCustomFolder(
                                      folderId: folder.id,
                                      imageUrl: imageUrl,
                                    );
                              }
                            },
                          ),
                        ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.zoom_out_map_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAllPhotosFlatGrid(
    BuildContext context, {
    required List<GalleryFolder> folders,
  }) {
    final items = <({GalleryFolder folder, String url, int indexInFolder})>[];
    for (final f in folders) {
      for (var i = 0; i < f.imageUrls.length; i++) {
        items.add((folder: f, url: f.imageUrls[i], indexInFolder: i));
      }
    }

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No photos found across folders.')),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount =
        width >= 1100
            ? 4
            : width >= 760
            ? 3
            : width >= 480
            ? 2
            : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, idx) {
        final item = items[idx];

        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.borderSubtle),
          ),
          child: InkWell(
            onTap:
                () => _openLightbox(
                  context,
                  folder: item.folder,
                  initialIndex: item.indexInFolder,
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: AppNetworkImage(url: item.url, fit: BoxFit.cover),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  color: AppColors.surfaceWhite,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        size: 15,
                        color: AppColors.primaryEmerald,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedFolderId = item.folder.id;
                              _showAllPhotosFlat = false;
                            });
                          },
                          child: Text(
                            item.folder.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Visual Folder Card representing a GalleryFolder (campaign folder or custom folder).
class _GalleryFolderCard extends StatelessWidget {
  final GalleryFolder folder;
  final VoidCallback onOpenFolder;

  const _GalleryFolderCard({
    required this.folder,
    required this.onOpenFolder,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = CampaignCard.colorForCategory(folder.category);
    final photos = folder.imageUrls;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        onTap: onOpenFolder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Folder Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface.withValues(alpha: 0.65),
                border: const Border(
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    folder.isCampaignFolder
                        ? Icons.folder_rounded
                        : Icons.folder_special_rounded,
                    color:
                        folder.isCampaignFolder
                            ? AppColors.accentAmber
                            : AppColors.primaryEmerald,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      folder.category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: categoryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryEmerald,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${photos.length} ${photos.length == 1 ? "Photo" : "Photos"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Collage Thumbnail Preview inside Folder
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildCollagePreview(photos),
                ),
              ),
            ),

            // Folder Title, Location & Open Action
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          folder.locationLabel.isEmpty
                              ? (folder.isCampaignFolder
                                  ? 'Verified Campaign Folder'
                                  : 'Custom Media Folder')
                              : folder.locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Text(
                        'Open Folder →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
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

  Widget _buildCollagePreview(List<String> photos) {
    if (photos.isEmpty) {
      return Container(
        color: AppColors.surfaceSubtle,
        child: const Center(
          child: Icon(
            Icons.photo_library_outlined,
            size: 42,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    if (photos.length == 1) {
      return AppNetworkImage(url: photos.first, fit: BoxFit.cover);
    }

    if (photos.length == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: AppNetworkImage(url: photos[0], fit: BoxFit.cover)),
          const SizedBox(width: 4),
          Expanded(child: AppNetworkImage(url: photos[1], fit: BoxFit.cover)),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: AppNetworkImage(url: photos[0], fit: BoxFit.cover),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AppNetworkImage(url: photos[1], fit: BoxFit.cover),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(url: photos[2], fit: BoxFit.cover),
                    if (photos.length > 3)
                      Container(
                        color: Colors.black.withValues(alpha: 0.55),
                        alignment: Alignment.center,
                        child: Text(
                          '+${photos.length - 3}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Modal dialog to create a brand-new Gallery Folder and immediately upload/add images to it.
class _CreateGalleryFolderDialog extends ConsumerStatefulWidget {
  const _CreateGalleryFolderDialog();

  @override
  ConsumerState<_CreateGalleryFolderDialog> createState() =>
      _CreateGalleryFolderDialogState();
}

class _CreateGalleryFolderDialogState
    extends ConsumerState<_CreateGalleryFolderDialog> {
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  ImpactCategory _category = ImpactCategory.education;
  final List<String> _stagedImageUrls = [];
  bool _isUploadingPhoto = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndStagePhoto() async {
    setState(() => _isUploadingPhoto = true);
    try {
      final url = await ref
          .read(impactStorageServiceProvider)
          .pickAndUploadImage(
            folderPath: 'projects/gallery_folders',
            customMetadata: {'category': _category.value},
          );
      if (url != null && mounted) {
        setState(() => _stagedImageUrls.add(url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorRed,
            content: Text('Upload error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _addStagedUrl() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      if (!_stagedImageUrls.contains(url)) {
        _stagedImageUrls.add(url);
      }
      _urlCtrl.clear();
    });
  }

  Future<void> _handleCreateFolder() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Please enter a folder name.'),
        ),
      );
      return;
    }

    // If user typed a URL in the input box without clicking '+', include it
    final pendingUrl = _urlCtrl.text.trim();
    if (pendingUrl.isNotEmpty && !_stagedImageUrls.contains(pendingUrl)) {
      _stagedImageUrls.add(pendingUrl);
    }

    setState(() => _isCreating = true);
    try {
      final now = DateTime.now();
      final slug = name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      final folderId =
          'folder-${slug.isEmpty ? "media" : slug.substring(0, slug.length > 20 ? 20 : slug.length)}-${now.millisecondsSinceEpoch.toString().substring(8)}';

      final folder = GalleryFolder(
        id: folderId,
        name: name,
        description: _descCtrl.text.trim(),
        category: _category,
        locationLabel: _locationCtrl.text.trim(),
        imageUrls: List<String>.from(_stagedImageUrls),
        createdAt: now,
      );

      await ref
          .read(campaignRepositoryProvider)
          .createCustomGalleryFolder(folder);

      if (!mounted) return;
      Navigator.of(context).pop(folder);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryEmerald,
          content: Text(
            'Folder "${folder.name}" created with ${folder.imageUrls.length} ${folder.imageUrls.length == 1 ? "image" : "images"}!',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorRed,
            content: Text('Failed to create folder: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.create_new_folder_rounded,
                      color: AppColors.primaryEmerald,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Create New Campaign Folder',
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Folder / Campaign Name *',
                  hintText: 'e.g., Koraput Solar Water Drive 2026',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ImpactCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Impact Sector',
                  prefixIcon: Icon(Icons.category_outlined),
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
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location (Optional)',
                  hintText: 'e.g., Koraput, Odisha',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Short Description (Optional)',
                  hintText: 'Field visit photos and milestone deliverables...',
                ),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 14),
              const Text(
                'Add Images to Folder',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _isUploadingPhoto ? null : _pickAndStagePhoto,
                icon:
                    _isUploadingPhoto
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.upload_file_rounded),
                label: Text(
                  _isUploadingPhoto
                      ? 'Uploading Image...'
                      : 'Upload Image from Device',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlCtrl,
                      onSubmitted: (_) => _addStagedUrl(),
                      decoration: const InputDecoration(
                        labelText: 'Or Paste Direct Image URL (https://...)',
                        prefixIcon: Icon(Icons.link_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Add Image URL',
                    onPressed: _addStagedUrl,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              if (_stagedImageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Staged Images (${_stagedImageUrls.length}):',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryEmerald,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _stagedImageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final url = _stagedImageUrls[i];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 96,
                              height: 76,
                              child: AppNetworkImage(
                                url: url,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: InkWell(
                              onTap:
                                  () => setState(
                                    () => _stagedImageUrls.removeAt(i),
                                  ),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed:
                    (_isCreating || _isUploadingPhoto)
                        ? null
                        : _handleCreateFolder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryEmerald,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon:
                    _isCreating
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  _isCreating
                      ? 'Creating Folder...'
                      : 'Create Folder (${_stagedImageUrls.length} ${_stagedImageUrls.length == 1 ? "Image" : "Images"})',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for uploading or adding photos directly into an existing Folder.
class _AddPhotosToFolderDialog extends ConsumerStatefulWidget {
  final List<GalleryFolder> folders;
  final GalleryFolder initialFolder;

  const _AddPhotosToFolderDialog({
    required this.folders,
    required this.initialFolder,
  });

  @override
  ConsumerState<_AddPhotosToFolderDialog> createState() =>
      _AddPhotosToFolderDialogState();
}

class _AddPhotosToFolderDialogState
    extends ConsumerState<_AddPhotosToFolderDialog> {
  late String _selectedFolderId;
  final _urlController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _selectedFolderId = widget.initialFolder.id;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  GalleryFolder get _currentFolder => widget.folders.firstWhere(
    (f) => f.id == _selectedFolderId,
    orElse: () => widget.initialFolder,
  );

  Future<void> _savePhotoToSelectedFolder(String imageUrl) async {
    final folder = _currentFolder;
    if (folder.isCampaignFolder) {
      await ref
          .read(campaignRepositoryProvider)
          .addPhotoToCampaignGallery(
            projectId: folder.linkedProjectId!,
            imageUrl: imageUrl,
          );
    } else {
      await ref
          .read(campaignRepositoryProvider)
          .addPhotosToCustomFolder(
            folderId: folder.id,
            imageUrls: [imageUrl],
          );
    }
  }

  Future<void> _pickAndUploadFile() async {
    setState(() => _isUploading = true);
    try {
      final uploadedUrl = await ref
          .read(impactStorageServiceProvider)
          .pickAndUploadImage(
            folderPath: 'projects/$_selectedFolderId/gallery',
            customMetadata: {'folderId': _selectedFolderId},
          );
      if (uploadedUrl != null && mounted) {
        await _savePhotoToSelectedFolder(uploadedUrl);
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryEmerald,
            content: Text('Image uploaded to "${_currentFolder.name}"!'),
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
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveImageUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      await _savePhotoToSelectedFolder(url);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryEmerald,
          content: Text('Image added to "${_currentFolder.name}"!'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.primaryEmerald,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Add Images to Folder',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedFolderId,
                decoration: const InputDecoration(
                  labelText: 'Select Target Folder',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
                items:
                    widget.folders.map((f) {
                      final shortTitle =
                          f.name.length > 36
                              ? '${f.name.substring(0, 36)}...'
                              : f.name;
                      return DropdownMenuItem<String>(
                        value: f.id,
                        child: Text(shortTitle),
                      );
                    }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedFolderId = val);
                  }
                },
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryEmerald,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon:
                    _isUploading
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
                  _isUploading
                      ? 'Uploading to Firebase Storage...'
                      : 'Choose Image File from Device',
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'OR PASTE IMAGE URL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Direct Image URL (https://...)',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _isUploading ? null : _saveImageUrl,
                icon: const Icon(Icons.add_link_rounded),
                label: const Text('Save Image URL to Folder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive Lightbox modal for cycling through photos in a folder.
class _GalleryLightboxDialog extends StatefulWidget {
  final GalleryFolder folder;
  final int initialIndex;

  const _GalleryLightboxDialog({
    required this.folder,
    required this.initialIndex,
  });

  @override
  State<_GalleryLightboxDialog> createState() => _GalleryLightboxDialogState();
}

class _GalleryLightboxDialogState extends State<_GalleryLightboxDialog> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _prev() {
    setState(() {
      _currentIndex =
          (_currentIndex - 1 + widget.folder.imageUrls.length) %
          widget.folder.imageUrls.length;
    });
  }

  void _next() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.folder.imageUrls.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.folder.imageUrls;
    final currentUrl = photos[_currentIndex];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1020, maxHeight: 780),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                color: AppColors.surfaceWhite,
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder_open_rounded,
                      color: AppColors.primaryEmerald,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.folder.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Photo ${_currentIndex + 1} of ${photos.length}${widget.folder.locationLabel.isNotEmpty ? " • ${widget.folder.locationLabel}" : ""}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Image Viewer Area
              Expanded(
                child: Container(
                  color: Colors.black87,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: AppNetworkImage(
                          url: currentUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                      if (photos.length > 1) ...[
                        Positioned(
                          left: 14,
                          child: IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            onPressed: _prev,
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          child: IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            onPressed: _next,
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
