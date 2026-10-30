import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookReview {
  const BookReview({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  final String id;
  final String bookId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  factory BookReview.fromMap(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'];

    return BookReview(
      id: id,
      bookId: data['bookId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? 'Customer',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment']?.toString() ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}

class RatingSummary {
  const RatingSummary({required this.average, required this.count});

  final double average;
  final int count;
}

class ReviewService {
  ReviewService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('book_reviews');

  /// A user can review a book only if its delivery record exists.
  Future<bool> canReviewBook(String bookId) async {
    final user = _auth.currentUser;

    if (user == null || bookId.trim().isEmpty) {
      return false;
    }

    final deliveredBook = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('delivered_books')
        .doc(bookId)
        .get();

    return deliveredBook.exists;
  }

  /// Stream reviews for a single book.
  Stream<List<BookReview>> watchReviews(String bookId) {
    return _reviews.where('bookId', isEqualTo: bookId).snapshots().map((
      snapshot,
    ) {
      final reviews = snapshot.docs
          .map((doc) => BookReview.fromMap(doc.id, doc.data()))
          .toList();

      reviews.sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });

      return reviews;
    });
  }

  /// Stream average rating and count for all books.
  Stream<Map<String, RatingSummary>> watchRatingSummaries() {
    return _reviews.snapshots().map((snapshot) {
      final ratings = <String, List<int>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final bookId = data['bookId']?.toString() ?? '';
        final rating = (data['rating'] as num?)?.toInt() ?? 0;

        if (bookId.isEmpty || rating < 1 || rating > 5) {
          continue;
        }

        ratings.putIfAbsent(bookId, () => <int>[]).add(rating);
      }

      return ratings.map((bookId, values) {
        final total = values.fold<int>(0, (sum, value) => sum + value);

        return MapEntry(
          bookId,
          RatingSummary(
            average: values.isEmpty ? 0 : total / values.length,
            count: values.length,
          ),
        );
      });
    });
  }

  /// Get the current user's review for a book.
  Future<BookReview?> getMyReview(String bookId) async {
    final user = _auth.currentUser;

    if (user == null) return null;

    final snapshot = await _reviews.doc('${bookId}_${user.uid}').get();

    if (!snapshot.exists) return null;

    return BookReview.fromMap(snapshot.id, snapshot.data()!);
  }

  /// Submit a new review or update the existing review.
  Future<void> submitReview({
    required String bookId,
    required int rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please log in to submit a review.');
    }

    if (bookId.trim().isEmpty) {
      throw StateError('Book information is missing.');
    }

    if (rating < 1 || rating > 5) {
      throw StateError('Please select a rating from 1 to 5 stars.');
    }

    if (comment.trim().length > 1000) {
      throw StateError('Your review cannot exceed 1000 characters.');
    }

    // Client-side check for a helpful message.
    // Firestore Rules independently enforce the same restriction.
    final eligible = await canReviewBook(bookId);

    if (!eligible) {
      throw StateError(
        'You can review this book after your order is delivered.',
      );
    }

    final reviewId = '${bookId}_${user.uid}';
    final reviewRef = _reviews.doc(reviewId);
    final existing = await reviewRef.get();

    final reviewData = <String, dynamic>{
      'bookId': bookId,
      'userId': user.uid,
      'userName': user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Customer',
      'rating': rating,
      'comment': comment.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (existing.exists) {
      await reviewRef.update(reviewData);
    } else {
      reviewData['createdAt'] = FieldValue.serverTimestamp();
      await reviewRef.set(reviewData);
    }
  }

  /// Delete the current user's own review.
  Future<void> deleteMyReview(String bookId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please log in to delete your review.');
    }

    await _reviews.doc('${bookId}_${user.uid}').delete();
  }
}
