import 'package:flutter/material.dart';

import '../../models/banner_model.dart';
import '../../models/book_model.dart';
import '../../models/category_model.dart';
import '../../services/banner_service.dart';
import '../../services/book_service.dart';
import '../../services/category_service.dart';
import '../../services/review_service.dart';
import '../../utils/constants.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/book_card.dart';
import '../../widgets/category_list.dart';
import '../../widgets/free_delivery_card.dart';
import '../../widgets/home_header.dart';
import '../../widgets/section_header.dart';
import '../books/books_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenCategories});

  /// Lets MainScreen switch to the Categories tab for "See All".
  final VoidCallback? onOpenCategories;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BookService _bookService = BookService();
  final CategoryService _categoryService = CategoryService();
  final ReviewService _reviewService = ReviewService();
  final BannerService _bannerService = BannerService();

  late Stream<List<BookModel>> _books;
  late Stream<List<CategoryModel>> _categories;
  late Stream<Map<String, RatingSummary>> _ratings;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _books = _bookService.getBooks();
    _categories = _categoryService.watchCategories();
    _ratings = _reviewService.watchRatingSummaries();
  }

  void _openBooks({String? category, String? query}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            BooksScreen(initialCategory: category, initialQuery: query),
      ),
    );
  }

  void _openBanner(BannerModel banner) {
    _openBooks(category: banner.category, query: banner.query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bottomls.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(color: AppColors.pageBg);
            },
          ),
          const ColoredBox(color: Color(0x6600100E)),
          Column(
            children: [
              HomeHeader(onSearch: (query) => _openBooks(query: query)),
              Expanded(
                child: StreamBuilder<List<BookModel>>(
                  stream: _books,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _errorState();
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.green,
                        ),
                      );
                    }

                    return _content(snapshot.data!);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _content(List<BookModel> books) {
    final featured = books.where((book) => book.isFeatured).toList();
    final shown = (featured.isNotEmpty ? featured : books).take(10).toList();

    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 28),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: BannerCarousel(
            banners: _bannerService.getBanners(),
            onTap: _openBanner,
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SectionHeader(
            title: 'Shop by Category',
            onSeeAll: widget.onOpenCategories,
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder<List<CategoryModel>>(
          stream: _categories,
          builder: (context, snapshot) {
            final categories = CategoryService.resolve(
              snapshot.data ?? const <CategoryModel>[],
              books,
            );

            if (categories.isEmpty) {
              return _hint('Categories will appear here soon.');
            }

            return CategoryList(
              categories: categories,
              onTap: (category) => _openBooks(category: category.name),
            );
          },
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SectionHeader(
            title: 'Featured Books',
            onSeeAll: () => _openBooks(),
          ),
        ),
        const SizedBox(height: 14),
        if (shown.isEmpty)
          _hint('No books available yet.')
        else
          StreamBuilder<Map<String, RatingSummary>>(
            stream: _ratings,
            builder: (context, snapshot) {
              final ratings = snapshot.data ?? const <String, RatingSummary>{};

              return SizedBox(
                height: 296,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                  itemCount: shown.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final book = shown[index];
                    return BookCard(book: book, rating: ratings[book.id]);
                  },
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FreeDeliveryCard(onTap: () => _openBooks()),
        ),
      ],
    );
  }

  Widget _hint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 60,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load books',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => setState(_connect),
              style: FilledButton.styleFrom(backgroundColor: AppColors.green),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
