// File generated based on Firebase configuration
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzhLPV2XNWtw9bvey9pK_WqOlhsHezFLk',
    appId: '1:1053816818404:android:543a9eb9c1dcb2b55cbaf1',
    messagingSenderId: '1053816818404',
    projectId: 'kreoecosystem',
    storageBucket: 'kreoecosystem.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyArPdhJA3-8Il19fJveG4Or7T0eEIIVxkk',
    appId: '1:1053816818404:ios:13d61fcdd952ea445cbaf1',
    messagingSenderId: '1053816818404',
    projectId: 'kreoecosystem',
    storageBucket: 'kreoecosystem.firebasestorage.app',
    iosBundleId: 'com.kreoecosystem.kreoCalendar',
    iosClientId:
        '1053816818404-euobjid50b52rbk6ff26bo6ldbqd7uba.apps.googleusercontent.com',
  );

  // macOS uses the same config as iOS for this project
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyArPdhJA3-8Il19fJveG4Or7T0eEIIVxkk',
    appId: '1:1053816818404:ios:13d61fcdd952ea445cbaf1',
    messagingSenderId: '1053816818404',
    projectId: 'kreoecosystem',
    storageBucket: 'kreoecosystem.firebasestorage.app',
    iosBundleId: 'com.kreoecosystem.kreoCalendar',
    iosClientId:
        '1053816818404-euobjid50b52rbk6ff26bo6ldbqd7uba.apps.googleusercontent.com',
  );

  // Web configuration - add a web app in Firebase Console to get these values
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBzhLPV2XNWtw9bvey9pK_WqOlhsHezFLk',
    appId: '1:1053816818404:web:REPLACE_WITH_WEB_APP_ID',
    messagingSenderId: '1053816818404',
    projectId: 'kreoecosystem',
    authDomain: 'kreoecosystem.firebaseapp.com',
    storageBucket: 'kreoecosystem.firebasestorage.app',
  );

  // Windows uses web config
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBzhLPV2XNWtw9bvey9pK_WqOlhsHezFLk',
    appId: '1:1053816818404:web:REPLACE_WITH_WEB_APP_ID',
    messagingSenderId: '1053816818404',
    projectId: 'kreoecosystem',
    authDomain: 'kreoecosystem.firebaseapp.com',
    storageBucket: 'kreoecosystem.firebasestorage.app',
  );
}
