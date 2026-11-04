// File cấu hình Firebase Options được tạo theo thông số của người dùng
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBPgJ9OWdeqbykAWVQaxpoVJA85tVb4M4s',
    appId: '1:951461248042:web:e84acfe891b31cf9fdd753',
    messagingSenderId: '951461248042',
    projectId: 'englishth3-a1d0c',
    authDomain: 'englishth3-a1d0c.firebaseapp.com',
    storageBucket: 'englishth3-a1d0c.firebasestorage.app',
    measurementId: 'G-JB72SR59TN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBPgJ9OWdeqbykAWVQaxpoVJA85tVb4M4s',
    appId: '1:951461248042:android:e84acfe891b31cf9fdd753',
    messagingSenderId: '951461248042',
    projectId: 'englishth3-a1d0c',
    storageBucket: 'englishth3-a1d0c.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBPgJ9OWdeqbykAWVQaxpoVJA85tVb4M4s',
    appId: '1:951461248042:web:e84acfe891b31cf9fdd753',
    messagingSenderId: '951461248042',
    projectId: 'englishth3-a1d0c',
    authDomain: 'englishth3-a1d0c.firebaseapp.com',
    storageBucket: 'englishth3-a1d0c.firebasestorage.app',
  );
}

