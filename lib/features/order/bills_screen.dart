import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/data/repositories/order_repository.dart';
import 'package:pos_system/data/database/database.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paidOrdersStream = ref
        .watch(orderRepositoryProvider)
        .watchPaidOrders();

    return StreamBuilder(
      stream: paidOrdersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!;
        if (orders.isEmpty) {
          return const Center(child: Text('No bills found'));
        }

        // Group by table and time (approximate)
        // Since we now set completedAt to exact same time for batches, we can group strictly by time
        final groupedMap = <String, List<Order>>{};
        for (var order in orders) {
          // Key: Table_Time. If table is null, fallback to orderId (no grouping)
          // Time is completedAt. If null (shouldn't be for paid), use createdAt
          final timeKey = (order.completedAt ?? order.createdAt)
              .millisecondsSinceEpoch
              .toString();
          final tableKey = order.tableNumber ?? 'no_table';
          final key = '${tableKey}_$timeKey';

          if (!groupedMap.containsKey(key)) {
            groupedMap[key] = [];
          }
          groupedMap[key]!.add(order);
        }

        final groupedOrders = groupedMap.values.toList();

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Order #')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Table')),
                DataColumn(label: Text('Waiter')),
                DataColumn(label: Text('Payment')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Actions')),
              ],
              rows: groupedOrders.map((group) {
                final mainOrder = group.first;
                final billTotal = group.fold(
                  0.0,
                  (sum, o) => sum + o.totalAmount,
                );

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        group.length > 1
                            ? '#${mainOrder.orderNumber} (+${group.length - 1})'
                            : '#${mainOrder.orderNumber}',
                      ),
                    ),
                    DataCell(
                      Text(
                        DateFormat(
                          'MM/dd/yyyy hh:mm a',
                        ).format(mainOrder.completedAt ?? mainOrder.createdAt),
                      ),
                    ),
                    DataCell(Text(mainOrder.type)),
                    DataCell(Text(mainOrder.tableNumber ?? '-')),
                    DataCell(Text('ID: ${mainOrder.waiterId}')),
                    DataCell(const Text('Cash/Card')), // Placeholder
                    DataCell(Text('\$${billTotal.toStringAsFixed(2)}')),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.print),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reprinting receipt...'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
