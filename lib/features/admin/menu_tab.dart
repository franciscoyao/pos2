import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos_system/data/database/database.dart';
import 'package:pos_system/data/repositories/menu_repository.dart';
import 'package:pos_system/features/admin/categories_tab.dart';
import 'package:pos_system/features/admin/edit_menu_item_dialog.dart';

final menuItemsProvider = StreamProvider<List<MenuItem>>((ref) {
  return ref.watch(menuRepositoryProvider).watchAllItems();
});

class MenuTab extends ConsumerStatefulWidget {
  const MenuTab({super.key});

  @override
  ConsumerState<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends ConsumerState<MenuTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStationFilter = 'All Stations';
  String _selectedTypeFilter = 'All Types';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _importCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        final input = file.openRead();
        final fields = await input
            .transform(utf8.decoder)
            .transform(const CsvToListConverter())
            .toList();

        if (fields.isEmpty) return;

        // Skip header if present (assume first row is header if it contains "Code")
        int startIndex = 0;
        if (fields.isNotEmpty &&
            fields[0][0].toString().toLowerCase() == 'code') {
          startIndex = 1;
        }

        final menuRepo = ref.read(menuRepositoryProvider);
        final categories = await menuRepo.getCategories();

        Map<String, int> categoryNameIdMap = {
          for (var c in categories) c.name.toLowerCase(): c.id,
        };

        for (var i = startIndex; i < fields.length; i++) {
          var row = fields[i];
          // Expected: Code, Name, Price, Category, Station, Type, AllowPriceEdit
          if (row.length < 3) continue; // At least Name, Price

          String code = row[0].toString();
          String name = row[1].toString();
          double price = double.tryParse(row[2].toString()) ?? 0.0;
          String catName = row.length > 3 ? row[3].toString() : 'General';
          String station = row.length > 4 ? row[4].toString() : 'kitchen';
          String type = row.length > 5 ? row[5].toString() : 'dine-in';
          bool allowPriceEdit = row.length > 6
              ? (row[6].toString().toLowerCase() == 'yes' ||
                    row[6].toString().toLowerCase() == 'true')
              : false;

          int catId;
          if (categoryNameIdMap.containsKey(catName.toLowerCase())) {
            catId = categoryNameIdMap[catName.toLowerCase()]!;
          } else {
            catId = await menuRepo.addCategory(
              CategoriesCompanion(name: Value(catName)),
            );
            categoryNameIdMap[catName.toLowerCase()] = catId;
          }

          await menuRepo.addItem(
            MenuItemsCompanion(
              code: Value(code.isEmpty ? null : code),
              name: Value(name),
              price: Value(price),
              categoryId: Value(catId),
              station: Value(station),
              type: Value(type),
              allowPriceEdit: Value(allowPriceEdit),
            ),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu imported successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing CSV: $e')));
      }
    }
  }

  Future<void> _exportCsv() async {
    try {
      final menuRepo = ref.read(menuRepositoryProvider);
      final items = await menuRepo.getAllItems();
      final categories = await menuRepo.getCategories();
      final categoryMap = {for (var c in categories) c.id: c.name};

      List<List<dynamic>> rows = [];
      rows.add([
        'Code',
        'Name',
        'Price',
        'Category',
        'Station',
        'Type',
        'Allow Price Edit',
      ]);

      for (var item in items) {
        rows.add([
          item.code ?? '',
          item.name,
          item.price,
          categoryMap[item.categoryId] ?? '',
          item.station,
          item.type,
          item.allowPriceEdit ? 'Yes' : 'No',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: 'menu_export.csv',
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(csv);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu exported successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting CSV: $e')));
      }
    }
  }

  Future<void> _exportPdf() async {
    try {
      final menuRepo = ref.read(menuRepositoryProvider);
      final items = await menuRepo.getAllItems();
      final categories = await menuRepo.getCategories();
      final categoryMap = {for (var c in categories) c.id: c.name};

      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Menu Items Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>[
                    'Code',
                    'Name',
                    'Price',
                    'Category',
                    'Station',
                    'Type',
                  ],
                  ...items.map(
                    (item) => [
                      item.code ?? '',
                      item.name,
                      item.price.toStringAsFixed(2),
                      categoryMap[item.categoryId] ?? '',
                      item.station,
                      item.type,
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
        fileName: 'menu_report.pdf',
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF exported successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Menu Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage menu items and categories',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tabs
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              labelColor: const Color(0xFF111827),
              unselectedLabelColor: Colors.grey.shade600,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  child: Text(
                    'Menu Items',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Tab(
                  child: Text(
                    'Categories',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMenuItemsTab(), // Menu Items
                const CategoriesTab(), // Categories
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemsTab() {
    final menuItemsAsync = ref.watch(menuItemsProvider);

    return Column(
      children: [
        // Action Bar
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by name or item code...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTypeFilter,
                    isExpanded: true,
                    items: ['All Types', 'Dine-in', 'Takeaway'].map((e) {
                      return DropdownMenuItem(value: e, child: Text(e));
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedTypeFilter = val!),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStationFilter,
                    isExpanded: true,
                    items: ['All Stations', 'Kitchen', 'Bar'].map((e) {
                      return DropdownMenuItem(value: e, child: Text(e));
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedStationFilter = val!),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: _importCsv,
              icon: const Icon(Icons.upload_file),
              label: const Text('Import CSV'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF111827),
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _exportCsv,
              icon: const Icon(Icons.download),
              label: const Text('Export CSV'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF111827),
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export PDF'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF111827),
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showEditDialog(null),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Data Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: menuItemsAsync.when(
              data: (items) {
                // Filter Items
                final filteredItems = items.where((item) {
                  final matchesSearch =
                      item.name.toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      ) ||
                      (item.code?.toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          ) ??
                          false);

                  final matchesStation =
                      _selectedStationFilter == 'All Stations' ||
                      item.station.toLowerCase() ==
                          _selectedStationFilter.toLowerCase();

                  final matchesType =
                      _selectedTypeFilter == 'All Types' ||
                      item.type.toLowerCase() ==
                          _selectedTypeFilter.toLowerCase();

                  return matchesSearch && matchesStation && matchesType;
                }).toList();

                if (filteredItems.isEmpty) {
                  return const Center(child: Text('No menu items found'));
                }

                return SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                    horizontalMargin: 24,
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Code',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Price',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Station',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Type',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: filteredItems.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              item.code ?? '-',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          DataCell(
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(Text('\$${item.price.toStringAsFixed(2)}')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                item.station,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                item.type,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: item.status == 'active'
                                    ? const Color(0xFF111827)
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.status == 'active'
                                    ? 'Available'
                                    : 'Unavailable',
                                style: TextStyle(
                                  color: item.status == 'active'
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _showEditDialog(item),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                  splashRadius: 20,
                                ),
                                IconButton(
                                  onPressed: () => _deleteItem(item),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  splashRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditDialog(MenuItem? item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditMenuItemDialog(item: item),
    );
  }

  void _deleteItem(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(menuRepositoryProvider).deleteItem(item.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
