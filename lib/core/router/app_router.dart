import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/pages/admin_campaign_studio_page.dart';
import '../../features/campaigns/presentation/pages/campaign_detail_page.dart';
import '../../features/campaigns/presentation/pages/home_discovery_page.dart';
import '../../features/gallery/presentation/pages/campaign_gallery_page.dart';
import '../../features/map_explorer/presentation/pages/impact_map_page.dart';
import '../../features/verification/presentation/pages/verification_portal_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeDiscoveryPage(),
      ),
      GoRoute(
        path: '/gallery',
        name: 'campaign-gallery',
        builder: (context, state) {
          final folderId = state.uri.queryParameters['folder'];
          return CampaignGalleryPage(initialFolderProjectId: folderId);
        },
      ),
      GoRoute(
        path: '/explore-map',
        name: 'explore-map',
        builder: (context, state) => const ImpactMapPage(),
      ),
      GoRoute(
        path: '/project/:id',
        name: 'project-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CampaignDetailPage(projectId: id);
        },
      ),
      GoRoute(
        path: '/verification-portal',
        name: 'verification-portal',
        builder: (context, state) => const VerificationPortalPage(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin-studio',
        builder: (context, state) {
          final editId = state.uri.queryParameters['edit'];
          return AdminCampaignStudioPage(editProjectId: editId);
        },
      ),
    ],
  );
});
