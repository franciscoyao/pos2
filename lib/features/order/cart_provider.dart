import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/data/database/database.dart';

// Simple cart state
class CartItem {
  final MenuItem menuItem;
  int quantity;
  String? note;
  double? overriddenPrice;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.note,
    this.overriddenPrice,
  });

  double get total => (overriddenPrice ?? menuItem.price) * quantity;
}

class CartState {
  final List<CartItem> items;
  final String? tableNumber;
  final String type; // 'dine-in' or 'takeaway'

  CartState({this.items = const [], this.tableNumber, this.type = 'takeaway'});

  CartState copyWith({
    List<CartItem>? items,
    String? tableNumber,
    String? type,
  }) {
    return CartState(
      items: items ?? this.items,
      tableNumber: tableNumber ?? this.tableNumber,
      type: type ?? this.type,
    );
  }

  double get total => items.fold(0, (sum, item) => sum + item.total);
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return CartState();
  }

  void setType(String type) {
    state = state.copyWith(type: type);
  }

  void setTableNumber(String tableNumber) {
    state = state.copyWith(tableNumber: tableNumber);
  }

  void addItem(MenuItem item) {
    if (item.status != 'active') return;
    final existingIndex = state.items.indexWhere(
      (i) => i.menuItem.id == item.id,
    );
    if (existingIndex >= 0) {
      final newItems = List<CartItem>.from(state.items);
      newItems[existingIndex].quantity++;
      state = state.copyWith(items: newItems);
    } else {
      state = state.copyWith(
        items: [
          ...state.items,
          CartItem(menuItem: item),
        ],
      );
    }
  }

  void updateItemNote(MenuItem item, String note) {
    final existingIndex = state.items.indexWhere(
      (i) => i.menuItem.id == item.id,
    );
    if (existingIndex >= 0) {
      final newItems = List<CartItem>.from(state.items);
      final currentItem = newItems[existingIndex];
      newItems[existingIndex] = CartItem(
        menuItem: currentItem.menuItem,
        quantity: currentItem.quantity,
        note: note,
        overriddenPrice: currentItem.overriddenPrice,
      );
      state = state.copyWith(items: newItems);
    }
  }

  void updateItemPrice(MenuItem item, double price) {
    final existingIndex = state.items.indexWhere(
      (i) => i.menuItem.id == item.id,
    );
    if (existingIndex >= 0) {
      final newItems = List<CartItem>.from(state.items);
      final currentItem = newItems[existingIndex];
      newItems[existingIndex] = CartItem(
        menuItem: currentItem.menuItem,
        quantity: currentItem.quantity,
        note: currentItem.note,
        overriddenPrice: price,
      );
      state = state.copyWith(items: newItems);
    }
  }

  void removeItem(MenuItem item) {
    final existingIndex = state.items.indexWhere(
      (i) => i.menuItem.id == item.id,
    );
    if (existingIndex >= 0) {
      final newItems = List<CartItem>.from(state.items);
      if (newItems[existingIndex].quantity > 1) {
        newItems[existingIndex].quantity--;
        state = state.copyWith(items: newItems);
      } else {
        newItems.removeAt(existingIndex);
        state = state.copyWith(items: newItems);
      }
    }
  }

  void clear() {
    state = CartState(type: state.type); // Keep type but clear items
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);
