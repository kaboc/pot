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
    Pot.uninitialize();
    fooPot = barPot = nullablePot = null;
  });

  testWidgets(
    'Calling of() on a map returns the associated object provided by nearest '
    'LocalPottery ancestor that contains the pot in its pots map.',
    (tester) async {
      fooPot = Pot.pending();
      barPot = Pot.pending();

      expect(fooPot?.create, throwsA(isA<PotNotReadyException>()));
      expect(barPot?.create, throwsA(isA<PotNotReadyException>()));

      var called = false;
      await tester.pumpWidget(
        TestLocalPottery(
          pots: {
            fooPot!: Foo.new,
          },
          builder: (context) {
            return Descendant(
              builder: (context) {
                expect(fooPot?.create, throwsA(isA<PotNotReadyException>()));
                expect(fooPot?.of(context), isA<Foo>());
                expect(
                  () => barPot?.of(context),
                  throwsA(isA<PotNotReadyException>()),
                );
                called = true;
                return const SizedBox.shrink();
              },
            );
          },
        ),
      );
      expect(called, isTrue);
    },
  );

  testWidgets(
    'Pots are immediately available in the builder function',
    (tester) async {
      fooPot = Pot.replaceable(() => const Foo(10));
      expect(fooPot?.call().value, 10);

      Foo? foo1;
      Foo? foo2;
      await tester.pumpWidget(
        TestLocalPottery(
          pots: {
            fooPot!: () => const Foo(20),
          },
          builder: (context) {
            foo1 ??= fooPot?.call();
            foo2 ??= fooPot?.of(context);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(foo1?.value, 10);
      expect(foo2?.value, 20);
    },
  );

  testWidgets('Factory returning null causes no issue', (tester) async {
    nullablePot = Pot.pending();
    expect(nullablePot?.create, throwsA(isA<PotNotReadyException>()));

    var isNullObtained = false;
    await tester.pumpWidget(
      TestLocalPottery(
        pots: {
          nullablePot!: () => null,
        },
        builder: (context) {
          isNullObtained = nullablePot?.of(context) == null;
          return const SizedBox.shrink();
        },
      ),
    );
    expect(isNullObtained, isTrue);
  });

  testWidgets(
    'Disposer of pot is not called when LocalPottery is removed, '
    'while disposer of LocalPottery is called with map holding objects',
    (tester) async {
      var globallyDisposed = false;
      fooPot = Pot.replaceable(
        () => const Foo(10),
        disposer: (_) => globallyDisposed = true,
      );
      barPot = Pot.pending();

      fooPot?.create();

      LocalPotteryObjects? map;
      await tester.pumpWidget(
        TestLocalPottery(
          pots: {
            fooPot!: () => const Foo(20),
            barPot!: () => const Bar(),
          },
          disposer: (pots) {
            map = pots;
          },
        ),
      );
      expect(map, isNull);

      final buttonFinder = find.byType(RemovePotteryButton);
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(map, {fooPot: const Foo(20), barPot: const Bar()});

      // Global pot is still available.
      expect(globallyDisposed, isFalse);
      expect(fooPot?.hasObject, isTrue);
    },
  );

  testWidgets('Multiple LocalPotteries as siblings', (tester) async {
    fooPot = Pot.pending();

    Foo? foo1;
    Foo? foo2;
    Foo? foo3;
    Foo? foo4;
    await tester.pumpWidget(
      Column(
        children: [
          TestLocalPottery(
            pots: {
              fooPot!: () => const Foo(10),
            },
            builder: (context1) {
              foo1 = fooPot?.of(context1);
              return Descendant(
                builder: (context2) {
                  foo2 = fooPot?.of(context2);
                  return const SizedBox.shrink();
                },
              );
            },
          ),
          TestLocalPottery(
            pots: {
              fooPot!: () => const Foo(20),
            },
            builder: (context3) {
              foo3 = fooPot?.of(context3);
              return Descendant(
                builder: (context4) {
                  foo4 = fooPot?.of(context4);
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ],
      ),
    );

    expect(foo1?.value, 10);
    expect(foo2?.value, 10);
    expect(foo3?.value, 20);
    expect(foo4?.value, 20);
  });

  testWidgets('Nested LocalPotteries', (tester) async {
    fooPot = Pot.pending();
    barPot = Pot.pending();

    Foo? foo1;
    Foo? foo2;
    Foo? foo3;

    await tester.pumpWidget(
      TestLocalPottery(
        pots: {
          fooPot!: () => const Foo(10),
        },
        builder: (context1) {
          foo1 = fooPot?.of(context1);
          return TestLocalPottery(
            pots: {
              fooPot!: () => const Foo(20),
            },
            builder: (context2) {
              foo2 = fooPot?.of(context2);
              return TestLocalPottery(
                pots: {
                  barPot!: () => const Bar(),
                },
                builder: (context3) {
                  foo3 = fooPot?.of(context3);
                  return const SizedBox.shrink();
                },
              );
            },
          );
        },
      ),
    );

    expect(foo1?.value, 10);
    expect(foo2?.value, 20);
    expect(foo3?.value, 20);
  });

  testWidgets('debugFillProperties()', (tester) async {
    fooPot = Pot.pending();
    barPot = Pot.pending(disposer: (_) => fooPot?.call());

    const foo = Foo(10);
    const bar = Bar();

    final key = GlobalKey();
    await tester.pumpWidget(
      TestLocalPottery(
        localPotteryKey: key,
        pots: {
          fooPot!: () => foo,
          barPot!: () => bar,
        },
      ),
    );

    final builder = DiagnosticPropertiesBuilder();
    key.currentState?.debugFillProperties(builder);

    expect(
      builder.properties.firstWhere((v) => v.name == 'objects').value,
      equals({fooPot: foo, barPot: bar}),
    );
  });
}
