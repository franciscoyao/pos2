import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/data/repositories/order_repository.dart';
import 'package:pos_system/features/checkout/checkout_screen.dart';

class CheckoutTableSelectionScreen extends ConsumerWidget {
  const CheckoutTableSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reuse the logic to get active orders
    final activeOrdersStream = ref
        .watch(orderRepositoryProvider)
        .watchActiveOrders();

    return StreamBuilder(
      stream: activeOrdersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!;
        // Group orders by table
        final Map<String, List<dynamic>> tableData = {};

        for (var order in orders) {
          if (order.tableNumber != null && order.status != 'paid') {
            if (!tableData.containsKey(order.tableNumber)) {
              tableData[order.tableNumber!] = [];
            }
            tableData[order.tableNumber]!.add(order);
          }
        }

        if (tableData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No active tables to checkout',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Table to Checkout',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // 4 columns for wider screens
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: tableData.length,
                  itemBuilder: (context, index) {
                    final tableNo = tableData.keys.elementAt(index);
                    final orders = tableData[tableNo]!;
                    final totalAmount = orders.fold(
                      0.0,
                      (sum, o) => sum + o.totalAmount,
                    );

                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                CheckoutScreen(tableNumber: tableNo),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Table $tableNo',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${orders.length} Orders',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '\$${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827), // Dark text
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
