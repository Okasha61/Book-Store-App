import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String bookId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const ReviewModel({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromMap(String id, Map<String, dynamic> data) {
    final value = data['createdAt'];
    return ReviewModel(
      id: id,
      bookId: data['bookId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? 'Reader',
      rating: ((data['rating'] as num?)?.toInt() ?? 0).clamp(0, 5),
      comment: data['comment']?.toString() ?? '',
      createdAt: value is Timestamp
          ? value.toDate()
          : value is DateTime
          ? value
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'bookId': bookId,
    'userId': userId,
    'userName': userName,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(createdAt!),
  };
}
