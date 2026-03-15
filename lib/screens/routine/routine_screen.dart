import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/routine_task_model.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glow_card.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  DateTime get _monday {
    final only = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    return only.subtract(Duration(days: only.weekday - 1));
  }

  Future<void> _showAddTaskSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddTaskSheet(selectedDay: _selectedDay),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        final weekDays = List.generate(7, (index) => _monday.add(Duration(days: index)));
        final tasks = app.tasksForDay(_selectedDay);
        final score = app.scoreForDay(_selectedDay);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Routine'),
            actions: [
              IconButton(
                onPressed: () => app.generateRoutineForWeek(anchorDay: _selectedDay, force: true),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Regenerate week',
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddTaskSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Task'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              GlowCard(
                accent: AppTheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Routine', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(
                      'Today focus: ${app.planForDay(_selectedDay)}',
                      style: const TextStyle(color: AppTheme.subtleText),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: weekDays.map((day) {
                        final selected = DateUtils.isSameDay(day, _selectedDay);
                        return ChoiceChip(
                          label: Text('${DateFormat('EEE').format(day)} ${day.day}'),
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedDay = day),
                        );
                      }).toList(),
                    ),
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
                        Text('Daily Score', style: Theme.of(context).textTheme.titleLarge),
                        Text(
                          score.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: (score / 10).clamp(0, 1).toDouble(),
                      minHeight: 12,
                      backgroundColor: AppTheme.border,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Score is calculated from completed daily routine tasks on a 0–10 scale.',
                      style: TextStyle(color: AppTheme.subtleText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                DateFormat('EEEE, MMM d').format(_selectedDay),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                const GlowCard(
                  child: Text(
                    'No tasks for this day yet. Regenerate the week or add a custom task.',
                    style: TextStyle(color: AppTheme.subtleText),
                  ),
                )
              else
                ...tasks.map(
                  (task) => GlowCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: CheckboxListTile.adaptive(
                      value: task.completed,
                      onChanged: (value) => app.toggleRoutineTask(task, value ?? false),
                      contentPadding: EdgeInsets.zero,
                      title: Text(task.title),
                      subtitle: Text(task.type),
                      activeColor: AppTheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet({required this.selectedDay});

  final DateTime selectedDay;

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  String _type = 'training';

  static const _types = [
    'training',
    'mobility',
    'nutrition goal',
    'recovery',
    'hydration target',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    await context.read<AppState>().addRoutineTask(
          date: widget.selectedDay,
          title: title,
          type: _type,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Routine Task', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Task title')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Task type'),
            items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _type = value);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _save, child: const Text('Save Task')),
          ),
        ],
      ),
    );
  }
}
