import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  // Keys for SharedPreferences
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';

  // Current logged in user
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Initialize auth service
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson != null) {
      _currentUser = User.fromJson(jsonDecode(userJson));
    }

    // If no users exist, create an admin user
    final users = await getUsers();
    if (users.isEmpty) {
      await _createDefaultAdmin();
    }
  }

  // Create default admin user if no users exist
  Future<void> _createDefaultAdmin() async {
    final adminUser = User(
      name: 'Admin',
      email: 'admin@example.com',
      role: UserRole.admin,
      passwordHash: User.hashPassword('admin123'),
    );
    
    await saveUser(adminUser);
  }

  // Save users to SharedPreferences
  Future<void> saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = users.map((user) => jsonEncode(user.toJson())).toList();
    await prefs.setStringList(_usersKey, usersJson);
  }

  // Load users from SharedPreferences
  Future<List<User>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    return usersJson
        .map((json) => User.fromJson(jsonDecode(json)))
        .toList();
  }

  // Save a single user to SharedPreferences
  Future<void> saveUser(User user) async {
    final users = await getUsers();
    final index = users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      users[index] = user;
    } else {
      users.add(user);
    }
    await saveUsers(users);
  }

  // Delete a user from SharedPreferences
  Future<void> deleteUser(String userId) async {
    final users = await getUsers();
    users.removeWhere((user) => user.id == userId);
    await saveUsers(users);
  }

  // Login with email and password
  Future<User?> login(String email, String password) async {
    final users = await getUsers();
    final passwordHash = User.hashPassword(password);
    
    try {
      final user = users.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase() && 
                  user.passwordHash == passwordHash,
      );
      
      // Save current user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
      _currentUser = user;
      
      return user;
    } catch (e) {
      return null; // User not found or password incorrect
    }
  }

  // Register a new user
  Future<User?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final users = await getUsers();
    
    // Check if email already exists
    final emailExists = users.any(
      (user) => user.email.toLowerCase() == email.toLowerCase(),
    );
    
    if (emailExists) {
      return null; // Email already in use
    }
    
    final newUser = User(
      name: name,
      email: email,
      role: role,
      passwordHash: User.hashPassword(password),
    );
    
    await saveUser(newUser);
    return newUser;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    _currentUser = null;
  }

  // Check if a user has a specific permission
  bool hasPermission(UserPermission permission) {
    if (_currentUser == null) return false;
    
    switch (permission) {
      case UserPermission.viewRats:
        return true; // All users can view RATs
      case UserPermission.createRats:
        return _currentUser!.role == UserRole.admin || 
               _currentUser!.role == UserRole.technician;
      case UserPermission.editRats:
        return _currentUser!.role == UserRole.admin || 
               _currentUser!.role == UserRole.technician;
      case UserPermission.deliverEquipment:
        return _currentUser!.role == UserRole.admin || 
               _currentUser!.role == UserRole.technician;
      case UserPermission.manageUsers:
        return _currentUser!.role == UserRole.admin;
      default:
        return false;
    }
  }
}

enum UserPermission {
  viewRats,
  createRats,
  editRats,
  deliverEquipment,
  manageUsers,
}