import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'screens/auth_screen.dart';
import 'screens/v2/dashboard_v2.dart';
import 'screens/v2/v2_theme.dart';

void main() {
  runApp(const HealthCompanionApp());
}

class HealthCompanionApp extends StatelessWidget {
  const HealthCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Companion',
      debugShowCheckedModeBanner: false,
      theme: buildV2LightTheme(),
      darkTheme: buildV2DarkTheme(),
      themeMode: ThemeMode.light,
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        // Verify token is still valid
        try {
          final api = ApiService();
          api.setToken(token);
          await api.getMe();
          _isLoggedIn = true;
        } catch (e) {
          // Token invalid, clear it
          await prefs.remove('auth_token');
          _isLoggedIn = false;
        }
      }
    } catch (e) {
      _isLoggedIn = false;
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Health Companion',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (_isLoggedIn) {
      return const DashboardV2();
    }

    return const AuthScreen();
  }
}
