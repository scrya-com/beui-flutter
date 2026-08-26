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

class _TodoListDemoState extends State<TodoListDemo> {
  int step = 0;
  int run = 0;

  static const tasks = [
    'Inspect the current data flow',
    'Update the response schema',
    'Add coverage for edge cases',
    'Run checks and prepare the result',
  ];
  static const ticks = 4;

  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled && !_running) {
      _running = true;
      _tick();
    }
  }

  void _tick() {
    if (step >= tasks.length * ticks) return;
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      if (!TickerMode.valuesOf(context).enabled) return;
      setState(() => step++);
      _tick();
    });
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
              onTap: () => setState(() {
                step = 0;
                run++;
                _tick();
              }),
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
