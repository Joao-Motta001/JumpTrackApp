import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glow_card.dart';

class HydrationScreen extends StatelessWidget {
  const HydrationScreen({super.key});

  Future<void> _addWater(BuildContext context, int amountMl) async {
    await context.read<AppState>().addWaterLog(amountMl);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        final targetMl = app.nutritionTargets?.waterMl ?? 0;
        final logs = app.waterLogsToday;
        return Scaffold(
          appBar: AppBar(title: const Text('Hydration')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              GlowCard(
                accent: AppTheme.primary,
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: app.hydrationProgress),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, _) {
                        return SizedBox(
                          width: 180,
                          height: 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: value,
                                strokeWidth: 12,
                                backgroundColor: AppTheme.border,
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(app.waterConsumedToday / 1000).toStringAsFixed(1)} L',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'of ${(targetMl / 1000).toStringAsFixed(1)} L',
                                    style: const TextStyle(color: AppTheme.subtleText),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Hydrate aggressively to protect power output, recovery, and jump consistency.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.subtleText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Add', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [250, 500, 750, 1000].map((amount) {
                        return ActionChip(
                          label: Text('+ ${amount} ml'),
                          avatar: const Icon(Icons.local_drink_rounded, size: 18),
                          onPressed: () => _addWater(context, amount),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: app.hydrationRemindersEnabled,
                      onChanged: (value) => app.toggleHydrationReminders(value),
                      title: const Text('Water reminders'),
                      subtitle: const Text(
                        'Receive automatic hydration reminders through the day.',
                        style: TextStyle(color: AppTheme.subtleText),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text("Today's Water Logs", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (logs.isEmpty)
                const GlowCard(
                  child: Text(
                    'No hydration entries yet. Log your first bottle to start progress tracking.',
                    style: TextStyle(color: AppTheme.subtleText),
                  ),
                )
              else
                ...logs.map((log) {
                  return GlowCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.water_drop_rounded, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('${log.amountMl} ml'),
                        ),
                        Text(
                          TimeOfDay.fromDateTime(log.timestamp).format(context),
                          style: const TextStyle(color: AppTheme.subtleText),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
