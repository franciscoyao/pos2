import 'package:pos_system/data/database/database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pos_system/data/database/database_provider.dart';

part 'printer_repository.g.dart';

class PrinterRepository {
  final AppDatabase db;

  PrinterRepository(this.db);

  Stream<List<Printer>> watchAllPrinters() {
    return db.select(db.printers).watch();
  }

  Future<List<Printer>> getAllPrinters() {
    return db.select(db.printers).get();
  }

  Future<int> addPrinter(PrintersCompanion printer) {
    return db.into(db.printers).insert(printer);
  }

  Future<bool> updatePrinter(PrintersCompanion printer) {
    return db.update(db.printers).replace(printer);
  }

  Future<int> deletePrinter(int id) {
    return (db.delete(db.printers)..where((t) => t.id.equals(id))).go();
  }
}

@Riverpod(keepAlive: true)
PrinterRepository printerRepository(Ref ref) {
  return PrinterRepository(ref.watch(databaseProvider));
}
