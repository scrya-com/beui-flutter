import 'package:beui/beui.dart';
import 'package:flutter/widgets.dart';

const _sidebarResources = <BeuiSidebarResource>[
  BeuiSidebarResource(
    id: 'design-system',
    label: 'Design system',
    kind: BeuiSidebarResourceKind.project,
  ),
  BeuiSidebarResource(
    id: 'client-portal',
    label: 'Client portal',
    kind: BeuiSidebarResourceKind.project,
  ),
  BeuiSidebarResource(
    id: 'platform',
    label: 'Platform',
    kind: BeuiSidebarResourceKind.project,
    children: [
      BeuiSidebarResource(
        id: 'api',
        label: 'API migration',
        kind: BeuiSidebarResourceKind.file,
      ),
      BeuiSidebarResource(
        id: 'billing',
        label: 'Billing states',
        kind: BeuiSidebarResourceKind.file,
      ),
      BeuiSidebarResource(
        id: 'docs',
        label: 'Read platform docs',
        kind: BeuiSidebarResourceKind.bookmark,
      ),
    ],
  ),
  BeuiSidebarResource(
    id: 'agent-workspace',
    label: 'Agent workspace',
    kind: BeuiSidebarResourceKind.project,
    children: [
      BeuiSidebarResource(
        id: 'resource-review',
        label: 'Review resource sidebar interaction details',
        kind: BeuiSidebarResourceKind.file,
      ),
      BeuiSidebarResource(
        id: 'release-offer',
        label: 'Prepare release announcement',
        kind: BeuiSidebarResourceKind.file,
      ),
      BeuiSidebarResource(
        id: 'haptics',
        label: 'Explore interaction feedback',
        kind: BeuiSidebarResourceKind.bookmark,
      ),
    ],
  ),
  BeuiSidebarResource(
    id: 'release-notes',
    label: 'Release notes',
    kind: BeuiSidebarResourceKind.file,
  ),
];

class AISidebarDemo extends StatefulWidget {
  const AISidebarDemo({super.key});

  @override
  State<AISidebarDemo> createState() => _AISidebarDemoState();
}

class _AISidebarDemoState extends State<AISidebarDemo> {
  var _active = 'resource-review';
  var _items = List<BeuiSidebarResource>.of(_sidebarResources);

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return SizedBox(
      width: 640,
      height: 520,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.foreground.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 256,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Action(icon: BeuiIcons.pencil, label: 'New workspace'),
                    _Action(icon: BeuiIcons.listTodo, label: 'Pull requests'),
                    _Action(icon: BeuiIcons.globe, label: 'Sites'),
                    const SizedBox(height: 16),
                    Text(
                      'Projects',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: BeuiAISidebar(
                        items: _items,
                        activeId: _active,
                        initialExpandedIds: const ['platform', 'agent-workspace'],
                        onActiveChanged: (id) => setState(() => _active = id),
                        onItemsChanged: (next) => setState(() => _items = next),
                        onMove: (_) => Future<void>.delayed(
                          const Duration(milliseconds: 450),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: colors.muted.withValues(alpha: 0.35),
                child: Center(
                  child: Text(
                    _active,
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label});
  final BeuiIconPainter icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        spacing: 10,
        children: [
          BeuiIcon(icon, size: 16, color: colors.foreground),
          Text(label, style: TextStyle(fontSize: 14, color: colors.foreground)),
        ],
      ),
    );
  }
}

const _chatResources = <BeuiSidebarResource>[
  BeuiSidebarResource(
    id: 'release',
    label: 'Release',
    kind: BeuiSidebarResourceKind.project,
    children: [
      BeuiSidebarResource(
        id: 'checkout',
        label: 'Checkout release',
        kind: BeuiSidebarResourceKind.file,
      ),
    ],
  ),
  BeuiSidebarResource(
    id: 'design',
    label: 'Design',
    kind: BeuiSidebarResourceKind.project,
    children: [
      BeuiSidebarResource(
        id: 'motion',
        label: 'Motion notes',
        kind: BeuiSidebarResourceKind.bookmark,
      ),
    ],
  ),
];

class ChatAppDemo extends StatefulWidget {
  const ChatAppDemo({super.key});

