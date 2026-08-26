import 'package:flutter/widgets.dart';

import '../../motion/presence.dart';
import '../../motion/reduce.dart';
import '../../tokens/ease.dart';
import '../../tokens/theme.dart';
import '../icons.dart';
import 'file_upload.dart';

enum BeuiAttachmentKind { file, link, image, audio }

enum BeuiAttachmentStatus { idle, uploading, complete, failed }

class BeuiAttachmentItem {
  const BeuiAttachmentItem({
    required this.id,
    required this.name,
    required this.kind,
    this.size,
    this.href,
    this.previewUrl,
    this.currentTime = 0,
    this.duration,
    this.status = BeuiAttachmentStatus.idle,
    this.error,
  });

  final String id;
  final String name;
  final BeuiAttachmentKind kind;
  final int? size;
  final String? href;
  final String? previewUrl;
  final double currentTime;
  final double? duration;
  final BeuiAttachmentStatus status;
  final String? error;

  BeuiAttachmentItem copyWith({
    double? currentTime,
    BeuiAttachmentStatus? status,
    String? error,
    bool clearError = false,
  }) {
    return BeuiAttachmentItem(
      id: id,
      name: name,
      kind: kind,
      size: size,
      href: href,
      previewUrl: previewUrl,
      currentTime: currentTime ?? this.currentTime,
      duration: duration,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

const _waveform = <double>[
  18, 31, 24, 39, 30, 43, 27, 18, 9, 29, 38, 24, 34, 18, 26, 37, 21, 14,
  7, 11, 22, 35, 18, 26, 41, 29, 17, 33,
];

String beuiFormatDuration(double? seconds) {
  final safe = (seconds ?? 0).clamp(0, 24 * 3600).round();
  final minutes = safe ~/ 60;
  return '$minutes:${(safe % 60).toString().padLeft(2, '0')}';
}

/// Mixed attachment workspace. Port of `components/motion/attachment-upload.tsx`.
class BeuiAttachmentUpload extends StatefulWidget {
  const BeuiAttachmentUpload({
    super.key,
    this.value,
    this.initialValue = const [],
    this.onChanged,
    this.onRetry,
    this.onRemove,
    this.onBrowse,
    this.playingId,
    this.onAudioToggle,
    this.maxFiles = 12,
    this.enabled = true,
    this.title = 'Drag and drop or browse files',
    this.description,
    this.attachmentsLabel = 'Attachments',
  });

  final List<BeuiAttachmentItem>? value;
  final List<BeuiAttachmentItem> initialValue;
  final ValueChanged<List<BeuiAttachmentItem>>? onChanged;
  final ValueChanged<BeuiAttachmentItem>? onRetry;
  final ValueChanged<BeuiAttachmentItem>? onRemove;
  final VoidCallback? onBrowse;
  final String? playingId;
  final ValueChanged<BeuiAttachmentItem>? onAudioToggle;
  final int maxFiles;
  final bool enabled;
  final String title;
  final String? description;
  final String attachmentsLabel;

  @override
  State<BeuiAttachmentUpload> createState() => _BeuiAttachmentUploadState();
}

class _BeuiAttachmentUploadState extends State<BeuiAttachmentUpload> {
  late List<BeuiAttachmentItem> _internal;
  String? _previewId;
  OverlayEntry? _previewEntry;
  OverlayState? _overlay;

  bool get _controlled => widget.value != null;
  List<BeuiAttachmentItem> get _items => widget.value ?? _internal;

  @override
  void initState() {
    super.initState();
    _internal = List.of(widget.initialValue);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _overlay = Overlay.maybeOf(context);
  }

  @override
  void dispose() {
    _previewEntry?.remove();
    super.dispose();
  }

  void _commit(List<BeuiAttachmentItem> next) {
    if (!_controlled) setState(() => _internal = next);
    widget.onChanged?.call(next);
  }

  void _remove(BeuiAttachmentItem item) {
    _commit(_items.where((e) => e.id != item.id).toList());
    widget.onRemove?.call(item);
    if (_previewId == item.id) _closePreview();
  }

  void _retry(BeuiAttachmentItem item) {
    widget.onRetry?.call(item);
  }

  void _openPreview(BeuiAttachmentItem item) {
    _closePreview();
    final src = item.previewUrl ?? item.href;
    if (src == null) return;
    _previewId = item.id;
    final overlay = _overlay;
    if (overlay == null) return;
    _previewEntry = OverlayEntry(
      builder: (context) {
        final reduce = beuiReduceMotion(context);
        return BeuiPresence(
          present: true,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closePreview,
                  child: ColoredBox(
                    color: const Color(0x73000000),
                    child: reduce
                        ? const SizedBox.expand()
                        : const SizedBox.expand(),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 720,
                    maxHeight: 640,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          src,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) {
                            return ColoredBox(
                              color: context.beuiColors.muted,
                              child: const SizedBox(width: 280, height: 180),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: -12,
                        right: -12,
                        child: GestureDetector(
                          onTap: _closePreview,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: context.beuiColors.background,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.beuiColors.borderStrong,
                              ),
                            ),
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: Center(
                                child: BeuiIcon(
                                  BeuiIcons.x,
                                  size: 16,
                                  color: context.beuiColors.foreground,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    overlay.insert(_previewEntry!);
  }

  void _closePreview() {
    _previewEntry?.remove();
    _previewEntry = null;
    _previewId = null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final maxReached = _items.length >= widget.maxFiles;
    final canAdd = widget.enabled && !maxReached;
    final description = widget.description ??
        'Images, audio, PDFs and links · up to ${widget.maxFiles} files';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        BeuiFileUpload(
          enabled: canAdd,
          variant: BeuiFileUploadVariant.centered,
          title: maxReached ? 'Upload limit reached' : widget.title,
          description: maxReached
              ? '${_items.length} of ${widget.maxFiles} files added'
              : description,
          browseLabel: 'Browse',
          onBrowse: widget.onBrowse ??
              () {
                _commit([
                  ..._items,
                  BeuiAttachmentItem(
                    id: 'file-${DateTime.now().microsecondsSinceEpoch}',
                    name: 'attachment.txt',
                    kind: BeuiAttachmentKind.file,
                    size: 12000,
                  ),
                ]);
              },
          onChanged: (_) {},
        ),
        if (_items.isNotEmpty)
          Text(
            widget.attachmentsLabel,
            style: TextStyle(
              color: colors.mutedForeground,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        for (final item in _items)
          _AttachmentRow(
            key: ValueKey(item.id),
            item: item,
            playing: widget.playingId == item.id,
            onRemove: () => _remove(item),
            onRetry: item.status == BeuiAttachmentStatus.failed
                ? () => _retry(item)
                : null,
            onAudioToggle: item.kind == BeuiAttachmentKind.audio
                ? () => widget.onAudioToggle?.call(item)
                : null,
            onPreview: item.kind == BeuiAttachmentKind.image
                ? () => _openPreview(item)
                : null,
          ),
      ],
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    super.key,
    required this.item,
    required this.playing,
    required this.onRemove,
    required this.onRetry,
    required this.onAudioToggle,
    required this.onPreview,
  });

  final BeuiAttachmentItem item;
  final bool playing;
  final VoidCallback onRemove;
  final VoidCallback? onRetry;
  final VoidCallback? onAudioToggle;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final reduce = beuiReduceMotion(context);
    final failed = item.status == BeuiAttachmentStatus.failed;
    final uploading = item.status == BeuiAttachmentStatus.uploading;
    final complete = item.status == BeuiAttachmentStatus.complete;
    final progress = item.duration != null && item.duration! > 0
        ? (item.currentTime / item.duration!).clamp(0.0, 1.0)
        : 0.0;

    Widget leading;
    if (item.kind == BeuiAttachmentKind.image) {
      final src = item.previewUrl ?? item.href;
      leading = GestureDetector(
        onTap: onPreview,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 36,
            height: 36,
            child: src == null
                ? ColoredBox(
                    color: colors.muted,
                    child: Center(
                      child: BeuiIcon(
                        BeuiIcons.fileImage,
                        size: 16,
                        color: colors.mutedForeground,
                      ),
                    ),
                  )
                : Image.network(
                    src,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) {
                      return ColoredBox(
                        color: colors.muted,
                        child: Center(
                          child: BeuiIcon(
                            BeuiIcons.fileImage,
                            size: 16,
                            color: colors.mutedForeground,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      );
    } else {
      final painter = switch (item.kind) {
        BeuiAttachmentKind.link => BeuiIcons.globe,
        BeuiAttachmentKind.audio => BeuiIcons.mic,
        BeuiAttachmentKind.image => BeuiIcons.fileImage,
        BeuiAttachmentKind.file => BeuiIcons.paperclip,
      };
      leading = SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: BeuiIcon(painter, size: 16, color: colors.mutedForeground),
        ),
      );
    }

    Widget body;
    if (item.kind == BeuiAttachmentKind.audio) {
      body = Row(
        spacing: 8,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              beuiFormatDuration(item.currentTime),
              style: TextStyle(
                color: colors.mutedForeground,
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: _Waveform(
              progress: progress,
              playing: playing && !reduce,
              color: colors.foreground,
              rest: colors.mutedForeground.withValues(alpha: 0.35),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              beuiFormatDuration(item.duration),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: colors.mutedForeground,
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          GestureDetector(
            onTap: onAudioToggle,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.foreground,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: BeuiIcon(
                playing ? BeuiIcons.pause : BeuiIcons.play,
                size: 16,
                color: colors.background,
              ),
            ),
          ),
        ],
      );
    } else {
      body = Row(
        spacing: 8,
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
                if (failed)
                  Text(
                    item.error ?? 'Upload failed',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.destructive,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            item.kind == BeuiAttachmentKind.link
                ? 'Web'
                : (item.size != null ? beuiFormatBytes(item.size!) : ''),
            style: TextStyle(color: colors.mutedForeground, fontSize: 12),
          ),
        ],
      );
    }

    Widget action;
    if (uploading) {
      action = const SizedBox(width: 36, height: 36);
    } else if (complete) {
      action = SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: BeuiIcon(BeuiIcons.check, size: 16, color: colors.success),
        ),
      );
    } else if (failed && onRetry != null) {
      action = GestureDetector(
        onTap: onRetry,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: BeuiIcon(
              BeuiIcons.rotateCcw,
              size: 16,
              color: colors.destructive,
            ),
          ),
        ),
      );
    } else if (failed) {
      action = SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: BeuiIcon(
            BeuiIcons.alertCircle,
            size: 16,
            color: colors.destructive,
          ),
        ),
      );
    } else {
      action = GestureDetector(
        onTap: onRemove,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: BeuiIcon(
              BeuiIcons.x,
              size: 16,
              color: colors.mutedForeground,
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: failed
                      ? colors.destructive.withValues(alpha: 0.1)
                      : colors.background,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      spacing: 12,
                      children: [
                        leading,
                        Expanded(child: body),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            action,
          ],
        ),
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({
    required this.progress,
    required this.playing,
    required this.color,
    required this.rest,
  });

  final double progress;
  final bool playing;
  final Color color;
  final Color rest;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          for (var i = 0; i < _waveform.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.8),
                child: Align(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: BeuiCurves.easeOut,
                    height: playing
                        ? _waveform[i] * (i.isEven ? 0.85 : 1)
                        : _waveform[i].toDouble(),
                    decoration: BoxDecoration(
                      color: i / _waveform.length <= progress ? color : rest,
                      borderRadius: BorderRadius.circular(99),
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
