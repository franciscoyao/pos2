import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/data/repositories/order_repository.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'All Statuses';
  String _typeFilter = 'All Types';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allOrdersAsync = ref.watch(orderRepositoryProvider).watchAllOrders();

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
                        labelText: 'Search by order number, table...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _statusFilter,
                    items:
                        [
                              'All Statuses',
                              'pending',
                              'cooking',
                              'ready',
                              'paid',
                              'cancelled',
                            ]
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => _statusFilter = val!),
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
          child: StreamBuilder(
            stream: allOrdersAsync,
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
                final matchesSearch =
                    _searchController.text.isEmpty ||
                    order.orderNumber.contains(_searchController.text) ||
                    (order.tableNumber?.contains(_searchController.text) ??
                        false);

                final matchesStatus =
                    _statusFilter == 'All Statuses' ||
                    order.status == _statusFilter;
                final matchesType =
                    _typeFilter == 'All Types' || order.type == _typeFilter;

                return matchesSearch && matchesStatus && matchesType;
              }).toList();

              if (filteredOrders.isEmpty) {
                return const Center(child: Text('No orders found'));
              }

              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Order #')),
                      DataColumn(label: Text('Date & Time')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Table')),
                      DataColumn(label: Text('Waiter')), // ID for now
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Status')),
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
                          DataCell(
                            Text('\$${order.totalAmount.toStringAsFixed(2)}'),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () {
                                // Show Order Details
                                showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: Text('Order #${order.orderNumber}'),
                                    content: const Text(
                                      'Details view pending implementation',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c),
                                        child: const Text('Close'),
                                      ),
                                    ],
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
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'cooking':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'paid':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
