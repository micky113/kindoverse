import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../campaigns/domain/models/project.dart';

/// Domain model for `impact_stories/{storyId}` in Cloud Firestore.
class ImpactStory {
  final String id;
  final String projectId;
  final ImpactCategory sectorCategory;
  final String title;
  final String beforeImageUrl;
  final String afterImageUrl;
  final String metricKey;
  final num metricValue;
  final String? locationSummary;
  final DateTime publishedAt;

  const ImpactStory({
    required this.id,
    required this.projectId,
    required this.sectorCategory,
    required this.title,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    required this.metricKey,
    required this.metricValue,
    this.locationSummary,
    required this.publishedAt,
  });

  /// Human-readable deliverable label, e.g. "120 Trees Planted"
  String get formattedMetricDeliverable {
    final readableKey = metricKey
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
    return '$metricValue $readableKey';
  }

  factory ImpactStory.fromJson(Map<String, dynamic> json, {String? id}) {
    return ImpactStory(
      id: id ?? (json['id'] as String? ?? ''),
      projectId: json['projectId'] as String? ?? '',
      sectorCategory: ImpactCategory.fromString(
        json['sectorCategory'] as String?,
      ),
      title: json['title'] as String? ?? '',
      beforeImageUrl: json['beforeImageUrl'] as String? ?? '',
      afterImageUrl: json['afterImageUrl'] as String? ?? '',
      metricKey: json['metricKey'] as String? ?? 'beneficiaries_impacted',
      metricValue: json['metricValue'] as num? ?? 0,
      locationSummary: json['locationSummary'] as String?,
      publishedAt: _parseDateTime(json['publishedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'sectorCategory': sectorCategory.value,
      'title': title,
      'beforeImageUrl': beforeImageUrl,
      'afterImageUrl': afterImageUrl,
      'metricKey': metricKey,
      'metricValue': metricValue,
      'locationSummary': locationSummary,
      'publishedAt': Timestamp.fromDate(publishedAt),
    };
  }

  ImpactStory copyWith({
    String? id,
    String? projectId,
    ImpactCategory? sectorCategory,
    String? title,
    String? beforeImageUrl,
    String? afterImageUrl,
    String? metricKey,
    num? metricValue,
    String? locationSummary,
    DateTime? publishedAt,
  }) {
    return ImpactStory(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      sectorCategory: sectorCategory ?? this.sectorCategory,
      title: title ?? this.title,
      beforeImageUrl: beforeImageUrl ?? this.beforeImageUrl,
      afterImageUrl: afterImageUrl ?? this.afterImageUrl,
      metricKey: metricKey ?? this.metricKey,
      metricValue: metricValue ?? this.metricValue,
      locationSummary: locationSummary ?? this.locationSummary,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  static DateTime _parseDateTime(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    if (raw is DateTime) return raw;
    return DateTime.now();
  }
}
