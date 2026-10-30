import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.createdAt,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    final value = data['createdAt'];
    return UserModel(
      id: id,
      name: data['name']?.toString() ?? data['displayName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      createdAt: value is Timestamp
          ? value.toDate()
          : value is DateTime
          ? value
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name.trim(),
    'email': email.trim(),
    'phone': phone.trim(),
    'address': address.trim(),
    'createdAt': createdAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(createdAt!),
  };
}
