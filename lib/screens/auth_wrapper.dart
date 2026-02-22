import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/utils/error_handler.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';
import 'admin_dashboard.dart';
import 'dashboard/doctor_dashboard.dart';

/// AuthWrapper - Handles authentication state and role-based routing
/// 
/// Features:
/// - Robust Firebase Auth/Firestore synchronization
/// - Safe null handling for role data
/// - Proper loading states with timeout handling
/// - Error recovery with retry option
/// - Role-based navigation (admin, doctor, patient)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading during initialization
        if (authProvider.isInitializing) {
          return const _LoadingScreen(message: 'Initializing...');
        }

        // Show loading during auth operations
        if (authProvider.isLoading) {
          return const _LoadingScreen(message: 'Please wait...');
        }

        // Not authenticated - show login
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Authenticated - route based on role with safe null handling
        final userRole = authProvider.userRole;
        
        // Handle null or empty role gracefully
        if (userRole == null || userRole.isEmpty) {
          // Log error and show recovery option
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showRoleError(context, authProvider);
          });
          return const _LoadingScreen(message: 'Loading user data...');
        }

        // Route based on role
        switch (userRole.toLowerCase()) {
          case 'admin':
            return const AdminDashboard();
          case 'doctor':
            return const DoctorDashboard();
          case 'patient':
            return const HomeScreen();
          default:
            // Unknown role - show error and fallback to patient view
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showUnknownRoleError(context, userRole, authProvider);
            });
            return const HomeScreen();
        }
      },
    );
  }

  /// Show role error with retry option
  void _showRoleError(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('User Data Issue'),
          ],
        ),
        content: const Text(
          'Unable to load your user data. This might be due to a network issue or incomplete account setup.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.signOut();
            },
            child: const Text('Sign Out'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.refreshUserData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Show unknown role error
  void _showUnknownRoleError(BuildContext context, String role, AuthProvider authProvider) {
    ErrorHandler.showErrorSnackBar(
      context,
      'Unknown role "$role". Please contact support.',
    );
  }
}

/// Loading screen with animated indicator
class _LoadingScreen extends StatelessWidget {
  final String message;

  const _LoadingScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.medical_services,
                    size: 48,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Loading indicator
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Message
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Error screen with retry option
class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Oops!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
