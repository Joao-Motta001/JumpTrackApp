import 'package:flutter_test/flutter_test.dart';

import 'package:jumptrack/theme/app_theme.dart';

void main() {
  test('jumptrack theme primary color is configured', () {
    expect(AppTheme.primary.value, 0xFFE50914);
  });
}
