import 'package:drift/drift.dart';
import 'package:pos_system/data/database/database.dart';
import 'package:pos_system/data/database/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'report_repository.g.dart';

class ReportStats {
  final double totalSales;
  final int totalOrders;
  final double avgOrderValue;
  final Duration avgWaitTime;

  ReportStats({
    required this.totalSales,
    required this.totalOrders,
    required this.avgOrderValue,
    required this.avgWaitTime,
  });
}

class SalesByDay {
  final DateTime date;
  final double totalSales;
  final int orderCount;

  SalesByDay(this.date, this.totalSales, this.orderCount);
}

class SalesByCategory {
  final String categoryName;
  final double totalSales;
  final double percentage;

  SalesByCategory(this.categoryName, this.totalSales, this.percentage);
}

class TopSellingItem {
  final String name;
  final double price;
  final int count;
  final double totalRevenue;

  final String status;

  TopSellingItem({
    required this.name,
    required this.price,
    required this.count,
    required this.totalRevenue,
    required this.status,
  });
}

class ReportRepository {
  final AppDatabase db;

  ReportRepository(this.db);

  // Helper to filter orders by date range and status
  Expression<bool> _orderFilter(DateTime start, DateTime end) {
    return db.orders.createdAt.isBetweenValues(start, end) &
        db.orders.status.isIn(['paid', 'completed']);
  }

  Future<ReportStats> getStats(DateTime start, DateTime end) async {
    final salesQuery = db.selectOnly(db.orders)
      ..addColumns([db.orders.totalAmount.sum(), db.orders.id.count()]);

    salesQuery.where(_orderFilter(start, end));

    final result = await salesQuery.getSingle();
    final totalSales = result.read(db.orders.totalAmount.sum()) ?? 0.0;
    final totalOrders = result.read(db.orders.id.count()) ?? 0;

    // Avg Wait Time
    final completedOrders =
        await (db.select(db.orders)..where(
              (t) =>
                  t.createdAt.isBetweenValues(start, end) &
                  t.completedAt.isNotNull(),
            ))
            .get();

    Duration totalWait = Duration.zero;
    int waitCount = 0;
    for (var order in completedOrders) {
      if (order.completedAt != null) {
        totalWait += order.completedAt!.difference(order.createdAt);
        waitCount++;
      }
    }

    final avgWaitTime = waitCount > 0
        ? Duration(milliseconds: totalWait.inMilliseconds ~/ waitCount)
        : Duration.zero;

    return ReportStats(
      totalSales: totalSales,
      totalOrders: totalOrders,
      avgOrderValue: totalOrders > 0 ? totalSales / totalOrders : 0.0,
      avgWaitTime: avgWaitTime,
    );
  }

  Future<List<SalesByDay>> getSalesByDay(DateTime start, DateTime end) async {
    final orders =
        await (db.select(db.orders)
              ..where((t) => _orderFilter(start, end))
              ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
            .get();

    final Map<String, SalesByDay> grouped = {};

    // Initialize with all days in range to ensure empty days are shown (optional, but good for charts)
    // For now, let's just show days with sales to match the chart which might be sparse,
    // or better yet, fill in the gaps in the UI logic or here.
    // The UI chart expects 7 days probably if it's "This Week".

    for (var order in orders) {
      final dateKey = order.createdAt.toIso8601String().split('T')[0];
      final current = grouped[dateKey];

      if (current == null) {
        grouped[dateKey] = SalesByDay(
          DateTime.parse(dateKey),
          order.totalAmount,
          1,
        );
      } else {
        grouped[dateKey] = SalesByDay(
          current.date,
          current.totalSales + order.totalAmount,
          current.orderCount + 1,
        );
      }
    }

    return grouped.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<SalesByCategory>> getSalesByCategory(
    DateTime start,
    DateTime end,
  ) async {
    final query = db.select(db.orderItems).join([
      innerJoin(db.orders, db.orders.id.equalsExp(db.orderItems.orderId)),
      innerJoin(
        db.menuItems,
        db.menuItems.id.equalsExp(db.orderItems.menuItemId),
      ),
      innerJoin(
        db.categories,
        db.categories.id.equalsExp(db.menuItems.categoryId),
      ),
    ]);

    query.where(
      db.orders.createdAt.isBetweenValues(start, end) &
          db.orders.status.isIn(['paid', 'completed']),
    );

    final rows = await query.get();

    final Map<String, double> categorySales = {};
    double totalSales = 0;

    for (var row in rows) {
      final categoryName = row.readTable(db.categories).name;
      final itemAmount =
          row.readTable(db.orderItems).priceAtTime *
          row.readTable(db.orderItems).quantity;

      categorySales[categoryName] =
          (categorySales[categoryName] ?? 0) + itemAmount;
      totalSales += itemAmount;
    }

    if (totalSales == 0) return [];

    final list = categorySales.entries.map((e) {
      return SalesByCategory(e.key, e.value, (e.value / totalSales) * 100);
    }).toList();

    // Sort by percentage desc
    list.sort((a, b) => b.percentage.compareTo(a.percentage));

    return list;
  }

  Future<List<TopSellingItem>> getTopSellingItems({
    int limit = 5,
    String? orderType,
  }) async {
    final countExp = db.orderItems.quantity.sum();
    final revenueExp =
        db.orderItems.quantity.cast<double>() * db.orderItems.priceAtTime;
    final totalRevenueExp = revenueExp.sum();

    final query = db.select(db.orderItems).join([
      innerJoin(
        db.menuItems,
        db.menuItems.id.equalsExp(db.orderItems.menuItemId),
      ),
      innerJoin(db.orders, db.orders.id.equalsExp(db.orderItems.orderId)),
    ]);

    var filter = db.orders.status.isIn(['paid', 'completed']);
    if (orderType != null) {
      filter = filter & db.orders.type.equals(orderType);
    }

    query
      ..where(filter)
      ..groupBy([db.orderItems.menuItemId])
      ..orderBy([OrderingTerm(expression: countExp, mode: OrderingMode.desc)])
      ..limit(limit);

    // Add aggregate columns
    query.addColumns([countExp, totalRevenueExp]);

    final rows = await query.get();

    return rows.map((row) {
      final menuItem = row.readTable(db.menuItems);
      final count = row.read(countExp) ?? 0;
      final revenue = row.read(totalRevenueExp) ?? 0.0;

      return TopSellingItem(
        name: menuItem.name,
        price: menuItem.price,
        count: count,
        totalRevenue: revenue,
        status: menuItem.status,
      );
    }).toList();
  }
}

@Riverpod(keepAlive: true)
ReportRepository reportRepository(Ref ref) {
  return ReportRepository(ref.watch(databaseProvider));
}
