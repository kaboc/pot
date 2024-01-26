import 'package:flutter/material.dart';
import 'package:grab/grab.dart';
import 'package:pottery/pottery.dart';

import 'package:pottery_example/counter_notifier.dart';
import 'package:pottery_example/widgets.dart';

final counterNotifierPot = Pot.pending<CounterNotifier>(
  disposer: (notifier) => notifier.dispose(),
);

void main() {
  runApp(
    const Grab(child: App()),
  );
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
            MaterialPageRoute<void>(
              builder: (_) => const CounterPage(),
            ),
          ),
          child: const Text('To counter page'),
        ),
      ),
    );
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage();

  @override
  Widget build(BuildContext context) {
    return Pottery(
      pots: {
        // counterNotifierPot should be prepared here because it is not used
        // before this page,
        // The notifier is disposed automatically when this page is disposed.
        counterNotifierPot: () => CounterNotifier(showMessage: true),
      },
      builder: (context) {
        final notifier = counterNotifierPot();
        final count = counterNotifierPot().grab(context);

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
      },
    );
  }
}
