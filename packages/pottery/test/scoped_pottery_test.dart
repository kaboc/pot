import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pottery/pottery.dart';

import 'widgets.dart';

ReplaceablePot<Foo>? fooPot;
ReplaceablePot<Bar>? barPot;

class Foo {
  const Foo([this.value]);
  final int? value;
}

class Bar {
  const Bar();
}

void main() {
  setUp(() {
    fooPot = null;
    barPot = null;
  });

  testWidgets(
    'Pots provided by nearest ScopedPottery are obtained with `of()`',
    (tester) async {
      fooPot = Pot.pending<Foo>();
      barPot = Pot.pending<Bar>();

      expect(fooPot?.create, throwsA(isA<PotNotReadyException>()));
      expect(barPot?.create, throwsA(isA<PotNotReadyException>()));

      var called = false;
      await tester.pumpWidget(
        TestScopedPottery(
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
        TestScopedPottery(
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

  testWidgets(
    'disposer of pot is not called when ScopedPottery is removed, '
    'while disposer of ScopedPottery is called with correct map',
    (tester) async {
      var globallyDisposed = false;
      fooPot = Pot.replaceable(
        () => const Foo(10),
        disposer: (_) => globallyDisposed = true,
      );
      barPot = Pot.pending<Bar>();

      fooPot?.create();

      ScopedPots? map;
      await tester.pumpWidget(
        TestScopedPottery(
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

  testWidgets('Multiple ScopedPotteries as siblings', (tester) async {
    fooPot = Pot.pending<Foo>();

    Foo? foo1;
    Foo? foo2;
    Foo? foo3;
    Foo? foo4;
    await tester.pumpWidget(
      Column(
        children: [
          TestScopedPottery(
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
          TestScopedPottery(
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

  testWidgets('Nested ScopedPotteries', (tester) async {
    fooPot = Pot.pending<Foo>();

    Foo? foo1;
    Foo? foo2;
    Foo? foo3;
    Foo? foo4;
    await tester.pumpWidget(
      TestScopedPottery(
        pots: {
          fooPot!: () => const Foo(10),
        },
        builder: (context1) {
          foo1 = fooPot?.of(context1);
          return Descendant(
            builder: (context2) {
              foo2 = fooPot?.of(context2);
              return TestScopedPottery(
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
              );
            },
          );
        },
      ),
    );

    expect(foo1?.value, 10);
    expect(foo2?.value, 10);
    expect(foo3?.value, 20);
    expect(foo4?.value, 20);
  });

  testWidgets('debugFillProperties()', (tester) async {
    fooPot = Pot.pending<Foo>();
    barPot = Pot.pending<Bar>(disposer: (_) => fooPot?.call());

    const foo = Foo(10);
    const bar = Bar();

    final key = GlobalKey();
    await tester.pumpWidget(
      TestScopedPottery(
        scopedPotteryKey: key,
        pots: {
          fooPot!: () => foo,
          barPot!: () => bar,
        },
      ),
    );

    final builder = DiagnosticPropertiesBuilder();
    key.currentState?.debugFillProperties(builder);
    final props = {
      for (final prop in builder.properties)
        if (prop.name != null) prop.name: prop.value,
    };

    expect(props['scopedPots'], equals({fooPot: foo, barPot: bar}));
  });
}
