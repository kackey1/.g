import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, video }

class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String senderUsername;
  final String? senderProfilePhoto;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;
  final String? mediaUrl;
  final String? replyToMessageId;
  final bool isDeleted;

  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.senderUsername,
    this.senderProfilePhoto,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.readBy = const [],
    this.mediaUrl,
    this.replyToMessageId,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderProfilePhoto': senderProfilePhoto,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'readBy': readBy,
      'mediaUrl': mediaUrl,
      'replyToMessageId': replyToMessageId,
      'isDeleted': isDeleted,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderUsername: map['senderUsername'] ?? '',
      senderProfilePhoto: map['senderProfilePhoto'],
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      readBy: List<String>.from(map['readBy'] ?? []),
      mediaUrl: map['mediaUrl'],
      replyToMessageId: map['replyToMessageId'],
      isDeleted: map['isDeleted'] ?? false,
    );
  }
}

class ChatModel {
  final String chatId;
  final List<String> participants;
  final Map<String, String> participantNames;
  final MessageModel? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isGroup;
  final String? groupName;
  final String? groupPhoto;
  final Map<String, int> unreadCounts;

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.participantNames,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.isGroup = false,
    this.groupName,
    this.groupPhoto,
    this.unreadCounts = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isGroup': isGroup,
      'groupName': groupName,
      'groupPhoto': groupPhoto,
      'unreadCounts': unreadCounts,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      lastMessage: map['lastMessage'] != null 
          ? MessageModel.fromMap(map['lastMessage']) 
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isGroup: map['isGroup'] ?? false,
      groupName: map['groupName'],
      groupPhoto: map['groupPhoto'],
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
    );
  }
}