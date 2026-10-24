import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB0bfuzfVO6PR28erEWn0dzVuwAa74vCn8',
    appId: '1:813733906604:web:3075f9f91ddcde1dc27709',
    messagingSenderId: '813733906604',
    projectId: 'mlintex-17ad8',
    authDomain: 'mlintex-17ad8.firebaseapp.com',
    storageBucket: 'mlintex-17ad8.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0bfuzfVO6PR28erEWn0dzVuwAa74vCn8',
    appId: '1:813733906604:android:3075f9f91ddcde1dc27709',
    messagingSenderId: '813733906604',
    projectId: 'mlintex-17ad8',
    storageBucket: 'mlintex-17ad8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB0bfuzfVO6PR28erEWn0dzVuwAa74vCn8',
    appId: '1:813733906604:ios:3075f9f91ddcde1dc27709',
    messagingSenderId: '813733906604',
    projectId: 'mlintex-17ad8',
    storageBucket: 'mlintex-17ad8.firebasestorage.app',
    iosBundleId: 'com.example.shopManager',
  );
}
