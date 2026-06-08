import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/bp_entry.dart';

class ApiService {
  // Use relative URLs - nginx reverse proxy handles API routing
  // For local development, use absolute URL with: flutter run -d chrome
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: '');
  
  // Static singleton - token is shared across all instances
  static String? _staticToken;
  
  String? _token;
  
  // Singleton pattern - use ApiService() or ApiService.instance
  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;
  ApiService._internal();
  
  void setToken(String token) {
    _staticToken = token;
    _token = token;
  }

  void clearToken() {
    _staticToken = null;
    _token = null;
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    final token = _token ?? _staticToken;
    if (token != null) {
      headers['x-auth-token'] = token;
    }
    return headers;
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required int yearOfBirth,
    String? mobile,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'gender': gender,
        'yearOfBirth': yearOfBirth,
        'mobile': mobile,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Login failed');
    }
  }

  Future<void> logout() async {
    await http.post(
      Uri.parse('$baseUrl/api/auth/logout'),
      headers: _headers,
    );
    clearToken();
  }

  Future<User> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get user');
    }
  }

  Future<User> updateProfile({String? name, String? mobile}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: _headers,
      body: jsonEncode({'name': name, 'mobile': mobile}),
    );
    
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update profile');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/change-password'),
      headers: _headers,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to change password');
    }
  }

  // Preferences
  Future<Map<String, dynamic>> getPreferences() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/preferences'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get preferences');
    }
  }

  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> prefs) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/preferences'),
      headers: _headers,
      body: jsonEncode(prefs),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update preferences');
    }
  }

  // Settings
  Future<Map<String, dynamic>> getSettings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/settings'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get settings');
    }
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/settings'),
      headers: _headers,
      body: jsonEncode(settings),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update settings');
    }
  }

  // BP Entries
  Future<List<BpEntry>> getBpEntries({int limit = 100, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/bp?limit=$limit&offset=$offset'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => BpEntry.fromJson(e)).toList();
    } else {
      throw Exception('Failed to get BP entries');
    }
  }

  Future<BpEntry> addBpEntry({
    required int systolic,
    required int diastolic,
    int? pulse,
    String? session,
    List<String>? context,
    String? notes,
    bool medicationTaken = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/bp'),
      headers: _headers,
      body: jsonEncode({
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
        'session': session,
        'context': context,
        'notes': notes,
        'medicationTaken': medicationTaken,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return BpEntry.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to add BP entry');
    }
  }

  Future<void> deleteBpEntry(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/bp/$id'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete BP entry');
    }
  }

  // Mood Entries
  Future<List<MoodEntry>> getMoodEntries({int limit = 100, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/mood?limit=$limit&offset=$offset'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => MoodEntry.fromJson(e)).toList();
    } else {
      throw Exception('Failed to get mood entries');
    }
  }

  Future<MoodEntry> addMoodEntry({
    required String mood,
    int? dayRating,
    int? sleepQuality,
    int? energyLevel,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/mood'),
      headers: _headers,
      body: jsonEncode({
        'mood': mood,
        'dayRating': dayRating,
        'sleepQuality': sleepQuality,
        'energyLevel': energyLevel,
        'notes': notes,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return MoodEntry.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to add mood entry');
    }
  }

  Future<void> deleteMoodEntry(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/mood/$id'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete mood entry');
    }
  }

  // Water Entries
  Future<List<WaterEntry>> getWaterEntries({int limit = 100, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/water?limit=$limit&offset=$offset'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WaterEntry.fromJson(e)).toList();
    } else {
      throw Exception('Failed to get water entries');
    }
  }

  Future<WaterEntry> addWaterEntry({required int amount, String unit = 'ml'}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/water'),
      headers: _headers,
      body: jsonEncode({'amount': amount, 'unit': unit}),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return WaterEntry.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to add water entry');
    }
  }

  Future<void> deleteWaterEntry(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/water/$id'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete water entry');
    }
  }

  // Steps Entries
  Future<List<StepsEntry>> getStepsEntries({int limit = 100, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/steps?limit=$limit&offset=$offset'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => StepsEntry.fromJson(e)).toList();
    } else {
      throw Exception('Failed to get steps entries');
    }
  }

  Future<StepsEntry> addStepsEntry({required int steps}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/steps'),
      headers: _headers,
      body: jsonEncode({'steps': steps}),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return StepsEntry.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to add steps entry');
    }
  }

  Future<void> deleteStepsEntry(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/steps/$id'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete steps entry');
    }
  }

  // Weight Entries
  Future<List<WeightEntry>> getWeightEntries({int limit = 100, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/weight?limit=$limit&offset=$offset'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WeightEntry.fromJson(e)).toList();
    } else {
      throw Exception('Failed to get weight entries');
    }
  }

  Future<WeightEntry> addWeightEntry({required double weight, String? notes}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/weight'),
      headers: _headers,
      body: jsonEncode({'weight': weight, 'notes': notes}),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return WeightEntry.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to add weight entry');
    }
  }

  Future<void> deleteWeightEntry(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/weight/$id'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete weight entry');
    }
  }

  // Stats
  Future<Map<String, dynamic>> getStats({int days = 7}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/stats?days=$days'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get stats');
    }
  }
}