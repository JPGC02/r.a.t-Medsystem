import 'package:flutter/foundation.dart';
import '../models/rat.dart';
import '../models/equipment.dart';
import '../models/history_entry.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

class AppStateProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

  List<RAT> _rats = [];
  List<Equipment> _equipment = [];
  List<HistoryEntry> _historyEntries = [];
  bool _isLoading = true;

  // Getters
  List<RAT> get rats => _rats;
  List<Equipment> get equipment => _equipment;
  List<HistoryEntry> get historyEntries => _historyEntries;
  bool get isLoading => _isLoading;
  AuthService get authService => _authService;
  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.currentUser != null;

  // Constructor
  AppStateProvider() {
    _initializeApp();
  }

  // Initialize app
  Future<void> _initializeApp() async {
    _isLoading = true;
    notifyListeners();

    // Initialize auth service
    await _authService.init();
    await _loadData();

    _isLoading = false;
    notifyListeners();
  }

  // Load all data from storage
  Future<void> _loadData() async {
    _rats = await _storageService.loadRATs();
    _equipment = await _storageService.loadEquipment();
    _historyEntries = await _storageService.loadHistoryEntries();
    notifyListeners();
  }

  // Refresh data
  Future<void> refreshData() async {
    await _loadData();
  }

  // Login user
  Future<User?> login(String email, String password) async {
    final user = await _authService.login(email, password);
    notifyListeners();
    return user;
  }

  // Register user
  Future<User?> registerUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (!_authService.hasPermission(UserPermission.manageUsers)) {
      throw Exception('No permission to manage users');
    }
    
    final user = await _authService.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    notifyListeners();
    return user;
  }

  // Logout user
  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  // Get all users (admin only)
  Future<List<User>> getUsers() async {
    if (!_authService.hasPermission(UserPermission.manageUsers)) {
      throw Exception('No permission to manage users');
    }
    
    return await _authService.getUsers();
  }

  // Update user (admin only)
  Future<void> updateUser(User user) async {
    if (!_authService.hasPermission(UserPermission.manageUsers)) {
      throw Exception('No permission to manage users');
    }
    
    await _authService.saveUser(user);
    notifyListeners();
  }

  // Delete user (admin only)
  Future<void> deleteUser(String userId) async {
    if (!_authService.hasPermission(UserPermission.manageUsers)) {
      throw Exception('No permission to manage users');
    }
    
    await _authService.deleteUser(userId);
    notifyListeners();
  }

  // Create a new RAT
  Future<RAT> createRAT({
    required String clientName,
    required String responsiblePerson,
    required String signature,
  }) async {
    // Check permission
    if (!_authService.hasPermission(UserPermission.createRats)) {
      throw Exception('No permission to create RATs');
    }

    final newRAT = RAT(
      clientName: clientName,
      dateCreated: DateTime.now(),
      responsiblePerson: responsiblePerson,
      signature: signature,
    );

    await _storageService.saveRAT(newRAT);
    await refreshData();
    return newRAT;
  }

  // Add equipment to a RAT
  Future<Equipment> addEquipment({
    required String ratId,
    required String brand,
    required String model,
    required String serialNumber,
    required String assetId,
    required List<String> photos,
    required String serviceDescription,
    required List<String> accessories,
  }) async {
    // Check permission
    if (!_authService.hasPermission(UserPermission.editRats)) {
      throw Exception('No permission to add equipment');
    }
    
    // Create new equipment
    final equipment = Equipment(
      ratId: ratId,
      brand: brand,
      model: model,
      serialNumber: serialNumber,
      assetId: assetId,
      photos: photos,
      serviceDescription: serviceDescription,
      accessories: accessories,
      withdrawalDate: DateTime.now(),
    );

    // Save equipment
    await _storageService.saveEquipmentItem(equipment);

    // Update RAT's equipment list
    final rat = _rats.firstWhere((r) => r.id == ratId);
    final updatedEquipmentIds = List<String>.from(rat.equipmentIds)..add(equipment.id);
    final updatedRAT = rat.copyWith(equipmentIds: updatedEquipmentIds);
    await _storageService.saveRAT(updatedRAT);

    // Create history entry for withdrawal
    final historyEntry = HistoryEntry.createWithdrawalEntry(
      equipmentId: equipment.id,
      ratId: ratId,
      date: DateTime.now(),
      responsiblePerson: rat.responsiblePerson,
    );
    await _storageService.saveHistoryEntry(historyEntry);

    await refreshData();
    return equipment;
  }

  // Mark equipment as delivered
  Future<void> markEquipmentAsDelivered({
    required String equipmentId,
    required String responsiblePerson,
    required String signature,
  }) async {
    // Check permission
    if (!_authService.hasPermission(UserPermission.deliverEquipment)) {
      throw Exception('No permission to deliver equipment');
    }
    
    await _storageService.markEquipmentAsDelivered(
      equipmentId: equipmentId,
      responsiblePerson: responsiblePerson,
      signature: signature,
    );
    await refreshData();
  }

  // Get equipment for a specific RAT
  List<Equipment> getEquipmentForRAT(String ratId) {
    return _equipment.where((e) => e.ratId == ratId).toList();
  }

  // Get history for a specific equipment
  List<HistoryEntry> getHistoryForEquipment(String equipmentId) {
    return _historyEntries.where((h) => h.equipmentId == equipmentId).toList();
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStatistics({
    String? clientFilter,
    String? technicianFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _storageService.getDashboardStatistics(
      clientFilter: clientFilter,
      technicianFilter: technicianFilter,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Search equipment
  Future<List<Equipment>> searchEquipment({
    String? name,
    String? serialNumber,
    String? assetId,
    String? client,
    EquipmentStatus? status,
  }) async {
    return await _storageService.searchEquipment(
      name: name,
      serialNumber: serialNumber,
      assetId: assetId,
      client: client,
      status: status,
    );
  }
}