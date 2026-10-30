class BannerModel {
  final String tag;
  final String title;
  final String highlight;
  final String subtitle;
  final String buttonText;
  final String imagePath;

  /// Optional filters applied when the banner button is tapped.
  final String? category;
  final String? query;

  const BannerModel({
    required this.tag,
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.buttonText,
    required this.imagePath,
    this.category,
    this.query,
  });
}
