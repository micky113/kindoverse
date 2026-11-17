import 'package:cloud_firestore/cloud_firestore.dart';

enum MilestoneStatus {
  pending('pending', 'Pending Verification'),
  completed('completed', 'Verified & Completed');

  final String value;
  final String label;
  const MilestoneStatus(this.value, this.label);

  static MilestoneStatus fromString(String? raw) {
    return MilestoneStatus.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => MilestoneStatus.pending,
    );
  }
}

/// Domain model for `projects/{projectId}/milestones/{milestoneId}`.
class Milestone {
  final String id;
  final String projectId;
  final String title;
  final num targetBudget;
  final MilestoneStatus status;
  final List<String> proofBeforeUrls;
  final List<String> proofAfterUrls;
  final String remarks;
  final double? gpsLat;
  final double? gpsLng;
  final String? receiptUrl;
  final DateTime? completedAt;

  const Milestone({
    required this.id,
    required this.projectId,
    required this.title,
    required this.targetBudget,
    required this.status,
    required this.proofBeforeUrls,
    required this.proofAfterUrls,
    required this.remarks,
    this.gpsLat,
    this.gpsLng,
    this.receiptUrl,
    this.completedAt,
  });

  factory Milestone.fromJson(
    Map<String, dynamic> json, {
    String? id,
    String? projectId,
  }) {
    return Milestone(
      id: id ?? (json['id'] as String? ?? ''),
      projectId: projectId ?? (json['projectId'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      targetBudget: json['targetBudget'] as num? ?? 0,
      status: MilestoneStatus.fromString(json['status'] as String?),
      proofBeforeUrls:
          (json['proofBeforeUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      proofAfterUrls:
          (json['proofAfterUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      remarks: json['remarks'] as String? ?? '',
      gpsLat: (json['gpsLat'] as num?)?.toDouble(),
      gpsLng: (json['gpsLng'] as num?)?.toDouble(),
      receiptUrl: json['receiptUrl'] as String?,
      completedAt: _parseNullableDateTime(json['completedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'targetBudget': targetBudget,
      'status': status.value,
      'proofBeforeUrls': proofBeforeUrls,
      'proofAfterUrls': proofAfterUrls,
      'remarks': remarks,
      'gpsLat': gpsLat,
      'gpsLng': gpsLng,
      'receiptUrl': receiptUrl,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  Milestone copyWith({
    String? id,
    String? projectId,
    String? title,
    num? targetBudget,
    MilestoneStatus? status,
    List<String>? proofBeforeUrls,
    List<String>? proofAfterUrls,
    String? remarks,
    double? gpsLat,
    double? gpsLng,
    String? receiptUrl,
    DateTime? completedAt,
  }) {
    return Milestone(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      targetBudget: targetBudget ?? this.targetBudget,
      status: status ?? this.status,
      proofBeforeUrls: proofBeforeUrls ?? this.proofBeforeUrls,
      proofAfterUrls: proofAfterUrls ?? this.proofAfterUrls,
      remarks: remarks ?? this.remarks,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLng: gpsLng ?? this.gpsLng,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static DateTime? _parseNullableDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is DateTime) return raw;
    return null;
  }
}
