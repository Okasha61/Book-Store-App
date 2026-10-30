import 'package:flutter/material.dart';

import '../models/cart_item_model.dart';

class AppColors {
  AppColors._();

  static const Color headerDark = Color(0xFF0E1A19);
  static const Color searchFill = Color(0xFF2B3534);
  static const Color pageBg = Colors.white;
  static const Color green = Color(0xFF1FA84A);
  static const Color lime = Color(0xFF7BE779);
  static const Color textPrimary = Color(0xFF0F1A17);
  static const Color textSecondary = Color(0xFF6B7773);
  static const Color border = Color(0xFFEAEEEC);
  static const Color coverBg = Color(0xFFF3F5F4);
  static const Color star = Color(0xFFFFB400);
  static const Color heart = Color(0xFFE53935);
}

/// Delivery fee rules used by the home offer card and checkout.
/// Rs. 100 when the customer buys 2 or more books, otherwise Rs. 200.
class DeliveryRules {
  DeliveryRules._();

  static const double standardFee = 200;
  static const double discountedFee = 100;
  static const int discountMinBooks = 2;

  static double feeFor(Iterable<CartItemModel> items) {
    final books = items.fold<int>(0, (sum, item) => sum + item.quantity);
    return books >= discountMinBooks ? discountedFee : standardFee;
  }
}
