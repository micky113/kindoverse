import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../campaigns/domain/models/project.dart';

/// Represents a media folder in the Gallery — either a standalone custom folder
/// stored in `gallery_folders/{folderId}` or a folder linked to a campaign (`projects/{projectId}`).
class GalleryFolder {
  final String id;
  final String name;
  final String description;
  final ImpactCategory category;
  final String locationLabel;
  final List<String> imageUrls;
  final String? linkedProjectId;
  final DateTime createdAt;

  const GalleryFolder({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    this.locationLabel = '',
    required this.imageUrls,
    this.linkedProjectId,
    required this.createdAt,
  });

  bool get isCampaignFolder =>
      linkedProjectId != null && linkedProjectId!.isNotEmpty;

  /// Builds a [GalleryFolder] view from an existing [Project] campaign.
  factory GalleryFolder.fromProject(Project project) {
    final urls = <String>[];
    if (project.coverImageUrl.trim().isNotEmpty) {
      urls.add(project.coverImageUrl.trim());
    }
    for (final g in project.galleryUrls) {
      final trimmed = g.trim();
      if (trimmed.isNotEmpty && !urls.contains(trimmed)) {
        urls.add(trimmed);
      }
    }

    return GalleryFolder(
      id: project.id,
      name: project.title,
      description: project.description,
      category: project.category,
      locationLabel: project.location.displayAddress,
      imageUrls: urls,
      linkedProjectId: project.id,
      createdAt: project.createdAt,
    );
  }

  factory GalleryFolder.fromJson(Map<String, dynamic> json, {String? id}) {
    final rawUrls =
        (json['imageUrls'] as List<dynamic>?)
            ?.map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];

    return GalleryFolder(
      id: id ?? (json['id'] as String? ?? ''),
      name: json['name'] as String? ?? 'Untitled Folder',
      description: json['description'] as String? ?? '',
      category: ImpactCategory.fromString(json['category'] as String?),
      locationLabel: json['locationLabel'] as String? ?? '',
      imageUrls: rawUrls,
      linkedProjectId: json['linkedProjectId'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.value,
      'locationLabel': locationLabel,
      'imageUrls': imageUrls,
      'linkedProjectId': linkedProjectId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseDateTime(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    if (raw is DateTime) return raw;
    return DateTime.now();
  }
}
