import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentChatId;

  List<ChatModel> get chats => _chats;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentChatId => _currentChatId;

  Future<void> loadChats() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      _setLoading(true);
      _clearError();

      final query = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .orderBy('updatedAt', descending: true)
          .get();

      _chats = query.docs.map((doc) => ChatModel.fromMap(doc.data())).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load chats');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMessages(String chatId) async {
    try {
      _currentChatId = chatId;
      _setLoading(true);
      _clearError();

      final query = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _messages = query.docs.map((doc) => MessageModel.fromMap(doc.data())).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load messages');
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  Future<String?> createChat(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // Check if chat already exists
      final existingChatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      for (final doc in existingChatQuery.docs) {
        final chat = ChatModel.fromMap(doc.data());
        if (chat.participants.contains(otherUserId) && 
            chat.participants.length == 2) {
          return chat.chatId;
        }
      }

      // Get other user data
      final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
      if (!otherUserDoc.exists) return null;
      
      final otherUser = UserModel.fromMap(otherUserDoc.data()!);

      // Get current user data
      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!currentUserDoc.exists) return null;
      
      final currentUserData = UserModel.fromMap(currentUserDoc.data()!);

      // Create new chat
      final chatId = const Uuid().v4();
      final chat = ChatModel(
        chatId: chatId,
        participants: [currentUser.uid, otherUserId],
        participantNames: {
          currentUser.uid: currentUserData.displayName,
          otherUserId: otherUser.displayName,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('chats').doc(chatId).set(chat.toMap());

      // Add to local list
      _chats.insert(0, chat);
      notifyListeners();

      return chatId;
    } catch (e) {
      _setError('Failed to create chat');
      return null;
    }
  }

  Future<bool> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    String? replyToMessageId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get current user data
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return false;
      
      final userData = UserModel.fromMap(userDoc.data()!);

      final messageId = const Uuid().v4();
      final message = MessageModel(
        messageId: messageId,
        chatId: chatId,
        senderId: currentUser.uid,
        senderUsername: userData.username,
        senderProfilePhoto: userData.profilePhotoUrl,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        mediaUrl: mediaUrl,
        replyToMessageId: replyToMessageId,
      );

      final batch = _firestore.batch();

      // Add message
      batch.set(
        _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId),
        message.toMap(),
      );

      // Update chat
      batch.update(_firestore.collection('chats').doc(chatId), {
        'lastMessage': message.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Update local data
      if (_currentChatId == chatId) {
        _messages.insert(0, message);
      }

      // Update chat in local list
      final chatIndex = _chats.indexWhere((c) => c.chatId == chatId);
      if (chatIndex != -1) {
        _chats[chatIndex] = _chats[chatIndex].copyWith(
          lastMessage: message,
          updatedAt: DateTime.now(),
        );
        // Move to top
        final chat = _chats.removeAt(chatIndex);
        _chats.insert(0, chat);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to send message');
      return false;
    }
  }

  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (final doc in messagesQuery.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readBy': FieldValue.arrayUnion([currentUser.uid]),
        });
      }

      await batch.commit();
    } catch (e) {
      _setError('Failed to mark messages as read');
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Check if user owns the message
      final messageDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) return;

      final message = MessageModel.fromMap(messageDoc.data()!);
      if (message.senderId != currentUser.uid) return;

      // Mark as deleted instead of actually deleting
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isDeleted': true, 'content': 'This message was deleted'});

      // Update local data
      if (_currentChatId == chatId) {
        final messageIndex = _messages.indexWhere((m) => m.messageId == messageId);
        if (messageIndex != -1) {
          _messages[messageIndex] = _messages[messageIndex].copyWith(
            isDeleted: true,
            content: 'This message was deleted',
          );
          notifyListeners();
        }
      }
    } catch (e) {
      _setError('Failed to delete message');
    }
  }

  int getUnreadCount(String chatId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    final chat = _chats.firstWhere(
      (c) => c.chatId == chatId,
      orElse: () => ChatModel(
        chatId: '',
        participants: [],
        participantNames: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return chat.unreadCounts[currentUser.uid] ?? 0;
  }

  void clearCurrentChat() {
    _currentChatId = null;
    _messages = [];
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