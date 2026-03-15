import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/meal_model.dart';
import '../models/user_model.dart';

class NutritionTargets {
  const NutritionTargets({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.waterMl,
    this.matchAdjusted = false,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double waterMl;
  final bool matchAdjusted;
}

class NutritionService {
  final Uuid _uuid = const Uuid();

  NutritionTargets calculateTargets({required UserProfile profile, bool hasMatch = false}) {
    final bmr = (10 * profile.weight) + (6.25 * profile.height) - (5 * profile.age) + 5;
    final activityFactor = profile.trainingDays <= 3 ? 1.55 : 1.75;

    var calories = bmr * activityFactor;
    final protein = profile.weight * 2;
    var carbs = profile.weight * 4.5;
    final fat = profile.weight * 1;
    var waterMl = profile.weight * 35;

    if (hasMatch) {
      carbs *= 1.30;
      waterMl *= 1.15;
      calories *= 1.08;
    }

    return NutritionTargets(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      waterMl: waterMl,
      matchAdjusted: hasMatch,
    );
  }

  Future<MealModel?> fetchMealByBarcode({required String barcode, required String userId}) async {
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode'
      '?fields=product_name,nutriments,image_front_small_url,serving_size',
    );

    final response = await http.get(uri, headers: const {
      'User-Agent': 'JumpTrack-Flutter-App/1.0 (support@jumptrack.app)',
    });

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final product = data['product'];
    if (product is! Map<String, dynamic>) return null;

    final nutriments = Map<String, dynamic>.from(product['nutriments'] ?? const {});

    return MealModel(
      id: _uuid.v4(),
      userId: userId,
      name: product['product_name']?.toString().trim().isNotEmpty == true
          ? product['product_name'].toString()
          : 'Scanned Food',
      calories: _extractCalories(nutriments),
      protein: _extractValue(nutriments, const ['proteins_serving', 'proteins_100g', 'proteins']),
      carbs: _extractValue(nutriments, const ['carbohydrates_serving', 'carbohydrates_100g', 'carbohydrates']),
      fat: _extractValue(nutriments, const ['fat_serving', 'fat_100g', 'fat']),
      timestamp: DateTime.now(),
      barcode: barcode,
      source: 'open_food_facts',
      imageUrl: product['image_front_small_url']?.toString(),
      servingSize: product['serving_size']?.toString(),
    );
  }

  List<String> preGameMealSuggestions() {
    return const [
      'Rice bowl with grilled chicken and fruit 3–4h before match',
      'Oats, banana, yogurt, and honey for quick, digestible pre-game carbs',
      'Turkey sandwich + fruit + electrolytes for lighter digestion',
      'Post-match: lean protein + fast carbs + 500–750 ml water',
    ];
  }

  double _extractCalories(Map<String, dynamic> nutriments) {
    final kcal = _extractValue(
      nutriments,
      const ['energy-kcal_serving', 'energy-kcal_100g', 'energy-kcal', 'energy-kcal_value'],
    );
    if (kcal > 0) return kcal;
    final kj = _extractValue(
      nutriments,
      const ['energy_serving', 'energy-kj_serving', 'energy_100g', 'energy-kj_100g'],
    );
    if (kj > 0) return kj / 4.184;
    return 0;
  }

  double _extractValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }
}
