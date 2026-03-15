import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/workout_model.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/tiktok_player_widget.dart';
import '../../widgets/workout_timer.dart';
import '../../widgets/youtube_player_widget.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  Future<void> _createWorkout(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateWorkoutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Workout Builder'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${app.completedWorkouts} completed',
                    style: const TextStyle(color: AppTheme.subtleText),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createWorkout(context),
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Workout'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              GlowCard(
                accent: AppTheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Training Engine', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(
                      'Completion rate last 7 days: ${(app.workoutCompletionRateLast7Days * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create custom training blocks, attach tutorial videos, time live sessions, and store every finished workout in Firestore.',
                      style: TextStyle(color: AppTheme.subtleText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (app.workouts.isEmpty)
                const GlowCard(
                  child: Text(
                    'No workouts yet. Create your first routine with strength, plyometrics, speed, or recovery exercises.',
                    style: TextStyle(color: AppTheme.subtleText),
                  ),
                )
              else
                ...app.workouts.map((workout) => _WorkoutCard(workout: workout)),
            ],
          ),
        );
      },
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.workout});

  final WorkoutModel workout;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(workout.title, style: Theme.of(context).textTheme.titleLarge),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: workout.completed ? AppTheme.success.withOpacity(0.15) : AppTheme.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  workout.completed ? 'Completed' : 'Planned',
                  style: TextStyle(
                    color: workout.completed ? AppTheme.success : AppTheme.subtleText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (workout.description.isNotEmpty)
            Text(workout.description, style: const TextStyle(color: AppTheme.subtleText)),
          const SizedBox(height: 10),
          Text(
            '${workout.exercises.length} exercises • ${DateFormat('MMM d, HH:mm').format(workout.scheduledAt)}',
            style: const TextStyle(color: AppTheme.subtleText),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: workout.exercises.take(4).map((exercise) {
              return Chip(label: Text(exercise.name));
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WorkoutSessionScreen(workout: workout),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(workout.completed ? 'Open Session' : 'Start Workout'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateWorkoutSheet extends StatefulWidget {
  const _CreateWorkoutSheet();

  @override
  State<_CreateWorkoutSheet> createState() => _CreateWorkoutSheetState();
}

class _CreateWorkoutSheetState extends State<_CreateWorkoutSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _exerciseNameController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '5');
  final _weightController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  final _videoController = TextEditingController();

  final List<ExerciseModel> _exercises = [];
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _exerciseNameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void _addExercise() {
    final name = _exerciseNameController.text.trim();
    if (name.isEmpty) return;
    final exercise = ExerciseModel(
      name: name,
      sets: int.tryParse(_setsController.text.trim()) ?? 3,
      reps: int.tryParse(_repsController.text.trim()) ?? 5,
      weight: double.tryParse(_weightController.text.trim()) ?? 0,
      notes: _notesController.text.trim(),
      videoUrl: _videoController.text.trim(),
    );
    setState(() {
      _exercises.add(exercise);
      _exerciseNameController.clear();
      _setsController.text = '3';
      _repsController.text = '5';
      _weightController.text = '0';
      _notesController.clear();
      _videoController.clear();
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _saveWorkout() async {
    if (_titleController.text.trim().isEmpty || _exercises.isEmpty) return;
    await context.read<AppState>().createWorkout(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          exercises: _exercises,
          scheduledAt: _scheduledAt,
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Workout', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Workout title')),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description / focus'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.schedule_rounded),
              label: Text('Scheduled for ${DateFormat('MMM d, HH:mm').format(_scheduledAt)}'),
            ),
            const SizedBox(height: 16),
            Text('Add Exercise', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(controller: _exerciseNameController, decoration: const InputDecoration(labelText: 'Exercise name')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sets'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Weight'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes')),
            const SizedBox(height: 12),
            TextField(
              controller: _videoController,
              decoration: const InputDecoration(labelText: 'YouTube or TikTok video link'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Exercise to Workout'),
              ),
            ),
            if (_exercises.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Exercises', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...List.generate(_exercises.length, (index) {
                final exercise = _exercises[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${exercise.name} • ${exercise.sets}x${exercise.reps} @ ${exercise.weight.toStringAsFixed(0)}',
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _exercises.removeAt(index)),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _saveWorkout, child: const Text('Save Workout')),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key, required this.workout});

  final WorkoutModel workout;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final WorkoutTimerController _timerController = WorkoutTimerController();
  late final List<bool> _completed;

  @override
  void initState() {
    super.initState();
    _completed = widget.workout.exercises.map((exercise) => exercise.completed).toList();
    _timerController.start();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    _timerController.pause();
    await context.read<AppState>().completeWorkoutSession(
          workout: widget.workout,
          completedExercises: _completed,
          duration: _timerController.elapsed.value,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout saved successfully.')),
    );
    Navigator.pop(context);
  }

  void _openVideo(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _VideoTutorialScreen(url: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.workout.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          GlowCard(
            accent: AppTheme.primary,
            child: WorkoutTimer(controller: _timerController),
          ),
          const SizedBox(height: 16),
          ...List.generate(widget.workout.exercises.length, (index) {
            final exercise = widget.workout.exercises[index];
            return GlowCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(exercise.name, style: Theme.of(context).textTheme.titleLarge),
                      ),
                      Checkbox.adaptive(
                        value: _completed[index],
                        onChanged: (value) => setState(() => _completed[index] = value ?? false),
                      ),
                    ],
                  ),
                  Text(
                    '${exercise.sets} sets • ${exercise.reps} reps • ${exercise.weight.toStringAsFixed(0)} kg',
                    style: const TextStyle(color: AppTheme.subtleText),
                  ),
                  if (exercise.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(exercise.notes),
                  ],
                  if (exercise.videoUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _openVideo(exercise.videoUrl),
                      icon: const Icon(Icons.ondemand_video_rounded),
                      label: const Text('Watch Tutorial In-App'),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _finish,
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Finish Workout'),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoTutorialScreen extends StatelessWidget {
  const _VideoTutorialScreen({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final lower = url.toLowerCase();
    final Widget child;
    if (lower.contains('youtube') || lower.contains('youtu.be')) {
      child = YoutubePlayerWidget(url: url);
    } else if (lower.contains('tiktok')) {
      child = TikTokPlayerWidget(url: url);
    } else {
      child = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText(url, textAlign: TextAlign.center),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tutorial Video')),
      body: child,
    );
  }
}
