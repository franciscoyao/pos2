import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/data/repositories/order_repository.dart';

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
              rows: orders.map((order) {
                return DataRow(
                  cells: [
                    DataCell(Text('#${order.orderNumber}')),
                    DataCell(
                      Text(
                        DateFormat(
                          'MM/dd/yyyy hh:mm a',
                        ).format(order.createdAt),
                      ),
                    ),
                    DataCell(Text(order.type)),
                    DataCell(Text(order.tableNumber ?? '-')),
                    DataCell(Text('ID: ${order.waiterId}')),
                    DataCell(const Text('Cash/Card')), // Placeholder
                    DataCell(Text('\$${order.totalAmount.toStringAsFixed(2)}')),
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
