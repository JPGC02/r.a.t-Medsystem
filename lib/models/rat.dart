import 'dart:convert';
import 'package:uuid/uuid.dart';

class RAT {
  final String id;
  final String clientName;
  final DateTime dateCreated;
  final String responsiblePerson;
  final String signature; // base64 encoded signature
  bool isClosed;
  final List<String> equipmentIds;

  RAT({
    String? id,
    required this.clientName,
    required this.dateCreated,
    required this.responsiblePerson,
    required this.signature,
    this.isClosed = false,
    this.equipmentIds = const [],
  }) : id = id ?? const Uuid().v4();

  // Convert RAT instance to a map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientName': clientName,
      'dateCreated': dateCreated.toIso8601String(),
      'responsiblePerson': responsiblePerson,
      'signature': signature,
      'isClosed': isClosed,
      'equipmentIds': equipmentIds,
    };
  }

  // Create a RAT instance from a map
  factory RAT.fromJson(Map<String, dynamic> json) {
    return RAT(
      id: json['id'],
      clientName: json['clientName'],
      dateCreated: DateTime.parse(json['dateCreated']),
      responsiblePerson: json['responsiblePerson'],
      signature: json['signature'],
      isClosed: json['isClosed'] ?? false,
      equipmentIds: List<String>.from(json['equipmentIds'] ?? []),
    );
  }

  // Create a copy of this RAT with the given fields replaced with new values
  RAT copyWith({
    String? clientName,
    DateTime? dateCreated,
    String? responsiblePerson,
    String? signature,
    bool? isClosed,
    List<String>? equipmentIds,
  }) {
    return RAT(
      id: this.id,
      clientName: clientName ?? this.clientName,
      dateCreated: dateCreated ?? this.dateCreated,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      signature: signature ?? this.signature,
      isClosed: isClosed ?? this.isClosed,
      equipmentIds: equipmentIds ?? this.equipmentIds,
    );
  }
}