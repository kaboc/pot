import 'package:flutter/material.dart';

class CounterNotifier extends ValueNotifier<int> {
  CounterNotifier({this.showMessage = false}) : super(0) {
    if (showMessage) {
      _showMessage('CounterNotifier was created.', Colors.green);
    }
  }

  final bool showMessage;

  @override
  void dispose() {
    if (showMessage) {
      _showMessage('CounterNotifier was disposed.');
    }
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

class HyperCounterNotifier extends CounterNotifier {
  @override
  void increment() => value += 10;
}
