import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
// For Uint8List
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PrinterService {
  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _writeCharacteristic;
  Printer? _selectedSystemPrinter; // From printing package

  // Combine streams? Or just expose a list of found system printers
  Future<List<Printer>> scanSystemPrinters() async {
    return await Printing.listPrinters();
  }

  Stream<List<fbp.ScanResult>> get scanResults =>
      fbp.FlutterBluePlus.scanResults;
  Stream<bool> get isScanning => fbp.FlutterBluePlus.isScanning;

  Future<void> startScan() async {
    // Start scanning for 4 seconds
    try {
      await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Error starting scan: $e');
    }
  }

  Future<void> stopScan() async {
    try {
      await fbp.FlutterBluePlus.stopScan();
    } catch (e) {
      // Ignore errors stopping scan
    }
  }

  Future<void> connect(fbp.BluetoothDevice device) async {
    await device.connect();
    _connectedDevice = device;
    await _discoverServices(device);
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _writeCharacteristic = null;
    }
  }

  Future<void> _discoverServices(fbp.BluetoothDevice device) async {
    List<fbp.BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse) {
          _writeCharacteristic = characteristic;
          return;
        }
      }
    }
  }

  Future<void> printTicket(List<int> bytes) async {
    if (_selectedSystemPrinter != null) {
      throw Exception(
        'For System Printers, please use the PDF print method (not yet implemented for raw bytes).',
      );
    }

    if (_connectedDevice == null || _writeCharacteristic == null) {
      throw Exception('Printer not connected');
    }

    // Split into chunks to avoid potential size limits
    const int chunkSize = 512;
    for (int i = 0; i < bytes.length; i += chunkSize) {
      int end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
      await _writeCharacteristic!.write(bytes.sublist(i, end));
    }
  }

  void selectSystemPrinter(Printer printer) {
    _selectedSystemPrinter = printer;
  }

  Future<void> printPdf(List<int> pdfBytes) async {
    if (_selectedSystemPrinter != null) {
      await Printing.directPrintPdf(
        printer: _selectedSystemPrinter!,
        onLayout: (format) async => Uint8List.fromList(pdfBytes),
      );
    } else {
      // specific printer not selected, open dialog?
      await Printing.layoutPdf(
        onLayout: (format) async => Uint8List.fromList(pdfBytes),
      );
    }
  }

  Future<List<int>> generateTestReceipt() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text(
      'Test Print',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.feed(1);
    bytes += generator.text('Remote Printer Connection Successful!');
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  Future<Uint8List> generateTestPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Test Print',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('System Printer Connection Successful!'),
              ],
            ),
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<void> testPrintSavedDeviceViaDialog(String mac, String name) async {
    if (mac.startsWith('SYSTEM:')) {
      final pdfBytes = await generateTestPdf();
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Test Print - $name',
      );
    } else {
      // Fallback to normal test for BLE
      await testPrintSavedDevice(mac, name);
    }
  }

  Future<void> testPrintSavedDevice(String mac, String name) async {
    if (mac.startsWith('SYSTEM:')) {
      // System Printer
      final printers = await Printing.listPrinters();
      final printer = printers.firstWhere(
        (p) => p.name == name,
        orElse: () => throw Exception('System printer "$name" not found'),
      );

      final pdfBytes = await generateTestPdf();

      // Try direct print first
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) async => pdfBytes,
        name: 'Test Print $name',
      );
    } else {
      // BLE Printer
      // Re-construct the device using the ID (which is stored as mac)
      final device = fbp.BluetoothDevice(remoteId: fbp.DeviceIdentifier(mac));

      try {
        // Ensure connected
        await connect(device);
        final ticket = await generateTestReceipt();
        await printTicket(ticket);
      } finally {
        // Disconnect after test
        await disconnect();
      }
    }
  }

  Future<void> printEscPosTicket(String mac, List<int> bytes) async {
    // Re-construct the device using the ID (which is stored as mac)
    final device = fbp.BluetoothDevice(remoteId: fbp.DeviceIdentifier(mac));

    try {
      // Ensure connected
      await connect(device);
      await printTicket(bytes);
    } finally {
      // Disconnect after print
      await disconnect();
    }
  }
}

final printerServiceProvider = Provider<PrinterService>((ref) {
  return PrinterService();
});
