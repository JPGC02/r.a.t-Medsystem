import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/rat.dart';
import '../models/equipment.dart';
import '../models/history_entry.dart';

class StorageService {
  // Keys for SharedPreferences
  static const String _ratsKey = 'rats';
  static const String _equipmentKey = 'equipment';
  static const String _historyKey = 'history';

  // Save RATs to SharedPreferences
  Future<void> saveRATs(List<RAT> rats) async {
    final prefs = await SharedPreferences.getInstance();
    final ratsJson = rats.map((rat) => jsonEncode(rat.toJson())).toList();
    await prefs.setStringList(_ratsKey, ratsJson);
  }

  // Load RATs from SharedPreferences
  Future<List<RAT>> loadRATs() async {
    final prefs = await SharedPreferences.getInstance();
    final ratsJson = prefs.getStringList(_ratsKey) ?? [];
    return ratsJson
        .map((json) => RAT.fromJson(jsonDecode(json)))
        .toList();
  }

  // Save a single RAT to SharedPreferences
  Future<void> saveRAT(RAT rat) async {
    final rats = await loadRATs();
    final index = rats.indexWhere((r) => r.id == rat.id);
    if (index >= 0) {
      rats[index] = rat;
    } else {
      rats.add(rat);
    }
    await saveRATs(rats);
  }

  // Delete a RAT from SharedPreferences
  Future<void> deleteRAT(String ratId) async {
    final rats = await loadRATs();
    rats.removeWhere((rat) => rat.id == ratId);
    await saveRATs(rats);
  }

