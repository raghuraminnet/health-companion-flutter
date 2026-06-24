import 'package:flutter/material.dart';
import '../models/pregnancy.dart';

class PregnancyScreen extends StatefulWidget {
  const PregnancyScreen({super.key});

  @override
  State<PregnancyScreen> createState() => _PregnancyScreenState();
}

class _PregnancyScreenState extends State<PregnancyScreen> {
  PregnancyProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  DateTime _lastPeriodDate = DateTime.now().subtract(const Duration(days: 60));

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      // For now, create a demo profile since API might not have pregnancy endpoint
      setState(() {
        _profile = null; // Will show setup screen
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pregnancy Tracker'),
        actions: [
          if (_profile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? _buildSetupScreen()
              : _buildPregnancyDashboard(),
    );
  }

  Widget _buildSetupScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.pregnant_woman,
            size: 80,
            color: Colors.pink,
          ),
          const SizedBox(height: 24),
          Text(
            'Set Up Pregnancy Tracking',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter your last period date to track your pregnancy progress',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Period Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 12),
                          Text(
                            '${_lastPeriodDate.day}/${_lastPeriodDate.month}/${_lastPeriodDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Tracking'),
          ),
        ],
      ),
    );
  }

  Widget _buildPregnancyDashboard() {
    final profile = _profile!;
    final week = profile.currentWeek;
    final day = profile.currentDayInWeek;
    final progress = profile.progressPercentage;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Baby Progress Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Week $week, Day $day',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Due: ${profile.dueDate?.day}/${profile.dueDate?.month}/${profile.dueDate?.year ?? "TBD"}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  // Progress Ring
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.pink.shade100,
                          valueColor: const AlwaysStoppedAnimation(Colors.pink),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${progress.toInt()}%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('complete', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
 ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Baby Size Card
          Card(
            color: Colors.pink.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.child_friendly, size: 48, color: Colors.pink),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Baby is the size of a',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          profile.babySizeDescription,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Baby Development Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        'Baby Development',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.babyDevelopmentDescription,
                    style: const TextStyle(fontSize: 16),
 ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tips Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for Week $week',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('Stay hydrated - drink 8-10 glasses of water daily'),
                  _buildTip('Take prenatal vitamins if not already doing so'),
                  _buildTip('Get plenty of rest and listen to your body'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.pink)),
          Expanded(child: Text(tip)),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _lastPeriodDate,
      firstDate: DateTime.now().subtract(const Duration(days: 280)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _lastPeriodDate = date);
    }
  }

  Future<void> _saveProfile() async {
    // Calculate due date (40 weeks from last period)
    final dueDate = _lastPeriodDate.add(const Duration(days: 280));
    
    // Create local profile for demo
    setState(() {
      _profile = PregnancyProfile(
        id: 'local',
        userId: 'local',
        lastPeriodDate: _lastPeriodDate,
        dueDate: dueDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _isEditing = false;
    });
  }
}