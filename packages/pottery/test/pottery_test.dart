import 'package:flutter/foundation.dart' show DiagnosticPropertiesBuilder;
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
    Pot.uninitialize();
    fooPot = barPot = nullablePot = null;
  });

  test('The overrides parameter strictly requires PotReplacement type', () {
    Type getType<T>(List<T> v) => T;

    final List<num> list = <int>[10];
    final type = getType(list);

    // Ensures that the type obtained by getType() is the static type
    // argument (T) of the list, not the runtime type of its elements.
    expect(type, num);
    expect(type, isNot(int));

    final pottery = Pottery(
      overrides: [Pot.pending<int>().set(() => 10)],
      builder: (context) => const SizedBox(),
    );

    // Ensures that getType() captures the static type argument
    // defined in the property, rather than the actual runtime type
    // of the assigned instance.
    final overridesType = getType(pottery.overrides);

    expect(overridesType, PotReplacement<Object?>);
    expect(overridesType, isNot(PotOverride<Object?>));
  });

  testWidgets(
    'Using Pottery makes pots available and removing it makes pots '
    'unavailable again',
    (tester) async {
      var fooDisposed = false;
      var barDisposed = false;
      fooPot = Pot.pending(disposer: (_) => fooDisposed = true);
      barPot = Pot.pending(disposer: (_) => barDisposed = true);

      expect(fooPot!.create, throwsA(isA<PotNotReadyException>()));
      expect(barPot!.create, throwsA(isA<PotNotReadyException>()));

      await tester.pumpWidget(
        TestPottery(
          overrides: [
            fooPot!.set(Foo.new),
            barPot!.set(Bar.new),
          ],
        ),
      );

      expect(fooPot!(), isA<Foo>());
      expect(barPot!(), isA<Bar>());
      expect(fooPot!.hasObject, isTrue);
      expect(barPot!.hasObject, isTrue);

      final buttonFinder = find.byType(RemovePotteryButton);
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(fooDisposed, isTrue);
      expect(barDisposed, isTrue);
      expect(fooPot!.create, throwsA(isA<PotNotReadyException>()));
      expect(barPot!.create, throwsA(isA<PotNotReadyException>()));
      expect(fooPot!.hasObject, isFalse);
      expect(barPot!.hasObject, isFalse);
    },
  );

  testWidgets(
    'Pots are immediately available in the builder function',
    (tester) async {
      fooPot = Pot.replaceable(() => const Foo(10));
      expect(fooPot!().value, 10);

      Foo? foo;
      await tester.pumpWidget(
        TestPottery(
          overrides: [
            fooPot!.set(() => const Foo(20)),
          ],
          builder: (_) {
            foo ??= fooPot!();
            return const SizedBox.shrink();
          },
        ),
      );
      expect(foo!.value, 20);
    },
  );

  testWidgets('Factory returning null causes no issue', (tester) async {
    nullablePot = Pot.pending();
    expect(nullablePot!.create, throwsA(isA<PotNotReadyException>()));

    await tester.pumpWidget(
      TestPottery(
        overrides: [
          nullablePot!.set(() => null),
        ],
      ),
    );
    expect(nullablePot!(), isNull);
  });

  testWidgets(
    'PotNotReadyException is thrown when Pottery calls reset() '
    'of a pot that depends on a pot located later in overrides list',
    (tester) async {
      fooPot = Pot.pending(disposer: (_) => barPot!());
      barPot = Pot.pending();

      addTearDown(() {
        // A factory must be set so that dispose does not
        // throw when clean-up runs at the end of the test.
        barPot!.replace(Bar.new);
      });

      await tester.pumpWidget(
        TestPottery(
          overrides: [
            fooPot!.set(Foo.new),
            barPot!.set(Bar.new),
          ],
        ),
      );

      expect(fooPot!(), isA<Foo>());
      expect(barPot!(), isA<Bar>());

      final buttonFinder = find.byType(RemovePotteryButton);
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(tester.takeException(), isA<PotNotReadyException>());
    },
  );

  testWidgets(
    'PotNotReadyException is thrown when Pottery calls reset() of '
    'a pot that depends on a pot located earlier in overrides list',
    (tester) async {
      fooPot = Pot.pending();
      barPot = Pot.pending(disposer: (_) => fooPot!());

      await tester.pumpWidget(
        TestPottery(
          overrides: [
            fooPot!.set(Foo.new),
            barPot!.set(Bar.new),
          ],
        ),
      );

      fooPot!.create();
      barPot!.create();

      expect(fooPot!(), isA<Foo>());
      expect(barPot!(), isA<Bar>());

      final buttonFinder = find.byType(RemovePotteryButton);
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(tester.takeException(), isNot(throwsA(anything)));
    },
  );

  testWidgets('debugFillProperties()', (tester) async {
    fooPot = Pot.pending();
    barPot = Pot.pending(disposer: (_) => fooPot!());

    // ignore: prefer_function_declarations_over_variables
    final fooFactory = () => const Foo(10);
    // ignore: prefer_function_declarations_over_variables
    final barFactory = () => const Bar();

    final key = GlobalKey();
    await tester.pumpWidget(
      TestPottery(
        potteryKey: key,
        overrides: [
          fooPot!.set(fooFactory),
          barPot!.set(barFactory),
        ],
      ),
    );

    final builder = DiagnosticPropertiesBuilder();
    key.currentState!.debugFillProperties(builder);

    final prop = builder.properties.firstWhere((v) => v.name == 'overrides');
    final potReplacements = [
      if (prop.value case final List<PotReplacement<Object?>> repls)
        for (final repl in repls) (repl.pot, repl.factory),
    ];

    expect(
      potReplacements,
      [(fooPot, fooFactory), (barPot, barFactory)],
    );
  });
}