  // Save equipment list to SharedPreferences
  Future<void> saveEquipment(List<Equipment> equipment) async {
    final prefs = await SharedPreferences.getInstance();
    final equipmentJson = equipment.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_equipmentKey, equipmentJson);
  }

  // Load equipment list from SharedPreferences
  Future<List<Equipment>> loadEquipment() async {
    final prefs = await SharedPreferences.getInstance();
    final equipmentJson = prefs.getStringList(_equipmentKey) ?? [];
    return equipmentJson
        .map((json) => Equipment.fromJson(jsonDecode(json)))
        .toList();
  }

  // Save a single equipment to SharedPreferences
  Future<void> saveEquipmentItem(Equipment equipment) async {
    final equipmentList = await loadEquipment();
    final index = equipmentList.indexWhere((e) => e.id == equipment.id);
    if (index >= 0) {
      equipmentList[index] = equipment;
    } else {
      equipmentList.add(equipment);
    }
    await saveEquipment(equipmentList);
  }

  // Delete equipment from SharedPreferences
  Future<void> deleteEquipment(String equipmentId) async {
    final equipmentList = await loadEquipment();
    equipmentList.removeWhere((equipment) => equipment.id == equipmentId);
    await saveEquipment(equipmentList);
  }

  // Save history entries to SharedPreferences
  Future<void> saveHistoryEntries(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_historyKey, entriesJson);
  }

  // Load history entries from SharedPreferences
  Future<List<HistoryEntry>> loadHistoryEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList(_historyKey) ?? [];
    return entriesJson
        .map((json) => HistoryEntry.fromJson(jsonDecode(json)))
        .toList();
  }

  // Save a single history entry to SharedPreferences
  Future<void> saveHistoryEntry(HistoryEntry entry) async {
    final entries = await loadHistoryEntries();
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.add(entry);
    }
    await saveHistoryEntries(entries);
  }

  // Delete history entry from SharedPreferences
  Future<void> deleteHistoryEntry(String entryId) async {
    final entries = await loadHistoryEntries();
    entries.removeWhere((entry) => entry.id == entryId);
    await saveHistoryEntries(entries);
  }

  // Get all equipment for a specific RAT
  Future<List<Equipment>> getEquipmentForRAT(String ratId) async {
    final allEquipment = await loadEquipment();
    return allEquipment.where((equipment) => equipment.ratId == ratId).toList();
  }

  // Get history entries for a specific equipment
  Future<List<HistoryEntry>> getHistoryForEquipment(String equipmentId) async {
    final allEntries = await loadHistoryEntries();
    return allEntries.where((entry) => entry.equipmentId == equipmentId).toList();
  }

  // Check if all equipment for a RAT has been delivered
  Future<bool> isRATCompleted(String ratId) async {
    final equipment = await getEquipmentForRAT(ratId);
    if (equipment.isEmpty) return false;
    return equipment.every((e) => e.status == EquipmentStatus.delivered);
  }

  // Update RAT status based on equipment delivery status
  Future<void> updateRATStatus(String ratId) async {
    final rats = await loadRATs();
    final ratIndex = rats.indexWhere((r) => r.id == ratId);
    if (ratIndex < 0) return;

    final isCompleted = await isRATCompleted(ratId);
    final updatedRAT = rats[ratIndex].copyWith(isClosed: isCompleted);
    rats[ratIndex] = updatedRAT;
    await saveRATs(rats);
  }

  // Mark equipment as delivered and update history
  Future<void> markEquipmentAsDelivered({
    required String equipmentId,
    required String responsiblePerson,
    required String signature,
  }) async {
    final equipment = await loadEquipment();
    final index = equipment.indexWhere((e) => e.id == equipmentId);
    if (index < 0) return;

    final currentEquipment = equipment[index];
    final updatedEquipment = currentEquipment.markAsDelivered(
      deliveryDate: DateTime.now(),
      responsiblePerson: responsiblePerson,
      signature: signature,
    );

    equipment[index] = updatedEquipment;
    await saveEquipment(equipment);

    // Create delivery history entry
    final historyEntry = HistoryEntry.createDeliveryEntry(
      equipmentId: equipmentId,
      ratId: currentEquipment.ratId,
      date: DateTime.now(),
      responsiblePerson: responsiblePerson,
    );
    await saveHistoryEntry(historyEntry);

    // Update RAT status
    await updateRATStatus(currentEquipment.ratId);
  }

  // Get all open RATs
  Future<List<RAT>> getOpenRATs() async {
    final rats = await loadRATs();
    return rats.where((rat) => !rat.isClosed).toList();
  }

  // Get statistics for dashboard
  Future<Map<String, dynamic>> getDashboardStatistics({
    String? clientFilter,
    String? technicianFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final rats = await loadRATs();
    final equipment = await loadEquipment();
    final history = await loadHistoryEntries();

    // Apply filters
    List<RAT> filteredRATs = rats;
    if (clientFilter != null && clientFilter.isNotEmpty) {
      filteredRATs = filteredRATs
          .where((rat) => rat.clientName.toLowerCase().contains(clientFilter.toLowerCase()))
          .toList();
    }

    if (technicianFilter != null && technicianFilter.isNotEmpty) {
      filteredRATs = filteredRATs
          .where((rat) => rat.responsiblePerson.toLowerCase().contains(technicianFilter.toLowerCase()))
          .toList();
    }

    if (startDate != null) {
      filteredRATs = filteredRATs
          .where((rat) => rat.dateCreated.isAfter(startDate) || rat.dateCreated.isAtSameMomentAs(startDate))
          .toList();
    }

    if (endDate != null) {
      final nextDay = endDate.add(Duration(days: 1));
      filteredRATs = filteredRATs
          .where((rat) => rat.dateCreated.isBefore(nextDay))
          .toList();
    }

    // Get equipment associated with filtered RATs
    final ratIds = filteredRATs.map((rat) => rat.id).toSet();
    final filteredEquipment = equipment.where((e) => ratIds.contains(e.ratId)).toList();

    // Calculate statistics
    final withdrawnEquipment = filteredEquipment.where((e) => e.status == EquipmentStatus.withdrawn).length;
    final deliveredEquipment = filteredEquipment.where((e) => e.status == EquipmentStatus.delivered).length;
    final openRATs = filteredRATs.where((rat) => !rat.isClosed).length;

    // Calculate average days in laboratory
    int totalDays = 0;
    int count = 0;
    for (final e in filteredEquipment) {
      if (e.status == EquipmentStatus.delivered && e.deliveryDate != null) {
        final difference = e.deliveryDate!.difference(e.withdrawalDate).inDays;
        totalDays += difference;
        count++;
      }
    }

    final averageDays = count > 0 ? totalDays / count : 0;

    return {
      'withdrawnEquipment': withdrawnEquipment,
      'deliveredEquipment': deliveredEquipment,
      'openRATs': openRATs,
      'averageDays': averageDays,
    };
  }

  // Search equipment by various criteria
  Future<List<Equipment>> searchEquipment({
    String? name,
    String? serialNumber,
    String? assetId,
    String? client,
    EquipmentStatus? status,
  }) async {
    final equipment = await loadEquipment();
    final rats = await loadRATs();
    final ratMap = {for (var rat in rats) rat.id: rat};

    return equipment.where((e) {
      if (name != null && name.isNotEmpty) {
        final nameMatch = e.brand.toLowerCase().contains(name.toLowerCase()) ||
            e.model.toLowerCase().contains(name.toLowerCase());
        if (!nameMatch) return false;
      }

      if (serialNumber != null && serialNumber.isNotEmpty) {
        if (!e.serialNumber.toLowerCase().contains(serialNumber.toLowerCase())) {
          return false;
        }
      }

      if (assetId != null && assetId.isNotEmpty) {
        if (!e.assetId.toLowerCase().contains(assetId.toLowerCase())) {
          return false;
        }
      }

      if (client != null && client.isNotEmpty) {
        final rat = ratMap[e.ratId];
        if (rat == null || !rat.clientName.toLowerCase().contains(client.toLowerCase())) {
          return false;
        }
      }

      if (status != null && e.status != status) {
        return false;
      }

      return true;
    }).toList();
  }
}