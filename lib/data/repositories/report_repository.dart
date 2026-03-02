import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_system/data/services/api_service.dart';

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

  factory ReportStats.fromJson(Map<String, dynamic> json) {
    return ReportStats(
      totalSales: (json['totalSales'] as num).toDouble(),
      totalOrders: json['totalOrders'] as int,
      avgOrderValue: (json['avgOrderValue'] as num).toDouble(),
      avgWaitTime: Duration(seconds: json['avgWaitTime'] as int),
    );
  }
}

class SalesByDay {
  final DateTime date;
  final double totalSales;
  final int orderCount;

  SalesByDay(this.date, this.totalSales, this.orderCount);

  factory SalesByDay.fromJson(Map<String, dynamic> json) {
    return SalesByDay(
      DateTime.parse(json['date']),
      (json['totalSales'] as num).toDouble(),
      json['orderCount'] as int,
    );
  }
}

class SalesByCategory {
  final String categoryName;
  final double totalSales;
  final double percentage;

  SalesByCategory(this.categoryName, this.totalSales, this.percentage);

  factory SalesByCategory.fromJson(Map<String, dynamic> json) {
    return SalesByCategory(
      json['categoryName'] as String,
      (json['totalSales'] as num).toDouble(),
      (json['percentage'] as num).toDouble(),
    );
  }
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

  factory TopSellingItem.fromJson(Map<String, dynamic> json) {
    return TopSellingItem(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      count: json['count'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      status: json['status'] as String,
    );
  }
}

// Report repository with API integration
class ReportRepository {
  final Dio _dio;

  ReportRepository(this._dio);

  Future<ReportStats> getStats(DateTime start, DateTime end) async {
    try {
      final response = await _dio.get(
        '/reports/stats',
        queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      );
      return ReportStats.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching report stats: $e');
      // Return empty stats on error
      return ReportStats(
        totalSales: 0.0,
        totalOrders: 0,
        avgOrderValue: 0.0,
        avgWaitTime: Duration.zero,
      );
    }
  }

  Future<List<SalesByDay>> getSalesByDay(DateTime start, DateTime end) async {
    try {
      final response = await _dio.get(
        '/reports/sales-by-day',
        queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      );
      return (response.data as List)
          .map((json) => SalesByDay.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching sales by day: $e');
      return [];
    }
  }

  Future<List<SalesByCategory>> getSalesByCategory(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _dio.get(
        '/reports/sales-by-category',
        queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      );
      return (response.data as List)
          .map((json) => SalesByCategory.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching sales by category: $e');
      return [];
    }
  }

  Future<List<TopSellingItem>> getTopSellingItems({
    int limit = 5,
    String? orderType,
  }) async {
    try {
      final response = await _dio.get(
        '/reports/top-selling-items',
        queryParameters: {
          'limit': limit,
          if (orderType != null) 'orderType': orderType,
        },
      );
      return (response.data as List)
          .map((json) => TopSellingItem.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching top selling items: $e');
      return [];
    }
  }
}

@Riverpod(keepAlive: true)
ReportRepository reportRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return ReportRepository(dio);
}
