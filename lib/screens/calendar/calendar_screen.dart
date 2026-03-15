import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/calendar_event_model.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glow_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Future<void> _addEvent() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EventEditorSheet(selectedDay: _selectedDay),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        final selectedEvents = app.eventsForDay(_selectedDay);
        final targets = app.nutritionTargetsFor(_selectedDay);
        final hasMatch = app.hasMatchOnDate(_selectedDay);

        return Scaffold(
          appBar: AppBar(title: const Text('Calendar')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addEvent,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Event'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              GlowCard(
                child: TableCalendar<CalendarEventModel>(
                  firstDay: DateTime.utc(2023, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => DateUtils.isSameDay(day, _selectedDay),
                  eventLoader: app.eventsForDay,
                  headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.20),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    markerDecoration: const BoxDecoration(color: AppTheme.warning, shape: BoxShape.circle),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (hasMatch)
                GlowCard(
                  accent: AppTheme.warning,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Match-Day Adjustment', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Text('Calories: ${targets?.calories.toStringAsFixed(0) ?? '--'} kcal'),
                      Text('Carbs: ${targets?.carbs.toStringAsFixed(0) ?? '--'} g'),
                      Text('Hydration: ${((targets?.waterMl ?? 0) / 1000).toStringAsFixed(1)} L'),
                      const SizedBox(height: 10),
                      const Text(
                        'Boost carbs by 30%, raise hydration, and choose an easy-to-digest pre-game meal.',
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
              if (selectedEvents.isEmpty)
                const GlowCard(
                  child: Text(
                    'No events on this day. Add a training session, volleyball match, or friendly game.',
                    style: TextStyle(color: AppTheme.subtleText),
                  ),
                )
              else
                ...selectedEvents.map((event) => _CalendarEventTile(event: event)),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarEventTile extends StatelessWidget {
  const _CalendarEventTile({required this.event});

  final CalendarEventModel event;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: event.type == 'match'
                  ? AppTheme.primary
                  : event.type == 'friendly'
                      ? AppTheme.warning
                      : AppTheme.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)} • ${event.type}',
                  style: const TextStyle(color: AppTheme.subtleText),
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(event.description),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventEditorSheet extends StatefulWidget {
  const _EventEditorSheet({required this.selectedDay});

  final DateTime selectedDay;

  @override
  State<_EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends State<_EventEditorSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'training';
  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    _start = const TimeOfDay(hour: 18, minute: 0);
    _end = const TimeOfDay(hour: 20, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final time = await showTimePicker(context: context, initialTime: _start);
    if (time != null) setState(() => _start = time);
  }

  Future<void> _pickEnd() async {
    final time = await showTimePicker(context: context, initialTime: _end);
    if (time != null) setState(() => _end = time);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : (_type == 'training' ? 'Training Session' : _type == 'match' ? 'Volleyball Match' : 'Friendly Game');
    final start = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
      _start.hour,
      _start.minute,
    );
    final end = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
      _end.hour,
      _end.minute,
    );

    final event = CalendarEventModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      userId: '',
      title: title,
      type: _type,
      startTime: start,
      endTime: end.isAfter(start) ? end : start.add(const Duration(hours: 2)),
      description: _descriptionController.text.trim(),
    );

    await context.read<AppState>().addCalendarEvent(event);
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
          Text('Add Calendar Event', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Event type'),
            items: const [
              DropdownMenuItem(value: 'training', child: Text('Training Session')),
              DropdownMenuItem(value: 'match', child: Text('Volleyball Match')),
              DropdownMenuItem(value: 'friendly', child: Text('Friendly Game')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _type = value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Start ${_start.format(context)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEnd,
                  icon: const Icon(Icons.stop_rounded),
                  label: Text('End ${_end.format(context)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _save, child: const Text('Save Event')),
          ),
        ],
      ),
    );
  }
}
