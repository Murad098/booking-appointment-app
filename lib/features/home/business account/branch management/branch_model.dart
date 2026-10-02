// lib/features/home/business account/branch management/branch_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Branch {
  final String id;
  final String businessId;
  final String branchManagerId;
  final String branchManagerEmail;
  final String name;
  final String location;
  final List<String> services;
  final String imageUrl;
  final DateTime? createdAt;

  Branch({
    required this.id,
    required this.businessId,
    required this.branchManagerId,
    required this.branchManagerEmail,
    required this.name,
    required this.location,
    required this.services,
    required this.imageUrl,
    this.createdAt,
  });

  factory Branch.fromMap(Map<String, dynamic> map, String id) {
    return Branch(
      id: id,
      businessId: map['businessId'] ?? '',
      branchManagerId: map['branchManagerId'] ?? '',
      branchManagerEmail: map['branchManagerEmail'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      services: List<String>.from(map['services'] ?? []),
      imageUrl: map['imageUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'branchManagerId': branchManagerId,
      'branchManagerEmail': branchManagerEmail,
      'name': name,
      'location': location,
      'services': services,
      'imageUrl': imageUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}