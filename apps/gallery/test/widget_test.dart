import 'package:beui/beui.dart';
import 'package:beui_gallery/catalog/preview_fit.dart';
import 'package:beui_gallery/demos/motion/overlay_demos.dart';
import 'package:beui_gallery/main.dart';
import 'package:flutter/widgets.dart';
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
    expect(tester.takeException(), isNull);
  });

  testWidgets('scaled preview does not overflow a short card well',
      (tester) async {
    await tester.pumpWidget(
      BeuiTheme.wrap(
        brightness: Brightness.dark,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 280,
            height: 180,
            child: CatalogPreviewFit(
              child: SizedBox(
                height: 320,
                child: ColoredBox(color: Color(0xFF22C55E)),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('animated toast stack demo portals a toast onto Overlay',
      (tester) async {
    await tester.pumpWidget(
      BeuiTheme.wrap(
        brightness: Brightness.dark,
        child: WidgetsApp(
          color: const Color(0xFF151515),
          debugShowCheckedModeBanner: false,
          pageRouteBuilder: <T>(settings, builder) {
            return PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, _) => builder(context),
            );
          },
          home: const ColoredBox(
            color: Color(0xFF151515),
            child: AnimatedToastStackDemo(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Success'));
    await tester.pump();
    expect(find.text('Component published'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
