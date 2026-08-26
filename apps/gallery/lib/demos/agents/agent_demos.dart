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
    return const BeuiAgentProgress(label: 'Churning', initialSeconds: 151.6);
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

class MessageScrollerDemo extends StatelessWidget {
  const MessageScrollerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 420,
      child: BeuiMessageScroller(
        height: 320,
        children: [
          BeuiMessageBubble(
            align: BeuiMessageAlign.end,
            variant: BeuiMessageBubbleVariant.solid,
            child: Text('What should the first release include?'),
          ),
          BeuiMessageBubble(
            align: BeuiMessageAlign.start,
            variant: BeuiMessageBubbleVariant.soft,
            child: Text('Start with the smallest workflow that still feels complete.'),
          ),
          BeuiMessageBubble(
            align: BeuiMessageAlign.end,
            variant: BeuiMessageBubbleVariant.solid,
            child: Text('Include streaming and recovery states too.'),
          ),
          BeuiMessageBubble(
            align: BeuiMessageAlign.start,
            variant: BeuiMessageBubbleVariant.soft,
            child: Text('Yes. Those states make the first version feel dependable.'),
          ),
        ],
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
