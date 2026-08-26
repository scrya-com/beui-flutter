import 'package:flutter/widgets.dart';

import 'demos/agents/agent_demos.dart';
import 'demos/agents/workspace_demos.dart';
import 'demos/blocks/file_upload_demos.dart';
import 'demos/motion/button_demos.dart';
import 'demos/motion/display_demos.dart';
import 'demos/motion/form_demos.dart';
import 'demos/motion/layout_demos.dart';
import 'demos/motion/overlay_demos.dart';
import 'demos/motion/picker_demos.dart';
import 'demos/motion/slider_demos.dart';
import 'demos/motion/text_demos.dart';
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
  'motion/tooltip': () => const TooltipDemo(),
  'motion/marquee': () => const MarqueeDemo(),
  'motion/animated-badge': () => const AnimatedBadgeDemo(),
  'motion/loader': () => const LoaderDemo(),
  'motion/tilt-card': () => const TiltCardDemo(),
  'motion/expandable-control': () => const ExpandableControlDemo(),
  'motion/shared-layout-bg': () => const SharedLayoutBgDemo(),
  'motion/bouncy-accordion': () => const BouncyAccordionDemo(),
  'motion/dock': () => const DockDemo(),
  'motion/text-animation': () => const TextRevealDemo(),
  'motion/text-reveal': () => const TextRevealDemo(),
  'motion/text-scramble': () => const TextScrambleDemo(),
  'motion/chromatic-text-reveal': () => const ChromaticTextRevealDemo(),
  'motion/text-cascade': () => const TextCascadeDemo(),
  'motion/text-shimmer': () => const TextShimmerDemo(),
  'motion/number': () => const NumberTickerDemo(),
  'motion/number-ticker': () => const NumberTickerDemo(),
  'motion/animated-number': () => const AnimatedNumberDemo(),
  'motion/action-swap': () => const ActionSwapBlurDemo(),
  'motion/action-swap-blur': () => const ActionSwapBlurDemo(),
  'motion/action-swap-roll': () => const ActionSwapRollDemo(),
  'motion/action-swap-cascade': () => const ActionSwapCascadeDemo(),
  'motion/theme-toggle': () => const ThemeToggleDemo(),
  'motion/scroll-reveal': () => const ScrollRevealDemo(),
  'motion/scroll-progress': () => const ScrollProgressDemo(),
  'motion/bottom-sheet': () => const BottomSheetDemo(),
  'motion/drawer': () => const DrawerDemo(),
  'motion/range-slider': () => const RangeSliderDemo(),
  'motion/range-slider-fluid': () => const FluidSliderDemo(),
  'motion/range-slider-wave': () => const WaveSliderDemo(),
  'motion/range-slider-bubble': () => const BubbleSliderDemo(),
  'motion/range-slider-ruler': () => const RulerSliderDemo(),
  'motion/expanding-arrow-button': () => const ExpandingArrowButtonDemo(),
  'motion/hold-action-button': () => const HoldActionButtonDemo(),
  'motion/slide-action-button': () => const SlideActionButtonDemo(),
  'motion/select': () => const SelectDemo(),
  'motion/combobox': () => const ComboboxDemo(),
  'motion/wheel-picker': () => const WheelPickerDemo(),
  'motion/pull-to-refresh': () => const PullToRefreshDemo(),
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
  'agents/tool-approval': () => const ToolApprovalDemo(),
  'agents/ai-sidebar': () => const AISidebarDemo(),
  'agents/chat-app': () => const ChatAppDemo(),
  'blocks/file-upload': () => const FileUploadDemo(),
  'blocks/attachment-upload': () => const AttachmentUploadDemo(),
};
