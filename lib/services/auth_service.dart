import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sp;

import '../models/models.dart';

class AuthService {
  final sp.SupabaseClient _supabase = sp.Supabase.instance.client;

  Stream<User?> authStateChanges() {
    return _supabase.auth.onAuthStateChange
        .map((authState) => _mapAuthUser(authState.session?.user ?? _supabase.auth.currentUser))
        .startWith(_mapAuthUser(_supabase.auth.currentUser));
  }

  User? getCurrentUser() => _mapAuthUser(_supabase.auth.currentUser);

  bool isLoggedIn() => _supabase.auth.currentUser != null;

  Future<void> signIn(String email, String password) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw Exception('Enter a valid email address.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    await _supabase.auth.signInWithPassword(
      email: normalizedEmail,
      password: password,
    );
  }

  Future<void> signUp(String email, String password) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw Exception('Enter a valid email address.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    await _supabase.auth.signUp(
      email: normalizedEmail,
      password: password,
    );
  }

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      sp.OAuthProvider.google,
      redirectTo: 'colasticaxi://login-callback/',
    );
  }

  Future<void> sendOtp(String phone) async {
    final normalizedPhone = _normalizePhone(phone);
    _validatePhone(normalizedPhone);

    await _supabase.auth.signInWithOtp(
      phone: normalizedPhone,
    );
  }

  Future<void> verifyOtp(String phone, String token) async {
    final normalizedPhone = _normalizePhone(phone);
    final normalizedToken = token.replaceAll(RegExp(r'\s+'), '');

    _validatePhone(normalizedPhone);
    if (normalizedToken.length != 6) {
      throw Exception('Enter the 6-digit OTP sent to your phone.');
    }

    await _supabase.auth.verifyOTP(
      phone: normalizedPhone,
      token: normalizedToken,
      type: sp.OtpType.sms,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  String normalizePhoneForDisplay(String phone) => _normalizePhone(phone);

  void _validatePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (!phone.startsWith('+') || digits.length < 10 || digits.length > 15) {
      throw Exception('Enter your phone number with country code, for example +919876543210.');
    }
  }

  String _normalizePhone(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final normalized = trimmed.replaceAll(RegExp(r'[\s()-]'), '');
    if (normalized.startsWith('00')) {
      return '+${normalized.substring(2)}';
    }

    return normalized;
  }

  User? _mapAuthUser(sp.User? user) {
    if (user == null) {
      return null;
    }

    final metadata = user.userMetadata ?? const {};
    final primaryContact = user.phone ?? user.email ?? '';

    return User(
      id: user.id,
      email: primaryContact,
      displayName: metadata['display_name']?.toString() ?? metadata['name']?.toString(),
    );
  }
}

extension<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
