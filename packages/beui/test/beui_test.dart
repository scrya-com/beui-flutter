import 'package:beui/beui.dart';
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
