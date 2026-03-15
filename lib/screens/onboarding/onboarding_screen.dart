import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glow_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.editMode = false});

  final bool editMode;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '20');
  final _heightController = TextEditingController(text: '185');
  final _weightController = TextEditingController(text: '78');
  final _positionController = TextEditingController(text: 'Outside Hitter');

  final Set<String> _goals = {'increase vertical jump'};
  double _trainingDays = 4;
  double _matchDays = 1;
  bool _filledFromProfile = false;

  static const List<String> _goalOptions = [
    'increase vertical jump',
    'increase strength',
    'increase speed',
    'increase explosiveness',
    'improve endurance',
  ];

  static const List<String> _positions = [
    'Setter',
    'Outside Hitter',
    'Opposite',
    'Middle Blocker',
    'Libero',
    'Defensive Specialist',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filledFromProfile) return;
    final profile = context.read<AppState>().profile;
    if (profile != null) {
      _nameController.text = profile.name;
      _ageController.text = profile.age.toString();
      _heightController.text = profile.height.toStringAsFixed(0);
      _weightController.text = profile.weight.toStringAsFixed(0);
      _positionController.text = profile.volleyballPosition;
      _trainingDays = profile.trainingDays.toDouble();
      _matchDays = profile.matchDays.toDouble();
      _goals
        ..clear()
        ..addAll(profile.goals);
    }
    _filledFromProfile = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    if (name.isEmpty || age == null || height == null || weight == null || _goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all onboarding fields.')),
      );
      return;
    }

    final current = context.read<AppState>().profile;
    final profile = UserProfile(
      userId: current?.userId ?? '',
      email: current?.email ?? '',
      name: name,
      age: age,
      height: height,
      weight: weight,
      volleyballPosition: _positionController.text.trim(),
      trainingDays: _trainingDays.round(),
      matchDays: _matchDays.round(),
      goals: _goals.toList(),
      workoutCount: current?.workoutCount ?? 0,
      createdAt: current?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await context.read<AppState>().completeOnboarding(profile);
    if (widget.editMode && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final calories = _previewCalories;
    final protein = _previewWeight * 2;
    final carbs = _previewWeight * 4.5;
    final water = _previewWeight * 35;

    return Scaffold(
      appBar: widget.editMode ? AppBar(title: const Text('Edit Athlete Profile')) : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!widget.editMode) ...[
              Text(
                'Athlete Setup',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tell JumpTrack who you are so the app can generate nutrition, hydration, and a weekly performance plan.',
                style: TextStyle(color: AppTheme.subtleText, fontSize: 16),
              ),
              const SizedBox(height: 20),
            ],
            GlowCard(
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Age'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _positions.contains(_positionController.text.trim())
                              ? _positionController.text.trim()
                              : _positions.first,
                          decoration: const InputDecoration(labelText: 'Position'),
                          items: _positions
                              .map((position) => DropdownMenuItem(value: position, child: Text(position)))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _positionController.text = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Height (cm)'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Weight (kg)'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SliderField(
                    label: 'Training days / week',
                    value: _trainingDays,
                    min: 1,
                    max: 7,
                    onChanged: (value) => setState(() => _trainingDays = value),
                  ),
                  const SizedBox(height: 10),
                  _SliderField(
                    label: 'Match days / week',
                    value: _matchDays,
                    min: 0,
                    max: 4,
                    onChanged: (value) => setState(() => _matchDays = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlowCard(
              accent: AppTheme.secondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Athlete Goals', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _goalOptions.map((goal) {
                      final selected = _goals.contains(goal);
                      return FilterChip(
                        label: Text(goal),
                        selected: selected,
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _goals.add(goal);
                            } else {
                              _goals.remove(goal);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlowCard(
              accent: AppTheme.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Generated Daily Targets', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _TargetRow(label: 'Calories', value: '${calories.toStringAsFixed(0)} kcal'),
                  _TargetRow(label: 'Protein', value: '${protein.toStringAsFixed(0)} g'),
                  _TargetRow(label: 'Carbs', value: '${carbs.toStringAsFixed(0)} g'),
                  _TargetRow(label: 'Fat', value: '${_previewWeight.toStringAsFixed(0)} g'),
                  _TargetRow(label: 'Hydration', value: '${(water / 1000).toStringAsFixed(1)} L'),
                  const SizedBox(height: 10),
                  Text(
                    _trainingDays <= 3
                        ? 'Base recommendation: strength + plyometric balance with moderate volume.'
                        : 'Base recommendation: higher-volume explosive block with built-in recovery.' ,
                    style: const TextStyle(color: AppTheme.subtleText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(widget.editMode ? 'Save Profile' : 'Generate My Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get _previewWeight => double.tryParse(_weightController.text.trim()) ?? 78;
  double get _previewHeight => double.tryParse(_heightController.text.trim()) ?? 185;
  int get _previewAge => int.tryParse(_ageController.text.trim()) ?? 20;

  double get _previewCalories {
    final bmr = (10 * _previewWeight) + (6.25 * _previewHeight) - (5 * _previewAge) + 5;
    final activity = _trainingDays <= 3 ? 1.55 : 1.75;
    return bmr * activity;
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text(value.round().toString(), style: const TextStyle(color: AppTheme.primary)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.subtleText))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
