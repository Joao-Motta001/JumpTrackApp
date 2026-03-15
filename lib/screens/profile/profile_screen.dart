import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glow_card.dart';
import '../onboarding/onboarding_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        final profile = app.profile;
        final targets = app.nutritionTargets;

        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              GlowCard(
                accent: AppTheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 38),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile?.name ?? 'Athlete', style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 4),
                              Text(
                                '${profile?.volleyballPosition ?? 'Volleyball'} • ${profile?.age ?? 0} y • ${profile?.height.toStringAsFixed(0) ?? '--'} cm • ${profile?.weight.toStringAsFixed(0) ?? '--'} kg',
                                style: const TextStyle(color: AppTheme.subtleText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: (profile?.goals ?? const <String>[])
                          .map((goal) => Chip(label: Text(goal)))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.45,
                children: [
                  _ProfileStat(label: 'Workouts', value: '${profile?.workoutCount ?? 0}'),
                  _ProfileStat(label: 'Best Jump', value: '${app.bestJumpCm.toStringAsFixed(1)} cm'),
                  _ProfileStat(label: 'Training Days', value: '${profile?.trainingDays ?? 0}/wk'),
                  _ProfileStat(label: 'Hydration', value: '${((targets?.waterMl ?? 0) / 1000).toStringAsFixed(1)} L'),
                ],
              ),
              const SizedBox(height: 16),
              GlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Targets Snapshot', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _ProfileRow(label: 'Calories', value: '${targets?.calories.toStringAsFixed(0) ?? '--'} kcal'),
                    _ProfileRow(label: 'Protein', value: '${targets?.protein.toStringAsFixed(0) ?? '--'} g'),
                    _ProfileRow(label: 'Carbohydrates', value: '${targets?.carbs.toStringAsFixed(0) ?? '--'} g'),
                    _ProfileRow(label: 'Fat', value: '${targets?.fat.toStringAsFixed(0) ?? '--'} g'),
                    _ProfileRow(label: 'Hydration', value: '${((targets?.waterMl ?? 0) / 1000).toStringAsFixed(1)} L'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlowCard(
                accent: app.isDemoMode ? AppTheme.warning : AppTheme.success,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cloud Status', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(
                      app.isDemoMode
                          ? 'Demo mode active. Data is still cached locally on this device.'
                          : app.isCloudEnabled
                              ? 'Firebase connected. Authentication, Firestore, Messaging, and Storage are enabled.'
                              : 'Firebase placeholder configuration detected. Replace configuration files to enable live services.',
                      style: const TextStyle(color: AppTheme.subtleText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen(editMode: true)),
                  );
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Profile'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.read<AppState>().signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.subtleText)),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.subtleText))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
