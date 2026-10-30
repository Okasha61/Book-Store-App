import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book_model.dart';

class BookService {
  final CollectionReference<Map<String, dynamic>> _booksCollection =
      FirebaseFirestore.instance.collection('books');

  // Fetch all books in real time.
  Stream<List<BookModel>> getBooks() {
    return _booksCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((document) {
        return BookModel.fromMap(document.id, document.data());
      }).toList();
    });
  }

  // Fetch featured books in real time.
  Stream<List<BookModel>> getFeaturedBooks() {
    return _booksCollection
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((document) {
            return BookModel.fromMap(document.id, document.data());
          }).toList();
        });
  }

  // Fetch books by category.
  Stream<List<BookModel>> getBooksByCategory(String category) {
    return _booksCollection
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((document) {
            return BookModel.fromMap(document.id, document.data());
          }).toList();
        });
  }

  // Add a new book to Firestore.
  Future<String> addBook(BookModel book) async {
    final document = await _booksCollection.add(book.toMap());
    return document.id;
  }

  // Update an existing book.
  Future<void> updateBook(BookModel book) async {
    await _booksCollection.doc(book.id).update(book.toMap());
  }

  // Delete a book.
  Future<void> deleteBook(String bookId) async {
    await _booksCollection.doc(bookId).delete();
  }

  // Fetch a single book by ID.
  Future<BookModel?> getBookById(String bookId) async {
    final document = await _booksCollection.doc(bookId).get();

    if (!document.exists) {
      return null;
    }

    return BookModel.fromMap(document.id, document.data()!);
  }
}
