import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/data/database/database.dart';
import 'package:pos_system/data/repositories/printer_repository.dart';
import 'package:pos_system/core/services/printer_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:printing/printing.dart' as pw;

class PrintersTab extends ConsumerStatefulWidget {
  const PrintersTab({super.key});

  @override
  ConsumerState<PrintersTab> createState() => _PrintersTabState();
}

class _PrintersTabState extends ConsumerState<PrintersTab> {
  // We don't need local state for devices anymore, we listen to the stream

  void _startScan() {
    ref.read(printerServiceProvider).startScan();
  }

  void _stopScan() {
    ref.read(printerServiceProvider).stopScan();
  }

  @override
  Widget build(BuildContext context) {
    final savedPrintersStream = ref
        .watch(printerRepositoryProvider)
        .watchAllPrinters();
    final printerService = ref.watch(printerServiceProvider);

    return Row(
      children: [
        // Left: Saved Printers
        Expanded(
          flex: 1,
          child: Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              children: [
                const ListTile(
                  title: Text(
                    'Saved Printers',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<List<Printer>>(
                    stream: savedPrintersStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final printers = snapshot.data!;
                      if (printers.isEmpty) {
                        return const Center(child: Text('No printers saved'));
                      }
                      return ListView.builder(
                        itemCount: printers.length,
                        itemBuilder: (context, index) {
                          final printer = printers[index];
                          return ListTile(
                            leading: const Icon(Icons.print),
                            title: Text(printer.name),
                            subtitle: Text(
                              '${printer.macAddress}\nRoles: ${printer.role}',
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.print_outlined),
                                  onPressed: () async {
                                    // Attempt to connect and print
                                    try {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Connecting...'),
                                        ),
                                      );
                                      await ref
                                          .read(printerServiceProvider)
                                          .testPrintSavedDevice(
                                            printer.macAddress,
                                            printer.name,
                                          );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Print Successful!'),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(printerRepositoryProvider)
                                        .deletePrinter(printer.id);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right: Scan & Add
        Expanded(
          flex: 1,
          child: Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              children: [
                StreamBuilder<bool>(
                  stream: printerService.isScanning,
                  initialData: false,
                  builder: (context, snapshot) {
                    final isScanning = snapshot.data ?? false;
                    return ListTile(
                      title: const Text(
                        'Scan for Devices',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: isScanning
                          ? ElevatedButton.icon(
                              onPressed: _stopScan,
                              icon: const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              label: const Text('Stop'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: _startScan,
                              icon: const Icon(Icons.bluetooth_searching),
                              label: const Text('Scan'),
                            ),
                    );
                  },
                ),
                const Divider(),
                Expanded(
                  child: FutureBuilder<Object>(
                    future: Future.wait([printerService.scanSystemPrinters()]),
                    builder: (context, systemSnapshot) {
                      return StreamBuilder<List<fbp.ScanResult>>(
                        stream: printerService.scanResults,
                        initialData: [],
                        builder: (context, snapshot) {
                          final results = snapshot.data ?? [];
                          final bleDevices = results
                              .where((r) => r.device.platformName.isNotEmpty)
                              .toList();

                          final systemPrinters = (systemSnapshot.data == null)
                              ? <pw.Printer>[]
                              : ((systemSnapshot.data as List<dynamic>)[0]
                                    as List<pw.Printer>);

                          if (bleDevices.isEmpty && systemPrinters.isEmpty) {
                            return const Center(
                              child: Text(
                                'No devices found. Click Scan to start.\n(Ensure Bluetooth is ON or Driver is installed)',
                              ),
                            );
                          }

                          return ListView(
                            children: [
                              if (systemPrinters.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'System Printers (Drivers)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                ...systemPrinters.map(
                                  (printer) => ListTile(
                                    leading: const Icon(Icons.print),
                                    title: Text(printer.name),
                                    subtitle: Text(printer.url),
                                    trailing: ElevatedButton(
                                      onPressed: () {
                                        ref
                                            .read(printerRepositoryProvider)
                                            .addPrinter(
                                              PrintersCompanion.insert(
                                                name: printer.name,
                                                macAddress:
                                                    'SYSTEM:${printer.name}',
                                                role: 'receipt',
                                              ),
                                            );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Added System Printer',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Add'),
                                    ),
                                  ),
                                ),
                                const Divider(),
                              ],
                              if (bleDevices.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Bluetooth LE Devices',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                ...bleDevices.map((result) {
                                  final device = result.device;
                                  return _DeviceListItem(
                                    name: device.platformName,
                                    mac: device.remoteId.str,
                                    onAdd: (name, mac, roles) {
                                      ref
                                          .read(printerRepositoryProvider)
                                          .addPrinter(
                                            PrintersCompanion.insert(
                                              name: name,
                                              macAddress: mac,
                                              role: roles.join(','),
                                            ),
                                          );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Added $name'),
                                          ),
                                        );
                                      }
                                    },
                                    onTestPrint: () async {
                                      try {
                                        await printerService.connect(device);
                                        final ticket = await printerService
                                            .generateTestReceipt();
                                        await printerService.printTicket(
                                          ticket,
                                        );
                                        await printerService.disconnect();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Print Successful!',
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Print Failed: $e'),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  );
                                }),
                              ],
                            ],
                          );
                        },
                      );
                    },
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

class _DeviceListItem extends StatefulWidget {
  final String name;
  final String mac;
  final Function(String name, String mac, List<String> roles) onAdd;
  final VoidCallback? onTestPrint;

  const _DeviceListItem({
    required this.name,
    required this.mac,
    required this.onAdd,
    this.onTestPrint,
  });

  @override
  State<_DeviceListItem> createState() => _DeviceListItemState();
}

class _DeviceListItemState extends State<_DeviceListItem> {
  bool _kitchen = false;
  bool _bar = false;
  bool _receipt = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'MAC: ${widget.mac}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Role Assignment:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Checkbox(
                  value: _kitchen,
                  onChanged: (v) => setState(() => _kitchen = v!),
                ),
                const Text('Kitchen'),
                const SizedBox(width: 8),
                Checkbox(
                  value: _bar,
                  onChanged: (v) => setState(() => _bar = v!),
                ),
                const Text('Bar'),
                const SizedBox(width: 8),
                Checkbox(
                  value: _receipt,
                  onChanged: (v) => setState(() => _receipt = v!),
                ),
                const Text('Receipt'),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onTestPrint != null)
                    TextButton(
                      onPressed: widget.onTestPrint,
                      child: const Text('Test Print'),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (_kitchen || _bar || _receipt)
                        ? () {
                            List<String> roles = [];
                            if (_kitchen) roles.add('kitchen');
                            if (_bar) roles.add('bar');
                            if (_receipt) roles.add('receipt');
                            widget.onAdd(widget.name, widget.mac, roles);
                          }
                        : null,
                    child: const Text('Add Printer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
