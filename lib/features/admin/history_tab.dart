import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/data/database/database.dart';
import 'package:pos_system/data/repositories/order_repository.dart';

class AdminHistoryTab extends ConsumerStatefulWidget {
  const AdminHistoryTab({super.key});

  @override
  ConsumerState<AdminHistoryTab> createState() => _AdminHistoryTabState();
}

class _AdminHistoryTabState extends ConsumerState<AdminHistoryTab> {
  final _searchController = TextEditingController();
  String _paymentFilter = 'All Payments';
  String _typeFilter = 'All Types';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only paid orders
    final paidOrdersStream = ref
        .watch(orderRepositoryProvider)
        .watchPaidOrders();

    return Column(
      children: [
        // Header & Filters
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search by order, table, waiter, tax#...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _paymentFilter,
                    items: ['All Payments', 'cash', 'card', 'mixed']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => _paymentFilter = val!),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _typeFilter,
                    items: ['All Types', 'dine-in', 'takeaway']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => _typeFilter = val!),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Orders Table
        Expanded(
          child: StreamBuilder<List<Order>>(
            stream: paidOrdersStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = snapshot.data!;

              // Apply filters
              final filteredOrders = orders.where((order) {
                final search = _searchController.text.toLowerCase();
                final matchesSearch =
                    search.isEmpty ||
                    order.orderNumber.toLowerCase().contains(search) ||
                    (order.tableNumber?.toLowerCase().contains(search) ??
                        false) ||
                    (order.taxNumber?.toLowerCase().contains(search) ?? false);
                // Waiter check requires join, we'll skip strictly matching waiter name for now or assume ID matches

                final matchesPayment =
                    _paymentFilter == 'All Payments' ||
                    order.paymentMethod == _paymentFilter;
                final matchesType =
                    _typeFilter == 'All Types' || order.type == _typeFilter;

                return matchesSearch && matchesPayment && matchesType;
              }).toList();

              if (filteredOrders.isEmpty) {
                return const Center(child: Text('No paid orders found'));
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
                      DataColumn(label: Text('Tax #')),
                      DataColumn(label: Text('Total')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: filteredOrders.map((order) {
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
                          DataCell(Text(order.paymentMethod ?? '-')),
                          DataCell(Text(order.taxNumber ?? '-')),
                          DataCell(
                            Text('\$${order.totalAmount.toStringAsFixed(2)}'),
                          ),
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
                              tooltip: 'Reprint Receipt',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
