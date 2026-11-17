import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/models/app_user.dart';
import '../../../donations/domain/models/donation.dart';
import '../../../gallery/domain/models/gallery_folder.dart';
import '../../../impact_engine/domain/models/impact_story.dart';
import '../../data/repositories/campaign_repository.dart';
import '../../domain/models/milestone.dart';
import '../../domain/models/project.dart';

/// Singleton provider for the [CampaignRepository].
final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  return CampaignRepository();
});

/// Active RBAC role switcher for previewing Donor, Corporate CSR, Field Officer, and Admin flows.
class ActiveUserStateNotifier extends StateNotifier<AppUser> {
  ActiveUserStateNotifier()
    : super(
        AppUser(
          uid: 'usr-demo-01',
          name: 'Aarav Mehta',
          email: 'aarav.mehta@kindoverse.org',
          phone: '+91 98201 44510',
          role: UserRole.donor,
          panOrTaxId: 'ABCDE1234F',
          verified: true,
          totalContributed: 65000,
          createdAt: DateTime(2025, 4, 10),
        ),
      );

  void switchRole(UserRole role) {
    state = state.copyWith(role: role);
  }
}

final activeUserProvider =
    StateNotifierProvider<ActiveUserStateNotifier, AppUser>((ref) {
      return ActiveUserStateNotifier();
    });

/// StateNotifier managing active campaign search & filter parameters.
class CampaignFilterNotifier extends StateNotifier<CampaignFilter> {
  CampaignFilterNotifier() : super(const CampaignFilter());

  void setCategory(ImpactCategory? category) {
    state = state.copyWith(
      category: category,
      clearCategory: category == null,
    );
  }

  void setFundingType(FundingType? fundingType) {
    state = state.copyWith(
      fundingType: fundingType,
      clearFundingType: fundingType == null,
    );
  }

  void setStatus(ProjectStatus? status) {
    state = state.copyWith(status: status, clearStatus: status == null);
  }

  void setStateRegion(String? region) {
    state = state.copyWith(
      stateRegion: region,
      clearStateRegion: region == null || region.isEmpty,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearAll() {
    state = const CampaignFilter();
  }
}

final campaignFilterProvider =
    StateNotifierProvider<CampaignFilterNotifier, CampaignFilter>((ref) {
      return CampaignFilterNotifier();
    });

/// Reactive stream of campaigns filtered by [campaignFilterProvider].
final filteredCampaignsProvider = StreamProvider<List<Project>>((ref) {
  final repo = ref.watch(campaignRepositoryProvider);
  final filter = ref.watch(campaignFilterProvider);
  return repo.watchCampaigns(filter);
});

/// Viewport parameters for Geohash map bounding queries.
class MapViewportState {
  final double centerLat;
  final double centerLng;
  final double radiusInKm;
  final String? selectedProjectId;

  const MapViewportState({
    this.centerLat = 21.1458, // Central India (Nagpur reference)
    this.centerLng = 79.0882,
    this.radiusInKm = 2500,
    this.selectedProjectId,
  });

  MapViewportState copyWith({
    double? centerLat,
    double? centerLng,
    double? radiusInKm,
    String? selectedProjectId,
  }) {
    return MapViewportState(
      centerLat: centerLat ?? this.centerLat,
      centerLng: centerLng ?? this.centerLng,
      radiusInKm: radiusInKm ?? this.radiusInKm,
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
    );
  }
}

class MapViewportNotifier extends StateNotifier<MapViewportState> {
  MapViewportNotifier() : super(const MapViewportState());

  void updateViewport({
    required double lat,
    required double lng,
    required double radiusInKm,
  }) {
    state = state.copyWith(
      centerLat: lat,
      centerLng: lng,
      radiusInKm: radiusInKm,
    );
  }

  void selectProject(String? projectId) {
    state = state.copyWith(selectedProjectId: projectId);
  }
}

final mapViewportProvider =
    StateNotifierProvider<MapViewportNotifier, MapViewportState>((ref) {
      return MapViewportNotifier();
    });

/// Streams geo-queried campaigns inside the current map viewport.
final viewportCampaignsProvider = StreamProvider<List<Project>>((ref) {
  final repo = ref.watch(campaignRepositoryProvider);
  final filter = ref.watch(campaignFilterProvider);
  final viewport = ref.watch(mapViewportProvider);
  return repo.watchCampaignsInViewport(
    centerLat: viewport.centerLat,
    centerLng: viewport.centerLng,
    radiusInKm: viewport.radiusInKm,
    filter: filter,
  );
});

/// Family provider for streaming an individual project by ID.
final projectByIdProvider = StreamProvider.family<Project?, String>((
  ref,
  projectId,
) {
  final repo = ref.watch(campaignRepositoryProvider);
  return repo.watchProjectById(projectId);
});

/// Family provider for streaming project milestones.
final projectMilestonesProvider =
    StreamProvider.family<List<Milestone>, String>((ref, projectId) {
      final repo = ref.watch(campaignRepositoryProvider);
      return repo.watchMilestones(projectId);
    });

/// Family provider for streaming project donations.
final projectDonationsProvider = StreamProvider.family<List<Donation>, String>((
  ref,
  projectId,
) {
  final repo = ref.watch(campaignRepositoryProvider);
  return repo.watchDonations(projectId);
});

/// Streams published Before/After impact stories.
final impactStoriesProvider = StreamProvider<List<ImpactStory>>((ref) {
  final repo = ref.watch(campaignRepositoryProvider);
  return repo.watchImpactStories();
});

/// Streams custom gallery folders created by users/admins.
final customGalleryFoldersProvider = StreamProvider<List<GalleryFolder>>((ref) {
  final repo = ref.watch(campaignRepositoryProvider);
  return repo.watchCustomGalleryFolders();
});
