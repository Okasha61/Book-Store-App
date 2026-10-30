import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String customerName;
  final String email;
  final String phone;
  final String address;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String status;
  final String paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.email,
    required this.phone,
    required this.address,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime? date(dynamic value) => value is Timestamp
        ? value.toDate()
        : value is DateTime
        ? value
        : null;
    double number(dynamic value) => value is num ? value.toDouble() : 0;
    return OrderModel(
      id: id,
      userId: data['userId']?.toString() ?? '',
      customerName: data['customerName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      items: (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      subtotal: number(data['subtotal']),
      deliveryFee: number(data['deliveryFee']),
      total: number(data['total']),
      status: data['status']?.toString() ?? 'Pending',
      paymentMethod: data['paymentMethod']?.toString() ?? 'Cash on Delivery',
      createdAt: date(data['createdAt']),
      updatedAt: date(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'customerName': customerName,
    'email': email,
    'phone': phone,
    'address': address,
    'items': items,
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'total': total,
    'status': status,
    'paymentMethod': paymentMethod,
    'createdAt': createdAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(createdAt!),
    'updatedAt': updatedAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(updatedAt!),
  };
}
