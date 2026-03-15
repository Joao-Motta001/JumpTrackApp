import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('JumpTrack currently targets mobile only.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not configured for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_ANDROID_API_KEY',
    appId: '1:1234567890:android:jumptrackplaceholder',
    messagingSenderId: '1234567890',
    projectId: 'jumptrack-placeholder',
    storageBucket: 'jumptrack-placeholder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: '1:1234567890:ios:jumptrackplaceholder',
    messagingSenderId: '1234567890',
    projectId: 'jumptrack-placeholder',
    storageBucket: 'jumptrack-placeholder.appspot.com',
    iosBundleId: 'com.jumptrack.app',
  );
}
