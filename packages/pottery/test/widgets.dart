// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

import 'package:pottery/pottery.dart';

class TestPottery extends StatefulWidget {
  const TestPottery({
    this.potteryKey,
    required this.overrides,
    this.builder,
  });

  final GlobalKey<Object?>? potteryKey;
  final List<PotReplacement<Object?>> overrides;
  final WidgetBuilder? builder;

  @override
  State<TestPottery> createState() => _TestPotteryState();
}

class _TestPotteryState extends State<TestPottery> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          if (!_pressed)
            Pottery(
              key: widget.potteryKey,
              overrides: widget.overrides,
              builder: widget.builder ?? (_) => const SizedBox.shrink(),
            ),
          RemovePotteryButton(
            onPressed: () => setState(() => _pressed = true),
          ),
        ],
      ),
    );
  }
}

class TestLocalPottery extends StatefulWidget {
  const TestLocalPottery({
    this.localPotteryKey,
    required this.overrides,
    this.disposer,
    this.builder,
  });

  final GlobalKey<Object?>? localPotteryKey;
  final List<PotOverride<Object?>> overrides;
  final WidgetBuilder? builder;
  final void Function(LocalPotteryObjects)? disposer;

  @override
  State<TestLocalPottery> createState() => _TestLocalPotteryState();
}

class _TestLocalPotteryState extends State<TestLocalPottery> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          if (!_pressed)
            LocalPottery(
              key: widget.localPotteryKey,
              overrides: widget.overrides,
              disposer: widget.disposer,
              builder: widget.builder ?? (_) => const SizedBox.shrink(),
            ),
          RemovePotteryButton(
            onPressed: () => setState(() => _pressed = true),
          ),
        ],
      ),
    );
  }
}

class RemovePotteryButton extends StatelessWidget {
  const RemovePotteryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('Remove Pottery'),
    );
  }
}
