/// Nearest legal value on [min, max] for the given [step].
/// Port of `snapSliderValue` in `lib/hooks/use-slider.ts`.
double snapSliderValue(double next, double min, double max, double step) {
  if (!(max > min)) return min;
  if (!(step > 0)) return next.clamp(min, max);
  final whole = ((max - min) / step).toStringAsFixed(6);
  final wholeN = double.parse(whole).floor();
  final lastWhole = double.parse((min + wholeN * step).toStringAsFixed(6));
  final toGrid = (min + ((next - min) / step).round() * step).clamp(min, lastWhole);
  final snapped =
      lastWhole < max && (next - max).abs() <= (next - toGrid).abs()
          ? max
          : toGrid;
  return double.parse(snapped.toStringAsFixed(6));
}
