import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Kindoverse (`kindoverse-impact`).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB9DHXAKR9fSs5DaTm_wtY4gHTlobfn3Kc',
    appId: '1:451523281524:web:654610cb6cdcc0f1d0c721',
    messagingSenderId: '451523281524',
    projectId: 'kindoverse-impact',
    authDomain: 'kindoverse-impact.firebaseapp.com',
    storageBucket: 'kindoverse-impact.firebasestorage.app',
  );
}