  @override
  State<ChatAppDemo> createState() => _ChatAppDemoState();
}

class _ChatAppDemoState extends State<ChatAppDemo>
    with TickerProviderStateMixin {
  var _items = List<BeuiSidebarResource>.of(_chatResources);
  var _active = 'checkout';
  var _tool = BeuiToolApprovalStatus.pending;
  late final AnimationController _toApproved;
  late final AnimationController _toRunning;
  late final AnimationController _toComplete;
  late final AnimationController _pending;
  late final AnimationController _stream;
  final _messages = <_ChatLine>[];
  var _waiting = false;
  String? _streamId;
  var _streamFull = '';
  var _run = 0;

  static const _reply =
      'The checkout patch is ready for review.';

  @override
  void initState() {
    super.initState();
    _toApproved = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _tool = BeuiToolApprovalStatus.approved);
          _toRunning.forward(from: 0);
        }
      });
    _toRunning = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _tool = BeuiToolApprovalStatus.running);
          _toComplete.forward(from: 0);
        }
      });
    _toComplete = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _tool = BeuiToolApprovalStatus.complete);
        }
      });
    _pending = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _beginStream();
      });
    _stream = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..addListener(_onStream)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _finishStream();
      });
  }

  @override
  void dispose() {
    _toApproved.dispose();
    _toRunning.dispose();
    _toComplete.dispose();
    _pending.dispose();
    _stream.dispose();
    super.dispose();
  }

  void _approve() {
    setState(() => _tool = BeuiToolApprovalStatus.approving);
    _toApproved.forward(from: 0);
  }

  bool get _busy => _waiting || _streamId != null;

  void _submit(String value, String? _) {
    if (value.trim().isEmpty || _busy) return;
    final id = _run++;
    setState(() {
      _messages.add(
        _ChatLine(id: 'user-$id', user: true, text: value),
      );
      _waiting = true;
    });
    _pending.forward(from: 0);
  }

  void _beginStream() {
    if (!mounted) return;
    final id = 'assistant-$_run';
    setState(() {
      _waiting = false;
      _streamId = id;
      _streamFull = _reply;
      _messages.add(_ChatLine(id: id, user: false, text: '', streaming: true));
    });
    final ms = (_reply.length / 92 * 1000).round();
    _stream.duration = Duration(milliseconds: ms);
    _stream.forward(from: 0);
  }

  void _onStream() {
    if (_streamId == null) return;
    final cursor = (_stream.value * _streamFull.length)
        .floor()
        .clamp(0, _streamFull.length);
    final next = _streamFull.substring(0, cursor);
    for (final m in _messages) {
      if (m.id == _streamId && m.text != next) {
        setState(() => m.text = next);
        return;
      }
    }
  }

  void _finishStream() {
    setState(() {
      for (final m in _messages) {
        if (m.id == _streamId) {
          m
            ..text = _streamFull
            ..streaming = false;
        }
      }
      _streamId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    final plan = [
      const BeuiTodoItem(
        id: 'inspect',
        title: 'Inspect the checkout flow',
        status: BeuiTodoStatus.completed,
      ),
      const BeuiTodoItem(
        id: 'patch',
        title: 'Prepare the validation patch',
        status: BeuiTodoStatus.completed,
      ),
      BeuiTodoItem(
        id: 'checks',
        title: 'Run focused checks',
        status: _tool == BeuiToolApprovalStatus.complete
            ? BeuiTodoStatus.completed
            : _tool == BeuiToolApprovalStatus.running
                ? BeuiTodoStatus.inProgress
                : _tool == BeuiToolApprovalStatus.denied
                    ? BeuiTodoStatus.cancelled
                    : BeuiTodoStatus.pending,
      ),
      BeuiTodoItem(
        id: 'review',
        title: 'Collect release approval',
        status: _tool == BeuiToolApprovalStatus.complete
            ? BeuiTodoStatus.inProgress
            : BeuiTodoStatus.pending,
      ),
    ];

    return SizedBox(
      width: 720,
      height: 560,
      child: BeuiChatApp(
        sidebarWidth: 272,
        sidebar: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Action(icon: BeuiIcons.messageSquare, label: 'New task'),
              _Action(icon: BeuiIcons.search, label: 'Search'),
              const SizedBox(height: 12),
              Text(
                'Projects',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.mutedForeground,
                ),
              ),
              Expanded(
                child: BeuiAISidebar(
                  items: _items,
                  activeId: _active,
                  initialExpandedIds: const ['release', 'design'],
                  onActiveChanged: (id) => setState(() => _active = id),
                  onItemsChanged: (next) => setState(() => _items = next),
                ),
              ),
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Checkout release',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colors.foreground,
                            ),
                          ),
                          Text(
                            'Agent workspace · focused patch',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(BeuiRadii.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          'Connected',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: colors.success,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: BeuiMessageScroller(
                height: null,
                busy: _busy,
                children: [
                  BeuiScrollerMessage(
                    id: 'user-audit',
                    from: BeuiMessageFrom.user,
                    text:
                        'Audit the checkout flow, fix the validation gap, and prepare a release-ready patch.',
                    child: const BeuiMessageBubble(
                      align: BeuiMessageAlign.end,
                      variant: BeuiMessageBubbleVariant.solid,
                      child: Text(
                        'Audit the checkout flow, fix the validation gap, and prepare a release-ready patch.',
                      ),
                    ),
                  ),
                  BeuiScrollerMessage(
                    id: 'plan',
                    from: BeuiMessageFrom.assistant,
                    text: 'Release plan',
                    child: BeuiTodoList(
                      items: plan,
                      title: 'Release plan',
                      collapseOnComplete: false,
                    ),
                  ),
                  BeuiScrollerMessage(
                    id: 'approval',
                    from: BeuiMessageFrom.assistant,
                    text: 'Run focused checkout checks?',
                    child: BeuiToolApproval(
                      tool: 'terminal.run',
                      title: 'Run focused checkout checks?',
                      description:
                          'The agent needs permission to run the validation and accessibility suites.',
                      status: _tool,
                      initialOpen: true,
                      parameters: const [
                        BeuiToolApprovalParameter(
                          id: 'command',
                          label: 'Command',
                          value: BeuiToolApprovalCode(
                            code: 'bun test checkout --coverage',
                          ),
                        ),
                        BeuiToolApprovalParameter(
                          id: 'scope',
                          label: 'Scope',
                          value: Text('Current workspace'),
                        ),
                      ],
                      onApprove: _approve,
                      onAlwaysAllow: _approve,
                      onDeny: () => setState(
                        () => _tool = BeuiToolApprovalStatus.denied,
                      ),
                    ),
                  ),
                  if (_tool == BeuiToolApprovalStatus.running ||
                      _tool == BeuiToolApprovalStatus.complete)
                    BeuiScrollerMessage(
                      id: 'result',
                      from: BeuiMessageFrom.assistant,
                      text: 'Checkout checks',
                      child: BeuiToolResult(
                        tool: 'terminal.run',
                        title: _tool == BeuiToolApprovalStatus.running
                            ? 'Running checkout checks'
                            : 'Checkout checks passed',
                        status: _tool == BeuiToolApprovalStatus.running
                            ? BeuiToolResultStatus.running
                            : BeuiToolResultStatus.success,
                        output: _tool == BeuiToolApprovalStatus.running
                            ? '✓ validation contract\n… checkout keyboard flow'
                            : '✓ validation contract\n✓ checkout keyboard flow\n✓ order submission recovery',
                        meta: _tool == BeuiToolApprovalStatus.running
                            ? 'Live'
                            : '2.8s',
                        collapseOnComplete: false,
                      ),
                    ),
                  for (final message in _messages)
                    BeuiScrollerMessage(
                      id: message.id,
                      from: message.user
                          ? BeuiMessageFrom.user
                          : BeuiMessageFrom.assistant,
                      text: message.text,
                      child: BeuiMessageBubble(
                        align: message.user
                            ? BeuiMessageAlign.end
                            : BeuiMessageAlign.start,
                        variant: message.user
                            ? BeuiMessageBubbleVariant.solid
                            : BeuiMessageBubbleVariant.soft,
                        animateIn: true,
                        child: Text(
                          message.text.isEmpty ? '…' : message.text,
                        ),
                      ),
                    ),
                  if (_waiting)
                    const BeuiScrollerMessage(
                      id: 'pending',
                      from: BeuiMessageFrom.assistant,
                      text: 'Reviewing your direction',
                      child: BeuiThinkingShimmer(
                        text: 'Reviewing your direction',
                      ),
                    ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: BeuiPromptInput(
                  placeholder: 'Ask the agent to continue…',
                  loading: _busy,
                  onSubmit: _submit,
                  onStop: () {
                    _pending.stop();
                    _stream.stop();
                    setState(() {
                      _waiting = false;
                      _streamId = null;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatLine {
  _ChatLine({
    required this.id,
    required this.user,
    required this.text,
    this.streaming = false,
  });

  final String id;
  final bool user;
  String text;
  bool streaming;
}
