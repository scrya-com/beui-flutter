import 'package:flutter/widgets.dart';

/// Compact Lucide-style icons used by the first-wave previews.
class BeuiIcon extends StatelessWidget {
  const BeuiIcon(
    this.painter, {
    super.key,
    this.size = 16,
    this.color,
  });

  final BeuiIconPainter painter;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? DefaultTextStyle.of(context).style.color;
    return CustomPaint(
      size: Size.square(size),
      painter: _StrokePainter(painter, iconColor ?? const Color(0xFF000000)),
    );
  }
}

typedef BeuiIconPainter = void Function(Canvas canvas, Size size, Paint stroke);

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.paintIcon, this.color);

  final BeuiIconPainter paintIcon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * (2 / 24)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.scale(size.width / 24, size.height / 24);
    paintIcon(canvas, const Size(24, 24), stroke);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.paintIcon != paintIcon;
}

class BeuiIcons {
  BeuiIcons._();

  static void arrowRight(Canvas c, Size s, Paint p) {
    c.drawLine(const Offset(5, 12), const Offset(19, 12), p);
    c.drawPath(
      Path()
        ..moveTo(12, 5)
        ..lineTo(19, 12)
        ..lineTo(12, 19),
      p,
    );
  }

  static void arrowUpRight(Canvas c, Size s, Paint p) {
    c.drawLine(const Offset(7, 17), const Offset(17, 7), p);
    c.drawPath(
      Path()
        ..moveTo(7, 7)
        ..lineTo(17, 7)
        ..lineTo(17, 17),
      p,
    );
  }

