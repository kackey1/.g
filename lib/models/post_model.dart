import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { image, video }

class PostModel {
  final String postId;
  final String authorId;
  final String authorUsername;
  final String? authorProfilePhoto;
  final String? caption;
  final List<String> mediaUrls;
  final PostType type;
  final List<String> likes;
  final List<String> tags;
  final DateTime createdAt;
  final bool isPrivate;
  final int commentsCount;
  final int sharesCount;
  final String? location;
  final Map<String, dynamic>? metadata;

  PostModel({
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    this.authorProfilePhoto,
    this.caption,
    required this.mediaUrls,
    required this.type,
    this.likes = const [],
    this.tags = const [],
    required this.createdAt,
    this.isPrivate = false,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.location,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorProfilePhoto': authorProfilePhoto,
      'caption': caption,
      'mediaUrls': mediaUrls,
      'type': type.toString().split('.').last,
      'likes': likes,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPrivate': isPrivate,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'location': location,
      'metadata': metadata,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      postId: map['postId'] ?? '',
      authorId: map['authorId'] ?? '',
      authorUsername: map['authorUsername'] ?? '',
      authorProfilePhoto: map['authorProfilePhoto'],
      caption: map['caption'],
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      type: PostType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => PostType.image,
      ),
      likes: List<String>.from(map['likes'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isPrivate: map['isPrivate'] ?? false,
      commentsCount: map['commentsCount'] ?? 0,
      sharesCount: map['sharesCount'] ?? 0,
      location: map['location'],
      metadata: map['metadata'],
    );
  }

  PostModel copyWith({
    String? postId,
    String? authorId,
    String? authorUsername,
    String? authorProfilePhoto,
    String? caption,
    List<String>? mediaUrls,
    PostType? type,
    List<String>? likes,
    List<String>? tags,
    DateTime? createdAt,
    bool? isPrivate,
    int? commentsCount,
    int? sharesCount,
    String? location,
    Map<String, dynamic>? metadata,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorProfilePhoto: authorProfilePhoto ?? this.authorProfilePhoto,
      caption: caption ?? this.caption,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      type: type ?? this.type,
      likes: likes ?? this.likes,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      location: location ?? this.location,
      metadata: metadata ?? this.metadata,
    );
  }
}