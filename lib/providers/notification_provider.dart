import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  Future<void> loadNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      _setLoading(true);
      _clearError();

      final query = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _notifications = query.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();

      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load notifications');
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<NotificationModel>> getNotificationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data()))
              .toList();
          
          _notifications = notifications;
          _unreadCount = notifications.where((n) => !n.isRead).length;
          notifyListeners();
          
          return notifications;
        });
  }

  Future<void> createNotification({
    required String userId,
    required String fromUserId,
    required String fromUsername,
    String? fromUserPhoto,
    required NotificationType type,
    required String title,
    required String message,
    String? postId,
    String? chatId,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Don't send notification to self
      if (userId == fromUserId) return;

      final notificationId = const Uuid().v4();
      final notification = NotificationModel(
        notificationId: notificationId,
        userId: userId,
        fromUserId: fromUserId,
        fromUsername: fromUsername,
        fromUserPhoto: fromUserPhoto,
        type: type,
        title: title,
        message: message,
        postId: postId,
        chatId: chatId,
        createdAt: DateTime.now(),
        data: data,
      );

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .set(notification.toMap());

      // If this is for current user, add to local list
      final currentUser = _auth.currentUser;
      if (currentUser?.uid == userId) {
        _notifications.insert(0, notification);
        _unreadCount++;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to create notification');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Update local data
      final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to mark notification as read');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Update local data
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _setError('Failed to mark all notifications as read');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // Remove from local list
      final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
      if (index != -1) {
        if (!_notifications[index].isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        }
        _notifications.removeAt(index);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to delete notification');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final batch = _firestore.batch();
      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear notifications');
    }
  }

  // Helper methods for creating specific notification types
  Future<void> sendLikeNotification({
    required String postAuthorId,
    required String fromUserId,
    required String fromUsername,
    String? fromUserPhoto,
    required String postId,
  }) async {
    await createNotification(
      userId: postAuthorId,
      fromUserId: fromUserId,
      fromUsername: fromUsername,
      fromUserPhoto: fromUserPhoto,
      type: NotificationType.like,
      title: 'New Like',
      message: '$fromUsername liked your post',
      postId: postId,
    );
  }

  Future<void> sendFollowNotification({
    required String userId,
    required String fromUserId,
    required String fromUsername,
    String? fromUserPhoto,
  }) async {
    await createNotification(
      userId: userId,
      fromUserId: fromUserId,
      fromUsername: fromUsername,
      fromUserPhoto: fromUserPhoto,
      type: NotificationType.follow,
      title: 'New Follower',
      message: '$fromUsername started following you',
    );
  }

  Future<void> sendMessageNotification({
    required String userId,
    required String fromUserId,
    required String fromUsername,
    String? fromUserPhoto,
    required String chatId,
    required String messageContent,
  }) async {
    await createNotification(
      userId: userId,
      fromUserId: fromUserId,
      fromUsername: fromUsername,
      fromUserPhoto: fromUserPhoto,
      type: NotificationType.message,
      title: 'New Message',
      message: '$fromUsername: $messageContent',
      chatId: chatId,
    );
  }

  Future<void> sendWarningNotification({
    required String userId,
    required String reason,
    Map<String, dynamic>? data,
  }) async {
    await createNotification(
      userId: userId,
      fromUserId: 'admin',
      fromUsername: 'Admin',
      type: NotificationType.warning,
      title: 'Warning',
      message: 'You have received a warning: $reason',
      data: data,
    );
  }

  Future<void> sendBanNotification({
    required String userId,
    required String reason,
    DateTime? banExpiry,
    Map<String, dynamic>? data,
  }) async {
    final message = banExpiry != null
        ? 'Your account has been temporarily banned: $reason'
        : 'Your account has been permanently banned: $reason';

    await createNotification(
      userId: userId,
      fromUserId: 'admin',
      fromUsername: 'Admin',
      type: NotificationType.ban,
      title: 'Account Banned',
      message: message,
      data: {
        'reason': reason,
        'banExpiry': banExpiry?.toIso8601String(),
        ...?data,
      },
    );
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