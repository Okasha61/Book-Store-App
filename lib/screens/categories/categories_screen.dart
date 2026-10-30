import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/book_model.dart';
import '../../models/category_model.dart';
import '../../services/book_service.dart';
import '../../services/category_service.dart';
import '../../utils/constants.dart';
import '../books/books_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final Stream<List<BookModel>> _books = BookService().getBooks();
  late final Stream<List<CategoryModel>> _categories = CategoryService()
      .watchCategories();

  void _open({String? category}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BooksScreen(initialCategory: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.headerDark,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<BookModel>>(
        stream: _books,
        builder: (context, bookSnapshot) {
          if (bookSnapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load categories.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          if (!bookSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            );
          }

          final books = bookSnapshot.data!;

          return StreamBuilder<List<CategoryModel>>(
            stream: _categories,
            builder: (context, categorySnapshot) {
              final categories = CategoryService.resolve(
                categorySnapshot.data ?? const <CategoryModel>[],
                books,
              );

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 900
                      ? 5
                      : width >= 600
                      ? 4
                      : 3;

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: categories.length + 1,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _tile(
                          icon: Icons.library_books_rounded,
                          fg: AppColors.green,
                          bg: const Color(0xFFE3F8E6),
                          name: 'All Books',
                          count: books.length,
                          onTap: () => _open(),
                        );
                      }

                      final category = categories[index - 1];
                      final style = category.style;

                      return _tile(
                        icon: style.icon,
                        fg: style.fg,
                        bg: style.bg,
                        name: category.name,
                        count: CategoryService.countBooks(books, category.name),
                        onTap: () => _open(category: category.name),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required Color fg,
    required Color bg,
    required String name,
    required int count,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 34),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$count ${count == 1 ? 'book' : 'books'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
