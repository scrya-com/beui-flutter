import 'package:beui/beui.dart';
import 'package:flutter/widgets.dart';

class ThinkingShimmerDemo extends StatelessWidget {
  const ThinkingShimmerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const BeuiThinkingShimmer(
      text: 'Thinking…',
      style: TextStyle(fontSize: 18),
    );
  }
}

class AgentProgressDemo extends StatelessWidget {
  const AgentProgressDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const BeuiAgentProgress(
      label: 'Churning',
      initialSeconds: 151.6,
      fontSize: 16,
    );
  }
}

class ReasoningTextDemo extends StatelessWidget {
  const ReasoningTextDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = context.beuiColors.mutedForeground;
    Widget section(String title, BeuiReasoningVariant variant, List<String> phrases) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: muted.withValues(alpha: 0.6),
            ),
          ),
          BeuiReasoningText(variant: variant, phrases: phrases),
        ],
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 384),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 28,
        children: [
          section('Cascade', BeuiReasoningVariant.cascade, const [
            'Thinking',
            'Reading the request',
            'Working through the details',
            'Preparing the answer',
          ]),
          section('Swap', BeuiReasoningVariant.swap, const [
            'Thinking',
            'Reading the request',
            'Working through the details',
            'Preparing the answer',
          ]),
          section('Scramble', BeuiReasoningVariant.scramble, const [
            'Thinking',
            'Searching',
            'Reasoning',
            'Composing',
          ]),
        ],
      ),
    );
  }
}

class MessageBubbleDemo extends StatelessWidget {
  const MessageBubbleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 420,
      child: BeuiMessageBubbleGroup(
        children: [
          BeuiMessageBubble(
            align: BeuiMessageAlign.end,
            variant: BeuiMessageBubbleVariant.solid,
            animateIn: true,
            child: Text('Can you summarize the release notes?'),
          ),
          BeuiMessageBubble(
            align: BeuiMessageAlign.start,
            variant: BeuiMessageBubbleVariant.soft,
            animateIn: true,
            child: Text(
              'The release improves streaming, navigation, and recovery states.',
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubbleAvatarsDemo extends StatelessWidget {
  const MessageBubbleAvatarsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    Widget row({
      required bool end,
      required String name,
      required String body,
      required BeuiMessageBubbleVariant variant,
    }) {
      final avatar = Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.card,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: Text(
          name.substring(0, 1),
          style: TextStyle(fontSize: 12, color: colors.foreground),
        ),
      );
      final bubble = BeuiMessageBubble(
        align: end ? BeuiMessageAlign.end : BeuiMessageAlign.start,
        variant: variant,
        animateIn: true,
        child: Text(body),
      );
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: end
            ? [Expanded(child: bubble), const SizedBox(width: 8), avatar]
            : [avatar, const SizedBox(width: 8), Expanded(child: bubble)],
      );
    }

    return SizedBox(
      width: 420,
      child: Column(
        spacing: 12,
        children: [
          row(
            end: true,
            name: 'You',
            body: 'Ship the agent transcript tonight.',
            variant: BeuiMessageBubbleVariant.solid,
          ),
          row(
            end: false,
            name: 'Ada',
            body: 'Drafting the summary and attaching sources.',
            variant: BeuiMessageBubbleVariant.soft,
          ),
        ],
      ),
    );
  }
}

class MessageBubbleCollapsibleDemo extends StatelessWidget {
  const MessageBubbleCollapsibleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 420,
      child: BeuiMessageBubble(
        variant: BeuiMessageBubbleVariant.soft,
        child: BeuiMessageBubbleCollapsible(
          child: Text(
            'The assistant compared three approaches, measured streaming latency, '
            'and recommended keeping the live edge attached only while the reader '
            'is still at the bottom of the transcript. That keeps older turns '
            'stable when the model keeps talking.',
          ),
        ),
      ),
    );
  }
}

class PromptInputDemo extends StatefulWidget {
  const PromptInputDemo({super.key});

  @override
  State<PromptInputDemo> createState() => _PromptInputDemoState();
}

