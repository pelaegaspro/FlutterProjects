import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

class AppBootstrap {
  static Future<AppBootstrapState> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final notes = <String>[];
    var firebaseReady = false;

    final options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) {
      notes.add(
        'Firebase config is missing for this platform, so Wizard XI is running with seeded demo data.',
      );
    } else {
      try {
        await Firebase.initializeApp(options: options);
        firebaseReady = true;
      } catch (error) {
        notes.add(
          'Firebase initialization failed. Demo mode is active so you can still explore the app. Details: $error',
        );
      }
    }

    return AppBootstrapState(
      firebaseReady: firebaseReady,
      notes: notes,
      preferences: preferences,
    );
  }
}

class AppBootstrapState {
  const AppBootstrapState({
    required this.firebaseReady,
    required this.notes,
    required this.preferences,
  });

  final bool firebaseReady;
  final List<String> notes;
  final SharedPreferences preferences;

  bool get demoMode => !firebaseReady;
}
