import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String displayName;
  final String? profilePhotoUrl;
  final String? bio;
  final List<String> followers;
  final List<String> following;
  final DateTime createdAt;
  final DateTime lastActive;
  final bool isVerified;
  final bool isPrivate;
  final bool isBanned;
  final String? banReason;
  final DateTime? banExpiry;
  final int postsCount;
  final Map<String, dynamic>? settings;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.displayName,
    this.profilePhotoUrl,
    this.bio,
    this.followers = const [],
    this.following = const [],
    required this.createdAt,
    required this.lastActive,
    this.isVerified = false,
    this.isPrivate = false,
    this.isBanned = false,
    this.banReason,
    this.banExpiry,
    this.postsCount = 0,
    this.settings,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'displayName': displayName,
      'profilePhotoUrl': profilePhotoUrl,
      'bio': bio,
      'followers': followers,
      'following': following,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'isVerified': isVerified,
      'isPrivate': isPrivate,
      'isBanned': isBanned,
      'banReason': banReason,
      'banExpiry': banExpiry != null ? Timestamp.fromDate(banExpiry!) : null,
      'postsCount': postsCount,
      'settings': settings,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? '',
      profilePhotoUrl: map['profilePhotoUrl'],
      bio: map['bio'],
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastActive: (map['lastActive'] as Timestamp).toDate(),
      isVerified: map['isVerified'] ?? false,
      isPrivate: map['isPrivate'] ?? false,
      isBanned: map['isBanned'] ?? false,
      banReason: map['banReason'],
      banExpiry: map['banExpiry'] != null 
          ? (map['banExpiry'] as Timestamp).toDate() 
          : null,
      postsCount: map['postsCount'] ?? 0,
      settings: map['settings'],
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? displayName,
    String? profilePhotoUrl,
    String? bio,
    List<String>? followers,
    List<String>? following,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isVerified,
    bool? isPrivate,
    bool? isBanned,
    String? banReason,
    DateTime? banExpiry,
    int? postsCount,
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      bio: bio ?? this.bio,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isVerified: isVerified ?? this.isVerified,
      isPrivate: isPrivate ?? this.isPrivate,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      banExpiry: banExpiry ?? this.banExpiry,
      postsCount: postsCount ?? this.postsCount,
      settings: settings ?? this.settings,
    );
  }
}