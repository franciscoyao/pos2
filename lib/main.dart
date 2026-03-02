import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/features/auth/api_login_screen.dart';
import 'package:pos_system/core/theme/app_theme.dart';
import 'package:pos_system/core/services/config_service.dart';
import 'package:pos_system/data/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigService.load();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final apiService = ref.read(apiServiceProvider);
    final isConnected = await apiService.checkHealth();

    if (mounted) {
      setState(() {
        if (!isConnected) {
          _error =
              'Unable to connect to the server. Please ensure the backend is running at ${ConfigService.baseUrl}';
        }
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (_error != null) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  Text(
                    'Connection Required',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initialized = false;
                        _error = null;
                      });
                      _checkConnection();
                    },
                    child: const Text('Retry Connection'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'POS System',
      theme: AppTheme.lightTheme,
      home: const ApiLoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