class _PromptInputDemoState extends State<PromptInputDemo> {
  String text = '';
  String model = 'grok-4.5';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: BeuiPromptInput(
        value: text,
        onChanged: (v) => setState(() => text = v),
        model: model,
        onModelChanged: (v) => setState(() => model = v),
        loading: loading,
        onStop: () => setState(() => loading = false),
        onSubmit: (v, m) {
          setState(() {
            loading = true;
            text = '';
          });
          Future<void>.delayed(const Duration(milliseconds: 1400), () {
            if (mounted) setState(() => loading = false);
          });
        },
        models: const [
          BeuiPromptModel(value: 'grok-4.5', label: 'Grok 4.5'),
          BeuiPromptModel(value: 'gpt-5.2', label: 'GPT-5.2'),
          BeuiPromptModel(value: 'claude-sonnet-4', label: 'Claude Sonnet 4'),
        ],
        actions: const [
          BeuiPromptAction(
            value: 'image',
            label: 'Attach image',
            description: 'Add a screenshot or visual reference.',
          ),
          BeuiPromptAction(
            value: 'skill',
            label: 'Use a skill',
            description: 'Give the agent a specialized workflow.',
          ),
        ],
      ),
    );
  }
}

class TodoListDemo extends StatefulWidget {
  const TodoListDemo({super.key});

  @override
  State<TodoListDemo> createState() => _TodoListDemoState();
}

