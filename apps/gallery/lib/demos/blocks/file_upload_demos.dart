import 'package:beui/beui.dart';
import 'package:flutter/widgets.dart';

const _initialQueue = <BeuiFileUploadItem>[
  BeuiFileUploadItem(
    id: 'brand-assets',
    name: 'brand-assets.zip',
    size: 18400000,
    type: 'application/zip',
    progress: 100,
    status: BeuiFileUploadStatus.success,
  ),
  BeuiFileUploadItem(
    id: 'release-video',
    name: 'release-cut.mov',
    size: 84200000,
    type: 'video/quicktime',
    progress: 58,
    status: BeuiFileUploadStatus.uploading,
  ),
  BeuiFileUploadItem(
    id: 'contracts',
    name: 'vendor-contract.pdf',
    size: 2800000,
    type: 'application/pdf',
    progress: 32,
    status: BeuiFileUploadStatus.error,
    error: 'Connection lost',
  ),
];

class FileUploadDemo extends StatefulWidget {
  const FileUploadDemo({super.key});

  @override
  State<FileUploadDemo> createState() => _FileUploadDemoState();
}

class _FileUploadDemoState extends State<FileUploadDemo>
    with SingleTickerProviderStateMixin {
  var _items = List<BeuiFileUploadItem>.of(_initialQueue);
  var _variant = BeuiFileUploadVariant.centered;
  late final AnimationController _clock;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        _advance();
        final still =
            _items.any((e) => e.status == BeuiFileUploadStatus.uploading);
        if (still) _clock.forward(from: 0);
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled &&
        _items.any((e) => e.status == BeuiFileUploadStatus.uploading) &&
        !_clock.isAnimating) {
      _clock.forward();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _advance() {
    _tick += 1;
    setState(() {
      _items = [
        for (final item in _items)
          if (item.status == BeuiFileUploadStatus.uploading)
            () {
              final next = (item.progress + 7 + (_tick % 12)).clamp(0, 100);
              return item.copyWith(
                progress: next.toDouble(),
                status: next >= 100
                    ? BeuiFileUploadStatus.success
                    : BeuiFileUploadStatus.uploading,
              );
            }()
          else
            item,
      ];
    });
  }

  void _start(String id) {
    setState(() {
      _items = [
        for (final item in _items)
          if (item.id == id)
            item.copyWith(
              status: BeuiFileUploadStatus.uploading,
              progress: 0,
              clearError: true,
            )
          else
            item,
      ];
    });
    if (!_clock.isAnimating) _clock.forward(from: 0);
  }

  void _reset() {
    setState(() => _items = List.of(_initialQueue));
    _clock.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final ready =
        _items.where((e) => e.status == BeuiFileUploadStatus.success).length;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 448),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload package',
                          style: TextStyle(
                            color: colors.foreground,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$ready of ${_items.length} files ready',
                          style: TextStyle(
                            color: colors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: BorderRadius.circular(BeuiRadii.pill),
                      border: Border.all(color: colors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _Seg(
                            label: 'Centered',
                            selected:
                                _variant == BeuiFileUploadVariant.centered,
                            onTap: () => setState(
                              () => _variant = BeuiFileUploadVariant.centered,
                            ),
                          ),
                          _Seg(
                            label: 'Row',
                            selected: _variant == BeuiFileUploadVariant.row,
                            onTap: () => setState(
                              () => _variant = BeuiFileUploadVariant.row,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _reset,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.border),
                      ),
                      alignment: Alignment.center,
                      child: BeuiIcon(
                        BeuiIcons.rotateCcw,
                        size: 14,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
              BeuiFileUpload(
                value: _items,
                variant: _variant,
                maxFiles: 5,
                title: _variant == BeuiFileUploadVariant.centered
                    ? 'Drop files to upload'
                    : 'Drop release files',
                description: 'PDF, images, video or zipped assets',
                onChanged: (next) => setState(() => _items = next),
                onFilesAdded: (added) {
                  for (final item in added) {
                    _start(item.id);
                  }
                },
                onRetry: (item) => _start(item.id),
                onBrowse: () {
                  final added = createBeuiFileUploadItem(
                    name: 'new-asset.png',
                    size: 2400000,
                    type: 'image/png',
                  );
                  setState(() => _items = [..._items, added]);
                  _start(added.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.background : const Color(0x00000000),
          borderRadius: BorderRadius.circular(BeuiRadii.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? colors.foreground : colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}

const _initialAttachments = <BeuiAttachmentItem>[
  BeuiAttachmentItem(
    id: 'brief',
    name: 'launch-brief.pdf',
    kind: BeuiAttachmentKind.file,
    size: 32400000,
    href: 'data:application/pdf,beUI',
    status: BeuiAttachmentStatus.failed,
    error: 'Upload failed',
  ),
  BeuiAttachmentItem(
    id: 'flowers',
    name: 'orange-flowers.jpg',
    kind: BeuiAttachmentKind.image,
    size: 9800000,
    previewUrl:
        'https://images.unsplash.com/photo-1490750967868-88aa4486c946?auto=format&fit=crop&w=1200&q=85',
  ),
  BeuiAttachmentItem(
    id: 'voice-note',
    name: 'launch-note.m4a',
    kind: BeuiAttachmentKind.audio,
    currentTime: 12,
    duration: 48,
  ),
];

class AttachmentUploadDemo extends StatefulWidget {
  const AttachmentUploadDemo({super.key});

  @override
  State<AttachmentUploadDemo> createState() => _AttachmentUploadDemoState();
}

class _AttachmentUploadDemoState extends State<AttachmentUploadDemo>
    with TickerProviderStateMixin {
  var _items = List<BeuiAttachmentItem>.of(_initialAttachments);
  String? _playingId;
  late final AnimationController _play;
  late final AnimationController _retryHold;
  late final AnimationController _retryDone;
  String? _retryingId;

  @override
  void initState() {
    super.initState();
    _play = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        final id = _playingId;
        if (id == null) return;
        setState(() {
          _items = [
            for (final item in _items)
              if (item.id == id && item.duration != null)
                item.copyWith(
                  currentTime:
                      (item.currentTime + 1).clamp(0, item.duration!),
                )
              else
                item,
          ];
        });
        final playing = _items.firstWhere((e) => e.id == id);
        if ((playing.currentTime) >= (playing.duration ?? 0)) {
          setState(() => _playingId = null);
        } else {
          _play.forward(from: 0);
        }
      });
    _retryHold = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        final id = _retryingId;
        if (id == null) return;
        setState(() {
          _items = [
            for (final item in _items)
              if (item.id == id)
                item.copyWith(status: BeuiAttachmentStatus.complete)
              else
                item,
          ];
        });
        _retryDone.forward(from: 0);
      });
    _retryDone = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        final id = _retryingId;
        if (id == null) return;
        setState(() {
          _items = [
            for (final item in _items)
              if (item.id == id)
                item.copyWith(status: BeuiAttachmentStatus.idle)
              else
                item,
          ];
          _retryingId = null;
        });
      });
  }

  @override
  void dispose() {
    _play.dispose();
    _retryHold.dispose();
    _retryDone.dispose();
    super.dispose();
  }

  void _togglePlay(BeuiAttachmentItem item) {
    setState(() {
      _playingId = _playingId == item.id ? null : item.id;
    });
    if (_playingId != null && !_play.isAnimating) _play.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 672),
      child: BeuiAttachmentUpload(
        value: _items,
        playingId: _playingId,
        attachmentsLabel: 'Attachments:',
        onChanged: (next) => setState(() => _items = next),
        onAudioToggle: _togglePlay,
        onRetry: (item) {
          _retryingId = item.id;
          setState(() {
            _items = [
              for (final e in _items)
                if (e.id == item.id)
                  e.copyWith(
                    status: BeuiAttachmentStatus.uploading,
                    clearError: true,
                  )
                else
                  e,
            ];
          });
          _retryHold.forward(from: 0);
        },
        onBrowse: () {
          setState(() {
            _items = [
              ..._items,
              BeuiAttachmentItem(
                id: 'clip-${_items.length}',
                name: 'clip-${_items.length + 1}.png',
                kind: BeuiAttachmentKind.image,
                size: 1200000,
              ),
            ];
          });
        },
      ),
    );
  }
}
