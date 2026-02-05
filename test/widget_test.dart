import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_flashcard_app/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CardlyApp(),
      ),
    );

    // Allow the app to build
    await tester.pumpAndSettle();

    // Verify the app shows something
    expect(find.byType(CardlyApp), findsOneWidget);
  });

  group('Card Model Tests', () {
    test('CardType has correct display names', () {
      // Placeholder test - implement when models are generated
      expect(true, isTrue);
    });
  });

  group('SM-2 Algorithm Tests', () {
    test('calculateNextReview updates interval correctly', () {
      // Placeholder test - implement when models are generated
      expect(true, isTrue);
    });
  });
}
