import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:json_formatter/main.dart';
import 'package:json_formatter/features/settings/presentation/providers/settings_provider.dart';

void main() {
  testWidgets('App Boots Smoke Test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify main app dashboard header contains name
    expect(find.text('JSON Formatter Pro'), findsOneWidget);
  });
}
