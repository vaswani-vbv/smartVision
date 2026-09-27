import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/network/token_storage.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/auth_service.dart';
import 'features/profile/medical_profile_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartVisionApp());
}

class SmartVisionApp extends StatelessWidget {
  const SmartVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartVision Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashRouter(),
    );
  }
}

/// Checks auth state on launch and routes to the correct screen.
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutBack));
    _animController.forward();
    _checkAuthAndRoute();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndRoute() async {
    // Show splash for at least 1.8 seconds
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final hasToken = await TokenStorageService.hasToken();

    if (!hasToken) {
      // Not logged in → Login Screen
      _navigateTo(const LoginScreen());
      return;
    }

    // Logged in → check medical profile
    try {
      final hasProfile = await AuthService.hasMedicalProfile();
      if (!mounted) return;

      if (!hasProfile) {
        final stillHasToken = await TokenStorageService.hasToken();
        if (!stillHasToken) {
          _navigateTo(const LoginScreen());
        } else {
          _navigateTo(const MedicalProfileScreen(isOnboarding: true));
        }
      } else {
        _navigateTo(const DashboardScreen());
      }
    } catch (_) {
      // If network fails, proceed to Dashboard for logged in user instead of forcing onboarding
      if (!mounted) return;
      _navigateTo(const DashboardScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Logo
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.remove_red_eye_outlined,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ).createShader(bounds),
                  child: const Text(
                    'SmartVision',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AI-Powered Diabetes Management',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.primary,
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
