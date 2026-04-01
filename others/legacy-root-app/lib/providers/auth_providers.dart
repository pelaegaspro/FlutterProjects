import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import 'app_providers.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final bootstrap = ref.watch(appBootstrapProvider);
  if (bootstrap.firebaseReady) {
    return FirebaseAuthService();
  }
  return DemoAuthService(bootstrap.preferences);
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
