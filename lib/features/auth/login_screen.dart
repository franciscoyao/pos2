import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/core/theme/app_colors.dart';
import 'package:pos_system/core/widgets/glass_container.dart';
import 'package:pos_system/data/repositories/auth_repository.dart';
import 'package:pos_system/features/dashboard/admin_dashboard.dart';
import 'package:pos_system/features/dashboard/waiter_dashboard.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String role;

  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isQuickAccess = ['kitchen', 'bar', 'kiosk'].contains(widget.role);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.loginDark,
                  AppColors.loginDarkEnd,
                  AppColors.loginDark,
                ],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'role_${widget.role}',
                    child: Icon(
                      _getIconForRole(widget.role),
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassContainer(
                    width: 400,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Login as ${widget.role.capitalize()}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 32),
                        isQuickAccess
                            ? _buildQuickAccessUI()
                            : _buildLoginForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessUI() {
    String buttonText = 'Enter ${widget.role.capitalize()} Mode';
    if (widget.role == 'kiosk') buttonText = 'Start Kiosk Mode';

    return Column(
      children: [
        Text(
          'Quick Access Mode',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _handleQuickAccess,
            child: Text(buttonText),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.role == 'admin' || widget.role == 'waiter') ...[
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
        ],
        _buildTextField(
          controller: _pinController,
          label: 'PIN',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isNumber: true,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Login'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Default: admin/1111',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLength: isNumber ? 4 : null,
      cursorColor: AppColors.primary,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.6)),
        counterText: '',
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.2),
      ),
    );
  }

  void _handleQuickAccess() {
    _navigateBasedOnRole(widget.role);
  }

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final pin = _pinController.text.trim();

    if (pin.length != 4) {
      _showError('PIN must be 4 digits');
      return;
    }

    if ((widget.role == 'admin' || widget.role == 'waiter') &&
        username.isEmpty) {
      _showError('Username is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ref.read(authRepositoryProvider).login(username, pin);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        if (user.role == widget.role) {
          _navigateBasedOnRole(user.role);
        } else {
          _showError('User is not authorized for ${widget.role} role');
        }
      } else {
        _showError('Invalid credentials');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateBasedOnRole(String role) {
    Widget destination;
    switch (role) {
      case 'admin':
        destination = const AdminDashboard();
        break;
      case 'waiter':
        destination = const WaiterDashboard();
        break;
      default:
        destination = Scaffold(
          appBar: AppBar(title: Text('${role.capitalize()} Interface')),
          body: Center(child: Text('Welcome to $role interface (Coming Soon)')),
        );
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  IconData _getIconForRole(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'waiter':
        return Icons.restaurant_menu_rounded;
      case 'kitchen':
        return Icons.kitchen_rounded;
      case 'bar':
        return Icons.local_bar_rounded;
      case 'kiosk':
        return Icons.touch_app_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
