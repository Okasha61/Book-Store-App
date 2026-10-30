import '../models/banner_model.dart';

/// Banners are hardcoded for now. To make them dynamic later, replace
/// [getBanners] with a Firestore stream and keep BannerModel unchanged.
class BannerService {
  static const List<BannerModel> _banners = [
    BannerModel(
      tag: 'NEW ARRIVALS',
      title: 'Good Books',
      highlight: 'Better Days',
      subtitle: 'Discover new stories, new perspectives and a better you.',
      buttonText: 'Shop Now',
      imagePath: 'assets/images/banner_1.jpg',
    ),
    BannerModel(
      tag: 'READER FAVOURITES',
      title: 'Grow Your',
      highlight: 'Mind Daily',
      subtitle: 'Self help picks to build better habits.',
      buttonText: 'Explore',
      imagePath: 'assets/images/banner_2.jpg',
      category: 'Self Help',
    ),
    BannerModel(
      tag: 'FOR STUDENTS',
      title: 'Learn More',
      highlight: 'Achieve More',
      subtitle: 'Textbooks and study guides for every level.',
      buttonText: 'Browse',
      imagePath: 'assets/images/banner_3.jpg',
      category: 'Education',
    ),
  ];

  List<BannerModel> getBanners() => _banners;
}
