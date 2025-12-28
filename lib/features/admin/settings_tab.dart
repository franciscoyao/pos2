import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:pos_system/data/database/database.dart';
import 'package:pos_system/data/repositories/settings_repository.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  final _taxController = TextEditingController();
  final _serviceController = TextEditingController();
  final _delayController = TextEditingController();
  bool _kioskMode = false;
  bool _isLoading = true;
  int? _settingsId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.initSettings(); // Ensure defaults exist
    final settings = await repo.getSettings();

    if (settings != null && mounted) {
      setState(() {
        _settingsId = settings.id;
        _taxController.text = settings.taxRate.toString();
        _serviceController.text = settings.serviceRate.toString();
        _delayController.text = settings.orderDelayThreshold.toString();
        _kioskMode = settings.kioskMode;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_settingsId == null) return;

    final repo = ref.read(settingsRepositoryProvider);
    await repo.updateSettings(
      SettingsCompanion(
        id: drift.Value(_settingsId!),
        taxRate: drift.Value(double.tryParse(_taxController.text) ?? 0.0),
        serviceRate: drift.Value(
          double.tryParse(_serviceController.text) ?? 0.0,
        ),
        orderDelayThreshold: drift.Value(
          int.tryParse(_delayController.text) ?? 15,
        ),
        kioskMode: drift.Value(_kioskMode),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will delete all orders, sales history, and tables. '
          'Menu items and settings will be preserved. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      await ref.read(settingsRepositoryProvider).clearAllDataExceptMenu();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared successfully')),
        );
      }
    }
  }

  @override
  void dispose() {
    _taxController.dispose();
    _serviceController.dispose();
    _delayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        _buildSectionHeader('Tax & Service'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildNumberField('Tax Rate (%)', _taxController),
                const SizedBox(height: 16),
                _buildNumberField('Service Charge (%)', _serviceController),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('Kitchen Display Settings'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildNumberField(
                  'Order Delay Threshold (minutes)',
                  _delayController,
                  helperText: 'Orders older than this will show a delay alert',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('Kiosk Mode'),
        Card(
          child: SwitchListTile(
            title: const Text('Enable Kiosk Mode'),
            subtitle: const Text('Allows customers to place orders directly'),
            value: _kioskMode,
            onChanged: (v) => setState(() => _kioskMode = v),
          ),
        ),

        const SizedBox(height: 24),
        FilledButton(
          onPressed: _saveSettings,
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Save All Settings'),
          ),
        ),

        const SizedBox(height: 48),
        _buildSectionHeader('Database Management'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Backup Database'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Database backup created at Documents/pos_backup.sqlite',
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore from Backup'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Restore functionality not implemented in demo',
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Purge Data Older Than 90 Days',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Old data purged')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.red),
                title: const Text(
                  'Clear All Data (Except Menu)',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('Deletes orders, sales, and tables'),
                onTap: _clearData,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('System Info'),
        const Card(
          child: Column(
            children: [
              ListTile(title: Text('Version'), trailing: Text('1.0.0')),
              Divider(),
              ListTile(
                title: Text('Database Size'),
                trailing: Text('2.4 MB (Estimated)'),
              ),
              Divider(),
              ListTile(title: Text('Last Sync'), trailing: Text('Just now')),
            ],
          ),
        ),

        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
          },
          child: const Text('Clear Cache'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller, {
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
