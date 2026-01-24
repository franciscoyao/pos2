import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/core/theme/app_colors.dart';
import 'package:pos_system/data/database/database.dart';
import 'package:pos_system/data/repositories/order_repository.dart';
import 'package:pos_system/features/checkout/checkout_screen.dart';
import 'package:pos_system/features/order/cart_provider.dart';
import 'package:intl/intl.dart';
import 'package:pos_system/features/dashboard/dashboard_provider.dart';
import 'package:pos_system/core/services/printer_service.dart';
import 'package:pos_system/data/repositories/printer_repository.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class TableDetailsSidebar extends ConsumerWidget {
  final RestaurantTable table;

  const TableDetailsSidebar({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrdersFuture = ref
        .watch(orderRepositoryProvider)
        .getOrdersWithDetailsByTable(table.name);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Table ${table.name}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ordered',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage orders and table status',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // Close sidebar logic if implemented (usually by deselecting in parent)
                },
                icon: Icon(Icons.close, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // Actions
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to New Order with table set
                    ref.read(cartProvider.notifier).setTableNumber(table.name);
                    ref.read(cartProvider.notifier).setType('dine-in');

                    // Switch main tab to "New Order" (index 0)
                    ref.read(dashboardControllerProvider.notifier).setIndex(0);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Add Items',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final orders = await activeOrdersFuture;
                        if (context.mounted) {
                          _showSplitDialog(context, ref, orders, table);
                        }
                      },
                      icon: Icon(
                        Icons.call_split,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                      label: Text(
                        'Split Table',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showMergeDialog(context, ref, table),
                      icon: Icon(
                        Icons.merge_type,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                      label: Text(
                        'Merge',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Orders List
        Expanded(
          child: FutureBuilder<List<OrderWithDetails>>(
            future: activeOrdersFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final ordersWithDetails = snapshot.data!;

              if (ordersWithDetails.isEmpty) {
                return Center(
                  child: Text(
                    'No active orders',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current Orders',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${ordersWithDetails.length} active',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: ordersWithDetails.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final orderDetails = ordersWithDetails[index];
                        return _OrderCard(orderDetails: orderDetails);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Footer Total
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, -4),
                blurRadius: 16,
              ),
            ],
          ),
          child: FutureBuilder<List<OrderWithDetails>>(
            future: activeOrdersFuture,
            builder: (context, snapshot) {
              final orders = snapshot.data ?? [];
              final total = orders.fold(
                0.0,
                (sum, o) => sum + o.order.totalAmount,
              );

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (orders.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No orders to print'),
                                ),
                              );
                              return;
                            }

                            final printerRepo = ref.read(
                              printerRepositoryProvider,
                            );
                            final savedPrinters = await printerRepo
                                .getAllPrinters();
                            if (!context.mounted) return;
                            // Find receipt printer or fallback
                            final receiptPrinter = savedPrinters.firstWhere(
                              (p) => p.role.contains('receipt'),
                              orElse: () => savedPrinters.firstWhere(
                                (p) => p.role.isEmpty,
                                orElse: () => const Printer(
                                  id: -1,
                                  name: '',
                                  macAddress: '',
                                  role: '',
                                  status: 'active',
                                ),
                              ),
                            );

                            if (receiptPrinter.id == -1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No printer found. Please add one in Admin > Printers.',
                                  ),
                                ),
                              );
                              return;
                            }

                            final printerService = ref.read(
                              printerServiceProvider,
                            );

                            try {
                              if (receiptPrinter.macAddress.startsWith(
                                'SYSTEM:',
                              )) {
                                // System Printer
                                final pdfBytes = await _generatePdfReceipt(
                                  table,
                                  orders,
                                );
                                final systemPrinters = await printerService
                                    .scanSystemPrinters();
                                try {
                                  final targetPrinter = systemPrinters
                                      .firstWhere(
                                        (p) => p.name == receiptPrinter.name,
                                      );
                                  printerService.selectSystemPrinter(
                                    targetPrinter,
                                  );
                                  await printerService.printPdf(pdfBytes);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Sent to System Printer'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  // Fallback to default print dialog
                                  await printerService.printPdf(pdfBytes);
                                }
                              } else {
                                // BLE Printer
                                try {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Generating receipt and connecting...',
                                      ),
                                    ),
                                  );

                                  final bytes = await _generateEscPosReceipt(
                                    table,
                                    orders,
                                  );
                                  await printerService.printEscPosTicket(
                                    receiptPrinter.macAddress,
                                    bytes,
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Print Successful!'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Bluetooth Print Error: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Print Error: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.print, size: 16),
                          label: const Text(
                            'Print Bill',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            foregroundColor: AppColors.error,
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    CheckoutScreen(tableNumber: table.name),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text(
                            'Checkout',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<List<int>> _generatePdfReceipt(
    RestaurantTable table,
    List<OrderWithDetails> orders,
  ) async {
    final pdf = pw.Document();
    final total = orders.fold(0.0, (sum, o) => sum + o.order.totalAmount);
    final date = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'POS System',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Table: ${table.name}'),
              pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(date)}'),
              pw.Divider(),
              ...orders.expand(
                (order) => order.items.map(
                  (item) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${item.item.quantity}x ${item.menu.name}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Text(
                        '\$${(item.item.quantity * item.item.priceAtTime).toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Thank you!',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<List<int>> _generateEscPosReceipt(
    RestaurantTable table,
    List<OrderWithDetails> orders,
  ) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text(
      'POS System',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      'Table: ${table.name}',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);

    // Items
    for (var order in orders) {
      for (var item in order.items) {
        bytes += generator.row([
          PosColumn(text: '${item.item.quantity}x', width: 2),
          PosColumn(text: item.menu.name, width: 7),
          PosColumn(
            text:
                '\$${(item.item.quantity * item.item.priceAtTime).toStringAsFixed(2)}',
            width: 3,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
    }

    bytes += generator.feed(1);
    final total = orders.fold(0.0, (sum, o) => sum + o.order.totalAmount);
    bytes += generator.text(
      'TOTAL: \$${total.toStringAsFixed(2)}',
      styles: const PosStyles(
        align: PosAlign.right,
        bold: true,
        height: PosTextSize.size2,
      ),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  void _showMergeDialog(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable currentTable,
  ) {
    final TextEditingController tableController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Merge Table ${currentTable.name} into...'),
        content: TextField(
          controller: tableController,
          decoration: InputDecoration(
            labelText: 'Target Table Number',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (tableController.text.isNotEmpty) {
                try {
                  await ref
                      .read(orderRepositoryProvider)
                      .mergeTables(currentTable.name, tableController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tables merged successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Merge failed: $e')));
                  }
                }
              }
            },
            child: Text('Merge'),
          ),
        ],
      ),
    );
  }

  void _showSplitDialog(
    BuildContext context,
    WidgetRef ref,
    List<OrderWithDetails> orders,
    RestaurantTable currentTable,
  ) {
    // Split selection state
    final selectedItems = <int, int>{}; // itemId -> quantity
    final TextEditingController tableController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Split Items to New Table'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 400,
                height: 500,
                child: Column(
                  children: [
                    TextField(
                      controller: tableController,
                      decoration: InputDecoration(
                        labelText: 'Target Table Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: orders.expand((o) => o.items).map((item) {
                          final isSelected = selectedItems.containsKey(
                            item.item.id,
                          );
                          final selectedQty = selectedItems[item.item.id] ?? 0;

                          return Column(
                            children: [
                              CheckboxListTile(
                                title: Text(item.menu.name),
                                subtitle: Text('${item.item.quantity}x'),
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val!) {
                                      selectedItems[item.item.id] =
                                          item.item.quantity;
                                    } else {
                                      selectedItems.remove(item.item.id);
                                    }
                                  });
                                },
                              ),
                              if (isSelected && item.item.quantity > 1)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove_circle_outline),
                                        onPressed: () {
                                          setState(() {
                                            if (selectedQty > 1) {
                                              selectedItems[item.item.id] =
                                                  selectedQty - 1;
                                            } else {
                                              selectedItems.remove(
                                                item.item.id,
                                              );
                                            }
                                          });
                                        },
                                      ),
                                      Text(
                                        '$selectedQty / ${item.item.quantity}',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add_circle_outline),
                                        onPressed: () {
                                          setState(() {
                                            if (selectedQty <
                                                item.item.quantity) {
                                              selectedItems[item.item.id] =
                                                  selectedQty + 1;
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (tableController.text.isNotEmpty &&
                    selectedItems.isNotEmpty) {
                  try {
                    // Group by order
                    final grouped = <int, List<Map<String, dynamic>>>{};
                    for (var o in orders) {
                      for (var i in o.items) {
                        if (selectedItems.containsKey(i.item.id)) {
                          if (!grouped.containsKey(o.order.id)) {
                            grouped[o.order.id] = [];
                          }
                          grouped[o.order.id]!.add({
                            'id': i.item.id,
                            'quantity': selectedItems[i.item.id],
                          });
                        }
                      }
                    }

                    for (var orderId in grouped.keys) {
                      await ref
                          .read(orderRepositoryProvider)
                          .splitTable(
                            orderId,
                            tableController.text,
                            grouped[orderId]!,
                          );
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Split successful')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Split failed: $e')),
                      );
                    }
                  }
                }
              },
              child: Text('Split'),
            ),
          ],
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderWithDetails orderDetails;

  const _OrderCard({required this.orderDetails});

  @override
  Widget build(BuildContext context) {
    final order = orderDetails.order;
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Order #${order.orderNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeFormat.format(order.createdAt),
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (orderDetails.items.isEmpty)
            Text(
              'No items',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )
          else
            ...orderDetails.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.item.quantity}x',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.menu.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '\$${(item.item.quantity * item.item.priceAtTime).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
