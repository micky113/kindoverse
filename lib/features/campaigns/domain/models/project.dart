import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

/// Target impact sectors supported by Kindoverse.
enum ImpactCategory {
  education('education', 'Individual Education & Higher Studies'),
  villageAdoption('village_adoption', 'Village Adoption'),
  plantation('plantation', 'Tree Plantation & Reforestation'),
  agriculture('agriculture', 'Agriculture & Allied Activities'),
  healthWaterSanitation(
    'health_water_sanitation',
    'Health, Clean Water & Sanitation',
  ),
  communalWelfare('communal_welfare', 'Communal Welfare');

  final String value;
  final String label;
  const ImpactCategory(this.value, this.label);

  static ImpactCategory fromString(String? raw) {
    return ImpactCategory.values.firstWhere(
      (c) => c.value == raw,
      orElse: () => ImpactCategory.communalWelfare,
    );
  }
}

/// Primary funding channels on the platform.
enum FundingType {
  crowdfunding('crowdfunding', 'Crowd Funding'),
  sponsorship('sponsorship', 'Corporate / CSR Sponsorship'),
  individualDonation('individual_donation', 'Individual Donation');

  final String value;
  final String label;
  const FundingType(this.value, this.label);

  static FundingType fromString(String? raw) {
    return FundingType.values.firstWhere(
      (f) => f.value == raw,
      orElse: () => FundingType.crowdfunding,
    );
  }
}

/// Lifecycle state of an impact project.
enum ProjectStatus {
  draft('draft', 'Draft'),
  verified('verified', 'Verified'),
  active('active', 'Active'),
  funded('funded', 'Funded'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed');

  final String value;
  final String label;
  const ProjectStatus(this.value, this.label);

  static ProjectStatus fromString(String? raw) {
    return ProjectStatus.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => ProjectStatus.active,
    );
  }
}

/// Structured geographic location with Geohash support for viewport queries.
class ProjectLocation {
  final double lat;
  final double lng;
  final String village;
  final String district;
  final String state;
  final String geohash;

  const ProjectLocation({
    required this.lat,
    required this.lng,
    required this.village,
    required this.district,
    required this.state,
    required this.geohash,
  });

  factory ProjectLocation.fromCoordinates({
    required double lat,
    required double lng,
    required String village,
    required String district,
    required String state,
  }) {
    final geoFirePoint = GeoFirePoint(GeoPoint(lat, lng));
    return ProjectLocation(
      lat: lat,
      lng: lng,
      village: village,
      district: district,
      state: state,
      geohash: geoFirePoint.geohash,
    );
  }

  factory ProjectLocation.fromJson(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble() ?? 20.5937;
    final lng = (json['lng'] as num?)?.toDouble() ?? 78.9629;
    final geoData = json['geo'] as Map<String, dynamic>?;
    final existingGeohash =
        (geoData?['geohash'] as String?) ?? (json['geohash'] as String?);
    final computedGeohash =
        existingGeohash ?? GeoFirePoint(GeoPoint(lat, lng)).geohash;

    return ProjectLocation(
      lat: lat,
      lng: lng,
      village: json['village'] as String? ?? '',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? '',
      geohash: computedGeohash,
    );
  }

  Map<String, dynamic> toJson() {
    final geoFirePoint = GeoFirePoint(GeoPoint(lat, lng));
    return {
      'lat': lat,
      'lng': lng,
      'village': village,
      'district': district,
      'state': state,
      'geohash': geohash,
      // Compatible with geoflutterfire_plus GeoCollectionReference queries
      'geo': geoFirePoint.data,
    };
  }

  ProjectLocation copyWith({
    double? lat,
    double? lng,
    String? village,
    String? district,
    String? state,
    String? geohash,
  }) {
    final nextLat = lat ?? this.lat;
    final nextLng = lng ?? this.lng;
    return ProjectLocation(
      lat: nextLat,
      lng: nextLng,
      village: village ?? this.village,
      district: district ?? this.district,
      state: state ?? this.state,
      geohash: geohash ?? GeoFirePoint(GeoPoint(nextLat, nextLng)).geohash,
    );
  }

  String get displayAddress =>
      [village, district, state].where((s) => s.isNotEmpty).join(', ');
}

