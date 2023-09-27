// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

import 'package:pottery/pottery.dart';

class TestPottery extends StatefulWidget {
  const TestPottery({required this.pots, this.builder});

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
