class BpEntry {
  final String id;
  final String userId;
  final int systolic;
  final int diastolic;
  final int? pulse;
  final String? session;
  final List<String>? context;
  final String? notes;
  final bool medicationTaken;
  final DateTime recordedAt;

  BpEntry({
    required this.id,
    required this.userId,
    required this.systolic,
    required this.diastolic,
    this.pulse,
    this.session,
    this.context,
    this.notes,
    this.medicationTaken = false,
    required this.recordedAt,
  });

  factory BpEntry.fromJson(Map<String, dynamic> json) {
    return BpEntry(
      id: json['id'],
      userId: json['user_id'],
      systolic: json['systolic'],
      diastolic: json['diastolic'],
      pulse: json['pulse'],
      session: json['session'],
      context: json['context'] != null ? List<String>.from(json['context']) : null,
      notes: json['notes'],
      medicationTaken: json['medication_taken'] ?? false,
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }

  String get status {
    if (systolic < 120 && diastolic < 80) return 'normal';
    if (systolic < 130 || diastolic < 85) return 'elevated';
    if (systolic < 140 || diastolic < 90) return 'stage1';
    if (systolic < 180 || diastolic < 120) return 'stage2';
    return 'crisis';
  }
}

class MoodEntry {
  final String id;
  final String userId;
  final String mood;
  final int? dayRating;
  final int? sleepQuality;
  final int? energyLevel;
  final String? notes;
  final DateTime recordedAt;

  MoodEntry({
    required this.id,
    required this.userId,
    required this.mood,
    this.dayRating,
    this.sleepQuality,
    this.energyLevel,
    this.notes,
    required this.recordedAt,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'],
      userId: json['user_id'],
      mood: json['mood'],
      dayRating: json['day_rating'],
      sleepQuality: json['sleep_quality'],
      energyLevel: json['energy_level'],
      notes: json['notes'],
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }
}

class WaterEntry {
  final String id;
  final String userId;
  final int amount;
  final String unit;
  final DateTime recordedAt;

  WaterEntry({
    required this.id,
    required this.userId,
    required this.amount,
    this.unit = 'ml',
    required this.recordedAt,
  });

  factory WaterEntry.fromJson(Map<String, dynamic> json) {
    return WaterEntry(
      id: json['id'],
      userId: json['user_id'],
      amount: json['amount'],
      unit: json['unit'] ?? 'ml',
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }
}

class StepsEntry {
  final String id;
  final String userId;
  final int steps;
  final DateTime recordedAt;

  StepsEntry({
    required this.id,
    required this.userId,
    required this.steps,
    required this.recordedAt,
  });

  factory StepsEntry.fromJson(Map<String, dynamic> json) {
    return StepsEntry(
      id: json['id'],
      userId: json['user_id'],
      steps: json['steps'],
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }
}

class WeightEntry {
  final String id;
  final String userId;
  final double weight;
  final String? notes;
  final DateTime recordedAt;

  WeightEntry({
    required this.id,
    required this.userId,
    required this.weight,
    this.notes,
    required this.recordedAt,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      id: json['id'],
      userId: json['user_id'],
      weight: double.parse(json['weight'].toString()),
      notes: json['notes'],
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }
}