import 'package:beui_gallery/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('gallery shows the upstream-style catalog', (tester) async {
    await tester.pumpWidget(const BeuiGalleryApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('beUI'), findsOneWidget);
    expect(find.text('Agents'), findsOneWidget);
    expect(find.text('Animated AI agent components'), findsOneWidget);
    expect(find.text('Conversation components'), findsOneWidget);
    expect(find.textContaining('Not ported yet'), findsNothing);
  });
}
