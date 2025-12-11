import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/auth/entities/user.dart' as auth_entity;

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final bool isEmailVerified;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.isEmailVerified = false,
    this.createdAt,
  });

  factory UserModel.fromEntity(auth_entity.User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      isEmailVerified: user.isEmailVerified,
      createdAt: user.createdAt,
    );
  }

  auth_entity.User toEntity() {
    return auth_entity.User(
      id: id,
      email: email,
      displayName: displayName,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}
