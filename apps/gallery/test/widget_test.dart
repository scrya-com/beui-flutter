import 'package:beui_gallery/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('gallery lists live demos in dark mode', (tester) async {
    await tester.pumpWidget(const BeuiGalleryApp());
    expect(find.text('beUI for Flutter'), findsOneWidget);
    expect(find.text('Components'), findsOneWidget);
    expect(find.text('Live'), findsWidgets);
    expect(find.text('Soon'), findsNothing);
    expect(find.textContaining('Not ported yet'), findsNothing);
  });
}
