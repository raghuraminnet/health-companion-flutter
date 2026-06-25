import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/session.dart';
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
    authNotifier.addListener(_onAuthChanged);
    _checkAuth();
  }

  @override
  void dispose() {
    authNotifier.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    // Login / logout flips the notifier → re-verify the token and rebuild.
    if (mounted) _checkAuth();
  }

  Future<void> _checkAuth() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      bool loggedIn = false;
      if (token != null) {
        try {
          final api = ApiService();
          api.setToken(token);
          await api.getMe();
          loggedIn = true;
        } catch (e) {
          // Token invalid — clear it so we don't loop on a bad token.
          await prefs.remove('auth_token');
          loggedIn = false;
        }
      }
      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
          _isLoading = false;
        });
        // Keep the notifier in sync with reality (e.g. if the token
        // turned out to be stale and we just cleared it).
        setAuthed(loggedIn);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
        setAuthed(false);
      }
    }
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
