// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

import 'package:pottery/pottery.dart';

class TestPottery extends StatefulWidget {
  const TestPottery({
    this.potteryKey,
    required this.pots,
    this.builder,
  });

  final GlobalKey<Object?>? potteryKey;
  final PotReplacements pots;
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
              pots: widget.pots,
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
    required this.pots,
    this.disposer,
    this.builder,
  });

  final GlobalKey<Object?>? localPotteryKey;
  final PotReplacements pots;
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
              pots: widget.pots,
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
