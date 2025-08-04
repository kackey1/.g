import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      await _loadUserData(user.uid);
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!);
        // Update last active
        await _firestore.collection('users').doc(uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Check if username already exists
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        _setError('Username already exists');
        return false;
      }

      // Create user account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          username: username.toLowerCase(),
          displayName: displayName,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toMap());

        _userModel = userModel;
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
    } catch (e) {
      _setError('An unexpected error occurred');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
    } catch (e) {
      _setError('An unexpected error occurred');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _setError('Failed to sign out');
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
    } catch (e) {
      _setError('Failed to send reset email');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_user == null) return false;
      
      _setLoading(true);
      _clearError();

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );
      
      await _user!.reauthenticateWithCredential(credential);
      await _user!.updatePassword(newPassword);
      
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
    } catch (e) {
      _setError('Failed to change password');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> deleteAccount(String password) async {
    try {
      if (_user == null) return false;
      
      _setLoading(true);
      _clearError();

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: password,
      );
      
      await _user!.reauthenticateWithCredential(credential);
      
      // Delete user data from Firestore
      await _firestore.collection('users').doc(_user!.uid).delete();
      
      // Delete user account
      await _user!.delete();
      
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
    } catch (e) {
      _setError('Failed to delete account');
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? bio,
    String? profilePhotoUrl,
    bool? isPrivate,
  }) async {
    try {
      if (_user == null || _userModel == null) return;

      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (profilePhotoUrl != null) updates['profilePhotoUrl'] = profilePhotoUrl;
      if (isPrivate != null) updates['isPrivate'] = isPrivate;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(_user!.uid).update(updates);
        _userModel = _userModel!.copyWith(
          displayName: displayName ?? _userModel!.displayName,
          bio: bio ?? _userModel!.bio,
          profilePhotoUrl: profilePhotoUrl ?? _userModel!.profilePhotoUrl,
          isPrivate: isPrivate ?? _userModel!.isPrivate,
        );
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update profile');
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'email-already-in-use':
        return 'An account already exists for that email';
      case 'weak-password':
        return 'The password provided is too weak';
      case 'invalid-email':
        return 'The email address is not valid';
      case 'too-many-requests':
        return 'Too many requests. Try again later';
      case 'requires-recent-login':
        return 'Please log in again to perform this action';
      default:
        return 'An error occurred. Please try again';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}