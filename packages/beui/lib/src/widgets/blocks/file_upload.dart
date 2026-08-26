import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../motion/reduce.dart';
import '../../tokens/colors.dart';
import '../../tokens/theme.dart';
import '../icons.dart';

enum BeuiFileUploadStatus { queued, uploading, success, error }

enum BeuiFileUploadVariant { row, centered }

class BeuiFileUploadItem {
  const BeuiFileUploadItem({
    required this.id,
    required this.name,
    required this.size,
    this.type,
    this.progress = 0,
    this.status = BeuiFileUploadStatus.queued,
    this.error,
  });

  final String id;
  final String name;
  final int size;
  final String? type;
  final double progress;
  final BeuiFileUploadStatus status;
  final String? error;

  BeuiFileUploadItem copyWith({
    double? progress,
    BeuiFileUploadStatus? status,
    String? error,
    bool clearError = false,
  }) {
    return BeuiFileUploadItem(
      id: id,
      name: name,
      size: size,
      type: type,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

BeuiFileUploadItem createBeuiFileUploadItem({
  required String name,
  required int size,
  String? type,
  int index = 0,
}) {
  return BeuiFileUploadItem(
    id: '${DateTime.now().microsecondsSinceEpoch}-$index-$name',
    name: name,
    size: size,
    type: type,
    progress: 0,
    status: BeuiFileUploadStatus.uploading,
  );
}

String beuiFormatBytes(int bytes) {
  if (!bytes.isFinite || bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  final exponent = math.min(
    (math.log(bytes) / math.log(1024)).floor(),
    units.length - 1,
  );
  final value = bytes / math.pow(1024, exponent);
  final shown = value >= 10 || exponent == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$shown ${units[exponent]}';
}

double beuiClampUploadProgress(double? value, BeuiFileUploadStatus status) {
  if (status == BeuiFileUploadStatus.success) return 100;
  if (value == null || value.isNaN) return 0;
  return value.clamp(0, 100);
}

String _fileKind(BeuiFileUploadItem item) {
  if (item.name.contains('.')) {
    return item.name.split('.').last.toUpperCase();
  }
  final type = item.type;
  if (type != null && type.contains('/')) {
    return type.split('/').last.toUpperCase();
  }
  return 'FILE';
}

BeuiIconPainter _fileIcon(BeuiFileUploadItem item) {
  final extension = item.name.contains('.')
      ? item.name.split('.').last.toLowerCase()
      : '';
  final type = item.type ?? '';
  if (type.startsWith('image/')) return BeuiIcons.fileImage;
  if (type.startsWith('video/')) return BeuiIcons.fileVideo;
  if (type.startsWith('audio/')) return BeuiIcons.fileAudio;
  if (type.contains('zip') ||
      type.contains('compressed') ||
      const ['zip', 'rar', '7z', 'tar', 'gz'].contains(extension)) {
    return BeuiIcons.fileArchive;
  }
  if (type.contains('pdf') ||
      type.startsWith('text/') ||
      const ['pdf', 'doc', 'docx', 'md', 'txt'].contains(extension)) {
    return BeuiIcons.fileText;
  }
  if (const [
    'css',
    'html',
    'js',
    'jsx',
    'json',
    'mdx',
    'ts',
    'tsx',
    'xml',
    'yaml',
    'yml',
  ].contains(extension)) {
    return BeuiIcons.code;
  }
  return BeuiIcons.file;
}

/// Progress queue with a dashed dropzone. Port of `components/motion/file-upload.tsx`.
class BeuiFileUpload extends StatefulWidget {
  const BeuiFileUpload({
    super.key,
    this.value,
    this.initialValue = const [],
    this.onChanged,
    this.onFilesAdded,
    this.onRemove,
    this.onRetry,
    this.onBrowse,
    this.multiple = true,
    this.maxFiles,
    this.enabled = true,
    this.variant = BeuiFileUploadVariant.row,
    this.title = 'Drop files here',
    this.description = 'Add files to the upload queue',
    this.browseLabel = 'Browse',
  });

  final List<BeuiFileUploadItem>? value;
  final List<BeuiFileUploadItem> initialValue;
  final ValueChanged<List<BeuiFileUploadItem>>? onChanged;
  final ValueChanged<List<BeuiFileUploadItem>>? onFilesAdded;
  final ValueChanged<BeuiFileUploadItem>? onRemove;
  final ValueChanged<BeuiFileUploadItem>? onRetry;
  final VoidCallback? onBrowse;
  final bool multiple;
  final int? maxFiles;
  final bool enabled;
  final BeuiFileUploadVariant variant;
  final String title;
  final String description;
  final String browseLabel;

  @override
  State<BeuiFileUpload> createState() => _BeuiFileUploadState();
}

class _BeuiFileUploadState extends State<BeuiFileUpload> {
  late List<BeuiFileUploadItem> _internal;

  bool get _controlled => widget.value != null;
  List<BeuiFileUploadItem> get _items => widget.value ?? _internal;

  @override
  void initState() {
    super.initState();
    _internal = List.of(widget.initialValue);
  }

  void _commit(List<BeuiFileUploadItem> next) {
    if (!_controlled) setState(() => _internal = next);
    widget.onChanged?.call(next);
  }

  void _add(List<BeuiFileUploadItem> incoming) {
    if (!widget.enabled || incoming.isEmpty) return;
    final remaining = widget.maxFiles == null
        ? incoming.length
        : widget.maxFiles! - _items.length;
    if (remaining <= 0) return;
    final take = widget.multiple ? remaining : math.min(1, remaining);
    final added = incoming.take(take).toList();
    if (added.isEmpty) return;
    _commit([..._items, ...added]);
    widget.onFilesAdded?.call(added);
  }

  void _remove(BeuiFileUploadItem item) {
    _commit(_items.where((e) => e.id != item.id).toList());
    widget.onRemove?.call(item);
  }

  void _retry(BeuiFileUploadItem item) {
    final retrying = item.copyWith(
      status: BeuiFileUploadStatus.uploading,
      progress: 0,
      clearError: true,
    );
    _commit([
      for (final e in _items)
        if (e.id == item.id) retrying else e,
    ]);
    widget.onRetry?.call(retrying);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final maxReached =
        widget.maxFiles != null && _items.length >= widget.maxFiles!;
    final centered = widget.variant == BeuiFileUploadVariant.centered;
    final canAdd = widget.enabled && !maxReached;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _Dropzone(
          enabled: canAdd,
          centered: centered,
          title: maxReached ? 'Upload limit reached' : widget.title,
          description: maxReached
              ? '${_items.length} of ${widget.maxFiles} files added'
              : widget.description,
          browseLabel: widget.browseLabel,
          onPressed: canAdd
              ? () {
                  if (widget.onBrowse != null) {
                    widget.onBrowse!();
                    return;
                  }
                  _add([
                    createBeuiFileUploadItem(
                      name: 'dropped-file.txt',
                      size: 12 * 1024,
                      type: 'text/plain',
                    ),
                  ]);
                }
              : null,
        ),
        for (final item in _items)
          _FileRow(
            key: ValueKey(item.id),
            item: item,
            reduce: reduce,
            colors: colors,
            onRemove: () => _remove(item),
            onRetry: item.status == BeuiFileUploadStatus.error
                ? () => _retry(item)
                : null,
          ),
      ],
    );
  }
}

class _Dropzone extends StatefulWidget {
  const _Dropzone({
    required this.enabled,
    required this.centered,
    required this.title,
    required this.description,
    required this.browseLabel,
    required this.onPressed,
  });

  final bool enabled;
  final bool centered;
  final String title;
  final String description;
  final String browseLabel;
  final VoidCallback? onPressed;

  @override
  State<_Dropzone> createState() => _DropzoneState();
}

class _DropzoneState extends State<_Dropzone> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final scale = !reduce && _pressed && widget.enabled ? 0.99 : 1.0;
    final iconBox = widget.centered ? 64.0 : 56.0;

    final icon = Container(
      width: iconBox,
      height: iconBox,
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(widget.centered ? 21.6 : 20),
        border: widget.centered ? Border.all(color: colors.border) : null,
      ),
      alignment: Alignment.center,
      child: BeuiIcon(
        BeuiIcons.uploadCloud,
        size: widget.centered ? 28 : 24,
        color: colors.foreground,
      ),
    );

