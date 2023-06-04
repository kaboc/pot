import 'package:flutter/material.dart';
import 'package:grab/grab.dart';
import 'package:pottery/pottery.dart';

import 'package:pottery_example/counter_notifier.dart';
import 'package:pottery_example/widgets.dart';

final counterNotifierPot = Pot.pending<CounterNotifier>(
  disposer: (notifier) => notifier.dispose(),
);

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            CounterPage.route(),
          ),
          child: const Text('To counter page'),
        ),
      ),
    );
  }
}

class CounterPage extends StatelessWidget with Grab {
  const CounterPage._();

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => Pottery(
        pots: {
          counterNotifierPot: CounterNotifier.new,
        },
        builder: (_) => const CounterPage._(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = counterNotifierPot();
    final count = notifier.grab(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: const TextStyle(fontSize: 32.0),
            ),
            const SizedBox(width: 16.0),
            IncrementButton(onPressed: notifier.increment),
          ],
        ),
      ),
    );
  }
}
