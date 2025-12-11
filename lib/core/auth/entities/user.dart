import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final bool isEmailVerified;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.isEmailVerified = false,
    this.createdAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? isEmailVerified,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    isEmailVerified,
    createdAt,
  ];
}