class _TodoListDemoState extends State<TodoListDemo>
    with SingleTickerProviderStateMixin {
  int step = 0;
  int run = 0;
  late final AnimationController _clock;

  static const tasks = [
    'Inspect the current data flow',
    'Update the response schema',
    'Add coverage for edge cases',
    'Run checks and prepare the result',
  ];
  static const ticks = 4;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        if (step >= tasks.length * ticks) return;
        setState(() => step++);
        if (step < tasks.length * ticks) _clock.forward(from: 0);
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled &&
        step < tasks.length * ticks &&
        !_clock.isAnimating) {
      _clock.forward();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  List<BeuiTodoItem> get items {
    return [
      for (var i = 0; i < tasks.length; i++)
        BeuiTodoItem(
          id: 'task-$i',
          title: tasks[i],
          status: step >= (i + 1) * ticks
              ? BeuiTodoStatus.completed
              : step >= i * ticks
                  ? BeuiTodoStatus.inProgress
                  : BeuiTodoStatus.pending,
          progress: step >= i * ticks && step < (i + 1) * ticks
              ? ((step % ticks) + 1) * 25.0
              : null,
          detail: step >= i * ticks && step < (i + 1) * ticks
              ? '${((step % ticks) + 1) * 25}%'
              : null,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 480,
      height: 330,
      child: Stack(
        children: [
          BeuiTodoList(key: ValueKey(run), items: items, title: 'Implementation plan'),
          Positioned(
            left: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  step = 0;
                  run++;
                });
                _clock.forward(from: 0);
              },
              child: Row(
                children: [
                  BeuiIcon(
                    BeuiIcons.rotateCcw,
                    size: 12,
                    color: context.beuiColors.mutedForeground,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Replay',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.beuiColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageDemo extends StatelessWidget {
  const MessageDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 420,
      child: BeuiMessageBubbleGroup(
        children: [
          BeuiMessageBubble(
            align: BeuiMessageAlign.end,
            variant: BeuiMessageBubbleVariant.solid,
            animateIn: true,
            child: Text('What is the agent doing?'),
          ),
          BeuiMessageBubble(
            align: BeuiMessageAlign.start,
            variant: BeuiMessageBubbleVariant.soft,
            child: BeuiThinkingShimmer(text: 'Reading the workspace…'),
          ),
        ],
      ),
    );
  }
}

class _ThreadMessage {
  _ThreadMessage({
    required this.id,
    required this.from,
    required this.content,
    this.streaming = false,
    this.animateIn = false,
  });

  final String id;
  final BeuiMessageFrom from;
  String content;
  bool streaming;
  final bool animateIn;
}

class MessageScrollerDemo extends StatefulWidget {
  const MessageScrollerDemo({super.key});

  @override
  State<MessageScrollerDemo> createState() => _MessageScrollerDemoState();
}

class _MessageScrollerDemoState extends State<MessageScrollerDemo>
    with TickerProviderStateMixin {
  static const _reply =
      'The viewport follows while you stay at the live edge. Scroll upward while this response streams and it will leave your reading position alone.';

  late final AnimationController _pending;
  late final AnimationController _stream;
  int _run = 0;
  int _pendingRun = 0;
  bool _waiting = false;
  String? _streamId;
  String _streamFull = '';

  final List<_ThreadMessage> _messages = [
    _ThreadMessage(
      id: 'scope-question',
      from: BeuiMessageFrom.user,
      content: 'What should the first release include?',
    ),
    _ThreadMessage(
      id: 'scope-answer',
      from: BeuiMessageFrom.assistant,
      content: 'Start with the smallest workflow that still feels complete.',
    ),
    _ThreadMessage(
      id: 'states-question',
      from: BeuiMessageFrom.user,
      content: 'Include streaming and recovery states too.',
    ),
    _ThreadMessage(
      id: 'states-answer',
      from: BeuiMessageFrom.assistant,
      content: 'Yes. Those states make the first version feel dependable.',
    ),
    _ThreadMessage(
      id: 'evidence-question',
      from: BeuiMessageFrom.user,
      content: 'How should we present tool results?',
    ),
    _ThreadMessage(
      id: 'evidence-answer',
      from: BeuiMessageFrom.assistant,
      content: 'Keep results close to the action that produced them.',
    ),
    _ThreadMessage(
      id: 'approval-question',
      from: BeuiMessageFrom.user,
      content: 'What about actions that need confirmation?',
    ),
    _ThreadMessage(
      id: 'approval-answer',
      from: BeuiMessageFrom.assistant,
      content: 'Pause the run, explain the impact, and ask before continuing.',
    ),
    _ThreadMessage(
      id: 'summary-question',
      from: BeuiMessageFrom.user,
      content: 'Can the transcript stay easy to navigate?',
    ),
    _ThreadMessage(
      id: 'summary-answer',
      from: BeuiMessageFrom.assistant,
      content: 'Use the rail to jump between turns without losing your place.',
    ),
  ];

  bool get _loading => _waiting || _streamId != null;

  @override
  void initState() {
    super.initState();
    _pending = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _beginStream();
      });
    _stream = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_onStreamTick)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _finishStream();
      });
  }

  @override
  void dispose() {
    _pending.dispose();
    _stream.dispose();
    super.dispose();
  }

  void _submit(String prompt, String? _) {
    if (_loading || prompt.trim().isEmpty) return;
    final run = _run++;
    _pendingRun = run;
    setState(() {
      _messages.add(
        _ThreadMessage(
          id: 'sent-user-$run',
          from: BeuiMessageFrom.user,
          content: prompt,
          animateIn: true,
        ),
      );
      _waiting = true;
    });
    if (beuiReduceMotion(context)) {
      _beginStream();
    } else {
      _pending.forward(from: 0);
    }
  }

  void _beginStream() {
    if (!mounted) return;
    final id = 'sent-assistant-$_pendingRun';
    setState(() {
      _waiting = false;
      _streamId = id;
      _streamFull = _reply;
      _messages.add(
        _ThreadMessage(
          id: id,
          from: BeuiMessageFrom.assistant,
          content: '',
          streaming: true,
          animateIn: true,
        ),
      );
    });
    if (beuiReduceMotion(context)) {
      _finishStream();
      return;
    }
    final ms = 140 + (_reply.length / 96 * 1000).round();
    _stream.duration = Duration(milliseconds: ms);
    _stream.forward(from: 0);
  }

  void _onStreamTick() {
    if (_streamId == null) return;
    final duration = _stream.duration ?? Duration.zero;
    final elapsed = duration.inMilliseconds * _stream.value;
    final cursor = ((elapsed - 140) / 1000 * 96).floor().clamp(0, _streamFull.length);
    final next = _streamFull.substring(0, cursor);
    _ThreadMessage? msg;
    for (final m in _messages) {
      if (m.id == _streamId) {
        msg = m;
        break;
      }
    }
    final target = msg;
    if (target == null || target.content == next) return;
    setState(() => target.content = next);
  }

  void _finishStream() {
    if (!mounted || _streamId == null) return;
    setState(() {
      for (final m in _messages) {
        if (m.id == _streamId) {
          m
            ..content = _streamFull
            ..streaming = false;
        }
      }
      _streamId = null;
    });
  }

  void _stop() {
    _pending.stop();
    _stream.stop();
    setState(() {
      _waiting = false;
      for (final m in _messages) {
        if (m.streaming) m.streaming = false;
      }
      _streamId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return SizedBox(
      width: 440,
      height: 440,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(BeuiRadii.card),
          border: Border.all(color: colors.border.withValues(alpha: 0.7)),
        ),
        child: Column(
          children: [
            Expanded(
              child: BeuiMessageScroller(
                height: null,
                busy: _loading,
                navigation: BeuiMessageScrollerNavigation.rail,
                children: [
                  for (final message in _messages)
                    BeuiScrollerMessage(
                      id: message.id,
                      from: message.from,
                      text: message.content,
                      child: BeuiMessageBubble(
                        align: message.from == BeuiMessageFrom.user
                            ? BeuiMessageAlign.end
                            : BeuiMessageAlign.start,
                        variant: message.from == BeuiMessageFrom.user
                            ? BeuiMessageBubbleVariant.solid
                            : BeuiMessageBubbleVariant.soft,
                        animateIn: message.animateIn &&
                            message.from == BeuiMessageFrom.user,
                        child: message.from == BeuiMessageFrom.assistant
                            ? BeuiStreamingResponse(
                                status: message.streaming
                                    ? BeuiStreamingStatus.streaming
                                    : BeuiStreamingStatus.complete,
                                showActions: false,
                                copyText: message.content,
                                child: Text(
                                  message.content.isEmpty
                                      ? '…'
                                      : message.content,
                                ),
                              )
                            : Text(message.content),
                      ),
                    ),
                  if (_waiting)
                    const BeuiScrollerMessage(
                      id: 'pending-assistant',
                      from: BeuiMessageFrom.assistant,
                      text: 'Preparing response',
                      child: BeuiMessageBubble(
                        child: Text('Preparing response'),
                      ),
                    ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border.withValues(alpha: 0.6))),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: BeuiPromptInput(
                  placeholder: 'Send another message…',
                  loading: _loading,
                  onSubmit: _submit,
                  onStop: _stop,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CitationsDemo extends StatelessWidget {
  const CitationsDemo({super.key});

  static const items = [
    BeuiCitationItem(
      id: 'motion',
      title: 'Motion documentation',
      domain: 'motion.dev',
      url: 'https://motion.dev/docs/react',
    ),
    BeuiCitationItem(
      id: 'wai',
      title: 'WAI accessibility patterns',
      domain: 'w3.org',
      url: 'https://www.w3.org/WAI/ARIA/apg/',
    ),
    BeuiCitationItem(
      id: 'react',
      title: 'React documentation',
      domain: 'react.dev',
      url: 'https://react.dev/learn',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.beuiColors;
    return SizedBox(
      width: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 14, height: 1.55, color: colors.foreground),
              children: const [
                TextSpan(text: 'Use layout-aware motion for newly appended results '),
                WidgetSpan(child: BeuiCitation(index: 1)),
                TextSpan(text: ' and preserve accessible disclosure '),
                WidgetSpan(child: BeuiCitation(index: 2)),
                TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const BeuiCitations(citations: items, initialOpen: true),
        ],
      ),
    );
  }
}

class StreamingResponseDemo extends StatefulWidget {
  const StreamingResponseDemo({super.key});

  @override
  State<StreamingResponseDemo> createState() => _StreamingResponseDemoState();
}

class _StreamingResponseDemoState extends State<StreamingResponseDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  int _chars = 0;
  static const text =
      'A streaming response can link directly to Motion\'s React guide while the rest of the answer continues to arrive.';

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 18),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        if (_chars >= text.length) return;
        setState(() => _chars++);
        if (_chars < text.length) _clock.forward(from: 0);
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled &&
        _chars < text.length &&
        !_clock.isAnimating) {
      _clock.forward();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complete = _chars >= text.length;
    return SizedBox(
      width: 420,
      child: BeuiStreamingResponse(
        status: complete
            ? BeuiStreamingStatus.complete
            : BeuiStreamingStatus.streaming,
        copyText: text,
        sources: complete
            ? const [
                BeuiCitationItem(
                  id: 'motion-react',
                  title: 'Motion for React',
                  domain: 'motion.dev',
                ),
              ]
            : const [],
        child: Text(text.substring(0, _chars)),
      ),
    );
  }
}

class ToolResultDemo extends StatefulWidget {
  const ToolResultDemo({super.key});

  @override
  State<ToolResultDemo> createState() => _ToolResultDemoState();
}

class _ToolResultDemoState extends State<ToolResultDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  int visible = 0;
  static const lines = [
    '\$ bun test tests/a11y.test.tsx',
    'bun test v1.3.14',
    '✓ StreamingResponse complete',
    '✓ ToolApproval pending',
    '✓ Citations expanded',
    '49 pass · 0 fail',
  ];

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        if (visible >= lines.length) return;
        setState(() => visible++);
        if (visible < lines.length) _clock.forward(from: 0);
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled &&
        visible < lines.length &&
        !_clock.isAnimating) {
      _clock.forward();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = visible < lines.length;
    return SizedBox(
      width: 480,
      child: BeuiToolResult(
        tool: 'terminal.run',
        title: running ? 'Running accessibility tests' : 'Tests passed',
        kind: BeuiToolResultKind.terminal,
        status: running
            ? BeuiToolResultStatus.running
            : BeuiToolResultStatus.success,
        meta: running ? null : '2.9s',
        output: lines.take(visible).join('\n'),
        collapseOnComplete: false,
        maxHeight: 150,
      ),
    );
  }
}

class AgentActivityDemo extends StatefulWidget {
  const AgentActivityDemo({super.key});

  @override
  State<AgentActivityDemo> createState() => _AgentActivityDemoState();
}

class _AgentActivityDemoState extends State<AgentActivityDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  int frame = 0;

  static const frames = <List<BeuiAgentActivityItem>>[
    [
      BeuiAgentActivityItem.step(
        id: 'brief',
        label: 'Reading the launch brief',
        status: BeuiAgentStepStatus.active,
      ),
    ],
    [
      BeuiAgentActivityItem.step(
        id: 'brief',
        label: 'Reading the launch brief',
        status: BeuiAgentStepStatus.complete,
      ),
      BeuiAgentActivityItem.search(
        id: 'search',
        query: 'independent coffee roasters in Portland',
      ),
    ],
    [
      BeuiAgentActivityItem.step(
        id: 'brief',
        label: 'Reading the launch brief',
        status: BeuiAgentStepStatus.complete,
      ),
      BeuiAgentActivityItem.search(
        id: 'search',
        query: 'independent coffee roasters in Portland',
        results: [
          BeuiAgentSearchResult(
            id: 'heart',
            title: 'Heart Coffee',
            domain: 'heartroasters.com',
          ),
          BeuiAgentSearchResult(
            id: 'coava',
            title: 'Coava Coffee',
            domain: 'coavacoffee.com',
          ),
        ],
      ),
    ],
    [
      BeuiAgentActivityItem.step(
        id: 'brief',
        label: 'Reading the launch brief',
        status: BeuiAgentStepStatus.complete,
      ),
      BeuiAgentActivityItem.search(
        id: 'search',
        query: 'independent coffee roasters in Portland',
        results: [
          BeuiAgentSearchResult(
            id: 'heart',
            title: 'Heart Coffee',
            domain: 'heartroasters.com',
          ),
        ],
      ),
      BeuiAgentActivityItem.tool(
        id: 'read',
        action: 'read',
        target: 'campaign-notes.md',
      ),
      BeuiAgentActivityItem.tool(
        id: 'edit',
        action: 'edit',
        target: 'launch-plan.ts',
        additions: 42,
        deletions: 8,
      ),
    ],
  ];

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        if (frame >= frames.length - 1) return;
        setState(() => frame++);
        if (frame < frames.length - 1) _clock.forward(from: 0);
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled &&
        frame < frames.length - 1 &&
        !_clock.isAnimating) {
      _clock.forward();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complete = frame >= frames.length - 1;
    return SizedBox(
      width: 480,
      child: BeuiAgentActivity(
        items: frames[frame],
        status: complete
            ? BeuiAgentActivityStatus.complete
            : BeuiAgentActivityStatus.working,
        duration: frame * 2.4,
        collapseOnComplete: false,
        activeLabel: 'Working',
      ),
    );
  }
}

