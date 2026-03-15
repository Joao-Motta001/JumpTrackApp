import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../models/meal_model.dart';
import '../../providers/app_state.dart';
import '../../services/nutrition_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glow_card.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  Future<void> _showAddMealSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddMealSheet(),
    );
  }

  Future<void> _scanBarcode(BuildContext context) async {
    final meal = await Navigator.of(context).push<MealModel>(
      MaterialPageRoute(builder: (_) => const _BarcodeScannerScreen()),
    );
    if (meal != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${meal.name} added to today.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        final NutritionTargets? targets = app.nutritionTargets;
        final meals = app.mealsToday;
        return Scaffold(
          appBar: AppBar(title: const Text('Nutrition')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              GlowCard(
                accent: AppTheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Targets', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TargetStat(
                            label: 'Calories',
                            value: '${targets?.calories.toStringAsFixed(0) ?? '--'} kcal',
                          ),
                        ),
                        Expanded(
                          child: _TargetStat(
                            label: 'Protein',
                            value: '${targets?.protein.toStringAsFixed(0) ?? '--'} g',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _TargetStat(
                            label: 'Carbs',
                            value: '${targets?.carbs.toStringAsFixed(0) ?? '--'} g',
                          ),
                        ),
                        Expanded(
                          child: _TargetStat(
                            label: 'Fat',
                            value: '${targets?.fat.toStringAsFixed(0) ?? '--'} g',
                          ),
                        ),
                      ],
                    ),
                    if (targets?.matchAdjusted == true) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Match-day adjustment active: carbs +30% and hydration boosted.',
                        style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Macro Progress', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 14),
                    _MacroBar(
                      label: 'Calories',
                      consumed: app.caloriesConsumedToday,
                      target: targets?.calories ?? 1,
                      suffix: 'kcal',
                    ),
                    _MacroBar(
                      label: 'Protein',
                      consumed: app.proteinConsumedToday,
                      target: targets?.protein ?? 1,
                    ),
                    _MacroBar(
                      label: 'Carbs',
                      consumed: app.carbsConsumedToday,
                      target: targets?.carbs ?? 1,
                    ),
                    _MacroBar(
                      label: 'Fat',
                      consumed: app.fatConsumedToday,
                      target: targets?.fat ?? 1,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddMealSheet(context),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Meal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _scanBarcode(context),
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            label: const Text('Scan Barcode'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (app.hasMatchWithin48Hours) ...[
                const SizedBox(height: 16),
                GlowCard(
                  accent: AppTheme.warning,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pre-Game Fuel Suggestions', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      ...app.preGameMealSuggestions().map(
                        (tip) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.restaurant_rounded, color: AppTheme.warning, size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(tip)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text("Today's Meals", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (meals.isEmpty)
                const GlowCard(
                  child: Text(
                    'No meals logged today. Add meals manually or scan a barcode to start tracking macros.',
                    style: TextStyle(color: AppTheme.subtleText),
                  ),
                )
              else
                ...meals.map((meal) => _MealTile(meal: meal)),
            ],
          ),
        );
      },
    );
  }
}

class _TargetStat extends StatelessWidget {
  const _TargetStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.subtleText)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.consumed,
    required this.target,
    this.suffix = 'g',
  });

  final String label;
  final double consumed;
  final double target;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (consumed / target).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              Text('${consumed.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $suffix'),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppTheme.border,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal});

  final MealModel meal;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              image: meal.imageUrl != null && meal.imageUrl!.isNotEmpty
                  ? DecorationImage(image: NetworkImage(meal.imageUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: meal.imageUrl == null || meal.imageUrl!.isEmpty
                ? const Icon(Icons.fastfood_rounded, color: AppTheme.primary)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${meal.calories.toStringAsFixed(0)} kcal • P ${meal.protein.toStringAsFixed(0)} • C ${meal.carbs.toStringAsFixed(0)} • F ${meal.fat.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppTheme.subtleText),
                ),
                if (meal.servingSize != null && meal.servingSize!.isNotEmpty)
                  Text(
                    meal.servingSize!,
                    style: const TextStyle(color: AppTheme.subtleText, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMealSheet extends StatefulWidget {
  const _AddMealSheet();

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final calories = double.tryParse(_caloriesController.text.trim()) ?? 0;
    final protein = double.tryParse(_proteinController.text.trim()) ?? 0;
    final carbs = double.tryParse(_carbsController.text.trim()) ?? 0;
    final fat = double.tryParse(_fatController.text.trim()) ?? 0;

    if (name.isEmpty) return;

    await context.read<AppState>().addManualMeal(
          name: name,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
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
          Text('Add Meal', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Meal name')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Calories'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _proteinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Protein'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _carbsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Carbs'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _fatController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Fat'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _save, child: const Text('Save Meal')),
          ),
        ],
      ),
    );
  }
}

class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCode(BarcodeCapture capture) async {
    if (_busy) return;
    final code = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _busy = true);
    final meal = await context.read<AppState>().addMealFromBarcode(code);
    if (!mounted) return;

    if (meal == null) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to find nutrition data for that barcode.')),
      );
      return;
    }

    Navigator.pop(context, meal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Food Barcode')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleCode),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primary, width: 3),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.black.withOpacity(0.45),
              child: const Text(
                'Place the barcode inside the red frame. JumpTrack will fetch calories and macros from Open Food Facts.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (_busy)
            Container(
              color: Colors.black.withOpacity(0.55),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
