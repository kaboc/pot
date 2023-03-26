import 'package:flutter/material.dart';

class CounterNotifier extends ValueNotifier<int> {
  CounterNotifier() : super(0) {
    _showMessage('CounterNotifier was created.', Colors.green);
  }

  @override
  void dispose() {
    _showMessage('CounterNotifier was discarded.');
    super.dispose();
  }

  void increment() {
    value++;
  }
}

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void _showMessage(String message, [Color? color]) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    scaffoldMessengerKey.currentState!
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: color,
        ),
      );
  });
}
