import 'package:beui/beui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('spring physics (Rust closed form)', () {
    test('response is 1 at t=0 and decays toward 0', () {
      const spec = BeuiSpringSpec.press;
      expect(
        beuiSpringResponse(0, spec.mass, spec.stiffness, spec.damping),
        closeTo(1, 1e-9),
      );
      expect(
        beuiSpringEase(0, spec.mass, spec.stiffness, spec.damping),
        closeTo(0, 1e-9),
      );
      expect(
        beuiSpringEase(1.0, spec.mass, spec.stiffness, spec.damping),
        closeTo(1, 0.05),
      );
    });

    test('overdamped panel spring does not overshoot', () {
      const spec = BeuiSpringSpec.panel;
      var max = 0.0;
      for (var i = 0; i <= 200; i++) {
        final v = beuiSpringEaseSpec(i / 200, spec);
        if (v > max) max = v;
      }
      expect(max, lessThanOrEqualTo(1.02));
    });

    test('snapSliderValue matches the React helper', () {
      expect(snapSliderValue(37, 0, 100, 10), 40);
      expect(snapSliderValue(100, 0, 100, 15), 100);
      expect(snapSliderValue(-4, 0, 100, 1), 0);
    });
  });

  group('BeuiAgentProgress', () {
    testWidgets('formats 151.6s as 2m 31.6s like the React helper',
        (tester) async {
      await tester.pumpWidget(
        BeuiTheme.wrap(
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: BeuiAgentProgress(
              label: 'Churning',
              elapsedSeconds: 151.6,
              fontSize: 16,
            ),
          ),
        ),
      );
      expect(find.text('2m 31.6s'), findsOneWidget);
      expect(find.text('Churning'), findsOneWidget);
    });
  });

  group('BeuiSwitch', () {
    testWidgets('controlled value is not written by the widget', (tester) async {
      var last = false;
      const value = false;
      await tester.pumpWidget(
        BeuiTheme.wrap(
          brightness: Brightness.light,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: BeuiSwitch(
                value: value,
                onChanged: (v) => last = v,
                label: 'Notify',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Notify'));
      await tester.pump();
      expect(last, isTrue);
      expect(value, isFalse);
    });

    testWidgets('uncontrolled switch toggles internally', (tester) async {
      var last = false;
      await tester.pumpWidget(
        BeuiTheme.wrap(
          brightness: Brightness.light,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: BeuiSwitch(
                initialValue: false,
                onChanged: (v) => last = v,
                label: 'On',
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('On'));
      await tester.pump();
      expect(last, isTrue);
    });
  });

  group('BeuiButton', () {
    testWidgets('press fires onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        BeuiTheme.wrap(
          brightness: Brightness.light,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: BeuiButton(
                onPressed: () => taps++,
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      expect(taps, 1);
    });

    testWidgets('hover then press retargets without starting the ticker twice',
        (tester) async {
      await tester.pumpWidget(
        BeuiTheme.wrap(
          brightness: Brightness.light,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: BeuiButton(
                onPressed: () {},
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('Go')));
      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('disabled button does not fire', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        BeuiTheme.wrap(
          brightness: Brightness.light,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: BeuiButton(
                enabled: false,
                onPressed: () => taps++,
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      expect(taps, 0);
    });
  });

  group('BeuiTabs', () {
    testWidgets('selects a trigger and keeps inactive content offstage',
        (tester) async {
      await tester.pumpWidget(
        BeuiTheme.wrap(
          brightness: Brightness.light,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: BeuiTabs(
              initialValue: 'a',
              child: Column(
                children: [
                  BeuiTabsList(
                    children: [
                      BeuiTabsTrigger(value: 'a', child: Text('A')),
                      BeuiTabsTrigger(value: 'b', child: Text('B')),
                    ],
                  ),
                  BeuiTabsContent(value: 'a', child: Text('Panel A')),
                  BeuiTabsContent(value: 'b', child: Text('Panel B')),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Panel A'), findsOneWidget);
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(find.text('Panel B'), findsOneWidget);
    });
  });

  group('BeuiToolResult', () {
    testWidgets('re-opens when a completed run starts again', (tester) async {
      var open = false;
      await tester.pumpWidget(
        BeuiTheme.wrap(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: BeuiToolResult(
                tool: 'test',
                title: 'Done',
                output: 'ok',
                status: BeuiToolResultStatus.success,
                open: open,
                onOpenChanged: (v) => open = v,
                collapseOnComplete: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(
        BeuiTheme.wrap(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: BeuiToolResult(
                tool: 'test',
                title: 'Running',
                output: '',
                status: BeuiToolResultStatus.running,
                open: open,
                onOpenChanged: (v) => open = v,
              ),
            ),
          ),
        ),
      );
      expect(open, isTrue);
    });
  });

  group('BeuiFileDiff', () {
    testWidgets('re-opens when a completed diff starts streaming again',
        (tester) async {
      var open = false;
      await tester.pumpWidget(
        BeuiTheme.wrap(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: BeuiFileDiff(
              file: 'a.ts',
              open: open,
              onOpenChanged: (v) => open = v,
              status: BeuiFileDiffStatus.complete,
              lines: const [
                BeuiFileDiffLine(id: '1', content: 'done'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpWidget(
        BeuiTheme.wrap(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: BeuiFileDiff(
              file: 'a.ts',
              open: open,
              onOpenChanged: (v) => open = v,
              status: BeuiFileDiffStatus.streaming,
              lines: const [
                BeuiFileDiffLine(id: '1', content: 'run'),
              ],
            ),
          ),
        ),
      );
      expect(open, isTrue);
    });
  });

  group('BeuiTodoList', () {
    testWidgets('re-opens when a completed plan starts a new lifecycle',
        (tester) async {
      var open = false;
      await tester.pumpWidget(
        BeuiTheme.wrap(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: BeuiTodoList(
                open: open,
                onOpenChanged: (v) => open = v,
                items: const [
                  BeuiTodoItem(
                    id: 'a',
                    title: 'Done',
                    status: BeuiTodoStatus.completed,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(
        BeuiTheme.wrap(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: BeuiTodoList(
                open: open,
                onOpenChanged: (v) => open = v,
                items: const [
                  BeuiTodoItem(
                    id: 'a',
                    title: 'Done',
                    status: BeuiTodoStatus.pending,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(open, isTrue);
    });
  });

  group('BeuiMessageScroller', () {
    testWidgets('pins to the live edge when output grows', (tester) async {
      var count = 8;
      await tester.pumpWidget(
        BeuiTheme.wrap(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(400, 800)),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      BeuiMessageScroller(
                        height: 160,
                        children: [
                          for (var i = 0; i < count; i++)
                            BeuiScrollerMessage(
                              id: '$i',
                              from: BeuiMessageFrom.assistant,
                              text: 'Line $i of a longer conversation transcript',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Line $i of a longer conversation transcript',
                                ),
                              ),
                            ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() => count += 4),
                        child: const Text('Grow'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      var pos = tester.state<ScrollableState>(find.byType(Scrollable)).position;
      expect(pos.maxScrollExtent, greaterThan(0));
      expect(pos.pixels, closeTo(pos.maxScrollExtent, 2));

      await tester.tap(find.text('Grow'));
      await tester.pumpAndSettle();
      pos = tester.state<ScrollableState>(find.byType(Scrollable)).position;
      expect(pos.pixels, closeTo(pos.maxScrollExtent, 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a drag away from the edge stops following later growth',
        (tester) async {
      var count = 10;
      await tester.pumpWidget(
        BeuiTheme.wrap(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(400, 800)),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      BeuiMessageScroller(
                        height: 160,
                        children: [
                          for (var i = 0; i < count; i++)
                            BeuiScrollerMessage(
                              id: '$i',
                              from: BeuiMessageFrom.assistant,
                              text: 'Row $i keeps the transcript scrolling',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text('Row $i keeps the transcript scrolling'),
                              ),
                            ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() => count += 6),
                        child: const Text('More'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable), const Offset(0, 240));
      await tester.pumpAndSettle();
      final before =
          tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
      expect(before, lessThan(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.maxScrollExtent -
            20,
      ));

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      final after =
          tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
      expect(after, closeTo(before, 8));
    });
  });

  group('BeuiMorphicTooltip', () {
    Widget wrap(Widget child) {
      return BeuiTheme.wrap(
        brightness: Brightness.dark,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(
              initialEntries: [
                OverlayEntry(builder: (_) => Center(child: child)),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('activating a trigger shows one tooltip', (tester) async {
      await tester.pumpWidget(
        wrap(
          const BeuiMorphicTooltipScope(
            delay: Duration.zero,
            child: BeuiMorphicTooltip(
              content: Text('Hello'),
              child: SizedBox(width: 80, height: 40, child: Text('Go')),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Hello'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('moving between triggers keeps a single morphing surface',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const BeuiMorphicTooltipScope(
            delay: Duration.zero,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BeuiMorphicTooltip(
                  content: Text('One'),
                  child: SizedBox(width: 40, height: 40, child: Text('A')),
                ),
                BeuiMorphicTooltip(
                  content: Text('Two'),
                  child: SizedBox(width: 40, height: 40, child: Text('B')),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('B'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Two'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('BeuiRowCursor', () {
    test('clears a stale id instead of keeping the old highlight', () {
      final cursor = BeuiRowCursor();
      cursor.moveTo('a', 'q1');
      expect(cursor.activeIndex(['a', 'b'], 'q1'), 0);
      expect(cursor.activeIndex(['x', 'y'], 'q1'), 0);
      expect(cursor.id, isNull);
    });

    test('two steps in one batch move two rows', () {
      final cursor = BeuiRowCursor();
      final rows = ['a', 'b', 'c'];
      cursor.moveActive(rows, '', 1);
      cursor.moveActive(rows, '', 1);
      expect(cursor.activeIndex(rows, ''), 2);
    });
  });
}
