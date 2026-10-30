import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/book_model.dart';
import '../models/cart_item_model.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _cartCollection() {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please log in to use your cart.');
    }

    return _firestore.collection('users').doc(user.uid).collection('cart');
  }

  Stream<List<CartItemModel>> getCartItems() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(<CartItemModel>[]);

      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (document) =>
                      CartItemModel.fromMap(document.id, document.data()),
                )
                .toList(),
          );
    });
  }

  Future<void> addToCart(BookModel book) async {
    if (_auth.currentUser == null) {
      throw StateError('Please log in to add books to your cart.');
    }

    if (book.stock <= 0) {
      throw StateError('This book is currently out of stock.');
    }

    final collection = _cartCollection();
    final itemRef = collection.doc(book.id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(itemRef);

      if (snapshot.exists) {
        final data = snapshot.data()!;
        final currentQuantity = (data['quantity'] as num?)?.toInt() ?? 1;

        if (currentQuantity >= book.stock) {
          throw StateError('You cannot add more than the available stock.');
        }

        transaction.update(itemRef, {
          'quantity': currentQuantity + 1,
          'stock': book.stock,
          'price': book.price,
          'title': book.title,
          'author': book.author,
          'imageUrl': book.imageUrl,
          'category': book.category,
        });
      } else {
        transaction.set(itemRef, {
          'title': book.title,
          'author': book.author,
          'imageUrl': book.imageUrl,
          'category': book.category,
          'price': book.price,
          'quantity': 1,
          'stock': book.stock,
        });
      }
    });
  }

  Future<void> updateQuantity(CartItemModel item, int newQuantity) async {
    final itemRef = _cartCollection().doc(item.bookId);

    if (newQuantity <= 0) {
      await itemRef.delete();
      return;
    }

    if (newQuantity > item.stock) {
      throw StateError('Only ${item.stock} copies are available.');
    }

    await itemRef.update({'quantity': newQuantity});
  }

  Future<void> removeFromCart(String bookId) async {
    await _cartCollection().doc(bookId).delete();
  }

  Future<void> clearCart() async {
    final collection = _cartCollection();
    final snapshot = await collection.get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();

    for (final document in snapshot.docs) {
      batch.delete(document.reference);
    }

    await batch.commit();
  }
}
