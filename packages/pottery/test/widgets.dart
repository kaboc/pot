// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

import 'package:pottery/pottery.dart';

class TestWidget extends StatefulWidget {
  const TestWidget({required this.pots});

  final PotsMap pots;

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
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
              builder: (_) => const SizedBox.shrink(),
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
