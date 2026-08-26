import 'package:flutter/widgets.dart';

import 'demos/agents/agent_demos.dart';
import 'demos/motion/button_demos.dart';
import 'demos/motion/form_demos.dart';
import 'demos/motion/tooltip_demos.dart';

typedef DemoBuilder = Widget Function();

final demoBuilders = <String, DemoBuilder>{
  'motion/button': () => const ButtonBaseDemo(),
  'motion/button-base': () => const ButtonBaseDemo(),
  'motion/button-stateful': () => const ButtonStatefulDemo(),
  'motion/button-magnetic': () => const ButtonMagneticDemo(),
  'motion/button-metallic': () => const ButtonMetallicDemo(),
  'motion/switch': () => const SwitchDemo(),
  'motion/checkbox': () => const CheckboxDemo(),
  'motion/radio': () => const RadioDemo(),
  'motion/input': () => const InputDemo(),
  'motion/tabs': () => const TabsDemo(),
  'motion/morphic-tooltip': () => const MorphicTooltipDemo(),
  'agents/thinking-shimmer': () => const ThinkingShimmerDemo(),
  'agents/agent-progress': () => const AgentProgressDemo(),
  'agents/reasoning-text': () => const ReasoningTextDemo(),
  'agents/message-bubble': () => const MessageBubbleDemo(),
  'agents/message-bubble-avatars': () => const MessageBubbleAvatarsDemo(),
  'agents/message-bubble-collapsible': () => const MessageBubbleCollapsibleDemo(),
  'agents/prompt-input': () => const PromptInputDemo(),
  'agents/todo-list': () => const TodoListDemo(),
  'agents/message': () => const MessageDemo(),
  'agents/message-scroller': () => const MessageScrollerDemo(),
  'agents/citations': () => const CitationsDemo(),
  'agents/streaming-response': () => const StreamingResponseDemo(),
  'agents/tool-result-terminal': () => const ToolResultDemo(),
  'agents/tool-result': () => const ToolResultDemo(),
  'agents/agent-activity-mixed': () => const AgentActivityDemo(),
  'agents/agent-activity': () => const AgentActivityDemo(),
  'agents/code-block': () => const CodeBlockDemo(),
  'agents/file-diff': () => const FileDiffDemo(),
  'agents/image-generation': () => const ImageGenerationDemo(),
};
