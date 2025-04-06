import 'package:uuid/uuid.dart';

enum HistoryEntryType {
  withdrawal,
  delivery,
}

class HistoryEntry {
  final String id;
  final String equipmentId;
  final String ratId;
  final HistoryEntryType type;
  final DateTime date;
  final String responsiblePerson;
  final String? notes;

  HistoryEntry({
    String? id,
    required this.equipmentId,
    required this.ratId,
    required this.type,
    required this.date,
    required this.responsiblePerson,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  // Convert HistoryEntry instance to a map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'ratId': ratId,
      'type': type.toString().split('.').last,
      'date': date.toIso8601String(),
      'responsiblePerson': responsiblePerson,
      'notes': notes,
    };
  }

  // Create a HistoryEntry instance from a map
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'],
      equipmentId: json['equipmentId'],
      ratId: json['ratId'],
      type: _parseType(json['type']),
      date: DateTime.parse(json['date']),
      responsiblePerson: json['responsiblePerson'],
      notes: json['notes'],
    );
  }

  // Helper method to parse type string to enum
  static HistoryEntryType _parseType(String type) {
    return HistoryEntryType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => HistoryEntryType.withdrawal,
    );
  }

  // Create a history entry for equipment withdrawal
  static HistoryEntry createWithdrawalEntry({
    required String equipmentId,
    required String ratId,
    required DateTime date,
    required String responsiblePerson,
    String? notes,
  }) {
    return HistoryEntry(
      equipmentId: equipmentId,
      ratId: ratId,
      type: HistoryEntryType.withdrawal,
      date: date,
      responsiblePerson: responsiblePerson,
      notes: notes,
    );
  }

  // Create a history entry for equipment delivery
  static HistoryEntry createDeliveryEntry({
    required String equipmentId,
    required String ratId,
    required DateTime date,
    required String responsiblePerson,
    String? notes,
  }) {
    return HistoryEntry(
      equipmentId: equipmentId,
      ratId: ratId,
      type: HistoryEntryType.delivery,
      date: date,
      responsiblePerson: responsiblePerson,
      notes: notes,
    );
  }
}