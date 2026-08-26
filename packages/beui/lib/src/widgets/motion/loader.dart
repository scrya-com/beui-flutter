import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';

/// All 17 loaders from `components/motion/loader.tsx`.
enum BeuiLoaderVariant {
  spinner,
  dots,
  bars,
  dotMatrix,
  dither,
  ascii,
  asciiLine,
  asciiBraille,
  asciiBlocks,
  asciiBounce,
  morph,
  comet,
  scramble,
  metaballs,
  newton,
  helix,
  percent,
}

/// Terminal-style frame sets — the loaders CLI AI agents cycle through.
const _kAsciiSets = <BeuiLoaderVariant, List<String>>{
  BeuiLoaderVariant.ascii: ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'],
  BeuiLoaderVariant.asciiLine: ['|', '/', '-', '\\'],
  BeuiLoaderVariant.asciiBraille: ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'],
  BeuiLoaderVariant.asciiBlocks: [
    '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█', '▇', '▆', '▅', '▄', '▃', '▂',
  ],
  BeuiLoaderVariant.asciiBounce: ['⠁', '⠂', '⠄', '⡀', '⢀', '⠠', '⠐', '⠈'],
};

const _kScrambleTarget = 'LOADING';
const _kScrambleGlyphs = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789<>/*#@';

const _kBayer4 = [
  0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5,
];

const _kMorphRot = [
  0.0, 0.0, 72.0, 72.0, 144.0, 144.0, 216.0, 216.0, 288.0, 288.0, 360.0,
];
const _kMorphScale = [
  1.0, 1.0, 0.88, 0.88, 1.0, 1.0, 0.88, 0.88, 1.0, 1.0, 1.0,
];
const _kMorphIndex = [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 0];

/// Animated loading mark. Port of `components/motion/loader.tsx`.
class BeuiLoader extends StatefulWidget {
  const BeuiLoader({
    super.key,
    this.variant = BeuiLoaderVariant.spinner,
    this.size = 32,
    this.speed = 1,
    this.label = 'Loading',
  });

  final BeuiLoaderVariant variant;

  /// Base square size in logical pixels.
  final double size;

  /// Seconds per animation cycle.
  final double speed;

  /// Accessible label announced to screen readers.
  final String label;

  @override
  State<BeuiLoader> createState() => _BeuiLoaderState();
}

class _BeuiLoaderState extends State<BeuiLoader>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(BeuiLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _elapsed = elapsed;
    if (mounted) setState(() {});
  }

  void _syncTicker() {
    final live = TickerMode.valuesOf(context).enabled;
    if (live) {
      if (!(_ticker?.isActive ?? false)) _ticker?.start();
    } else if (_ticker?.isActive ?? false) {
      _ticker?.stop();
    }
  }

  double get _seconds => _elapsed.inMicroseconds / 1e6;

  @override
  Widget build(BuildContext context) {
    final reduce = beuiReduceMotion(context);
    final color =
        DefaultTextStyle.of(context).style.color ?? context.beuiColors.foreground;
    final child = _paint(reduce: reduce, color: color);
    return Semantics(
      label: widget.label,
      liveRegion: true,
      container: true,
      child: ExcludeSemantics(child: child),
    );
  }

  Widget _paint({required bool reduce, required Color color}) {
    final variant = widget.variant;
    final ascii = _kAsciiSets[variant];
    if (ascii != null) {
      return _ascii(ascii, reduce: reduce, color: color);
    }
    return switch (variant) {
      BeuiLoaderVariant.spinner => _spinner(reduce: reduce, color: color),
      BeuiLoaderVariant.dots => _dots(reduce: reduce, color: color),
      BeuiLoaderVariant.bars => _bars(reduce: reduce, color: color),
      BeuiLoaderVariant.dotMatrix => _dotMatrix(reduce: reduce, color: color),
      BeuiLoaderVariant.dither => _dither(reduce: reduce, color: color),
      BeuiLoaderVariant.morph => _morph(reduce: reduce, color: color),
      BeuiLoaderVariant.comet => _comet(reduce: reduce, color: color),
      BeuiLoaderVariant.scramble => _scramble(reduce: reduce, color: color),
      BeuiLoaderVariant.metaballs => _metaballs(reduce: reduce, color: color),
      BeuiLoaderVariant.newton => _newton(reduce: reduce, color: color),
      BeuiLoaderVariant.helix => _helix(reduce: reduce, color: color),
      BeuiLoaderVariant.percent => _percent(reduce: reduce, color: color),
      _ => _spinner(reduce: reduce, color: color),
    };
  }

  Widget _reducedPulse({required Widget child}) {
    final t = _pingPong(_seconds, duration: 1.4);
    return Opacity(opacity: lerpDouble(1, 0.4, t)!, child: child);
  }

  Widget _dot(double size, Color color, {double opacity = 1}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity.clamp(0.0, 1.0)),
        shape: BoxShape.circle,
      ),
      child: SizedBox(width: size, height: size),
    );
  }

  Widget _spinner({required bool reduce, required Color color}) {
    final size = widget.size;
    final stroke = math.max(2.0, size * 0.09);
    final child = CustomPaint(
      size: Size.square(size),
      painter: _SpinnerPainter(color: color, stroke: stroke),
    );
    if (reduce) return _reducedPulse(child: child);
    final turn = (_seconds % widget.speed) / widget.speed;
    return Transform.rotate(angle: turn * 2 * math.pi, child: child);
  }

  Widget _dots({required bool reduce, required Color color}) {
    final size = widget.size;
    final dot = size * 0.24;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: size * 0.14,
      children: [
        for (var i = 0; i < 3; i++)
          Builder(
            builder: (context) {
              final wave = _pingPong(
                _seconds,
                duration: widget.speed,
                delay: i * widget.speed * 0.16,
              );
              if (reduce) {
                return Opacity(
                  opacity: lerpDouble(0.4, 1, wave)!,
                  child: _dot(dot, color),
                );
              }
              return Opacity(
                opacity: lerpDouble(0.5, 1, wave)!,
                child: Transform.translate(
                  offset: Offset(0, -size * 0.3 * wave),
                  child: _dot(dot, color),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _bars({required bool reduce, required Color color}) {
    final size = widget.size;
    final bar = size * 0.16;
    return SizedBox(
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: size * 0.1,
        children: [
          for (var i = 0; i < 4; i++)
            Builder(
              builder: (context) {
                final wave = _pingPong(
                  _seconds,
                  duration: widget.speed,
                  delay: i * widget.speed * 0.12,
                );
                if (reduce) {
                  return Opacity(
                    opacity: lerpDouble(0.4, 1, wave)!,
                    child: _bar(bar, size, color),
                  );
                }
                return Transform.scale(
                  alignment: Alignment.bottomCenter,
                  scaleY: lerpDouble(0.3, 1, wave)!,
                  child: _bar(bar, size, color),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _bar(double w, double h, Color color) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(BeuiRadii.pill),
      ),
      child: SizedBox(width: w, height: h),
    );
  }

  Widget _dotMatrix({required bool reduce, required Color color}) {
    const n = 3;
    final size = widget.size;
    final gap = size * 0.14;
    final dot = (size - gap * (n - 1)) / n;
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: gap,
        children: [
          for (var y = 0; y < n; y++)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: gap,
              children: [
                for (var x = 0; x < n; x++)
                  Builder(
                    builder: (context) {
                      final delay = ((x + y) / (2 * (n - 1))) * widget.speed;
                      final wave = _pingPong(
                        _seconds,
                        duration: widget.speed,
                        delay: delay,
                      );
                      if (reduce) {
                        return Opacity(
                          opacity: lerpDouble(0.3, 1, wave)!,
                          child: _dot(dot, color),
                        );
                      }
                      return Opacity(
                        opacity: lerpDouble(0.2, 1, wave)!,
                        child: Transform.scale(
                          scale: lerpDouble(0.7, 1, wave)!,
                          child: _dot(dot, color),
                        ),
                      );
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _dither({required bool reduce, required Color color}) {
    const n = 4;
    final size = widget.size;
    final gap = math.max(1.0, size * 0.05);
    final cell = (size - gap * (n - 1)) / n;
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: gap,
        children: [
          for (var y = 0; y < n; y++)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: gap,
              children: [
                for (var x = 0; x < n; x++)
                  Builder(
                    builder: (context) {
                      final order = _kBayer4[y * n + x];
                      final wave = _pingPong(
                        _seconds,
                        duration: widget.speed,
                        delay: (order / _kBayer4.length) * widget.speed,
                      );
                      final opacity = reduce
                          ? lerpDouble(0.3, 1, wave)!
                          : lerpDouble(0.1, 1, wave)!;
                      return ColoredBox(
                        color: color.withValues(alpha: opacity),
                        child: SizedBox(width: cell, height: cell),
                      );
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _ascii(List<String> frames, {required bool reduce, required Color color}) {
    final cycle = (reduce ? widget.speed * 2.5 : widget.speed);
    final i = frames.isEmpty
        ? 0
        : ((_seconds / cycle) * frames.length).floor() % frames.length;
    return Text(
      frames[i],
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: widget.size,
        height: 1,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _morph({required bool reduce, required Color color}) {
    final size = widget.size;
    if (reduce) {
      return _reducedPulse(
        child: CustomPaint(
          size: Size.square(size),
          painter: _MorphPainter(color: color, points: _kMorphShapes[0]),
        ),
      );
    }
    final cycle = widget.speed * 5;
    final t = cycle <= 0 ? 0.0 : (_seconds % cycle) / cycle;
    final rot = _kf(t, _kMorphRot) * math.pi / 180;
    final scale = _kf(t, _kMorphScale);
    final points = _morphPointsAt(t);
    return Transform.rotate(
      angle: rot,
      child: Transform.scale(
        scale: scale,
        child: CustomPaint(
          size: Size.square(size),
          painter: _MorphPainter(color: color, points: points),
        ),
      ),
    );
  }

  Widget _comet({required bool reduce, required Color color}) {
    final size = widget.size;
    final head = size * 0.2;
    final r = size / 2 - head / 2;
    Widget trail = SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < 6; i++)
            Builder(
              builder: (context) {
                final scale = 1 - i * 0.13;
                final sz = head * scale;
                return Positioned(
                  left: size / 2 - sz / 2,
                  top: size / 2 - sz / 2,
                  child: Transform.rotate(
                    angle: -i * 15 * math.pi / 180,
                    child: Transform.translate(
                      offset: Offset(0, -r),
                      child: _dot(sz, color, opacity: 1 - i * 0.16),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
    if (reduce) return _reducedPulse(child: trail);
    final turn = (_seconds % widget.speed) / widget.speed;
    return Transform.rotate(angle: turn * 2 * math.pi, child: trail);
  }

  Widget _scramble({required bool reduce, required Color color}) {
    final text = reduce ? _kScrambleTarget : _scrambleText();
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontWeight: FontWeight.w500,
        fontSize: widget.size * 0.42,
        letterSpacing: widget.size * 0.42 * 0.2,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  String _scrambleText() {
    final interval = (widget.speed / _kScrambleTarget.length) * 0.55;
    final tick = interval <= 0 ? 0 : (_seconds / interval).floor();
    final total = _kScrambleTarget.length + 4;
    final reveal = tick % total;
    final rng = math.Random(tick);
    final buf = StringBuffer();
    for (var i = 0; i < _kScrambleTarget.length; i++) {
      if (i < reveal) {
        buf.write(_kScrambleTarget[i]);
      } else {
        buf.write(_kScrambleGlyphs[rng.nextInt(_kScrambleGlyphs.length)]);
      }
    }
    return buf.toString();
  }

  Widget _metaballs({required bool reduce, required Color color}) {
    final size = widget.size;
    final wave = _pingPong(_seconds, duration: widget.speed * 1.6);
    if (reduce) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _MetaballPainter(
            color: color,
            left: 40,
            right: 60,
            opacity: lerpDouble(0.4, 1, wave)!,
          ),
        ),
      );
    }
    final left = lerpDouble(30, 70, wave)!;
    final right = lerpDouble(70, 30, wave)!;
    final sigma = 5 * (size / 100);
    return SizedBox(
      width: size,
      height: size,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 20, -2040,
        ]),
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: CustomPaint(
            painter: _MetaballPainter(color: color, left: left, right: right),
          ),
        ),
      ),
    );
  }

  Widget _newton({required bool reduce, required Color color}) {
    final d = widget.size * 0.2;
    final out = d * 1.1;
    final cycle = widget.speed * 1.5;
    final t = cycle <= 0 ? 0.0 : (_seconds % cycle) / cycle;
    return SizedBox(
      height: d,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++)
            Transform.translate(
              offset: Offset(
                reduce
                    ? 0
                    : i == 0
                        ? _kfTimed(t, const [0, -1, 0, 0], const [0, 0.28, 0.5, 1]) *
                            out
                        : i == 4
                            ? _kfTimed(
                                  t,
                                  const [0, 0, 1, 0],
                                  const [0, 0.5, 0.78, 1],
                                ) *
                                out
                            : 0,
                0,
              ),
              child: _dot(d, color),
            ),
        ],
      ),
    );
  }

  Widget _helix({required bool reduce, required Color color}) {
    const rows = 7;
    final size = widget.size;
    final dot = size * 0.14;
    final amp = size * 0.32;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (var r = 0; r < rows; r++)
            for (final phase in [0, 1])
              Builder(
                builder: (context) {
                  final top = (r / (rows - 1)) * (size - dot);
                  final delay = (r / rows) * widget.speed;
                  final wave = _pingPong(
                    _seconds,
                    duration: widget.speed,
                    delay: delay,
                  );
                  if (reduce) {
                    return Positioned(
                      left: size / 2 - dot / 2,
                      top: top,
                      child: Opacity(
                        opacity: lerpDouble(0.4, 1, wave)!,
                        child: _dot(dot, color),
                      ),
                    );
                  }
                  final x = phase == 0
                      ? amp * (1 - 2 * wave)
                      : amp * (2 * wave - 1);
                  final scale = phase == 0
                      ? lerpDouble(1, 0.5, wave)!
                      : lerpDouble(0.5, 1, wave)!;
                  final opacity = phase == 0
                      ? lerpDouble(1, 0.45, wave)!
                      : lerpDouble(0.45, 1, wave)!;
                  return Positioned(
                    left: size / 2 - dot / 2 + x,
                    top: top,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: _dot(dot, color),
                      ),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _percent({required bool reduce, required Color color}) {
    final size = widget.size;
    final dur = reduce ? widget.speed * 2 : widget.speed;
    final t = dur <= 0 ? 0.0 : (_seconds % dur) / dur;
    final p = (t * 100).round().clamp(0, 100);
    final barH = math.max(3.0, size * 0.1);
    return SizedBox(
      width: size * 1.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: size * 0.14,
        children: [
          Text(
            '$p%',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
              fontSize: size * 0.42,
              height: 1,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(BeuiRadii.pill),
            child: SizedBox(
              height: barH,
              width: double.infinity,
              child: ColoredBox(
                color: color.withValues(alpha: 0.15),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: p / 100,
                    child: ColoredBox(
                      color: color,
                      child: SizedBox(height: barH),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _pingPong(double seconds, {required double duration, double delay = 0}) {
  final local = seconds - delay;
  if (local <= 0) return 0;
  if (duration <= 0) return 0;
  final u = (local % duration) / duration;
  final half = u < 0.5 ? u * 2 : (u - 0.5) * 2;
  final eased = BeuiCurves.easeInOut.transform(half);
  return u < 0.5 ? eased : 1 - eased;
}

double _kf(double t, List<double> keys) {
  if (keys.length == 1) return keys.first;
  final n = keys.length - 1;
  final x = t.clamp(0.0, 1.0) * n;
  final i = x.floor().clamp(0, n - 1);
  final f = x - i;
  final e = BeuiCurves.easeInOut.transform(f);
  return keys[i] + (keys[i + 1] - keys[i]) * e;
}

double _kfTimed(double t, List<double> values, List<double> times) {
  if (t <= times.first) return values.first;
  if (t >= times.last) return values.last;
  for (var i = 0; i < times.length - 1; i++) {
    if (t <= times[i + 1]) {
      final span = times[i + 1] - times[i];
      final u = span <= 0 ? 1.0 : (t - times[i]) / span;
      final e = BeuiCurves.easeInOut.transform(u.clamp(0.0, 1.0));
      return values[i] + (values[i + 1] - values[i]) * e;
    }
  }
  return values.last;
}

double _ngonRadius(double ang, int n, [double phase = 0]) {
  final seg = (2 * math.pi) / n;
  final a = ang - phase;
  final local = (((a % seg) + seg) % seg) - seg / 2;
  return math.cos(math.pi / n) / math.cos(local);
}

List<Offset> _morphShape(double Function(double ang) radiusAt) {
  const n = 24;
  return [
    for (var i = 0; i < n; i++)
      () {
        final ang = (i / n) * 2 * math.pi - math.pi / 2;
        final r = math.min(1.05, radiusAt(ang));
        return Offset(
          50 + math.cos(ang) * 46 * r,
          50 + math.sin(ang) * 46 * r,
        );
      }(),
  ];
}

final _kMorphShapes = <List<Offset>>[
  _morphShape((_) => 1),
  _morphShape((a) => _ngonRadius(a, 4, math.pi / 4)),
  _morphShape((a) => _ngonRadius(a, 3)),
  _morphShape((a) => _ngonRadius(a, 6)),
  _morphShape((a) => _ngonRadius(a, 4)),
];

List<Offset> _morphPointsAt(double t) {
  final n = _kMorphIndex.length - 1;
  final x = t.clamp(0.0, 1.0) * n;
  final i = x.floor().clamp(0, n - 1);
  final f = BeuiCurves.easeInOut.transform(x - i);
  final a = _kMorphShapes[_kMorphIndex[i]];
  final b = _kMorphShapes[_kMorphIndex[i + 1]];
  return [
    for (var p = 0; p < a.length; p++) Offset.lerp(a[p], b[p], f)!,
  ];
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({required this.color, required this.stroke});

  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - stroke) / 2;
    final track = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(c, r, track);
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi / 2,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.stroke != stroke;
}

class _MorphPainter extends CustomPainter {
  const _MorphPainter({required this.color, required this.points});

  final Color color;
  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    canvas.scale(size.width / 100, size.height / 100);
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MorphPainter oldDelegate) => true;
}

class _MetaballPainter extends CustomPainter {
  const _MetaballPainter({
    required this.color,
    required this.left,
    required this.right,
    this.opacity = 1,
  });

  final Color color;
  final double left;
  final double right;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final paint = Paint()..color = color.withValues(alpha: opacity);
    canvas.drawCircle(Offset(left, 50), 15, paint);
    canvas.drawCircle(Offset(right, 50), 15, paint);
  }

  @override
  bool shouldRepaint(covariant _MetaballPainter oldDelegate) =>
      oldDelegate.left != left ||
      oldDelegate.right != right ||
      oldDelegate.opacity != opacity ||
      oldDelegate.color != color;
}
