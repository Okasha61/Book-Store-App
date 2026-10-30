import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _saveProfile({
    required User user,
    String? name,
    String? phone,
  }) async {
    final reference = _firestore.collection('users').doc(user.uid);

    final displayName = name?.trim().isNotEmpty == true
        ? name!.trim()
        : (user.displayName ?? '');

    final displayPhone = phone?.trim() ?? '';

    final provider = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : 'password';

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        transaction.set(reference, {
          'uid': user.uid,
          'name': displayName,
          'email': user.email ?? '',
          'phone': displayPhone,
          'provider': provider,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final existing = snapshot.data() ?? <String, dynamic>{};

        final updates = <String, dynamic>{
          'provider': provider,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (displayName.isNotEmpty) {
          updates['name'] = displayName;
        } else if (existing['name'] == null) {
          updates['name'] = '';
        }

        if (displayPhone.isNotEmpty) {
          updates['phone'] = displayPhone;
        }

        transaction.update(reference, updates);
      }
    });
  }

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-creation-failed',
        message: 'Account could not be created.',
      );
    }

    await user.updateDisplayName(name.trim());
    await user.reload();

    final updatedUser = _auth.currentUser;

    if (updatedUser != null) {
      await _saveProfile(user: updatedUser, name: name, phone: phone);
    }

    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      await _saveProfile(user: user);
    }

    return credential;
  }

  Future<UserCredential?> signInWithGoogle() async {
    late final UserCredential credential;

    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});

      credential = await _auth.signInWithPopup(provider);
    } else {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'google-token-missing',
          message: 'Google did not return an ID token.',
        );
      }

      final googleCredential = GoogleAuthProvider.credential(idToken: idToken);

      credential = await _auth.signInWithCredential(googleCredential);
    }

    final user = credential.user;

    if (user != null) {
      await _saveProfile(user: user);
    }

    return credential;
  }

  Future<UserCredential?> signInWithFacebook() async {
    late final UserCredential credential;

    if (kIsWeb) {
      final provider = FacebookAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'display': 'popup'});

      credential = await _auth.signInWithPopup(provider);
    } else {
      final result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.cancelled) {
        return null;
      }

      if (result.status != LoginStatus.success) {
        throw FirebaseAuthException(
          code: 'facebook-login-failed',
          message: result.message ?? 'Facebook sign-in failed.',
        );
      }

      final accessToken = result.accessToken;

      if (accessToken == null) {
        throw FirebaseAuthException(
          code: 'facebook-token-missing',
          message: 'Facebook access token is unavailable.',
        );
      }

      final facebookCredential = FacebookAuthProvider.credential(
        accessToken.tokenString,
      );

      credential = await _auth.signInWithCredential(facebookCredential);
    }

    final user = credential.user;

    if (user != null) {
      await _saveProfile(user: user);
    }

    return credential;
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();

    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // No active Google session.
      }

      try {
        await FacebookAuth.instance.logOut();
      } catch (_) {
        // No active Facebook session.
      }
    }
  }
}
