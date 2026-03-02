import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'printer_repository.g.dart';

class PrinterModel {
  final String id;
  final String name;
  final String macAddress;
  final String role;
  final String status;

  PrinterModel({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.role,
    required this.status,
  });
}

// Printer repository stub (backend doesn't have printer API yet)
class PrinterRepository {
  PrinterRepository();

  Future<List<PrinterModel>> getPrinters() async {
    debugPrint('Printer API not implemented in backend yet');
    return [];
  }

  Future<List<PrinterModel>> getAllPrinters() {
    return getPrinters();
  }

  Future<PrinterModel> addPrinter({
    required String name,
    required String macAddress,
    required String role,
    String status = 'active',
  }) async {
    debugPrint('Printer API not implemented in backend yet');
    return PrinterModel(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      macAddress: macAddress,
      role: role,
      status: status,
    );
  }

  Future<PrinterModel> updatePrinter(PrinterModel printer) async {
    debugPrint('Printer API not implemented in backend yet');
    return printer;
  }

  Future<void> deletePrinter(String id) async {
    debugPrint('Printer API not implemented in backend yet');
  }
}

@Riverpod(keepAlive: true)
PrinterRepository printerRepository(Ref ref) {
  return PrinterRepository();
}
