import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_item_model.dart';

class OrderService {
  OrderService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String adminUid = 'fOztvfecJdccyg6wref0AnE2FJg1';

  static const List<String> orderStatuses = <String>[
    'Pending',
    'Confirmed',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  static const Map<String, Set<String>> allowedTransitions =
      <String, Set<String>>{
        'Pending': <String>{'Confirmed', 'Cancelled'},
        'Confirmed': <String>{'Processing', 'Cancelled'},
        'Processing': <String>{'Shipped', 'Cancelled'},
        'Shipped': <String>{'Delivered'},
        'Delivered': <String>{},
        'Cancelled': <String>{},
      };

  bool get isCurrentUserAdmin => _auth.currentUser?.uid == adminUid;

  Future<String> placeOrder({
    required String customerName,
    required String phone,
    required String address,
    required List<CartItemModel> items,
    required double deliveryFee,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please log in before placing an order.');
    }
    if (customerName.trim().isEmpty) {
      throw StateError('Please enter your full name.');
    }
    if (phone.trim().isEmpty) {
      throw StateError('Please enter your phone number.');
    }
    if (address.trim().isEmpty) {
      throw StateError('Please enter your delivery address.');
    }
    if (items.isEmpty) {
      throw StateError('Your cart is empty.');
    }
    if (!deliveryFee.isFinite || deliveryFee < 0) {
      throw StateError('Invalid delivery fee.');
    }

    final bookIds = <String>{};

    for (final item in items) {
      if (item.bookId.trim().isEmpty) {
        throw StateError('Invalid book in your cart.');
      }
      if (!bookIds.add(item.bookId)) {
        throw StateError(
          'Duplicate books were found in your cart. Please refresh your cart.',
        );
      }
      if (item.quantity <= 0) {
        throw StateError('Invalid quantity for "${item.title}".');
      }
    }

    final userRef = _firestore.collection('users').doc(user.uid);
    final cartCollection = userRef.collection('cart');
    final orderRef = userRef.collection('orders').doc();

    final initialCartSnapshot = await cartCollection.get();

    if (initialCartSnapshot.docs.isEmpty) {
      throw StateError('Your cart is empty. Add books before checkout.');
    }

    final cartIds = initialCartSnapshot.docs.map((doc) => doc.id).toSet();

    if (bookIds.length != cartIds.length || !bookIds.containsAll(cartIds)) {
      throw StateError(
        'Your cart changed. Please return to the cart and try again.',
      );
    }

    final bookRefs = <String, DocumentReference<Map<String, dynamic>>>{};
    final cartRefs = <String, DocumentReference<Map<String, dynamic>>>{};

    for (final item in items) {
      bookRefs[item.bookId] = _firestore.collection('books').doc(item.bookId);
      cartRefs[item.bookId] = cartCollection.doc(item.bookId);
    }

    await _firestore.runTransaction((transaction) async {
      final bookSnapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      final cartSnapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};

      for (final entry in bookRefs.entries) {
        bookSnapshots[entry.key] = await transaction.get(entry.value);
      }

      for (final entry in cartRefs.entries) {
        cartSnapshots[entry.key] = await transaction.get(entry.value);
      }

      final orderItems = <Map<String, dynamic>>[];
      double subtotal = 0;

      for (final item in items) {
        final bookSnapshot = bookSnapshots[item.bookId]!;
        final cartSnapshot = cartSnapshots[item.bookId]!;

        if (!bookSnapshot.exists || !cartSnapshot.exists) {
          throw StateError(
            'A book or cart item is no longer available. Please refresh your cart.',
          );
        }

        final bookData = bookSnapshot.data()!;
        final cartData = cartSnapshot.data()!;

        final currentQuantity = (cartData['quantity'] as num?)?.toInt() ?? 0;
        final currentStock = (bookData['stock'] as num?)?.toInt() ?? 0;
        final currentPrice = (bookData['price'] as num?)?.toDouble() ?? 0;

        if (currentQuantity != item.quantity) {
          throw StateError(
            'Your cart quantity changed for "${item.title}". Please refresh your cart.',
          );
        }
        if (currentQuantity <= 0) {
          throw StateError('Invalid quantity for "${item.title}".');
        }
        if (!currentPrice.isFinite || currentPrice < 0) {
          throw StateError('Invalid price for "${item.title}".');
        }
        if (currentStock < item.quantity) {
          throw StateError(
            'Not enough stock for "${item.title}". Please update your cart.',
          );
        }

        final itemTotal = currentPrice * item.quantity;
        subtotal += itemTotal;

        orderItems.add(<String, dynamic>{
          'bookId': item.bookId,
          'title': bookData['title'] as String? ?? item.title,
          'author': bookData['author'] as String? ?? item.author,
          'imageUrl': bookData['imageUrl'] as String? ?? item.imageUrl,
          'category': bookData['category'] as String? ?? item.category,
          'price': currentPrice,
          'quantity': item.quantity,
          'itemTotal': itemTotal,
        });
      }

      final total = subtotal + deliveryFee;

      if (!subtotal.isFinite || !total.isFinite) {
        throw StateError('Unable to calculate your order total.');
      }

      transaction.set(orderRef, <String, dynamic>{
        'userId': user.uid,
        'customerName': customerName.trim(),
        'email': user.email ?? '',
        'phone': phone.trim(),
        'address': address.trim(),
        'items': orderItems,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'status': 'Pending',
        'paymentMethod': 'Cash on Delivery',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (final reference in cartRefs.values) {
        transaction.delete(reference);
      }
    });

    return orderRef.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMyOrders() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.error(StateError('Please log in to view your orders.'));
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchMyOrder(String orderId) {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.error(StateError('Please log in to view your order.'));
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .doc(orderId)
        .snapshots();
  }

  Future<void> cancelMyOrder(String orderId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please log in to cancel an order.');
    }

    final orderRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .doc(orderId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderRef);

      if (!snapshot.exists) {
        throw StateError('This order no longer exists.');
      }

      final data = snapshot.data()!;
      final status = data['status']?.toString() ?? 'Pending';

      if (!(allowedTransitions[status] ?? <String>{}).contains('Cancelled')) {
        throw StateError(
          'This order cannot be cancelled at its current status.',
        );
      }

      transaction.update(orderRef, <String, dynamic>{
        'status': 'Cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllOrders() {
    if (!isCurrentUserAdmin) {
      return Stream.error(StateError('Admin access is required.'));
    }

    return _firestore
        .collectionGroup('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateOrderStatus({
    required String userId,
    required String orderId,
    required String newStatus,
  }) async {
    if (!isCurrentUserAdmin) {
      throw StateError('Only the administrator can update order status.');
    }

    if (!orderStatuses.contains(newStatus)) {
      throw StateError('Invalid order status.');
    }

    if (userId.trim().isEmpty || orderId.trim().isEmpty) {
      throw StateError('Order or customer information is missing.');
    }

    final admin = _auth.currentUser;

    if (admin == null) {
      throw StateError('Please log in as administrator.');
    }

    final orderRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderRef);

      if (!snapshot.exists) {
        throw StateError('Order not found for this customer.');
      }

      final data = snapshot.data()!;
      final storedUserId = data['userId']?.toString() ?? '';

      if (storedUserId.isNotEmpty && storedUserId != userId) {
        throw StateError(
          'This order does not belong to the selected customer.',
        );
      }

      final oldStatus = data['status']?.toString() ?? 'Pending';

      if (oldStatus == newStatus) return;

      final nextStatuses = allowedTransitions[oldStatus] ?? <String>{};

      if (!nextStatuses.contains(newStatus)) {
        throw StateError(
          'Status cannot be changed from $oldStatus to $newStatus.',
        );
      }

      final update = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': admin.uid,
      };

      if (newStatus == 'Confirmed') {
        update['confirmedAt'] = FieldValue.serverTimestamp();
      }
      if (newStatus == 'Processing') {
        update['processingAt'] = FieldValue.serverTimestamp();
      }
      if (newStatus == 'Shipped') {
        update['shippedAt'] = FieldValue.serverTimestamp();
      }
      if (newStatus == 'Delivered') {
        update['deliveredAt'] = FieldValue.serverTimestamp();
      }
      if (newStatus == 'Cancelled') {
        update['cancelledAt'] = FieldValue.serverTimestamp();
        update['cancelledBy'] = admin.uid;
      }

      transaction.update(orderRef, update);

      if (newStatus == 'Delivered') {
        final rawItems = data['items'];
        final items = rawItems is List ? rawItems : <dynamic>[];

        final userRef = _firestore.collection('users').doc(userId);

        for (final rawItem in items) {
          if (rawItem is! Map) continue;

          final bookId = rawItem['bookId']?.toString() ?? '';

          if (bookId.isEmpty) continue;

          final deliveredRef = userRef
              .collection('delivered_books')
              .doc(bookId);

          transaction.set(deliveredRef, <String, dynamic>{
            'bookId': bookId,
            'title': rawItem['title']?.toString() ?? 'Book',
            'orderId': orderId,
            'deliveredAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    });
  }
}
