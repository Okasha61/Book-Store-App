import 'package:flutter/material.dart';

class CategoryStyle {
  const CategoryStyle({
    required this.label,
    required this.icon,
    required this.fg,
    required this.bg,
  });

  final String label;
  final IconData icon;
  final Color fg;
  final Color bg;
}

/// Icon keys the admin can choose from. The key is stored in Firestore
/// in the `icon` field of each category document.
class CategoryStyles {
  CategoryStyles._();

  static const Map<String, CategoryStyle> all = {
    'book': CategoryStyle(
      label: 'Book',
      icon: Icons.menu_book_rounded,
      fg: Color(0xFF1B8A3E),
      bg: Color(0xFFE3F8E6),
    ),
    'psychology': CategoryStyle(
      label: 'Mind',
      icon: Icons.psychology_rounded,
      fg: Color(0xFF7C5CDB),
      bg: Color(0xFFEEE9FD),
    ),
    'school': CategoryStyle(
      label: 'Education',
      icon: Icons.school_rounded,
      fg: Color(0xFF2F6FD6),
      bg: Color(0xFFE3EEFD),
    ),
    'laptop': CategoryStyle(
      label: 'Technology',
      icon: Icons.laptop_mac_rounded,
      fg: Color(0xFFC7742A),
      bg: Color(0xFFFDEBDD),
    ),
    'health': CategoryStyle(
      label: 'Health',
      icon: Icons.monitor_heart_rounded,
      fg: Color(0xFFE0394B),
      bg: Color(0xFFFDE4E6),
    ),
    'kids': CategoryStyle(
      label: 'Kids',
      icon: Icons.sentiment_satisfied_alt_rounded,
      fg: Color(0xFF1BA38A),
      bg: Color(0xFFDDF8F1),
    ),
    'history': CategoryStyle(
      label: 'History',
      icon: Icons.history_edu_rounded,
      fg: Color(0xFF8A5A2B),
      bg: Color(0xFFF5EBDD),
    ),
    'science': CategoryStyle(
      label: 'Science',
      icon: Icons.science_rounded,
      fg: Color(0xFF0F8FB0),
      bg: Color(0xFFDDF3F9),
    ),
    'business': CategoryStyle(
      label: 'Business',
      icon: Icons.business_center_rounded,
      fg: Color(0xFF3B4A9E),
      bg: Color(0xFFE5E8FA),
    ),
    'art': CategoryStyle(
      label: 'Art',
      icon: Icons.palette_rounded,
      fg: Color(0xFFD1478F),
      bg: Color(0xFFFCE3F0),
    ),
    'food': CategoryStyle(
      label: 'Food',
      icon: Icons.restaurant_rounded,
      fg: Color(0xFFD9661C),
      bg: Color(0xFFFDE8D8),
    ),
    'spiritual': CategoryStyle(
      label: 'Spiritual',
      icon: Icons.self_improvement_rounded,
      fg: Color(0xFF6B7F1E),
      bg: Color(0xFFEEF3D6),
    ),
    'sports': CategoryStyle(
      label: 'Sports',
      icon: Icons.sports_soccer_rounded,
      fg: Color(0xFF2E7D32),
      bg: Color(0xFFE0F1E1),
    ),
    'travel': CategoryStyle(
      label: 'Travel',
      icon: Icons.flight_takeoff_rounded,
      fg: Color(0xFF1565C0),
      bg: Color(0xFFDDEAF8),
    ),
  };

  static bool has(String? key) => key != null && all.containsKey(key);

  static CategoryStyle of(String? key) => all[key] ?? all['book']!;
}

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String icon;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  factory CategoryModel.fromMap(String id, Map<String, dynamic> data) {
    final name = (data['name'] as String? ?? '').trim();
    final icon = data['icon'] as String?;

    return CategoryModel(
      id: id,
      name: name,
      description: data['description'] as String? ?? '',
      icon: CategoryStyles.has(icon) ? icon! : guessIconKey(name),
    );
  }

  CategoryStyle get style => CategoryStyles.of(icon);

  /// Used when a category has no saved icon yet.
  static String guessIconKey(String name) {
    final n = name.toLowerCase();

    bool has(List<String> words) => words.any(n.contains);

    if (has(['kid', 'child'])) return 'kids';
    if (has(['health', 'fitness', 'medic'])) return 'health';
    if (has(['tech', 'comput', 'program', 'software'])) return 'laptop';
    if (has(['self', 'psych', 'motiv'])) return 'psychology';
    if (has(['educ', 'school', 'study', 'academ', 'text'])) return 'school';
    if (has(['hist'])) return 'history';
    if (has(['sci'])) return 'science';
    if (has(['business', 'money', 'financ', 'econom'])) return 'business';
    if (has(['cook', 'food'])) return 'food';
    if (has(['relig', 'spirit', 'islam'])) return 'spiritual';
    if (has(['sport'])) return 'sports';
    if (has(['travel'])) return 'travel';
    if (has(['art', 'design'])) return 'art';
    return 'book';
  }
}