const _codeLines = [
  'import { generateText } from "ai";',
  '',
  'export async function summarize(input: string) {',
  '  const { text } = await generateText({',
  '    model: "openai/gpt-5",',
  '    prompt: `Summarize this clearly: \${input}`,',
  '  });',
  '',
  '  return {',
  '    text,',
  '    generatedAt: new Date().toISOString(),',
  '  };',
  '}',
];

class CodeBlockDemo extends StatefulWidget {
  const CodeBlockDemo({super.key});

  @override
  State<CodeBlockDemo> createState() => _CodeBlockDemoState();
}

class _CodeBlockDemoState extends State<CodeBlockDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  int _visible = 1;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed &&
            _visible < _codeLines.length &&
            mounted) {
          setState(() => _visible++);
          if (_visible < _codeLines.length) _clock.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complete = _visible >= _codeLines.length;
    return SizedBox(
      width: 440,
      child: BeuiCodeBlock(
        filename: 'summarize.ts',
        language: 'typescript',
        code: _codeLines.take(_visible).join('\n'),
        status: complete
            ? BeuiCodeBlockStatus.complete
            : BeuiCodeBlockStatus.streaming,
        highlightLines: const [4, 5, 6, 7],
        maxHeight: 224,
      ),
    );
  }
}

const _diffLines = [
  BeuiFileDiffLine(id: '1', oldLine: 18, newLine: 18, content: 'export async function runTask() {'),
  BeuiFileDiffLine(
    id: '2',
    type: BeuiFileDiffLineType.removed,
    oldLine: 19,
    content: '  return execute(task);',
  ),
  BeuiFileDiffLine(
    id: '3',
    type: BeuiFileDiffLineType.added,
    newLine: 19,
    content: '  const result = await execute(task);',
  ),
  BeuiFileDiffLine(
    id: '4',
    type: BeuiFileDiffLineType.added,
    newLine: 20,
    content: '  return normalize(result);',
  ),
  BeuiFileDiffLine(id: '5', oldLine: 20, newLine: 21, content: '}'),
];

