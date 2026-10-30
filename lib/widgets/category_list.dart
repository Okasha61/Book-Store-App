import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../utils/constants.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({
    super.key,
    required this.categories,
    required this.onTap,
  });

  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final style = category.style;

          return InkWell(
            onTap: () => onTap(category),
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 82,
              child: Column(
                children: [
                  Container(
                    width: 82,
                    height: 72,
                    decoration: BoxDecoration(
                      color: style.bg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(style.icon, color: style.fg, size: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
