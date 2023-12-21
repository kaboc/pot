import 'package:flutter/widgets.dart';

import 'package:devtools_app_shared/ui.dart';

class AutoScroller extends StatefulWidget {
  const AutoScroller({required this.itemCount, required this.child});

  final int itemCount;
  final Widget child;

  @override
  State<AutoScroller> createState() => _AutoScrollerState();
}

class _AutoScrollerState extends State<AutoScroller> {
  ScrollController? get _controller => PrimaryScrollController.maybeOf(context);

  @override
  void initState() {
    super.initState();
    _scrollToBottom(isInit: true);
  }

  @override
  void didUpdateWidget(AutoScroller oldWidget) {
    super.didUpdateWidget(oldWidget);

    final controller = _controller;
    final isAtBottom = controller?.atScrollBottom ?? false;
    final isIncreased = widget.itemCount > oldWidget.itemCount;

    if (isAtBottom && isIncreased) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom({bool isInit = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _controller;

      if (isInit) {
        controller?.jumpTo(controller.position.maxScrollExtent);
      } else {
        controller?.autoScrollToBottom();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
