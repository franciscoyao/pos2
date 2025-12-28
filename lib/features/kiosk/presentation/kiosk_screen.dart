import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:pos_system/data/database/database.dart';
import 'package:pos_system/data/repositories/menu_repository.dart';
import 'package:pos_system/data/repositories/order_repository.dart';
import 'package:pos_system/features/order/cart_provider.dart';
import 'package:pos_system/features/kiosk/presentation/widgets/kiosk_header.dart';
import 'package:pos_system/features/kiosk/presentation/widgets/kiosk_category_sidebar.dart';
import 'package:pos_system/features/kiosk/presentation/widgets/kiosk_menu_grid.dart';
import 'package:pos_system/features/kiosk/presentation/widgets/kiosk_cart_drawer.dart';
import 'package:pos_system/features/kiosk/presentation/widgets/kiosk_checkout_dialog.dart';

class KioskScreen extends ConsumerStatefulWidget {
  const KioskScreen({super.key});

  @override
  ConsumerState<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends ConsumerState<KioskScreen> {
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider.notifier).clear();
      ref.read(cartProvider.notifier).setType('takeaway');
    });
  }

  void _onCheckout() {
    final cart = ref.read(cartProvider);
    showDialog(
      context: context,
      builder: (context) => KioskCheckoutDialog(
        totalAmount: cart.total,
        onConfirm: () {
          Navigator.pop(context); // Close dialog
          _submitOrder();
        },
      ),
    );
  }

  Future<void> _submitOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) return;

    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final order = OrdersCompanion(
        orderNumber: drift.Value('K-ORD-$timestamp'),
        tableNumber: const drift.Value('Kiosk 1'),
        type: drift.Value(cart.type),
        totalAmount: drift.Value(cart.total),
        status: const drift.Value('pending'),
        paymentMethod: const drift.Value('card'),
      );

      final orderItems = cart.items.map((item) {
        return OrderItemsCompanion(
          menuItemId: drift.Value(item.menuItem.id),
          quantity: drift.Value(item.quantity),
          priceAtTime: drift.Value(item.total / item.quantity),
          status: const drift.Value('pending'),
        );
      }).toList();

      await orderRepo.submitOrder(order: order, items: orderItems);

      if (mounted) {
        ref.read(cartProvider.notifier).clear();
        _showSuccessAnimation();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 80, color: Colors.green),
                const SizedBox(height: 24),
                const Text(
                  'Order Placed!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Please collect your receipt.'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close success dialog
                  },
                  child: const Text('Start New Order'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesStream = ref
        .watch(menuRepositoryProvider)
        .watchCategories();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Row(
        children: [
          // Main Content Area
          Expanded(
            flex: 3,
            child: Column(
              children: [
                const KioskHeader(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar
                      StreamBuilder<List<Category>>(
                        stream: categoriesStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const SizedBox(width: 130);
                          }
                          if (!snapshot.hasData) {
                            return const SizedBox(
                              width: 130,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final categories = snapshot.data!;
                          if (categories.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          // Set default selection
                          if (_selectedCategoryId == null &&
                              categories.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(
                                  () =>
                                      _selectedCategoryId = categories.first.id,
                                );
                              }
                            });
                          }

                          return KioskCategorySidebar(
                            categories: categories,
                            selectedCategoryId: _selectedCategoryId,
                            onCategorySelected: (id) =>
                                setState(() => _selectedCategoryId = id),
                          );
                        },
                      ),

                      // Grid
                      Expanded(
                        child: _selectedCategoryId == null
                            ? const Center(
                                child: Text('Please select a category'),
                              )
                            : Consumer(
                                builder: (context, ref, child) {
                                  // Watch specific category items
                                  final itemsStream = ref
                                      .watch(menuRepositoryProvider)
                                      .watchItemsByCategory(
                                        _selectedCategoryId!,
                                      );

                                  return StreamBuilder<List<MenuItem>>(
                                    stream: itemsStream,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Text(
                                            'Error: ${snapshot.error}',
                                          ),
                                        );
                                      }
                                      if (!snapshot.hasData) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      return KioskMenuGrid(
                                        items: snapshot.data!,
                                        onItemSelected: (item) {
                                          ref
                                              .read(cartProvider.notifier)
                                              .addItem(item);
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cart Drawer
          Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: KioskCartDrawer(onCheckout: _onCheckout),
          ),
        ],
      ),
    );
  }
}
