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
    apiKey: 'AIzaSyAu9mkXGU91uqfogZQFt9tbrtt6znQl-to',
    appId: '1:634361097140:web:59f0173da0984fe1c460e1',
    messagingSenderId: '634361097140',
    projectId: 'iztex-group',
    authDomain: 'iztex-group.firebaseapp.com',
    storageBucket: 'iztex-group.firebasestorage.app',
    measurementId: 'G-W50SLJVV4J',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB2SK6ksjgj7nY7vvk1_qWEmnINxY3s2GA',
    appId: '1:634361097140:android:b54f976da0f0a39ac460e1',
    messagingSenderId: '634361097140',
    projectId: 'iztex-group',
    storageBucket: 'iztex-group.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB2SK6ksjgj7nY7vvk1_qWEmnINxY3s2GA',
    appId: '1:634361097140:ios:3075f9f91ddcde1dc27709',
    messagingSenderId: '634361097140',
    projectId: 'iztex-group',
    storageBucket: 'iztex-group.firebasestorage.app',
    iosBundleId: 'com.iztexgroup.shopManager',
  );
}
