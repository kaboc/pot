import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pottery/pottery.dart';

import 'widgets.dart';

class Foo {
  const Foo([this.value]);
  final int? value;
}

class Bar {
  const Bar();
}

void main() {
  ReplaceablePot<Foo>? fooPot;
  ReplaceablePot<Bar>? barPot;
  ReplaceablePot<Object?>? nullablePot;

  tearDown(() {
    Pot.resetAll(keepScopes: false);
    fooPot = barPot = nullablePot = null;
  });

  testWidgets(
    'Using Pottery makes pots available and removing it makes pots '
    'unavailable again',
    (tester) async {
      var fooDisposed = false;
      var barDisposed = false;
      fooPot = Pot.pending(disposer: (_) => fooDisposed = true);
      barPot = Pot.pending(disposer: (_) => barDisposed = true);

      expect(fooPot?.create, throwsA(isA<PotNotReadyException>()));
      expect(barPot?.create, throwsA(isA<PotNotReadyException>()));

      await tester.pumpWidget(
        TestPottery(
          pots: {
            fooPot!: Foo.new,
            barPot!: Bar.new,
          },
        ),
      );

      expect(fooPot?.call(), isA<Foo>());
      expect(barPot?.call(), isA<Bar>());
      expect(fooPot?.hasObject, isTrue);
      expect(barPot?.hasObject, isTrue);

      final buttonFinder = find.byType(RemovePotteryButton);
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(fooDisposed, isTrue);
      expect(barDisposed, isTrue);
      expect(fooPot?.create, throwsA(isA<PotNotReadyException>()));
      expect(barPot?.create, throwsA(isA<PotNotReadyException>()));
      expect(fooPot?.hasObject, isFalse);
      expect(barPot?.hasObject, isFalse);
    },
  );

  testWidgets(
    'Pots are immediately available in the builder function',
    (tester) async {
      fooPot = Pot.replaceable(() => const Foo(10));
      expect(fooPot?.call().value, 10);

      Foo? foo;
      await tester.pumpWidget(
        TestPottery(
          pots: {
            fooPot!: () => const Foo(20),
          },
          builder: (_) {
            foo ??= fooPot?.call();
            return const SizedBox.shrink();
          },
        ),
      );
      expect(foo?.value, 20);
    },
  );

  testWidgets('Factory returning null causes no issue', (tester) async {
    nullablePot = Pot.pending();
    expect(nullablePot?.create, throwsA(isA<PotNotReadyException>()));

    await tester.pumpWidget(
      TestPottery(
        pots: {
          nullablePot!: () => null,
        },
      ),
    );
    expect(nullablePot?.call(), isNull);
  });

  testWidgets(
    'PotNotReadyException is thrown when Pottery calls reset() '
    'of a pot that depends on a pot located later in the pots map',
    (tester) async {
      fooPot = Pot.pending(disposer: (_) => barPot?.call());
      barPot = Pot.pending();

      addTearDown(() {
        // A factory must be set so that dispose does not
        // throw when clean-up runs at the end of the test.
        barPot?.replace(Bar.new);
      });

      await tester.pumpWidget(
        TestPottery(
          pots: {
            fooPot!: Foo.new,
            barPot!: Bar.new,
          },
        ),
      );

      expect(fooPot?.call(), isA<Foo>());
      expect(barPot?.call(), isA<Bar>());

      final buttonFinder = find.byType(RemovePotteryButton);
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(tester.takeException(), isA<PotNotReadyException>());
    },
  );

  testWidgets(
    'PotNotReadyException is thrown when Pottery calls reset() '
    'of a pot that depends on a pot located earlier in the map',
    (tester) async {
      fooPot = Pot.pending();
      barPot = Pot.pending(disposer: (_) => fooPot?.call());

      await tester.pumpWidget(
        TestPottery(
          pots: {
            fooPot!: Foo.new,
            barPot!: Bar.new,
          },
        ),
      );

      fooPot?.create();
      barPot?.create();

      expect(fooPot?.call(), isA<Foo>());
      expect(barPot?.call(), isA<Bar>());

      final buttonFinder = find.byType(RemovePotteryButton);
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(tester.takeException(), isNot(throwsA(anything)));
    },
  );

  testWidgets('debugFillProperties()', (tester) async {
    fooPot = Pot.pending();
    barPot = Pot.pending(disposer: (_) => fooPot?.call());

    // ignore: prefer_function_declarations_over_variables
    final fooFactory = () => const Foo(10);
    // ignore: prefer_function_declarations_over_variables
    final barFactory = () => const Bar();

    final key = GlobalKey();
    await tester.pumpWidget(
      TestPottery(
        potteryKey: key,
        pots: {
          fooPot!: fooFactory,
          barPot!: barFactory,
        },
      ),
    );

    final builder = DiagnosticPropertiesBuilder();
    key.currentState?.debugFillProperties(builder);

    expect(
      builder.properties.firstWhere((v) => v.name == 'pots').value,
      {fooPot: fooFactory, barPot: barFactory},
    );
  });
}
