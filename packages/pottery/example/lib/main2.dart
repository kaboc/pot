// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:grab/grab.dart';
import 'package:pottery/pottery.dart';

import 'package:pottery_example/counter_notifier.dart';

final indexPot = Pot.pending<int>();
final counterPot = Pot.pending<CounterNotifier>(
  disposer: (notifier) => notifier.dispose(),
);

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App();

  @override
  Widget build(BuildContext context) {
    return Pottery(
      pots: {
        counterPot: CounterNotifier.new,
      },
      builder: (context) {
        return MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  for (var i = 0; i < 50; i++)
                    LocalPottery(
                      pots: {
                        indexPot: () => i,
                        // A different notifier is provided to the subtree
                        // when the index is an odd number.
                        if (i.isOdd) counterPot: HyperCounterNotifier.new,
                      },
                      disposer: (pots) {
                        // It is your responsibility to dispose of the
                        // objects created by LocalPottery.
                        (pots[counterPot] as CounterNotifier?)?.dispose();
                      },
                      builder: (context) {
                        // The object created by the factory specified
                        // above is immediately accessible here using the
                        // given BuildContext.
                        // (But this callback is not called after the first
                        // build because this example has no logic to trigger
                        // rebuilds of widgets above the _Item widget.)
                        final index = indexPot.of(context);
                        final count = counterPot.of(context);
                        print('$index: $count');

                        return const _Item();
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Item extends StatelessWidget with Grab {
  // This widget is const with no parameter.
  // It is possible because of LocalPottery and `of()`.
  // The index and other values are obtained from the LocalPottery above.
  const _Item();

  @override
  Widget build(BuildContext context) {
    final index = indexPot.of(context);
    final notifier = counterPot.of(context);
    final value = notifier.grab(context);

    return ListTile(
      title: Text('Index $index'),
      subtitle: Text(
        '$value',
        style: const TextStyle(fontSize: 24.0),
        textAlign: TextAlign.center,
      ),
      trailing: ElevatedButton(
        onPressed: notifier.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
