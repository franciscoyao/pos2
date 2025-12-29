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
import 'package:pos_system/core/services/printer_service.dart';
import 'package:pos_system/data/repositories/printer_repository.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

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
      final orderNumber = 'K-ORD-$timestamp';

      final order = OrdersCompanion(
        orderNumber: drift.Value(orderNumber),
        tableNumber: const drift.Value('Kiosk 1'),
        type: drift.Value(cart.type),
        totalAmount: drift.Value(cart.total),
        status: const drift.Value('pending'),
        paymentMethod: const drift.Value('pay_at_counter'),
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

      // --- Print Receipt Logic ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printing Order ticket...')),
        );
      }

      try {
        final printerRepo = ref.read(printerRepositoryProvider);
        final printerService = ref.read(printerServiceProvider);
        final savedPrinters = await printerRepo.getAllPrinters();

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

        if (receiptPrinter.id != -1) {
          if (receiptPrinter.macAddress.startsWith('SYSTEM:')) {
            final pdfBytes = await _generatePdfReceipt(orderNumber, cart);
            final systemPrinters = await printerService.scanSystemPrinters();
            try {
              final targetPrinter = systemPrinters.firstWhere(
                (p) => p.name == receiptPrinter.name,
              );
              printerService.selectSystemPrinter(targetPrinter);
              await printerService.printPdf(pdfBytes);
            } catch (e) {
              await printerService.printPdf(pdfBytes);
            }
          } else {
            final bytes = await _generateEscPosReceipt(orderNumber, cart);
            await printerService.printEscPosTicket(
              receiptPrinter.macAddress,
              bytes,
            );
          }
        }
      } catch (e) {
        debugPrint('Printing error: $e');
      }
      // ---------------------------

      if (mounted) {
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
        // Auto-close after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (context.mounted) {
            Navigator.of(context).pop(); // Close dialog
            ref.read(cartProvider.notifier).clear(); // Reset cart
          }
        });

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
                const Text('Please pay at the counter.'),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                const Text(
                  'Resetting screen in 5 seconds...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<int>> _generatePdfReceipt(
    String orderNumber,
    CartState cart,
  ) async {
    final pdf = pw.Document();
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
              pw.Text('Order: $orderNumber'),
              pw.Text('Kiosk Order (Pay at Counter)'),
              pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(date)}'),
              pw.Divider(),
              ...cart.items.map(
                (item) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '${item.quantity}x ${item.menuItem.name}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Text(
                      '\$${item.total.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
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
                    '\$${cart.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Please pay at counter',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<List<int>> _generateEscPosReceipt(
    String orderNumber,
    CartState cart,
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
      'Order: $orderNumber',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Pay at Counter',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(1);

    for (var item in cart.items) {
      bytes += generator.row([
        PosColumn(text: '${item.quantity}x', width: 2),
        PosColumn(text: item.menuItem.name, width: 7),
        PosColumn(
          text: '\$${item.total.toStringAsFixed(2)}',
          width: 3,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.feed(1);
    bytes += generator.text(
      'TOTAL: \$${cart.total.toStringAsFixed(2)}',
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

  @override
  Widget build(BuildContext context) {
    final categoriesStream = ref
        .watch(menuRepositoryProvider)
        .watchCategories(menuType: 'takeaway');

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
                                        type: 'takeaway',
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