class FileDiffDemo extends StatefulWidget {
  const FileDiffDemo({super.key});

  @override
  State<FileDiffDemo> createState() => _FileDiffDemoState();
}

class _FileDiffDemoState extends State<FileDiffDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  int _visible = 1;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed &&
            _visible < _diffLines.length &&
            mounted) {
          setState(() => _visible++);
          if (_visible < _diffLines.length) _clock.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complete = _visible >= _diffLines.length;
    return SizedBox(
      width: 440,
      child: BeuiFileDiff(
        file: 'src/runner.ts',
        lines: _diffLines.take(_visible).toList(),
        status: complete
            ? BeuiFileDiffStatus.complete
            : BeuiFileDiffStatus.streaming,
        copyText: _diffLines.map((l) => l.content).join('\n'),
        maxHeight: 150,
      ),
    );
  }
}

class ImageGenerationDemo extends StatefulWidget {
  const ImageGenerationDemo({super.key});

  @override
  State<ImageGenerationDemo> createState() => _ImageGenerationDemoState();
}

class _ImageGenerationDemoState extends State<ImageGenerationDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  BeuiImageGenerationStatus _status = BeuiImageGenerationStatus.queued;

  static const _steps = [
    BeuiImageGenerationStatus.queued,
    BeuiImageGenerationStatus.generating,
    BeuiImageGenerationStatus.refining,
    BeuiImageGenerationStatus.complete,
  ];

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          final i = _steps.indexOf(_status);
          if (i < _steps.length - 1) {
            setState(() => _status = _steps[i + 1]);
            _clock.forward(from: 0);
          }
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: BeuiImageGeneration(
        status: _status,
        prompt: 'A quiet valley at dusk',
        resolution: '800×600',
        child: const CustomPaint(
          painter: _DemoArtPainter(),
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}

class _DemoArtPainter extends CustomPainter {
  const _DemoArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF191B33), Color(0xFF60538D), Color(0xFFE59B7B)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);
    canvas.drawCircle(
      Offset(size.width * 0.71, size.height * 0.35),
      size.width * 0.08,
      Paint()..color = const Color(0xFFFFE5AD),
    );
    final ground = Path()
      ..moveTo(0, size.height * 0.66)
      ..lineTo(size.width * 0.15, size.height * 0.52)
      ..lineTo(size.width * 0.27, size.height * 0.61)
      ..lineTo(size.width * 0.43, size.height * 0.37)
      ..lineTo(size.width * 0.58, size.height * 0.58)
      ..lineTo(size.width * 0.68, size.height * 0.47)
      ..lineTo(size.width * 0.79, size.height * 0.62)
      ..lineTo(size.width, size.height * 0.52)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(ground, Paint()..color = const Color(0xFF283D43));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
