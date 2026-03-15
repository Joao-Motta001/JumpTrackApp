import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/calendar_event_model.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/progress_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        final profile = app.profile;
        final targets = app.nutritionTargets;
        final jumpValues = app.jumpRecords.reversed.map((item) => item.heightCm).toList();
        final jumpDates = app.jumpRecords.reversed.map((item) => item.timestamp).toList();
        final upcoming = app.upcomingEventsForDays(7).take(3).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('JumpTrack'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Chip(
                  label: Text(app.isDemoMode ? 'Demo' : 'Cloud'),
                  avatar: Icon(
                    app.isDemoMode ? Icons.bolt_rounded : Icons.cloud_done_rounded,
                    color: app.isDemoMode ? AppTheme.warning : AppTheme.success,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: app.refreshFromCloud,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                GlowCard(
                  accent: AppTheme.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome ${profile?.name.split(' ').first ?? 'Athlete'}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Today focus: ${app.todayPlanFocus}',
                        style: const TextStyle(color: AppTheme.subtleText, fontSize: 16),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _QuickBadge(label: profile?.volleyballPosition ?? 'Volleyball'),
                          _QuickBadge(label: '${profile?.trainingDays ?? 0} training days'),
                          _QuickBadge(label: app.hasMatchWithin48Hours ? 'Match in 48h' : 'No urgent match'),
                        ],
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
                  childAspectRatio: 1.35,
                  children: [
                    _MetricCard(
                      title: 'Calories',
                      value: '${app.caloriesConsumedToday.toStringAsFixed(0)} / ${targets?.calories.toStringAsFixed(0) ?? '--'}',
                      subtitle: 'Daily fuel',
                      icon: Icons.local_fire_department_rounded,
                    ),
                    _MetricCard(
                      title: 'Hydration',
                      value: '${(app.waterConsumedToday / 1000).toStringAsFixed(1)} L',
                      subtitle: '${((app.hydrationProgress) * 100).toStringAsFixed(0)}% of target',
                      icon: Icons.water_drop_rounded,
                    ),
                    _MetricCard(
                      title: 'Best Jump',
                      value: '${app.bestJumpCm.toStringAsFixed(1)} cm',
                      subtitle: 'All-time best',
                      icon: Icons.height_rounded,
                    ),
                    _MetricCard(
                      title: 'Daily Score',
                      value: app.scoreForDay(DateTime.now()).toStringAsFixed(1),
                      subtitle: 'Routine execution',
                      icon: Icons.stars_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GlowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Jump Trend', style: Theme.of(context).textTheme.titleLarge),
                          Text(
                            app.jumpRecords.isEmpty
                                ? 'No jumps yet'
                                : '${app.jumpImprovementLast4Weeks >= 0 ? '+' : ''}${app.jumpImprovementLast4Weeks.toStringAsFixed(1)} cm / 4 weeks',
                            style: TextStyle(
                              color: app.jumpImprovementLast4Weeks >= 0 ? AppTheme.success : AppTheme.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ProgressChart(values: jumpValues, dates: jumpDates),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlowCard(
                  accent: AppTheme.secondary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Recommendations', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      ...app.recommendations.map((item) => _RecommendationTile(text: item)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Upcoming Events', style: Theme.of(context).textTheme.titleLarge),
                          Text(
                            '${upcoming.length} this week',
                            style: const TextStyle(color: AppTheme.subtleText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (upcoming.isEmpty)
                        const Text('No events scheduled this week.', style: TextStyle(color: AppTheme.subtleText))
                      else
                        ...upcoming.map((event) => _EventTile(event: event)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly Plan', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      ...app.weeklyPlan.entries.map(
                        (entry) => _PlanTile(
                          day: entry.key,
                          focus: entry.value,
                          highlight: entry.key == DateFormat('EEEE').format(DateTime.now()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary),
          const Spacer(),
          Text(title, style: const TextStyle(color: AppTheme.subtleText)),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: AppTheme.subtleText, fontSize: 12)),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final CalendarEventModel event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: event.type == 'match' ? AppTheme.primary : AppTheme.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  '${DateFormat('EEE, MMM d • HH:mm').format(event.startTime)} · ${event.type}',
                  style: const TextStyle(color: AppTheme.subtleText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.day,
    required this.focus,
    required this.highlight,
  });

  final String day;
  final String focus;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.primary.withOpacity(0.10) : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlight ? AppTheme.primary.withOpacity(0.35) : AppTheme.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(day, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(child: Text(focus, style: const TextStyle(color: AppTheme.subtleText))),
        ],
      ),
    );
  }
}

class _QuickBadge extends StatelessWidget {
  const _QuickBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
