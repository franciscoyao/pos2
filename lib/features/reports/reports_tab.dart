import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos_system/data/repositories/report_repository.dart';

class ReportsTab extends ConsumerStatefulWidget {
  const ReportsTab({super.key});

  @override
  ConsumerState<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<ReportsTab> {
  // Default to this week (Mon-Sun)
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedPeriod = 'This Week';

  @override
  void initState() {
    super.initState();
    _updateDateRange('This Week');
  }

  void _updateDateRange(String period) {
    final now = DateTime.now();
    _selectedPeriod = period;

    if (period == 'This Week') {
      // Find the last Monday
      final monday = now.subtract(Duration(days: now.weekday - 1));
      _startDate = DateTime(monday.year, monday.month, monday.day);
      // End date is end of today or end of week? Let's say end of today for reporting up to now.
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (period == 'Today') {
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (period == 'Last Week') {
      final lastMonday = now.subtract(Duration(days: now.weekday - 1 + 7));
      _startDate = DateTime(lastMonday.year, lastMonday.month, lastMonday.day);
      final lastSunday = _startDate.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );
      _endDate = lastSunday;
    }
    setState(() {});
  }

  Future<void> _exportPdf() async {
    try {
      final reportRepo = ref.read(reportRepositoryProvider);

      // Fetch data
      final stats = await reportRepo.getStats(_startDate, _endDate);
      final salesByDay = await reportRepo.getSalesByDay(_startDate, _endDate);
      final salesByCategory = await reportRepo.getSalesByCategory(
        _startDate,
        _endDate,
      );

      final doc = pw.Document();
      final currencyFormat = NumberFormat.currency(symbol: '\$');
      final dateFormat = DateFormat('MM/dd/yyyy');

      doc.addPage(
        pw.MultiPage(
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Sales Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Paragraph(
                text:
                    'Period: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
              ),
              pw.SizedBox(height: 20),

              // Summary Stats
              pw.Text(
                'Summary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Metric', 'Value'],
                  ['Total Sales', currencyFormat.format(stats.totalSales)],
                  ['Total Orders', stats.totalOrders.toString()],
                  [
                    'Avg Order Value',
                    currencyFormat.format(stats.avgOrderValue),
                  ],
                  ['Avg Wait Time', '${stats.avgWaitTime.inMinutes} min'],
                ],
              ),
              pw.SizedBox(height: 20),

              // Sales by Day
              pw.Text(
                'Sales by Day',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Date', 'Sales'],
                  ...salesByDay.map(
                    (e) => [
                      dateFormat.format(e.date),
                      currencyFormat.format(e.totalSales),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Sales by Category
              pw.Text(
                'Sales by Category',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Category', 'Sales', 'Percentage'],
                  ...salesByCategory.map(
                    (e) => [
                      e.categoryName,
                      currencyFormat.format(e.totalSales),
                      '${e.percentage.toStringAsFixed(1)}%',
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      final bytes = await doc.save();

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: 'sales_report.pdf',
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report exported successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting report: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportRepo = ref.watch(reportRepositoryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters
          _buildFilters(),
          const SizedBox(height: 24),

          // Main Content with FutureBuilder
          FutureBuilder(
            future: Future.wait([
              reportRepo.getStats(_startDate, _endDate),
              reportRepo.getSalesByDay(_startDate, _endDate),
              reportRepo.getSalesByCategory(_startDate, _endDate),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final results = snapshot.data as List<dynamic>;
              final stats = results[0] as ReportStats;
              final salesByDay = results[1] as List<SalesByDay>;
              final salesByCategory = results[2] as List<SalesByCategory>;

              return Column(
                children: [
                  _buildStatsGrid(stats),
                  const SizedBox(height: 24),
                  _buildChartsRow(salesByDay, salesByCategory),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filters', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: PopupMenuButton<String>(
                  initialValue: _selectedPeriod,
                  onSelected: _updateDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedPeriod),
                        const Icon(Icons.keyboard_arrow_down, size: 20),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Today', child: Text('Today')),
                    const PopupMenuItem(
                      value: 'This Week',
                      child: Text('This Week'),
                    ),
                    const PopupMenuItem(
                      value: 'Last Week',
                      child: Text('Last Week'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                        _selectedPeriod = 'Custom';
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(DateFormat('MM/dd/yyyy').format(_startDate)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _endDate = picked.add(
                          const Duration(hours: 23, minutes: 59, seconds: 59),
                        );
                        _selectedPeriod = 'Custom';
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(DateFormat('MM/dd/yyyy').format(_endDate)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('Export PDF'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ReportStats stats) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Sales',
            value: currencyFormat.format(stats.totalSales),
            trend: 'based on selected period',
            trendUp: true,
            icon: Icons.attach_money,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Orders',
            value: stats.totalOrders.toString(),
            trend: 'based on selected period',
            trendUp: true,
            icon: Icons.shopping_cart_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Avg Order Value',
            value: currencyFormat.format(stats.avgOrderValue),
            trend: 'based on selected period',
            trendUp: true,
            icon: Icons.trending_up,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Avg Wait Time',
            value: '${stats.avgWaitTime.inMinutes} min',
            trend: 'based on selected period',
            trendUp: false,
            icon: Icons.access_time,
          ),
        ),
      ],
    );
  }

  Widget _buildChartsRow(
    List<SalesByDay> salesByDay,
    List<SalesByCategory> salesByCategory,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sales by Day',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Daily sales',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: salesByDay.isEmpty
                      ? const Center(child: Text('No data available'))
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: salesByDay.isEmpty
                                ? 100
                                : (salesByDay
                                          .map((e) => e.totalSales)
                                          .reduce((a, b) => a > b ? a : b) *
                                      1.2),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => Colors.blueGrey,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() < 0 ||
                                        value.toInt() >= salesByDay.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final date = salesByDay[value.toInt()].date;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        DateFormat('E').format(date),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey.shade100,
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: salesByDay.asMap().entries.map((entry) {
                              return BarChartGroupData(
                                x: entry.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: entry.value.totalSales,
                                    color: const Color(0xFF3B82F6),
                                    width: 20,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sales by Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Revenue distribution',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: salesByCategory.isEmpty
                      ? const Center(child: Text('No data available'))
                      : Row(
                          children: [
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 0,
                                  centerSpaceRadius: 40,
                                  sections: salesByCategory.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    final colors = [
                                      const Color(0xFF3B82F6),
                                      const Color(0xFF10B981),
                                      const Color(0xFFF59E0B),
                                      const Color(0xFFEF4444),
                                      const Color(0xFF8B5CF6),
                                    ];
                                    return PieChartSectionData(
                                      color: colors[index % colors.length],
                                      value: item.percentage,
                                      title:
                                          '${item.percentage.toStringAsFixed(0)}%',
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: salesByCategory.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final item = entry.value;
                                final colors = [
                                  const Color(0xFF3B82F6),
                                  const Color(0xFF10B981),
                                  const Color(0xFFF59E0B),
                                  const Color(0xFFEF4444),
                                  const Color(0xFF8B5CF6),
                                ];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: colors[index % colors.length],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item.categoryName,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool trendUp;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.trendUp,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: Colors.grey.shade400, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                trend,
                style: TextStyle(
                  color: trendUp ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
