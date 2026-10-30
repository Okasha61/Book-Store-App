import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please log in to use your wishlist.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _wishlistCollection {
    return _firestore.collection('users').doc(_userId).collection('wishlist');
  }

  Stream<List<String>> watchWishlistBookIds() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(<String>[]);
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map((document) => document.id).toList(),
          );
    });
  }

  Future<bool> isWishlisted(String bookId) async {
    final document = await _wishlistCollection.doc(bookId).get();
    return document.exists;
  }

  Future<void> addToWishlist(String bookId) async {
    await _wishlistCollection.doc(bookId).set({
      'bookId': bookId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFromWishlist(String bookId) async {
    await _wishlistCollection.doc(bookId).delete();
  }

  Future<void> toggleWishlist(String bookId) async {
    final document = _wishlistCollection.doc(bookId);
    final snapshot = await document.get();

    if (snapshot.exists) {
      await document.delete();
    } else {
      await document.set({
        'bookId': bookId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
