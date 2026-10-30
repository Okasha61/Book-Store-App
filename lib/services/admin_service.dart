import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/book_model.dart';

class AdminService {
  AdminService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const String adminUid = 'fOztvfecJdccyg6wref0AnE2FJg1';

  bool get isAdmin => _auth.currentUser?.uid == adminUid;

  void _requireAdmin() {
    if (!isAdmin) {
      throw StateError(
        'Only the authorized administrator can perform this action.',
      );
    }
  }

  Stream<List<BookModel>> watchBooks() {
    return _db
        .collection('books')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCustomers() {
    _requireAdmin();
    return _db.collection('users').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchReviews() {
    _requireAdmin();
    return _db.collection('book_reviews').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCategories() {
    _requireAdmin();
    return _db.collection('categories').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAllOrders() {
    _requireAdmin();
    return _db
        .collectionGroup('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addCategory({
    required String name,
    String description = '',
  }) async {
    _requireAdmin();

    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError('Category name is required.');
    }

    final duplicate = await _db
        .collection('categories')
        .where('nameLower', isEqualTo: trimmed.toLowerCase())
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) {
      throw StateError('This category already exists.');
    }

    await _db.collection('categories').add({
      'name': trimmed,
      'nameLower': trimmed.toLowerCase(),
      'description': description.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': _auth.currentUser!.uid,
    });
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String description,
  }) async {
    _requireAdmin();

    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError('Category name is required.');
    }

    final duplicate = await _db
        .collection('categories')
        .where('nameLower', isEqualTo: trimmed.toLowerCase())
        .get();

    if (duplicate.docs.any((doc) => doc.id != id)) {
      throw StateError('Another category already uses this name.');
    }

    await _db.collection('categories').doc(id).update({
      'name': trimmed,
      'nameLower': trimmed.toLowerCase(),
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String id) async {
    _requireAdmin();
    await _db.collection('categories').doc(id).delete();
  }
}
