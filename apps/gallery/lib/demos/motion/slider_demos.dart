import 'package:beui/beui.dart';

import 'package:flutter/widgets.dart';

class RangeSliderDemo extends StatefulWidget {
  const RangeSliderDemo({super.key});

  @override
  State<RangeSliderDemo> createState() => _RangeSliderDemoState();
}

class _RangeSliderDemoState extends State<RangeSliderDemo> {
  double value = 40;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 384),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Drag the handle',
                  style: TextStyle(fontSize: 14, color: colors.mutedForeground),
                ),
              ),
              Text(
                beuiSliderNumber(value),
                style: TextStyle(
                  fontSize: 14,
                  color: colors.foreground,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          BeuiRangeSlider(
            value: value,
            onChanged: (v) => setState(() => value = v),
            step: 5,
            semanticLabel: 'Value',
          ),
        ],
      ),
    );
  }
}

class FluidSliderDemo extends StatefulWidget {
  const FluidSliderDemo({super.key});

  @override
  State<FluidSliderDemo> createState() => _FluidSliderDemoState();
}

class _FluidSliderDemoState extends State<FluidSliderDemo> {
  double value = 35;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 384),
      child: BeuiFluidSlider(
        value: value,
        onChanged: (v) => setState(() => value = v),
        label: 'Brightness',
        semanticLabel: 'Brightness',
      ),
    );
  }
}

class WaveSliderDemo extends StatefulWidget {
  const WaveSliderDemo({super.key});

  @override
  State<WaveSliderDemo> createState() => _WaveSliderDemoState();
}

class _WaveSliderDemoState extends State<WaveSliderDemo> {
  double value = 45;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 448),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gain',
                  style: TextStyle(fontSize: 14, color: colors.mutedForeground),
                ),
              ),
              Text(
                beuiSliderNumber(value),
                style: TextStyle(
                  fontSize: 14,
                  color: colors.foreground,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          BeuiWaveSlider(
            value: value,
            onChanged: (v) => setState(() => value = v),
            semanticLabel: 'Gain',
          ),
        ],
      ),
    );
  }
}

class BubbleSliderDemo extends StatefulWidget {
  const BubbleSliderDemo({super.key});

  @override
  State<BubbleSliderDemo> createState() => _BubbleSliderDemoState();
}

class _BubbleSliderDemoState extends State<BubbleSliderDemo> {
  double value = 28;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 384),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            'Drag fast and the bubble leans',
            style: TextStyle(fontSize: 14, color: colors.mutedForeground),
          ),
          BeuiBubbleSlider(
            value: value,
            onChanged: (v) => setState(() => value = v),
            semanticLabel: 'Value',
          ),
        ],
      ),
    );
  }
}

class RulerSliderDemo extends StatefulWidget {
  const RulerSliderDemo({super.key});

  @override
  State<RulerSliderDemo> createState() => _RulerSliderDemoState();
}

class _RulerSliderDemoState extends State<RulerSliderDemo> {
  double value = 72.5;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 384),
      child: BeuiRulerSlider(
        value: value,
        onChanged: (v) => setState(() => value = v),
        min: 40,
        max: 120,
        step: 0.5,
        gap: 12,
        majorEvery: 10,
        unit: 'kg',
        semanticLabel: 'Weight',
      ),
    );
  }
}

class ExpandingArrowButtonDemo extends StatelessWidget {
  const ExpandingArrowButtonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BeuiExpandingArrowButton(
        onPressed: () {},
        child: const Text('Book a demo'),
      ),
    );
  }
}

class HoldActionButtonDemo extends StatefulWidget {
  const HoldActionButtonDemo({super.key});

  @override
  State<HoldActionButtonDemo> createState() => _HoldActionButtonDemoState();
}

class _HoldActionButtonDemoState extends State<HoldActionButtonDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _status;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _status = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _confirmed = false);
        }
      });
  }

  @override
  void dispose() {
    _status.dispose();
    super.dispose();
  }

  void _confirm() {
    setState(() => _confirmed = true);
    _status.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        BeuiHoldActionButton(
          onHoldComplete: _confirm,
          child: const Text('Hold for vertical fill'),
        ),
        BeuiHoldActionButton(
          type: BeuiHoldActionType.horizontal,
          onHoldComplete: _confirm,
          child: const Text('Hold for horizontal fill'),
        ),
        SizedBox(
          height: 16,
          child: Text(
            _confirmed ? 'Action confirmed' : 'Release early to cancel',
            style: TextStyle(fontSize: 12, color: colors.mutedForeground),
          ),
        ),
      ],
    );
  }
}

class SlideActionButtonDemo extends StatefulWidget {
  const SlideActionButtonDemo({super.key});

  @override
  State<SlideActionButtonDemo> createState() => _SlideActionButtonDemoState();
}

class _SlideActionButtonDemoState extends State<SlideActionButtonDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _status;
  bool _continued = false;

  @override
  void initState() {
    super.initState();
    _status = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _continued = false);
        }
      });
  }

  @override
  void dispose() {
    _status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        BeuiSlideActionButton(
          completeLabel: const Text('Ready'),
          onComplete: () {
            setState(() => _continued = true);
            _status.forward(from: 0);
          },
          child: const Text('Slide to continue'),
        ),
        SizedBox(
          height: 16,
          child: Text(
            _continued ? 'Action completed' : 'Drag the arrow to the end',
            style: TextStyle(fontSize: 12, color: colors.mutedForeground),
          ),
        ),
      ],
    );
  }
}
