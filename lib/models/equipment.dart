import 'dart:convert';
import 'package:uuid/uuid.dart';

enum EquipmentStatus {
  withdrawn,  // Retirado
  delivered,  // Entregue
}

class Equipment {
  final String id;
  final String ratId;
  final String brand;
  final String model;
  final String serialNumber;
  final String assetId; // patrimônio
  final List<String> photos; // base64 encoded images, max 5
  final String serviceDescription;
  final List<String> accessories;
  EquipmentStatus status;
  final DateTime withdrawalDate;
  DateTime? deliveryDate;
  String? deliveryResponsiblePerson;
  String? deliverySignature; // base64 encoded signature

  Equipment({
    String? id,
    required this.ratId,
    required this.brand,
    required this.model,
    required this.serialNumber,
    required this.assetId,
    this.photos = const [],
    required this.serviceDescription,
    this.accessories = const [],
    this.status = EquipmentStatus.withdrawn,
    required this.withdrawalDate,
    this.deliveryDate,
    this.deliveryResponsiblePerson,
    this.deliverySignature,
  }) : id = id ?? const Uuid().v4();

  // Convert Equipment instance to a map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ratId': ratId,
      'brand': brand,
      'model': model,
      'serialNumber': serialNumber,
      'assetId': assetId,
      'photos': photos,
      'serviceDescription': serviceDescription,
      'accessories': accessories,
      'status': status.toString().split('.').last,
      'withdrawalDate': withdrawalDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'deliveryResponsiblePerson': deliveryResponsiblePerson,
      'deliverySignature': deliverySignature,
    };
  }

  // Create an Equipment instance from a map
  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'],
      ratId: json['ratId'],
      brand: json['brand'],
      model: json['model'],
      serialNumber: json['serialNumber'],
      assetId: json['assetId'],
      photos: List<String>.from(json['photos'] ?? []),
      serviceDescription: json['serviceDescription'],
      accessories: List<String>.from(json['accessories'] ?? []),
      status: _parseStatus(json['status']),
      withdrawalDate: DateTime.parse(json['withdrawalDate']),
      deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
      deliveryResponsiblePerson: json['deliveryResponsiblePerson'],
      deliverySignature: json['deliverySignature'],
    );
  }

  // Helper method to parse status string to enum
  static EquipmentStatus _parseStatus(String status) {
    return EquipmentStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => EquipmentStatus.withdrawn,
    );
  }

  // Create a copy of this Equipment with the given fields replaced with new values
  Equipment copyWith({
    String? brand,
    String? model,
    String? serialNumber,
    String? assetId,
    List<String>? photos,
    String? serviceDescription,
    List<String>? accessories,
    EquipmentStatus? status,
    DateTime? deliveryDate,
    String? deliveryResponsiblePerson,
    String? deliverySignature,
  }) {
    return Equipment(
      id: this.id,
      ratId: this.ratId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      assetId: assetId ?? this.assetId,
      photos: photos ?? this.photos,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      accessories: accessories ?? this.accessories,
      status: status ?? this.status,
      withdrawalDate: this.withdrawalDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryResponsiblePerson: deliveryResponsiblePerson ?? this.deliveryResponsiblePerson,
      deliverySignature: deliverySignature ?? this.deliverySignature,
    );
  }

  // Check if equipment has 5 or more photos
  bool hasMaxPhotos() {
    return photos.length >= 5;
  }

  // Mark equipment as delivered
  Equipment markAsDelivered({
    required DateTime deliveryDate,
    required String responsiblePerson,
    required String signature,
  }) {
    return copyWith(
      status: EquipmentStatus.delivered,
      deliveryDate: deliveryDate,
      deliveryResponsiblePerson: responsiblePerson,
      deliverySignature: signature,
    );
  }
}