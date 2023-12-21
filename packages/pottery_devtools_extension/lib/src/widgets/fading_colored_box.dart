import 'package:flutter/widgets.dart';

typedef FadeStarter = void Function(VoidCallback starter);

class FadingColoredBox extends StatefulWidget {
  const FadingColoredBox({
    required this.color,
    required this.enabled,
    required this.onCreated,
    required this.child,
  });

  final Color color;
  final bool enabled;
  final FadeStarter onCreated;
  final Widget child;

  @override
  State<FadingColoredBox> createState() => _FadingColoredBoxState();
}

class _FadingColoredBoxState extends State<FadingColoredBox> {
  double? _opacity;

  @override
  void initState() {
    super.initState();

    widget.onCreated(_startFadingColor);
    _startFadingColor();
  }

  @override
  void didUpdateWidget(covariant FadingColoredBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enabled && !oldWidget.enabled) {
      _startFadingColor();
    }
  }

  void show() {
    setState(() => _opacity = 0.8);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _opacity = 0.0);
    });
  }

  void _startFadingColor() {
    if (!widget.enabled) {
      return;
    }

    if (_opacity == null) {
      show();
    } else {
      _opacity = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => show());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_opacity != null)
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _opacity!,
              duration: const Duration(seconds: 10),
              curve: Curves.easeOutCirc,
              onEnd: () => setState(() => _opacity = null),
              child: ColoredBox(color: widget.color),
            ),
          ),
      ],
    );
  }
}
