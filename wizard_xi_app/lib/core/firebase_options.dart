import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      case TargetPlatform.macOS:
        return _macos;
      case TargetPlatform.windows:
        return _windows;
      case TargetPlatform.linux:
        return _linux;
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  static String? get googleClientId {
    const value = String.fromEnvironment('GOOGLE_SIGN_IN_CLIENT_ID');
    return value.isEmpty ? null : value;
  }

  static String? get serverClientId {
    const value = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    return value.isEmpty ? null : value;
  }

  static FirebaseOptions? get _android => _optionsFor(
        appId: const String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
      );

  static FirebaseOptions? get _ios => _optionsFor(
        appId: const String.fromEnvironment('FIREBASE_IOS_APP_ID'),
        iosBundleId: const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
      );

  static FirebaseOptions? get _macos => _optionsFor(
        appId: const String.fromEnvironment('FIREBASE_MACOS_APP_ID'),
        iosBundleId: const String.fromEnvironment('FIREBASE_MACOS_BUNDLE_ID'),
      );

  static FirebaseOptions? get _windows => _optionsFor(
        appId: const String.fromEnvironment('FIREBASE_WINDOWS_APP_ID'),
      );

  static FirebaseOptions? get _linux => _optionsFor(
        appId: const String.fromEnvironment('FIREBASE_LINUX_APP_ID'),
      );

  static FirebaseOptions? _optionsFor({
    required String appId,
    String? iosBundleId,
  }) {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const messagingSenderId =
        String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
    const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
    const iosClientId = String.fromEnvironment('FIREBASE_IOS_CLIENT_ID');

    if (apiKey.isEmpty ||
        projectId.isEmpty ||
        messagingSenderId.isEmpty ||
        appId.isEmpty) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain.isEmpty ? null : authDomain,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      iosBundleId: (iosBundleId ?? '').isEmpty ? null : iosBundleId,
      iosClientId: iosClientId.isEmpty ? null : iosClientId,
    );
  }
}
