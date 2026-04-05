import 'package:flutter/material.dart';

class CategoryUtils {
  static IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      // Expense categories
      case 'food':
        return Icons.fastfood_rounded;
      case 'food & drink':
        return Icons.fastfood_rounded;
      case 'groceries':
        return Icons.shopping_cart_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'personal care':
        return Icons.spa_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'rent':
        return Icons.home_rounded;
      case 'taxes':
        return Icons.account_balance_rounded;
      case 'insurance':
        return Icons.security_rounded;
      case 'gifts':
        return Icons.card_giftcard_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'bike':
        return Icons.directions_bike_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'others(expense)':
        return Icons.more_horiz_rounded;
      // Income categories
      case 'salary':
        return Icons.work_rounded;
      case 'sold item':
        return Icons.sell_rounded;
      case 'coupons':
        return Icons.local_offer_rounded;
      case 'others(income)':
        return Icons.more_horiz_rounded;
      // Legacy / misc
      case 'entertainment':
        return Icons.movie_rounded;
      case 'utilities':
        return Icons.bolt_rounded;
      case 'freelance':
        return Icons.computer_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  static Color getColor(String category) {
    switch (category.toLowerCase()) {
      // Expense categories
      case 'food':
        return const Color(0xFFEF4444);
      case 'food & drink':
        return Colors.orange;
      case 'groceries':
        return const Color(0xFF22C55E);
      case 'travel':
        return const Color(0xFF06B6D4);
      case 'medical':
        return const Color(0xFFA855F7);
      case 'personal care':
        return const Color(0xFFEC4899);
      case 'education':
        return const Color(0xFF3B82F6);
      case 'bills':
        return const Color(0xFF8B5CF6);
      case 'rent':
        return const Color(0xFF2563EB);
      case 'taxes':
        return const Color(0xFF6B7280);
      case 'insurance':
        return const Color(0xFF7C3AED);
      case 'gifts':
        return const Color(0xFF0D9488);
      case 'movie':
        return const Color(0xFF9333EA);
      case 'bike':
        return const Color(0xFFB45309);
      case 'transport':
        return const Color(0xFFF97316);
      case 'shopping':
        return const Color(0xFF16A34A);
      case 'others(expense)':
        return const Color(0xFFE879A8);
      // Income categories
      case 'salary':
        return const Color(0xFF84CC16);
      case 'sold item':
        return const Color(0xFF9CA3AF);
      case 'coupons':
        return const Color(0xFFEAB308);
      case 'others(income)':
        return const Color(0xFFF59E0B);
      // Legacy / misc
      case 'entertainment':
        return Colors.pink;
      case 'utilities':
        return Colors.amber;
      case 'freelance':
        return Colors.lightBlue;
      default:
        final int colorIndex = category.hashCode.abs() % Colors.primaries.length;
        return Colors.primaries[colorIndex];
    }
  }

  // --- Category lists ---
  static const List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Food', 'icon': Icons.fastfood_rounded, 'color': Color(0xFFEF4444)},
    {'name': 'Groceries', 'icon': Icons.shopping_cart_rounded, 'color': Color(0xFF22C55E)},
    {'name': 'Travel', 'icon': Icons.flight_rounded, 'color': Color(0xFF06B6D4)},
    {'name': 'Medical', 'icon': Icons.medical_services_rounded, 'color': Color(0xFFA855F7)},
    {'name': 'Personal Care', 'icon': Icons.spa_rounded, 'color': Color(0xFFEC4899)},
    {'name': 'Education', 'icon': Icons.school_rounded, 'color': Color(0xFF3B82F6)},
    {'name': 'Bills', 'icon': Icons.receipt_long_rounded, 'color': Color(0xFF8B5CF6)},
    {'name': 'Rent', 'icon': Icons.home_rounded, 'color': Color(0xFF2563EB)},
    {'name': 'Taxes', 'icon': Icons.account_balance_rounded, 'color': Color(0xFF6B7280)},
    {'name': 'Insurance', 'icon': Icons.security_rounded, 'color': Color(0xFF7C3AED)},
    {'name': 'Gifts', 'icon': Icons.card_giftcard_rounded, 'color': Color(0xFF0D9488)},
    {'name': 'Movie', 'icon': Icons.movie_rounded, 'color': Color(0xFF9333EA)},
    {'name': 'Bike', 'icon': Icons.directions_bike_rounded, 'color': Color(0xFFB45309)},
    {'name': 'Transport', 'icon': Icons.directions_car_rounded, 'color': Color(0xFFF97316)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_rounded, 'color': Color(0xFF16A34A)},
    {'name': 'Others(Expense)', 'icon': Icons.more_horiz_rounded, 'color': Color(0xFFE879A8)},
  ];

  static const List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Salary', 'icon': Icons.work_rounded, 'color': Color(0xFF84CC16)},
    {'name': 'Sold Item', 'icon': Icons.sell_rounded, 'color': Color(0xFF9CA3AF)},
    {'name': 'Coupons', 'icon': Icons.local_offer_rounded, 'color': Color(0xFFEAB308)},
    {'name': 'Others(Income)', 'icon': Icons.more_horiz_rounded, 'color': Color(0xFFF59E0B)},
  ];
}