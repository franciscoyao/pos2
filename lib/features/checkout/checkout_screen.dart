import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/core/theme/app_colors.dart';
import 'package:pos_system/data/repositories/order_repository.dart';
import 'package:pos_system/data/repositories/settings_repository.dart';
import 'package:pos_system/data/database/database.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String tableNumber;

  const CheckoutScreen({super.key, required this.tableNumber});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _splitOption = 'None';
  String _paymentMethod = 'Cash';
  double _tipPercentage = 0.0;
  final _cashController = TextEditingController();
  final _tipController = TextEditingController();

  // Split State
  final Map<int, int> _selectedItems = {};
  int _splitCount = 2;

  @override
  void dispose() {
    _cashController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrderWithDetails>>(
      future: ref
          .read(orderRepositoryProvider)
          .getOrdersWithDetailsByTable(widget.tableNumber),
      builder: (context, ordersSnapshot) {
        if (!ordersSnapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(title: const Text('Checkout')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final orders = ordersSnapshot.data!;
        if (orders.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(title: const Text('Checkout')),
            body: const Center(child: Text('No active orders for this table')),
          );
        }

        // Fetch settings to get dynamic tax and service rates
        return FutureBuilder<SystemSetting?>(
          future: ref.read(settingsRepositoryProvider).getSettings(),
          builder: (context, settingsSnapshot) {
            if (!settingsSnapshot.hasData) {
              return Scaffold(
                backgroundColor: AppColors.surface,
                appBar: AppBar(title: const Text('Checkout')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final settings = settingsSnapshot.data;
            final taxRate = (settings?.taxRate ?? 10.0) / 100;
            final serviceRate = (settings?.serviceRate ?? 5.0) / 100;

            double subtotal = orders.fold(
              0,
              (sum, o) => sum + o.order.totalAmount,
            );
            double tax = subtotal * taxRate;
            double service = subtotal * serviceRate;
            double tip = subtotal * _tipPercentage;
            double total = subtotal + tax + service + tip;

            return Scaffold(
              backgroundColor: AppColors.surface,
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Checkout'),
                    Text(
                      'Process payment and finalize order',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              body: Row(
                children: [
                  // Left: Payment Options
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Split Bill'),
                          const SizedBox(height: 8),
                          Text(
                            'Choose how to divide the payment',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: ['None', 'Equal', 'Item', 'Seat', '%']
                                  .map((opt) {
                                    final isSelected = _splitOption == opt;
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _splitOption = opt),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            opt,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                          if (_splitOption != 'None') ...[
                            const SizedBox(height: 16),
                            if (_splitOption == 'Equal') ...[
                              Text(
                                'Number of People',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => setState(
                                      () => _splitCount = (_splitCount > 2)
                                          ? _splitCount - 1
                                          : 2,
                                    ),
                                    icon: Icon(Icons.remove),
                                  ),
                                  Text(
                                    '$_splitCount',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => _splitCount++),
                                    icon: Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ] else if (_splitOption == 'Item') ...[
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                height: 300,
                                child: ListView.builder(
                                  itemCount: orders
                                      .expand((o) => o.items)
                                      .length,
                                  itemBuilder: (context, index) {
                                    final item = orders
                                        .expand((o) => o.items)
                                        .toList()[index];
                                    final isPaid = item.item.status == 'paid';
                                    final isSelected = _selectedItems
                                        .containsKey(item.item.id);
                                    final selectedQty =
                                        _selectedItems[item.item.id] ?? 0;

                                    return Column(
                                      children: [
                                        CheckboxListTile(
                                          title: Text(item.menu.name),
                                          subtitle: Text(
                                            '\$${(item.item.priceAtTime * item.item.quantity).toStringAsFixed(2)} '
                                            '(${item.item.quantity}x)',
                                          ),
                                          value: isPaid ? true : isSelected,
                                          onChanged: isPaid
                                              ? null
                                              : (val) {
                                                  setState(() {
                                                    if (val!) {
                                                      _selectedItems[item
                                                              .item
                                                              .id] =
                                                          item.item.quantity;
                                                    } else {
                                                      _selectedItems.remove(
                                                        item.item.id,
                                                      );
                                                    }
                                                  });
                                                },
                                          enabled: !isPaid,
                                        ),
                                        if (isSelected &&
                                            item.item.quantity > 1)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.remove_circle_outline,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (selectedQty > 1) {
                                                        _selectedItems[item
                                                                .item
                                                                .id] =
                                                            selectedQty - 1;
                                                      } else {
                                                        _selectedItems.remove(
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
                                                  icon: Icon(
                                                    Icons.add_circle_outline,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (selectedQty <
                                                          item.item.quantity) {
                                                        _selectedItems[item
                                                                .item
                                                                .id] =
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
                                  },
                                ),
                              ),
                            ],
                          ],

                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _splitOption == 'None'
                                  ? 'Full payment - no split'
                                  : 'Methods',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSectionTitle('Payment Method'),
                          const SizedBox(height: 16),
                          _buildPaymentOption(
                            'Cash',
                            Icons.payments_outlined,
                            _paymentMethod == 'Cash',
                            () => setState(() => _paymentMethod = 'Cash'),
                          ),
                          const SizedBox(height: 12),
                          _buildPaymentOption(
                            'Card',
                            Icons.credit_card,
                            _paymentMethod == 'Card',
                            () => setState(() => _paymentMethod = 'Card'),
                          ),
                          const SizedBox(height: 12),
                          _buildPaymentOption(
                            'Mixed (Cash + Card)',
                            Icons.account_balance_wallet,
                            _paymentMethod == 'Mixed',
                            () => setState(() => _paymentMethod = 'Mixed'),
                          ),
                          if (_paymentMethod == 'Cash' ||
                              _paymentMethod == 'Mixed') ...[
                            const SizedBox(height: 24),
                            Text(
                              'Cash Received',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _cashController,
                              decoration: InputDecoration(
                                hintText: 'Enter amount',
                                prefixText: '\$',
                                prefixStyle: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Right: Order Summary
                  Container(
                    width: 400,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: AppColors.border)),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Table ${widget.tableNumber}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ...orders.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final orderDetails = entry.value;
                                  final order = orderDetails.order;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${index + 1}x',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: orderDetails.items.map((
                                              item,
                                            ) {
                                              return Text(
                                                '${item.item.quantity}x ${item.menu.name}',
                                                style: TextStyle(
                                                  color: AppColors.textPrimary,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                        Text(
                                          '\$${order.totalAmount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                Divider(color: AppColors.border),
                                const SizedBox(height: 16),
                                _buildSummaryRow('Subtotal:', subtotal),
                                const SizedBox(height: 8),
                                _buildSummaryRow('Tax:', tax),
                                const SizedBox(height: 8),
                                _buildSummaryRow('Service:', service),
                                const SizedBox(height: 16),
                                Text(
                                  'Add Tip',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [0.10, 0.15, 0.20].map((pct) {
                                    final isSelected = _tipPercentage == pct;
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => _tipPercentage =
                                                _tipPercentage == pct
                                                ? 0.0
                                                : pct,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.border,
                                              ),
                                            ),
                                            child: Text(
                                              '${(pct * 100).toInt()}%',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _tipController,
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                                const SizedBox(height: 24),
                                Divider(color: AppColors.border),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total:',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (_splitOption == 'Equal')
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '\$${total.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            '\$${(total / _splitCount).toStringAsFixed(2)} / person',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      )
                                    else if (_splitOption == 'Item')
                                      Text(
                                        '\$${orders.expand((o) => o.items).where((i) => _selectedItems.containsKey(i.item.id)).fold(0.0, (sum, i) => sum + (i.item.priceAtTime * (_selectedItems[i.item.id] ?? 0))).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    else
                                      Text(
                                        '\$${total.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _finalizePayment(context, orders),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.textPrimary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                'Complete Payment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOption(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.textPrimary : AppColors.border,
                  width: 2,
                ),
                color: isSelected ? AppColors.textPrimary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _finalizePayment(
    BuildContext context,
    List<OrderWithDetails> ordersWithDetails,
  ) async {
    final repo = ref.read(orderRepositoryProvider);
    final total = ordersWithDetails.fold(
      0.0,
      (sum, o) => sum + o.order.totalAmount,
    ); // Simplified total

    try {
      if (_splitOption == 'Item') {
        if (_selectedItems.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Please select items to pay')));
          return;
        }

        final groupedItems = <int, List<Map<String, dynamic>>>{};
        for (var orderDetail in ordersWithDetails) {
          for (var item in orderDetail.items) {
            if (_selectedItems.containsKey(item.item.id)) {
              if (!groupedItems.containsKey(orderDetail.order.id)) {
                groupedItems[orderDetail.order.id] = [];
              }
              groupedItems[orderDetail.order.id]!.add({
                'id': item.item.id,
                'quantity': _selectedItems[item.item.id],
              });
            }
          }
        }

        for (var orderId in groupedItems.keys) {
          await repo.payItems(orderId, groupedItems[orderId]!, _paymentMethod);
        }
      } else if (_splitOption == 'Equal') {
        final amountPerPerson = total / _splitCount;
        // Pay equal amount on FIRST order (or distribute? Distributing is hard).
        // We will just add payment to the first order for now, backend `addPayment` logic
        // might need to handle "Table Payment" if we want to be robust.
        // Current backend `addPayment` is per Order.
        // If we have multiple orders, we should probably merge them first or just pick one.
        // Let's pick the first one for payment.
        if (ordersWithDetails.isNotEmpty) {
          await repo.addPayment(
            ordersWithDetails.first.order.id,
            amountPerPerson,
            _paymentMethod,
          );
        }
      } else {
        // Full Payment
        final orderIds = ordersWithDetails.map((o) => o.order.id).toList();
        await repo.markOrdersAsPaid(
          orderIds,
        ); // Old method, maybe replace with addPayment(total)
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _splitOption == 'None'
                ? 'Payment processed'
                : 'Partial Payment processed',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      if (_splitOption == 'None') {
        Navigator.of(context).pop();
      } else {
        // If partial, maybe stay? Or refresh?
        // Refresh happens auto via stream.
        setState(() {
          _selectedItems.clear();
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment Failed: $e')));
      }
    }
  }
}
