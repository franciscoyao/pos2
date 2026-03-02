import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/core/theme/app_colors.dart';
import 'package:pos_system/data/repositories/api_auth_repository.dart';
import 'package:pos_system/features/bar/bar_screen.dart';
import 'package:pos_system/features/dashboard/admin_dashboard.dart';
import 'package:pos_system/features/dashboard/waiter_dashboard.dart';
import 'package:pos_system/features/kitchen/kitchen_screen.dart';
import 'package:pos_system/features/kiosk/presentation/kiosk_screen.dart';

class ApiLoginScreen extends ConsumerStatefulWidget {
  const ApiLoginScreen({super.key});

  @override
  ConsumerState<ApiLoginScreen> createState() => _ApiLoginScreenState();
}

class _ApiLoginScreenState extends ConsumerState<ApiLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showError('Email is required');
      return;
    }
    if (password.isEmpty) {
      _showError('Password is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ref
          .read(apiAuthRepositoryProvider)
          .login(email, password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        _navigateBasedOnRole(user.role);
      } else {
        _showError('Invalid email or password');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String msg = e.toString();
      if (msg.contains('401') || msg.contains('Invalid credentials')) {
        msg = 'Invalid email or password';
      } else if (msg.contains('Network') || msg.contains('Connection')) {
        msg = 'Network error. Please check your connection.';
      } else {
        msg = 'Login failed. Please try again.';
      }
      _showError(msg);
    }
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
      case 'kitchen':
        destination = const KitchenScreen();
        break;
      case 'bar':
        destination = const BarScreen();
        break;
      case 'cashier':
        destination = const WaiterDashboard(); // Cashier uses waiter dashboard
        break;
      case 'kiosk':
        destination = const KioskScreen();
        break;
      default:
        _showError('Unknown role: $role');
        return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => destination));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginDark,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
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
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // White Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'POS System',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sign in to continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Email Field
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Email',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            cursorColor: AppColors.textPrimary,
                            decoration: InputDecoration(
                              hintText: 'Enter your email',
                              hintStyle: const TextStyle(
                                color: AppColors.textTertiary,
                              ),
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Password',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            cursorColor: AppColors.textPrimary,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              hintStyle: const TextStyle(
                                color: AppColors.textTertiary,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.textPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Default: admin@pos.com / admin123',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
