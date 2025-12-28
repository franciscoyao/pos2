import 'package:flutter/material.dart';
import 'package:pos_system/data/database/database.dart';

class KioskCategorySidebar extends StatelessWidget {
  final List<Category> categories;
  final int? selectedCategoryId;
  final ValueChanged<int> onCategorySelected;

  const KioskCategorySidebar({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130, // Fixed width
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 24),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.id == selectedCategoryId;

          return GestureDetector(
            onTap: () => onCategorySelected(category.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF212121)
                    : Colors.grey[50], // Premium approach: Dark selected
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getCategoryIcon(category.name),
                    color: isSelected ? Colors.white : Colors.grey[400],
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 12,
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

  IconData _getCategoryIcon(String categoryName) {
    if (categoryName.toLowerCase().contains('burger')) {
      return Icons.lunch_dining;
    }
    if (categoryName.toLowerCase().contains('pizza')) {
      return Icons.local_pizza;
    }
    if (categoryName.toLowerCase().contains('drink') ||
        categoryName.toLowerCase().contains('beverage')) {
      return Icons.local_bar;
    }
    if (categoryName.toLowerCase().contains('dessert') ||
        categoryName.toLowerCase().contains('sweet')) {
      return Icons.icecream;
    }
    if (categoryName.toLowerCase().contains('salad') ||
        categoryName.toLowerCase().contains('vegan')) {
      return Icons.grass;
    }
    if (categoryName.toLowerCase().contains('side') ||
        categoryName.toLowerCase().contains('fries')) {
      return Icons.tapas;
    }
    if (categoryName.toLowerCase().contains('coffee')) {
      return Icons.coffee;
    }
    return Icons.restaurant;
  }
}
