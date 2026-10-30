import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book_model.dart';
import '../models/category_model.dart';

class CategoryService {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('categories');

  Stream<List<CategoryModel>> watchCategories() {
    return _collection.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
          .where((category) => category.name.isNotEmpty)
          .toList();

      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  /// Uses the admin-managed categories. If there are none (or they cannot
  /// be read), falls back to the distinct categories found on the books.
  static List<CategoryModel> resolve(
    List<CategoryModel> saved,
    List<BookModel> books,
  ) {
    if (saved.isNotEmpty) return saved;

    final names = <String>{
      for (final book in books)
        if (book.category.trim().isNotEmpty) book.category.trim(),
    }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return names
        .map(
          (name) => CategoryModel(
            id: name,
            name: name,
            description: '',
            icon: CategoryModel.guessIconKey(name),
          ),
        )
        .toList();
  }

  static int countBooks(List<BookModel> books, String categoryName) {
    final key = categoryName.trim().toLowerCase();
    return books.where((b) => b.category.trim().toLowerCase() == key).length;
  }
}
