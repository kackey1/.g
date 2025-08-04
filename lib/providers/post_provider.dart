import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class PostProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<PostModel> _posts = [];
  List<PostModel> _userPosts = [];
  List<PostModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  List<PostModel> get posts => _posts;
  List<PostModel> get userPosts => _userPosts;
  List<PostModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFeedPosts() async {
    try {
      _setLoading(true);
      _clearError();

      final query = await _firestore
          .collection('posts')
          .where('isPrivate', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      _posts = query.docs.map((doc) => PostModel.fromMap(doc.data())).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load posts');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserPosts(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final query = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _userPosts = query.docs.map((doc) => PostModel.fromMap(doc.data())).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user posts');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createPost({
    required List<String> mediaPaths,
    required PostType type,
    String? caption,
    List<String> tags = const [],
    bool isPrivate = false,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      _setLoading(true);
      _clearError();

      // Get user data
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return false;
      
      final userData = UserModel.fromMap(userDoc.data()!);

      // Upload media files
      final mediaUrls = <String>[];
      for (int i = 0; i < mediaPaths.length; i++) {
        final mediaPath = mediaPaths[i];
        final fileName = '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}';
        final ref = _storage.ref().child('posts/${currentUser.uid}/$fileName');
        
        // In a real app, you would upload the actual file here
        // For demo purposes, we'll use the path as URL
        mediaUrls.add(mediaPath);
      }

      // Create post
      final postId = const Uuid().v4();
      final post = PostModel(
        postId: postId,
        authorId: currentUser.uid,
        authorUsername: userData.username,
        authorProfilePhoto: userData.profilePhotoUrl,
        caption: caption,
        mediaUrls: mediaUrls,
        type: type,
        tags: tags,
        createdAt: DateTime.now(),
        isPrivate: isPrivate,
      );

      await _firestore.collection('posts').doc(postId).set(post.toMap());

      // Update user's post count
      await _firestore.collection('users').doc(currentUser.uid).update({
        'postsCount': FieldValue.increment(1),
      });

      // Add to local list
      _posts.insert(0, post);
      if (currentUser.uid == userData.uid) {
        _userPosts.insert(0, post);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create post');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> likePost(String postId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final postRef = _firestore.collection('posts').doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) return;

        final post = PostModel.fromMap(postDoc.data()!);
        final isLiked = post.likes.contains(currentUser.uid);

        if (isLiked) {
          // Unlike
          transaction.update(postRef, {
            'likes': FieldValue.arrayRemove([currentUser.uid])
          });
        } else {
          // Like
          transaction.update(postRef, {
            'likes': FieldValue.arrayUnion([currentUser.uid])
          });
        }
      });

      // Update local data
      _updateLocalPost(postId, (post) {
        final updatedLikes = List<String>.from(post.likes);
        if (updatedLikes.contains(currentUser.uid)) {
          updatedLikes.remove(currentUser.uid);
        } else {
          updatedLikes.add(currentUser.uid);
        }
        return post.copyWith(likes: updatedLikes);
      });

    } catch (e) {
      _setError('Failed to like post');
    }
  }

  Future<void> sharePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'sharesCount': FieldValue.increment(1),
      });

      // Update local data
      _updateLocalPost(postId, (post) {
        return post.copyWith(sharesCount: post.sharesCount + 1);
      });

    } catch (e) {
      _setError('Failed to share post');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Check if user owns the post
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return;

      final post = PostModel.fromMap(postDoc.data()!);
      if (post.authorId != currentUser.uid) return;

      // Delete post
      await _firestore.collection('posts').doc(postId).delete();

      // Update user's post count
      await _firestore.collection('users').doc(currentUser.uid).update({
        'postsCount': FieldValue.increment(-1),
      });

      // Remove from local lists
      _posts.removeWhere((p) => p.postId == postId);
      _userPosts.removeWhere((p) => p.postId == postId);
      _searchResults.removeWhere((p) => p.postId == postId);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete post');
    }
  }

  Future<void> searchPosts(String query) async {
    try {
      _setLoading(true);
      _clearError();

      if (query.isEmpty) {
        _searchResults = [];
        notifyListeners();
        return;
      }

      // Search by caption and tags
      final captionQuery = await _firestore
          .collection('posts')
          .where('caption', isGreaterThanOrEqualTo: query)
          .where('caption', isLessThan: query + 'z')
          .where('isPrivate', isEqualTo: false)
          .limit(20)
          .get();

      final tagsQuery = await _firestore
          .collection('posts')
          .where('tags', arrayContains: query.toLowerCase())
          .where('isPrivate', isEqualTo: false)
          .limit(20)
          .get();

      final Set<String> addedPosts = {};
      _searchResults = [];

      for (final doc in [...captionQuery.docs, ...tagsQuery.docs]) {
        if (!addedPosts.contains(doc.id)) {
          addedPosts.add(doc.id);
          _searchResults.add(PostModel.fromMap(doc.data()));
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to search posts');
    } finally {
      _setLoading(false);
    }
  }

  Future<PostModel?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      if (doc.exists) {
        return PostModel.fromMap(doc.data()!);
      }
    } catch (e) {
      _setError('Failed to load post');
    }
    return null;
  }

  bool isPostLiked(String postId, String userId) {
    final post = _posts.firstWhere(
      (p) => p.postId == postId,
      orElse: () => _userPosts.firstWhere(
        (p) => p.postId == postId,
        orElse: () => _searchResults.firstWhere(
          (p) => p.postId == postId,
          orElse: () => PostModel(
            postId: '',
            authorId: '',
            authorUsername: '',
            mediaUrls: [],
            type: PostType.image,
            createdAt: DateTime.now(),
          ),
        ),
      ),
    );
    return post.likes.contains(userId);
  }

  void _updateLocalPost(String postId, PostModel Function(PostModel) updater) {
    // Update in main posts list
    final postIndex = _posts.indexWhere((p) => p.postId == postId);
    if (postIndex != -1) {
      _posts[postIndex] = updater(_posts[postIndex]);
    }

    // Update in user posts list
    final userPostIndex = _userPosts.indexWhere((p) => p.postId == postId);
    if (userPostIndex != -1) {
      _userPosts[userPostIndex] = updater(_userPosts[userPostIndex]);
    }

    // Update in search results
    final searchIndex = _searchResults.indexWhere((p) => p.postId == postId);
    if (searchIndex != -1) {
      _searchResults[searchIndex] = updater(_searchResults[searchIndex]);
    }

    notifyListeners();
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