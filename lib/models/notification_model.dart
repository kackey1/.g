import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { like, comment, follow, message, warning, ban }

class NotificationModel {
  final String notificationId;
  final String userId;
  final String fromUserId;
  final String fromUsername;
  final String? fromUserPhoto;
  final NotificationType type;
  final String title;
  final String message;
  final String? postId;
  final String? chatId;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.fromUserId,
    required this.fromUsername,
    this.fromUserPhoto,
    required this.type,
    required this.title,
    required this.message,
    this.postId,
    this.chatId,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'fromUserPhoto': fromUserPhoto,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'postId': postId,
      'chatId': chatId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'data': data,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      notificationId: map['notificationId'] ?? '',
      userId: map['userId'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      fromUsername: map['fromUsername'] ?? '',
      fromUserPhoto: map['fromUserPhoto'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => NotificationType.like,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      postId: map['postId'],
      chatId: map['chatId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      data: map['data'],
    );
  }

  NotificationModel copyWith({
    String? notificationId,
    String? userId,
    String? fromUserId,
    String? fromUsername,
    String? fromUserPhoto,
    NotificationType? type,
    String? title,
    String? message,
    String? postId,
    String? chatId,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUsername: fromUsername ?? this.fromUsername,
      fromUserPhoto: fromUserPhoto ?? this.fromUserPhoto,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      postId: postId ?? this.postId,
      chatId: chatId ?? this.chatId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}