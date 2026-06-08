class PregnancyProfile {
  final String id;
  final String userId;
  final DateTime lastPeriodDate;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  PregnancyProfile({
    required this.id,
    required this.userId,
    required this.lastPeriodDate,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PregnancyProfile.fromJson(Map<String, dynamic> json) {
    return PregnancyProfile(
      id: json['id'],
      userId: json['user_id'],
      lastPeriodDate: DateTime.parse(json['last_period_date']),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Calculate current pregnancy week
  int get currentWeek {
    final now = DateTime.now();
    final daysSinceLastPeriod = now.difference(lastPeriodDate).inDays;
    return (daysSinceLastPeriod / 7).floor();
  }

  // Calculate current pregnancy day within week
  int get currentDayInWeek {
    final now = DateTime.now();
    final daysSinceLastPeriod = now.difference(lastPeriodDate).inDays;
    return daysSinceLastPeriod % 7;
  }

  // Calculate how many days until due date
  int get daysUntilDue {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  // Check if pregnancy is full term (40 weeks)
  bool get isFullTerm => currentWeek >= 40;

  // Get pregnancy progress percentage
  double get progressPercentage {
    const totalWeeks = 40;
    return (currentWeek / totalWeeks * 100).clamp(0, 100);
  }

  // Baby size comparison based on week
  String get babySizeDescription {
    final week = currentWeek;
    if (week < 4) return ' Poppy seed';
    if (week < 8) return ' Raspberry';
    if (week < 12) return ' Lime';
    if (week < 16) return ' Avocado';
    if (week < 20) return ' Banana';
    if (week < 24) return ' Papaya';
    if (week < 28) return ' Eggplant';
    if (week < 32) return ' Coconut';
    if (week < 36) return ' Romaine lettuce';
    if (week < 40) return ' Pumpkin';
    return ' Watermelon';
  }

  // Baby development description
  String get babyDevelopmentDescription {
    final week = currentWeek;
    if (week < 4) return 'Fertilization and implantation occur';
    if (week < 8) return 'Heart begins to beat, major organs form';
    if (week < 12) return 'Baby can open fists, fingers form';
    if (week < 16) return 'Baby can make facial expressions';
    if (week < 20) return 'Halfway there! Baby is very active';
    if (week < 24) return 'Baby has taste buds, lungs develop';
    if (week < 28) return 'Baby can open eyes, brain rapidly developing';
    if (week < 32) return 'Baby practices breathing, bones hardening';
    if (week < 36) return 'Baby is gaining weight rapidly';
    if (week < 40) return 'Baby is full term, ready for birth';
    return 'Baby should arrive soon!';
  }
}