/// Domain model for `projects/{projectId}` in Cloud Firestore.
class Project {
  final String id;
  final String title;
  final String description;
  final ImpactCategory category;
  final FundingType fundingType;
  final num targetAmount;
  final num raisedAmount;
  final num disbursedAmount;
  final String currency;
  final ProjectLocation location;
  final ProjectStatus status;
  final String coverImageUrl;
  final String? thumbnailUrl;
  final List<String> galleryUrls;
  final int beneficiariesCount;
  final String organizerName;
  final bool organizerVerified;
  final DateTime createdAt;
  final DateTime deadline;

  const Project({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.fundingType,
    required this.targetAmount,
    required this.raisedAmount,
    this.disbursedAmount = 0,
    this.currency = 'INR',
    required this.location,
    required this.status,
    required this.coverImageUrl,
    this.thumbnailUrl,
    required this.galleryUrls,
    required this.beneficiariesCount,
    this.organizerName = 'Kindoverse Verified Partner',
    this.organizerVerified = true,
    required this.createdAt,
    required this.deadline,
  });

  double get fundingProgress {
    if (targetAmount <= 0) return 0;
    return (raisedAmount / targetAmount).clamp(0.0, 1.0);
  }

  int get daysLeft {
    final diff = deadline.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory Project.fromJson(Map<String, dynamic> json, {String? id}) {
    final locMap =
        (json['location'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return Project(
      id: id ?? (json['id'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: ImpactCategory.fromString(json['category'] as String?),
      fundingType: FundingType.fromString(json['fundingType'] as String?),
      targetAmount: json['targetAmount'] as num? ?? 0,
      raisedAmount: json['raisedAmount'] as num? ?? 0,
      disbursedAmount: json['disbursedAmount'] as num? ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      location: ProjectLocation.fromJson(locMap),
      status: ProjectStatus.fromString(json['status'] as String?),
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      galleryUrls:
          (json['galleryUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      beneficiariesCount: (json['beneficiariesCount'] as num?)?.toInt() ?? 0,
      organizerName:
          json['organizerName'] as String? ?? 'Kindoverse Verified Partner',
      organizerVerified: json['organizerVerified'] as bool? ?? true,
      createdAt: _parseDateTime(json['createdAt']),
      deadline: _parseDateTime(json['deadline']),
    );
  }

  Map<String, dynamic> toJson() {
    final locJson = location.toJson();
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.value,
      'fundingType': fundingType.value,
      'targetAmount': targetAmount,
      'raisedAmount': raisedAmount,
      'disbursedAmount': disbursedAmount,
      'currency': currency,
      'location': locJson,
      // Top-level geo object for geoflutterfire_plus bounding-box / radius queries
      'geo': locJson['geo'],
      'status': status.value,
      'coverImageUrl': coverImageUrl,
      'thumbnailUrl': thumbnailUrl,
      'galleryUrls': galleryUrls,
      'beneficiariesCount': beneficiariesCount,
      'organizerName': organizerName,
      'organizerVerified': organizerVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'deadline': Timestamp.fromDate(deadline),
    };
  }

  Project copyWith({
    String? id,
    String? title,
    String? description,
    ImpactCategory? category,
    FundingType? fundingType,
    num? targetAmount,
    num? raisedAmount,
    num? disbursedAmount,
    String? currency,
    ProjectLocation? location,
    ProjectStatus? status,
    String? coverImageUrl,
    String? thumbnailUrl,
    List<String>? galleryUrls,
    int? beneficiariesCount,
    String? organizerName,
    bool? organizerVerified,
    DateTime? createdAt,
    DateTime? deadline,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      fundingType: fundingType ?? this.fundingType,
      targetAmount: targetAmount ?? this.targetAmount,
      raisedAmount: raisedAmount ?? this.raisedAmount,
      disbursedAmount: disbursedAmount ?? this.disbursedAmount,
      currency: currency ?? this.currency,
      location: location ?? this.location,
      status: status ?? this.status,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      beneficiariesCount: beneficiariesCount ?? this.beneficiariesCount,
      organizerName: organizerName ?? this.organizerName,
      organizerVerified: organizerVerified ?? this.organizerVerified,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
    );
  }

  static DateTime _parseDateTime(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    if (raw is DateTime) return raw;
    return DateTime.now();
  }
}
