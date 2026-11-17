import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

import '../../../donations/domain/models/donation.dart';
import '../../../gallery/domain/models/gallery_folder.dart';
import '../../../impact_engine/domain/models/impact_story.dart';
import '../../domain/models/milestone.dart';
import '../../domain/models/project.dart';

/// Filter criteria for discovering campaigns on grid and map views.
class CampaignFilter {
  final ImpactCategory? category;
  final FundingType? fundingType;
  final ProjectStatus? status;
  final String? stateRegion;
  final String searchQuery;

  const CampaignFilter({
    this.category,
    this.fundingType,
    this.status,
    this.stateRegion,
    this.searchQuery = '',
  });

  bool get hasActiveFilters =>
      category != null ||
      fundingType != null ||
      status != null ||
      (stateRegion != null && stateRegion!.isNotEmpty) ||
      searchQuery.trim().isNotEmpty;

  CampaignFilter copyWith({
    ImpactCategory? category,
    bool clearCategory = false,
    FundingType? fundingType,
    bool clearFundingType = false,
    ProjectStatus? status,
    bool clearStatus = false,
    String? stateRegion,
    bool clearStateRegion = false,
    String? searchQuery,
  }) {
    return CampaignFilter(
      category: clearCategory ? null : (category ?? this.category),
      fundingType: clearFundingType ? null : (fundingType ?? this.fundingType),
      status: clearStatus ? null : (status ?? this.status),
      stateRegion: clearStateRegion ? null : (stateRegion ?? this.stateRegion),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Pure Cloud Firestore + GeoFlutterFire Plus service layer for Kindoverse.
/// All dummy/seed data has been removed; all campaigns, milestones, donations,
/// and impact stories are read from and written to Cloud Firestore.
class CampaignRepository {
  final FirebaseFirestore? _firestore;

  static const List<String> _legacyDummyProjectIds = [
    'proj-solar-borewell-koraput',
    'proj-miyawaki-aravalli',
    'proj-stem-scholars-gadchiroli',
    'proj-model-village-chitrakoot',
    'proj-millet-fpo-anantapur',
    'proj-communal-health-kutch',
  ];

  static const List<String> _legacyDummyStoryIds = [
    'story-aravalli-forest',
    'story-koraput-water',
  ];

  CampaignRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  bool get _isFirebaseReady =>
      _firestore != null || Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Purges any previously seeded dummy documents from Cloud Firestore
  /// so only Admin-created campaigns and real records exist.
  Future<void> purgeLegacyDummyData() async {
    if (!_isFirebaseReady) return;
    try {
      for (final dummyId in _legacyDummyProjectIds) {
        final docRef = _db.collection('projects').doc(dummyId);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          final milestones = await docRef.collection('milestones').get();
          for (final m in milestones.docs) {
            await m.reference.delete();
          }
          final donations = await docRef.collection('donations').get();
          for (final d in donations.docs) {
            await d.reference.delete();
          }
          await docRef.delete();
        }
      }
      for (final storyId in _legacyDummyStoryIds) {
        final sRef = _db.collection('impact_stories').doc(storyId);
        final sSnap = await sRef.get();
        if (sSnap.exists) {
          await sRef.delete();
        }
      }
    } catch (_) {}
  }

  /// Creates a new fundraising campaign in `projects/{projectId}` along with
  /// its initial tranche milestones in `projects/{projectId}/milestones`.
  Future<Project> createCampaign({
    required Project project,
    List<Milestone> initialMilestones = const [],
  }) async {
    if (!_isFirebaseReady) {
      throw StateError('Firebase is not initialized.');
    }

    final projRef = _db.collection('projects').doc(project.id);
    final batch = _db.batch();
    batch.set(projRef, project.toJson());

    for (final milestone in initialMilestones) {
      final msRef = projRef.collection('milestones').doc(milestone.id);
      batch.set(msRef, milestone.toJson());
    }

    await batch.commit();
    return project;
  }

  /// Updates an existing campaign document (`projects/{projectId}`) in Cloud Firestore.
  Future<Project> updateCampaign({required Project project}) async {
    if (!_isFirebaseReady) {
      throw StateError('Firebase is not initialized.');
    }

    final projRef = _db.collection('projects').doc(project.id);
    await projRef.set(project.toJson(), SetOptions(merge: true));
    return project;
  }

  /// Updates the status of an existing campaign (`projects/{projectId}`).
  Future<void> updateProjectStatus({
    required String projectId,
    required ProjectStatus status,
  }) async {
    if (!_isFirebaseReady) return;
    await _db.collection('projects').doc(projectId).update({
      'status': status.value,
    });
  }

  /// Appends a photo URL to a campaign's folder (`galleryUrls`) in Cloud Firestore.
  Future<void> addPhotoToCampaignGallery({
    required String projectId,
    required String imageUrl,
  }) async {
    if (!_isFirebaseReady || imageUrl.trim().isEmpty) return;
    final docRef = _db.collection('projects').doc(projectId);
    final snap = await docRef.get();
    final currentCover = (snap.data()?['coverImageUrl'] as String?) ?? '';
    await docRef.update({
      'galleryUrls': FieldValue.arrayUnion([imageUrl.trim()]),
      if (currentCover.trim().isEmpty) 'coverImageUrl': imageUrl.trim(),
    });
  }

  /// Removes a photo URL from a campaign's folder (`galleryUrls`) in Cloud Firestore.
  Future<void> removePhotoFromCampaignGallery({
    required String projectId,
    required String imageUrl,
  }) async {
    if (!_isFirebaseReady || imageUrl.trim().isEmpty) return;
    await _db.collection('projects').doc(projectId).update({
      'galleryUrls': FieldValue.arrayRemove([imageUrl.trim()]),
    });
  }

  /// Creates a new custom gallery folder in `gallery_folders/{folderId}`.
  Future<GalleryFolder> createCustomGalleryFolder(GalleryFolder folder) async {
    if (!_isFirebaseReady) {
      throw StateError('Firebase is not initialized.');
    }
    await _db
        .collection('gallery_folders')
        .doc(folder.id)
        .set(folder.toJson());
    return folder;
  }

  /// Streams all custom gallery folders (`gallery_folders`) from Cloud Firestore.
  Stream<List<GalleryFolder>> watchCustomGalleryFolders() async* {
    if (!_isFirebaseReady) {
      yield const [];
      return;
    }

    await for (final snap in _db
        .collection('gallery_folders')
        .orderBy('createdAt', descending: true)
        .snapshots()) {
      yield snap.docs
          .map((d) => GalleryFolder.fromJson(d.data(), id: d.id))
          .toList();
    }
  }

  /// Appends one or more image URLs to a custom gallery folder (`gallery_folders/{folderId}`).
  Future<void> addPhotosToCustomFolder({
    required String folderId,
    required List<String> imageUrls,
  }) async {
    final cleaned =
        imageUrls.map((u) => u.trim()).where((u) => u.isNotEmpty).toList();
    if (!_isFirebaseReady || cleaned.isEmpty) return;
    await _db.collection('gallery_folders').doc(folderId).update({
      'imageUrls': FieldValue.arrayUnion(cleaned),
    });
  }

  /// Removes a photo URL from a custom gallery folder (`gallery_folders/{folderId}`).
  Future<void> removePhotoFromCustomFolder({
    required String folderId,
    required String imageUrl,
  }) async {
    if (!_isFirebaseReady || imageUrl.trim().isEmpty) return;
    await _db.collection('gallery_folders').doc(folderId).update({
      'imageUrls': FieldValue.arrayRemove([imageUrl.trim()]),
    });
  }

  /// Deletes a custom gallery folder (`gallery_folders/{folderId}`).
  Future<void> deleteCustomGalleryFolder(String folderId) async {
    if (!_isFirebaseReady || folderId.trim().isEmpty) return;
    await _db.collection('gallery_folders').doc(folderId).delete();
  }

  /// Deletes a campaign and its subcollections from Cloud Firestore.
  Future<void> deleteCampaign(String projectId) async {
    if (!_isFirebaseReady) return;
    final docRef = _db.collection('projects').doc(projectId);
    final milestones = await docRef.collection('milestones').get();
    for (final m in milestones.docs) {
      await m.reference.delete();
    }
    final donations = await docRef.collection('donations').get();
    for (final d in donations.docs) {
      await d.reference.delete();
    }
    await docRef.delete();
  }

  /// Publishes a new Before/After Impact Story to `impact_stories/{storyId}`.
  Future<void> publishImpactStory(ImpactStory story) async {
    if (!_isFirebaseReady) return;
    await _db.collection('impact_stories').doc(story.id).set(story.toJson());
  }

  /// Deletes an Impact Story from `impact_stories/{storyId}`.
  Future<void> deleteImpactStory(String storyId) async {
    if (!_isFirebaseReady) return;
    await _db.collection('impact_stories').doc(storyId).delete();
  }

  /// Streams campaigns matching the active [CampaignFilter] from Cloud Firestore.
  Stream<List<Project>> watchCampaigns(CampaignFilter filter) async* {
    if (!_isFirebaseReady) {
      yield const [];
      return;
    }

    Query<Map<String, dynamic>> query = _db.collection('projects');

    if (filter.category != null) {
      query = query.where('category', isEqualTo: filter.category!.value);
    }
    if (filter.fundingType != null) {
      query = query.where(
        'fundingType',
        isEqualTo: filter.fundingType!.value,
      );
    }
    if (filter.status != null) {
      query = query.where('status', isEqualTo: filter.status!.value);
    }
    if (filter.stateRegion != null && filter.stateRegion!.isNotEmpty) {
      query = query.where(
        'location.state',
        isEqualTo: filter.stateRegion,
      );
    }

    await for (final snapshot in query.snapshots()) {
      final items =
          snapshot.docs
              .map((d) => Project.fromJson(d.data(), id: d.id))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      yield _applySearchFilter(items, filter.searchQuery);
    }
  }

  /// Geohash bounding-radius query using `geoflutterfire_plus`.
  Stream<List<Project>> watchCampaignsInViewport({
    required double centerLat,
    required double centerLng,
    required double radiusInKm,
    CampaignFilter filter = const CampaignFilter(),
  }) async* {
    if (!_isFirebaseReady) {
      yield const [];
      return;
    }

    try {
      final collectionRef = _db.collection('projects');
      final center = GeoFirePoint(GeoPoint(centerLat, centerLng));

      final stream = GeoCollectionReference<Map<String, dynamic>>(
        collectionRef,
      ).subscribeWithin(
        center: center,
        radiusInKm: radiusInKm,
        field: 'geo',
        geopointFrom: (data) {
          final geo = data['geo'] as Map<String, dynamic>?;
          if (geo != null && geo['geopoint'] is GeoPoint) {
            return geo['geopoint'] as GeoPoint;
          }
          final loc = data['location'] as Map<String, dynamic>?;
          final lat = (loc?['lat'] as num?)?.toDouble() ?? 20.5937;
          final lng = (loc?['lng'] as num?)?.toDouble() ?? 78.9629;
          return GeoPoint(lat, lng);
        },
        queryBuilder: (query) {
          Query<Map<String, dynamic>> q = query;
          if (filter.category != null) {
            q = q.where('category', isEqualTo: filter.category!.value);
          }
          if (filter.fundingType != null) {
            q = q.where('fundingType', isEqualTo: filter.fundingType!.value);
          }
          if (filter.status != null) {
            q = q.where('status', isEqualTo: filter.status!.value);
          }
          return q;
        },
      );

      await for (final docs in stream) {
        final projects =
            docs
                .where((d) => d.data() != null)
                .map((d) => Project.fromJson(d.data()!, id: d.id))
                .toList();
        yield _applySearchFilter(projects, filter.searchQuery);
      }
    } catch (_) {
      yield* watchCampaigns(filter);
    }
  }

  /// Watches a single campaign by ID from Cloud Firestore.
  Stream<Project?> watchProjectById(String projectId) async* {
    if (!_isFirebaseReady || projectId.isEmpty) {
      yield null;
      return;
    }

    await for (final doc
        in _db.collection('projects').doc(projectId).snapshots()) {
      if (doc.exists && doc.data() != null) {
        yield Project.fromJson(doc.data()!, id: doc.id);
      } else {
        yield null;
      }
    }
  }

  /// Watches milestones for a specific campaign (`projects/{projectId}/milestones`).
  Stream<List<Milestone>> watchMilestones(String projectId) async* {
    if (!_isFirebaseReady || projectId.isEmpty) {
      yield const [];
      return;
    }

    await for (final snap in _db
        .collection('projects')
        .doc(projectId)
        .collection('milestones')
        .snapshots()) {
      yield snap.docs
          .map(
            (d) => Milestone.fromJson(
              d.data(),
              id: d.id,
              projectId: projectId,
            ),
          )
          .toList();
    }
  }

  /// Watches verified donations for a campaign (`projects/{projectId}/donations`).
  Stream<List<Donation>> watchDonations(String projectId) async* {
    if (!_isFirebaseReady || projectId.isEmpty) {
      yield const [];
      return;
    }

    await for (final snap in _db
        .collection('projects')
        .doc(projectId)
        .collection('donations')
        .orderBy('timestamp', descending: true)
        .snapshots()) {
      yield snap.docs
          .map(
            (d) => Donation.fromJson(
              d.data(),
              id: d.id,
              projectId: projectId,
            ),
          )
          .toList();
    }
  }

  /// Watches published Before/After impact stories (`impact_stories`).
  Stream<List<ImpactStory>> watchImpactStories() async* {
    if (!_isFirebaseReady) {
      yield const [];
      return;
    }

    await for (final snap in _db
        .collection('impact_stories')
        .orderBy('publishedAt', descending: true)
        .snapshots()) {
      yield snap.docs
          .map((d) => ImpactStory.fromJson(d.data(), id: d.id))
          .toList();
    }
  }

  /// Records a new donation in Cloud Firestore and atomically increments `raisedAmount`.
  Future<Donation> submitDonation({
    required String projectId,
    required String donorName,
    required bool isAnonymous,
    required num amount,
    String? panOrTaxId,
  }) async {
    final now = DateTime.now();
    final donationId = 'don-${now.millisecondsSinceEpoch}';
    final gatewayRef =
        'pay_Rzp${now.millisecondsSinceEpoch.toString().substring(6)}';
    final donation = Donation(
      id: donationId,
      projectId: projectId,
      donorId: 'usr-session-donor',
      donorName:
          donorName.trim().isEmpty ? 'Kindoverse Supporter' : donorName.trim(),
      isAnonymous: isAnonymous,
      amount: amount,
      paymentGatewayRef: gatewayRef,
      receiptUrl: 'https://kindoverse.org/receipts/80G-$donationId.pdf',
      panOrTaxId: panOrTaxId,
      timestamp: now,
      status: DonationStatus.success,
    );

    if (_isFirebaseReady) {
      final projRef = _db.collection('projects').doc(projectId);
      final donRef = projRef.collection('donations').doc(donationId);
      final batch = _db.batch();
      batch.set(donRef, donation.toJson());
      batch.update(projRef, {
        'raisedAmount': FieldValue.increment(amount),
      });
      await batch.commit();
    }
    return donation;
  }

  /// Field officer submission of GPS-stamped Before/After milestone proof.
  Future<void> submitFieldMilestoneProof({
    required String projectId,
    required String milestoneTitle,
    required num targetBudget,
    required String beforeImageUrl,
    required String afterImageUrl,
    required String remarks,
    required double gpsLat,
    required double gpsLng,
  }) async {
    final milestone = Milestone(
      id: 'ms-${DateTime.now().millisecondsSinceEpoch}',
      projectId: projectId,
      title: milestoneTitle,
      targetBudget: targetBudget,
      status: MilestoneStatus.pending,
      proofBeforeUrls: [if (beforeImageUrl.isNotEmpty) beforeImageUrl],
      proofAfterUrls: [if (afterImageUrl.isNotEmpty) afterImageUrl],
      remarks: remarks,
      gpsLat: gpsLat,
      gpsLng: gpsLng,
    );

    if (_isFirebaseReady) {
      await _db
          .collection('projects')
          .doc(projectId)
          .collection('milestones')
          .doc(milestone.id)
          .set(milestone.toJson());
    }
  }

  /// Admin verification approval of a pending milestone & automatic disbursement/story trigger.
  Future<void> approveMilestone({
    required String projectId,
    required String milestoneId,
  }) async {
    if (!_isFirebaseReady) return;

    final projRef = _db.collection('projects').doc(projectId);
    final msRef = projRef.collection('milestones').doc(milestoneId);
    final msSnap = await msRef.get();
    if (!msSnap.exists || msSnap.data() == null) return;

    final milestone = Milestone.fromJson(
      msSnap.data()!,
      id: msSnap.id,
      projectId: projectId,
    );

    await msRef.update({
      'status': MilestoneStatus.completed.value,
      'completedAt': FieldValue.serverTimestamp(),
    });

    await projRef.update({
      'disbursedAmount': FieldValue.increment(milestone.targetBudget),
    });

    // Check if all milestones in Firestore are now completed
    final allMsSnap = await projRef.collection('milestones').get();
    final allCompleted =
        allMsSnap.docs.isNotEmpty &&
        allMsSnap.docs.every((d) => d.data()['status'] == 'completed');

    if (allCompleted) {
      final projSnap = await projRef.get();
      if (projSnap.exists && projSnap.data() != null) {
        final project = Project.fromJson(projSnap.data()!, id: projSnap.id);
        await projRef.update({'status': ProjectStatus.completed.value});

        final story = ImpactStory(
          id: 'story-${DateTime.now().millisecondsSinceEpoch}',
          projectId: project.id,
          sectorCategory: project.category,
          title: '${project.title} — 100% Milestones Verified',
          beforeImageUrl:
              milestone.proofBeforeUrls.isNotEmpty
                  ? milestone.proofBeforeUrls.first
                  : project.coverImageUrl,
          afterImageUrl:
              milestone.proofAfterUrls.isNotEmpty
                  ? milestone.proofAfterUrls.first
                  : project.coverImageUrl,
          metricKey: 'beneficiaries_served',
          metricValue: project.beneficiariesCount,
          locationSummary: project.location.displayAddress,
          publishedAt: DateTime.now(),
        );

        await _db
            .collection('impact_stories')
            .doc(story.id)
            .set(story.toJson());
      }
    }
  }

  List<Project> _applySearchFilter(List<Project> items, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.location.village.toLowerCase().contains(q) ||
          p.location.district.toLowerCase().contains(q) ||
          p.location.state.toLowerCase().contains(q) ||
          p.organizerName.toLowerCase().contains(q);
    }).toList();
  }
}
