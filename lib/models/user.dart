import 'dart:convert';
import 'package:uuid/uuid.dart';

enum UserRole {
  admin,
  technician,
  viewer,
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String passwordHash; // Storing password hash, not actual password

  User({
    String? id,
    required this.name,
    required this.email,
    required this.role,
    required this.passwordHash,
  }) : id = id ?? const Uuid().v4();

  // Convert User instance to a map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'passwordHash': passwordHash,
    };
  }

  // Create a User instance from a map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: _parseRole(json['role']),
      passwordHash: json['passwordHash'],
    );
  }

  // Helper method to parse role string to enum
  static UserRole _parseRole(String role) {
    return UserRole.values.firstWhere(
      (e) => e.toString().split('.').last == role,
      orElse: () => UserRole.viewer,
    );
  }

  // Simple password hashing function
  // In a real app, use a proper hashing library
  static String hashPassword(String password) {
    // This is a simple hash for demonstration
    // Never use this in production!
    final bytes = utf8.encode(password + "salt_for_security");
    return base64.encode(bytes);
  }

  // Create a copy of this User with the given fields replaced with new values
  User copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? passwordHash,
  }) {
    return User(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }
}