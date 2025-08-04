import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserModel> _users = [];
  List<UserModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get users => _users;
  List<UserModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      _setError('Failed to load user');
    }
    return null;
  }

  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return UserModel.fromMap(query.docs.first.data());
      }
    } catch (e) {
      _setError('Failed to load user');
    }
    return null;
  }

  Future<void> searchUsers(String query) async {
    try {
      _setLoading(true);
      _clearError();

      if (query.isEmpty) {
        _searchResults = [];
        notifyListeners();
        return;
      }

      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThan: query.toLowerCase() + 'z')
          .limit(20)
          .get();

      final displayNameQuery = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: query + 'z')
          .limit(20)
          .get();

      final Set<String> addedUsers = {};
      _searchResults = [];

      for (final doc in [...usernameQuery.docs, ...displayNameQuery.docs]) {
        if (!addedUsers.contains(doc.id)) {
          addedUsers.add(doc.id);
          _searchResults.add(UserModel.fromMap(doc.data()));
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to search users');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> followUser(String targetUserId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null || currentUserId == targetUserId) return;

      final batch = _firestore.batch();

      // Add to current user's following list
      batch.update(
        _firestore.collection('users').doc(currentUserId),
        {
          'following': FieldValue.arrayUnion([targetUserId])
        },
      );

      // Add to target user's followers list
      batch.update(
        _firestore.collection('users').doc(targetUserId),
        {
          'followers': FieldValue.arrayUnion([currentUserId])
        },
      );

      await batch.commit();

      // Update local data
      final targetUserIndex = _searchResults.indexWhere((u) => u.uid == targetUserId);
      if (targetUserIndex != -1) {
        _searchResults[targetUserIndex] = _searchResults[targetUserIndex].copyWith(
          followers: [..._searchResults[targetUserIndex].followers, currentUserId],
        );
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to follow user');
    }
  }

  Future<void> unfollowUser(String targetUserId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null || currentUserId == targetUserId) return;

      final batch = _firestore.batch();

      // Remove from current user's following list
      batch.update(
        _firestore.collection('users').doc(currentUserId),
        {
          'following': FieldValue.arrayRemove([targetUserId])
        },
      );

      // Remove from target user's followers list
      batch.update(
        _firestore.collection('users').doc(targetUserId),
        {
          'followers': FieldValue.arrayRemove([currentUserId])
        },
      );

      await batch.commit();

      // Update local data
      final targetUserIndex = _searchResults.indexWhere((u) => u.uid == targetUserId);
      if (targetUserIndex != -1) {
        final updatedFollowers = List<String>.from(_searchResults[targetUserIndex].followers);
        updatedFollowers.remove(currentUserId);
        _searchResults[targetUserIndex] = _searchResults[targetUserIndex].copyWith(
          followers: updatedFollowers,
        );
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to unfollow user');
    }
  }

  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];

      final userData = UserModel.fromMap(userDoc.data()!);
      final followers = <UserModel>[];

      for (final followerId in userData.followers) {
        final followerDoc = await _firestore.collection('users').doc(followerId).get();
        if (followerDoc.exists) {
          followers.add(UserModel.fromMap(followerDoc.data()!));
        }
      }

      return followers;
    } catch (e) {
      _setError('Failed to load followers');
      return [];
    }
  }

  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];

      final userData = UserModel.fromMap(userDoc.data()!);
      final following = <UserModel>[];

      for (final followingId in userData.following) {
        final followingDoc = await _firestore.collection('users').doc(followingId).get();
        if (followingDoc.exists) {
          following.add(UserModel.fromMap(followingDoc.data()!));
        }
      }

      return following;
    } catch (e) {
      _setError('Failed to load following');
      return [];
    }
  }

  bool isFollowing(String targetUserId, String currentUserId) {
    final targetUser = _searchResults.firstWhere(
      (user) => user.uid == targetUserId,
      orElse: () => UserModel(
        uid: '',
        email: '',
        username: '',
        displayName: '',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ),
    );
    return targetUser.followers.contains(currentUserId);
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
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