  static void download(Canvas c, Size s, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(21, 15)
        ..lineTo(21, 19)
        ..lineTo(3, 19)
        ..lineTo(3, 15),
      p,
    );
    c.drawLine(const Offset(12, 3), const Offset(12, 15), p);
    c.drawPath(
      Path()
        ..moveTo(7, 10)
        ..lineTo(12, 15)
        ..lineTo(17, 10),
      p,
    );
  }

  static void trash(Canvas c, Size s, Paint p) {
    c.drawLine(const Offset(3, 6), const Offset(21, 6), p);
    c.drawPath(
      Path()
        ..moveTo(19, 6)
        ..lineTo(18, 20)
        ..lineTo(6, 20)
        ..lineTo(5, 6),
      p,
    );
    c.drawLine(const Offset(10, 11), const Offset(10, 17), p);
    c.drawLine(const Offset(14, 11), const Offset(14, 17), p);
    c.drawPath(
      Path()
        ..moveTo(9, 6)
        ..lineTo(9, 4)
        ..lineTo(15, 4)
        ..lineTo(15, 6),
      p,
    );
  }

  static void check(Canvas c, Size s, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(5, 13)
        ..lineTo(9, 17)
        ..lineTo(19, 7),
      p,
    );
  }

  static void x(Canvas c, Size s, Paint p) {
    c.drawLine(const Offset(6, 6), const Offset(18, 18), p);
    c.drawLine(const Offset(18, 6), const Offset(6, 18), p);
  }

  static void mail(Canvas c, Size s, Paint p) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 5, 18, 14),
        const Radius.circular(2),
      ),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(3, 7)
        ..lineTo(12, 13)
        ..lineTo(21, 7),
      p,
    );
  }

  static void search(Canvas c, Size s, Paint p) {
    c.drawCircle(const Offset(11, 11), 7, p);
    c.drawLine(const Offset(16, 16), const Offset(21, 21), p);
  }

  static void eye(Canvas c, Size s, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(2, 12)
        ..quadraticBezierTo(7, 5, 12, 5)
        ..quadraticBezierTo(17, 5, 22, 12)
        ..quadraticBezierTo(17, 19, 12, 19)
        ..quadraticBezierTo(7, 19, 2, 12),
      p,
    );
    c.drawCircle(const Offset(12, 12), 3, p);
  }

  static void eyeOff(Canvas c, Size s, Paint p) {
    eye(c, s, p);
    c.drawLine(const Offset(4, 4), const Offset(20, 20), p);
  }

  static void sparkles(Canvas c, Size s, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(12, 3)
        ..lineTo(13.5, 8.5)
        ..lineTo(19, 10)
        ..lineTo(13.5, 11.5)
        ..lineTo(12, 17)
        ..lineTo(10.5, 11.5)
        ..lineTo(5, 10)
        ..lineTo(10.5, 8.5)
        ..close(),
      p,
    );
  }

  static void loader(Canvas c, Size s, Paint p) {
    c.drawArc(
      const Rect.fromLTWH(4, 4, 16, 16),
      -0.4,
      4.4,
      false,
      p,
    );
  }

  static void chevronDown(Canvas c, Size s, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(6, 9)
        ..lineTo(12, 15)
        ..lineTo(18, 9),
      p,
    );
  }

  static void plus(Canvas c, Size s, Paint p) {
    c.drawLine(const Offset(12, 5), const Offset(12, 19), p);
    c.drawLine(const Offset(5, 12), const Offset(19, 12), p);
  }

  static void square(Canvas c, Size s, Paint p) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, 6, 12, 12),
        const Radius.circular(2),
      ),
      p,
    );
  }

  static void listTodo(Canvas c, Size s, Paint p) {
    c.drawLine(const Offset(10, 6), const Offset(20, 6), p);
    c.drawLine(const Offset(10, 12), const Offset(20, 12), p);
    c.drawLine(const Offset(10, 18), const Offset(20, 18), p);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 4, 4, 4),
        const Radius.circular(1),
      ),
      p,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 10, 4, 4),
        const Radius.circular(1),
      ),
      p,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 16, 4, 4),
        const Radius.circular(1),
      ),
      p,
    );
  }

  static void copy(Canvas c, Size s, Paint p) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 8, 12, 12),
        const Radius.circular(2),
      ),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(16, 8)
        ..lineTo(16, 4)
        ..lineTo(4, 4)
        ..lineTo(4, 16)
        ..lineTo(8, 16),
      p,
    );
  }

  static void thumbsUp(Canvas c, Size s, Paint p) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 12, 4, 8),
        const Radius.circular(1),
      ),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(7, 20)
        ..lineTo(18, 20)
        ..lineTo(21, 12)
        ..lineTo(12, 12)
        ..lineTo(13, 7)
        ..lineTo(10, 12)
        ..lineTo(7, 12)
        ..close(),
      p,
    );
  }

  static void thumbsDown(Canvas c, Size s, Paint p) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(17, 4, 4, 8),
        const Radius.circular(1),
      ),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(17, 4)
        ..lineTo(6, 4)
        ..lineTo(3, 12)
        ..lineTo(12, 12)
        ..lineTo(11, 17)
        ..lineTo(14, 12)
        ..lineTo(17, 12)
        ..close(),
      p,
    );
  }

  static void book(Canvas c, Size s, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(4, 19)
        ..lineTo(4, 5)
        ..lineTo(12, 8)
        ..lineTo(20, 5)
        ..lineTo(20, 19)
        ..lineTo(12, 16)
        ..close(),
      p,
    );
    c.drawLine(const Offset(12, 8), const Offset(12, 16), p);
  }

  static void terminal(Canvas c, Size s, Paint p) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 5, 18, 14),
        const Radius.circular(2),
      ),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(7, 10)
        ..lineTo(11, 12)
        ..lineTo(7, 14),
      p,
    );
    c.drawLine(const Offset(13, 15), const Offset(17, 15), p);
  }

  static void fileCode(Canvas c, Size s, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(14, 2)
        ..lineTo(6, 2)
        ..lineTo(6, 22)
        ..lineTo(18, 22)
        ..lineTo(18, 8)
        ..close(),
      p,
    );
    c.drawLine(const Offset(14, 2), const Offset(14, 8), p);
    c.drawLine(const Offset(18, 8), const Offset(14, 8), p);
    c.drawPath(
      Path()
        ..moveTo(10, 13)
        ..lineTo(8, 15)
        ..lineTo(10, 17),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(14, 13)
        ..lineTo(16, 15)
        ..lineTo(14, 17),
      p,
    );
  }

  static void settings(Canvas c, Size s, Paint p) {
    c.drawCircle(const Offset(12, 12), 3, p);
    c.drawCircle(const Offset(12, 12), 8, p);
    const ticks = <Offset>[
      Offset(12, 2),
      Offset(12, 22),
      Offset(2, 12),
      Offset(22, 12),
      Offset(5, 5),
      Offset(19, 19),
      Offset(19, 5),
      Offset(5, 19),
    ];
    for (final o in ticks) {
      c.drawLine(Offset.lerp(const Offset(12, 12), o, 0.72)!, o, p);
    }
  }

  static void circleCheck(Canvas c, Size s, Paint p) {
    c.drawCircle(const Offset(12, 12), 9, p);
    c.drawPath(
      Path()
        ..moveTo(8, 12)
        ..lineTo(11, 15)
        ..lineTo(16.5, 9.5),
      p,
    );
  }

  static void code(Canvas c, Size s, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(16, 18)
        ..lineTo(22, 12)
        ..lineTo(16, 6),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(8, 6)
        ..lineTo(2, 12)
        ..lineTo(8, 18),
      p,
    );
  }

  static void messageSquare(Canvas c, Size s, Paint p) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 3, 18, 13),
        const Radius.circular(2),
      ),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(8, 16)
        ..lineTo(8, 21)
        ..lineTo(13, 16),
      p,
    );
  }

  static void rotateCcw(Canvas c, Size s, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(3, 12)
        ..arcToPoint(
          const Offset(21, 12),
          radius: const Radius.circular(9),
          clockwise: false,
        ),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(3, 12)
        ..lineTo(3, 6)
        ..moveTo(3, 12)
        ..lineTo(8, 12),
      p,
    );
  }
}
