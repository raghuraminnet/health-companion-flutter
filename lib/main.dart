import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'utils/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const HealthCompanionApp());
}

class HealthCompanionApp extends StatefulWidget {
  const HealthCompanionApp({super.key});

  @override
  State<HealthCompanionApp> createState() => _HealthCompanionAppState();
}

class _HealthCompanionAppState extends State<HealthCompanionApp> {
  String? _token;
  String _theme = 'dark';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      ApiService().setToken(token);
    }
    
    setState(() {
      _token = token;
      _isLoading = false;
    });
  }

  void _onAuthSuccess() {
    setState(() => _token = 'authenticated');
  }

  void _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    ApiService().clearToken();
    setState(() => _token = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(_theme),
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _token == null
              ? AuthScreen(onAuthSuccess: _onAuthSuccess)
              : DashboardScreen(onLogout: _onLogout),
    );
  }
}