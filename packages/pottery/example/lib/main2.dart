import 'package:flutter/material.dart';
import 'package:grab/grab.dart';
import 'package:pottery/pottery.dart';

import 'package:pottery_example/counter_notifier.dart';

final indexPot = Pot.pending<int>();
final counterPot = Pot.pending<CounterNotifier>(
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
                        // It is your responsibility to dispose the objects
                        // created by LocalPottery, whereas Pottery does
                        // automatically.
                        (pots[counterPot] as CounterNotifier?)?.dispose();
                      },
                      builder: (context) {
                        // The object created by the factory specified
                        // above is immediately accessible here using the
                        // given BuildContext.
                        final index = indexPot.of(context);
                        final notifier = counterPot.of(context);
                        final count = notifier.grab(context);

                        debugPrint('$index: $count');

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

class _Item extends StatelessWidget {
  // This widget is const with no parameter.
  // It is possible thanks to LocalPottery and `of()`.
  // The index and other values are obtained from the LocalPottery above.
  const _Item();

  @override
  Widget build(BuildContext context) {
    final index = indexPot.of(context);
    final notifier = counterPot.of(context);
    final count = notifier.grab(context);

    return ListTile(
      title: Text('Index $index'),
      subtitle: Text(
        '$count',
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
