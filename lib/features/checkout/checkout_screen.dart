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
                          if (_splitOption != 'None')
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Full payment - no split',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          const SizedBox(height: 32),
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

    final orderIds = ordersWithDetails.map((o) => o.order.id).toList();
    await repo.markOrdersAsPaid(orderIds);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payment processed & Receipt Printed'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.of(context).pop();
  }
}
