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
}
