import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firebase_options.dart';
import '../models/models.dart';

abstract class AuthService {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<void> signInAnonymously();
  Future<void> signInWithGoogle();
  Future<void> signOut();
  bool get isDemoMode;
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService() : _auth = firebase_auth.FirebaseAuth.instance;

  final firebase_auth.FirebaseAuth _auth;
  bool _googleInitialized = false;

  @override
  bool get isDemoMode => false;

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  AppUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(firebase_auth.GoogleAuthProvider());
      return;
    }

    await _initializeGoogle();
    final account = await GoogleSignIn.instance.authenticate();
    final authentication = await account.authentication;
    final credential = firebase_auth.GoogleAuthProvider.credential(
      idToken: authentication.idToken,
    );

    await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Continue with Firebase sign-out if Google sign-out is unavailable.
      }
    }
    await _auth.signOut();
  }

  Future<void> _initializeGoogle() async {
    if (_googleInitialized) {
      return;
    }

    await GoogleSignIn.instance.initialize(
      clientId: DefaultFirebaseOptions.googleClientId,
      serverClientId: DefaultFirebaseOptions.serverClientId,
    );
    _googleInitialized = true;
  }

  AppUser? _mapUser(firebase_auth.User? user) {
    if (user == null) {
      return null;
    }

    return AppUser(
      id: user.uid,
      isAnonymous: user.isAnonymous,
      displayName: user.displayName,
      email: user.email,
    );
  }
}

class DemoAuthService implements AuthService {
  DemoAuthService(this._preferences) {
    final raw = _preferences.getString(_sessionKey);
    if (raw != null && raw.isNotEmpty) {
      _currentUser = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
  }

  static const _sessionKey = 'wizard_xi_demo_session';

  final SharedPreferences _preferences;
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  @override
  bool get isDemoMode => true;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<void> signInAnonymously() async {
    await _storeUser(
      const AppUser(
        id: 'demo-anon',
        isAnonymous: true,
        displayName: 'Guest Strategist',
      ),
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    await _storeUser(
      const AppUser(
        id: 'demo-google',
        isAnonymous: false,
        displayName: 'Demo Analyst',
        email: 'demo@wizardxi.app',
      ),
    );
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _preferences.remove(_sessionKey);
    _controller.add(null);
  }

  Future<void> _storeUser(AppUser user) async {
    _currentUser = user;
    await _preferences.setString(_sessionKey, jsonEncode(user.toJson()));
    _controller.add(_currentUser);
  }
}