    final copy = Column(
      crossAxisAlignment:
          widget.centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          textAlign: widget.centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: colors.foreground,
            fontWeight: FontWeight.w600,
            fontSize: widget.centered ? 16 : 14,
            height: 1.25,
          ),
        ),
        SizedBox(height: widget.centered ? 4 : 2),
        Text(
          widget.description,
          textAlign: widget.centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: colors.mutedForeground,
            fontSize: 12,
            height: widget.centered ? 1.4 : 1.3,
          ),
        ),
      ],
    );

    final browse = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.centered ? 16 : 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BeuiRadii.pill),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        widget.browseLabel,
        style: TextStyle(
          color: colors.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    return Opacity(
      opacity: widget.enabled ? 1 : 0.55,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Transform.scale(
          scale: scale,
          child: CustomPaint(
            painter: _DashedRRectPainter(
              color: colors.border,
              radius: 24,
            ),
            child: ConstrainedBox(
              constraints: widget.centered
                  ? const BoxConstraints(minHeight: 224)
                  : const BoxConstraints(),
              child: Padding(
              padding: widget.centered
                  ? const EdgeInsets.all(28)
                  : const EdgeInsets.all(20),
              child: widget.centered
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 12,
                      children: [
                        icon,
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: copy,
                        ),
                        browse,
                      ],
                    )
                  : Row(
                      spacing: 16,
                      children: [
                        icon,
                        Expanded(child: copy),
                        browse,
                      ],
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    super.key,
    required this.item,
    required this.reduce,
    required this.colors,
    required this.onRemove,
    required this.onRetry,
  });

  final BeuiFileUploadItem item;
  final bool reduce;
  final BeuiColors colors;
  final VoidCallback onRemove;
  final VoidCallback? onRetry;

  Color get _tone {
    switch (item.status) {
      case BeuiFileUploadStatus.success:
        return colors.success;
      case BeuiFileUploadStatus.error:
        return colors.destructive;
      case BeuiFileUploadStatus.uploading:
        return colors.foreground;
      case BeuiFileUploadStatus.queued:
        return colors.mutedForeground;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = beuiClampUploadProgress(item.progress, item.status);
    final showProgress = item.status == BeuiFileUploadStatus.uploading ||
        item.status == BeuiFileUploadStatus.success;
    final meta = '${_fileKind(item)} · ${beuiFormatBytes(item.size)}'
        '${item.status == BeuiFileUploadStatus.error && item.error != null ? ' · ${item.error}' : ''}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: BeuiIcon(
                _fileIcon(item),
                size: 20,
                color: colors.mutedForeground,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.foreground,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.mutedForeground,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StatusGlyph(
                            status: item.status,
                            color: _tone,
                            reduce: reduce,
                          ),
                          if (onRetry != null)
                            _IconTap(
                              semanticLabel: 'Retry ${item.name}',
                              onPressed: onRetry!,
                              child: BeuiIcon(
                                BeuiIcons.rotateCcw,
                                size: 14,
                                color: colors.mutedForeground,
                              ),
                            ),
                          _IconTap(
                            semanticLabel: 'Remove ${item.name}',
                            onPressed: onRemove,
                            child: BeuiIcon(
                              BeuiIcons.x,
                              size: 14,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (showProgress) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      label: '${item.name} upload progress',
                      value: '${progress.round()}%',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(BeuiRadii.pill),
                        child: SizedBox(
                          height: 6,
                          child: ColoredBox(
                            color: colors.muted,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: progress / 100,
                                child: ColoredBox(
                                  color: item.status ==
                                          BeuiFileUploadStatus.success
                                      ? colors.success
                                      : colors.foreground,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusGlyph extends StatefulWidget {
  const _StatusGlyph({
    required this.status,
    required this.color,
    required this.reduce,
  });

  final BeuiFileUploadStatus status;
  final Color color;
  final bool reduce;

  @override
  State<_StatusGlyph> createState() => _StatusGlyphState();
}

class _StatusGlyphState extends State<_StatusGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant _StatusGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final spinning =
        widget.status == BeuiFileUploadStatus.uploading && !widget.reduce;
    if (spinning) {
      if (!_spin.isAnimating) _spin.repeat();
    } else if (_spin.isAnimating) {
      _spin.stop();
      _spin.value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = switch (widget.status) {
      BeuiFileUploadStatus.success => BeuiIcons.circleCheck,
      BeuiFileUploadStatus.error => BeuiIcons.alertCircle,
      BeuiFileUploadStatus.uploading => BeuiIcons.loader,
      BeuiFileUploadStatus.queued => BeuiIcons.file,
    };
    Widget icon = BeuiIcon(painter, size: 16, color: widget.color);
    if (widget.status == BeuiFileUploadStatus.uploading && !widget.reduce) {
      icon = RotationTransition(turns: _spin, child: icon);
    }
    return SizedBox(width: 24, height: 24, child: Center(child: icon));
  }
}

class _IconTap extends StatelessWidget {
  const _IconTap({
    required this.semanticLabel,
    required this.onPressed,
    required this.child,
  });

  final String semanticLabel;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(width: 28, height: 28, child: Center(child: child)),
      ),
    );
  }
}
