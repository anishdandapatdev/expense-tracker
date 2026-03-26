import 'package:flutter/material.dart';

class CategoryUtils {
  static IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & drink': return Icons.fastfood_rounded;
      case 'transport': return Icons.directions_car_rounded;
      case 'shopping': return Icons.shopping_bag_rounded;
      case 'entertainment': return Icons.movie_rounded;
      case 'salary': return Icons.work_rounded;
      case 'freelance': return Icons.computer_rounded;
      case 'utilities': return Icons.bolt_rounded;
      default: return Icons.category_rounded;
    }
  }

  static Color getColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & drink': return Colors.orange;
      case 'transport': return Colors.blue;
      case 'shopping': return Colors.purple;
      case 'entertainment': return Colors.pink;
      case 'salary': return Colors.teal;
      case 'freelance': return Colors.lightBlue;
      case 'utilities': return Colors.amber;
      default: 
        // Generates a consistent Material color based on the category name's text
        final int colorIndex = category.hashCode.abs() % Colors.primaries.length;
        return Colors.primaries[colorIndex];
    }
  }
}