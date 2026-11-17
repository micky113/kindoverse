import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/router/app_router.dart';
import 'core/services/file_picker_registrar.dart';
import 'core/theme/app_theme.dart';
import 'features/campaigns/presentation/providers/campaign_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable clean path-based deep links for PWA & social sharing (no '#' in URLs)
  usePathUrlStrategy();

  // Ensure FilePicker platform instance is registered (prevents LateInitializationError)
  ensureFilePickerInitialized();

  // Initialize Firebase (Auth, Cloud Firestore, Cloud Storage)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  runApp(const ProviderScope(child: KindoverseApp()));
}

class KindoverseApp extends ConsumerStatefulWidget {
  final bool enableIntroSplash;

  const KindoverseApp({super.key, this.enableIntroSplash = false});

  @override
  ConsumerState<KindoverseApp> createState() => _KindoverseAppState();
}

class _KindoverseAppState extends ConsumerState<KindoverseApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(campaignRepositoryProvider).purgeLegacyDummyData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Kindoverse — Kindness starts with you',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
