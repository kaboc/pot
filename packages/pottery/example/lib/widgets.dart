import 'package:flutter/material.dart';

class IncrementButton extends StatelessWidget {
  const IncrementButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 32.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        onPressed: onPressed,
        child: const Icon(Icons.add),
      ),
    );
  }
}
