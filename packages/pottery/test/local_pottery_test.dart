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

  test(
    'The overrides parameter accepts both PotReplacement and PotOverride',
    () {
      // Ensures that PotReplacement extends PotOverride.
      expect(
        PotReplacement(pot: Pot.replaceable(() => 10), factory: () => 0),
        isA<PotOverride<Object?>>(),
      );

      final localPottery = LocalPottery(
        overrides: [Pot.pending<int>().set(() => 10)],
        builder: (context) => const SizedBox(),
      );

      Type getType<T>(List<T> v) => T;
      final overridesType = getType(localPottery.overrides);

      // Verifies that the declared type of the parameter is PotOverride.
      expect(overridesType, PotOverride<Object?>);
    },
  );

  testWidgets(
    'call() cannot get object from LocalPottery ancestor',
    (tester) async {
      fooPot = Pot.pending();

      var called = false;
      await tester.pumpWidget(
        TestLocalPottery(
          overrides: [
            fooPot!.set(() => const Foo(1)),
          ],
          builder: (context) {
            expect(fooPot!.call, throwsA(isA<PotNotReadyException>()));
            called = true;
            return const SizedBox.shrink();
          },
        ),
      );
      expect(called, isTrue);
    },
  );

  testWidgets(
    'of() returns the associated object provided by nearest LocalPottery '
    'ancestor that contains the pot in overrides list.',
    (tester) async {
      fooPot = Pot.pending();
      expect(fooPot!.create, throwsA(isA<PotNotReadyException>()));

      var called = false;
      await tester.pumpWidget(
        TestLocalPottery(
          overrides: [
            fooPot!.set(() => const Foo(1)),
          ],
          builder: (context) {
            expect(fooPot!.of(context), const Foo(1));
            called = true;
            return const SizedBox.shrink();
          },
        ),
      );
      expect(called, isTrue);
    },
  );

  {
    final variants = ValueVariant({
      (pot: Pot(() => 1), object: 1, typeName: 'Pot'),
      (pot: Pot.replaceable(() => 1), object: 1, typeName: 'ReplaceablePot'),
    });

    testWidgets(
      'Calling of() on a pot throws if no LocalPottery ancestors have the pot '
      'in overrides list',
      (tester) async {
        fooPot = Pot.replaceable(() => const Foo(1));
        barPot = Pot.pending();
        expect(fooPot!().value, 1);

        final variant = variants.currentValue!;
        var called = false;
        await tester.pumpWidget(
          TestLocalPottery(
            overrides: [
              barPot!.set(Bar.new),
            ],
            builder: (context) {
              expect(
                () => variant.pot.of(context),
                throwsA(
                  predicate(
                    (e) =>
                        e is LocalPotteryNotFoundException &&
                        e.potTypeName == variant.typeName,
                  ),
                ),
              );
              called = true;
              return const SizedBox.shrink();
            },
          ),
        );
        expect(called, isTrue);
      },
      variant: variants,
    );
  }

  testWidgets(
    'Calling maybeOf() on a pot returns null regardless of whether the pot is '
    'nullable if no LocalPottery ancestors have the pot in overrides list',
    (tester) async {
      barPot = Pot.pending();
      final nullablePot = Pot.replaceable<int?>(() => 10);
      final nonNullablePot = Pot.replaceable<int>(() => 10);
      expect(nullablePot(), 10);
      expect(nonNullablePot(), 10);

      var called = false;
      await tester.pumpWidget(
        TestLocalPottery(
          overrides: [
            barPot!.set(Bar.new),
          ],
          builder: (context) {
            expect(nullablePot.maybeOf(context), isNull);
            expect(nonNullablePot.maybeOf(context), isNull);
            called = true;
            return const SizedBox.shrink();
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
      expect(fooPot!().value, 10);

      Foo? foo1;
      Foo? foo2;
      await tester.pumpWidget(
        TestLocalPottery(
          overrides: [
            fooPot!.set(() => const Foo(20)),
          ],
          builder: (context) {
            foo1 ??= fooPot!();
            foo2 ??= fooPot!.of(context);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(foo1!.value, 10);
      expect(foo2!.value, 20);
    },
  );

  testWidgets('Factory returning null causes no issue', (tester) async {
    nullablePot = Pot.pending();
    expect(nullablePot!.create, throwsA(isA<PotNotReadyException>()));

    var isNullObtained = false;
    await tester.pumpWidget(
      TestLocalPottery(
        overrides: [
          nullablePot!.set(() => null),
        ],
        builder: (context) {
          isNullObtained = nullablePot!.of(context) == null;
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

      fooPot!.create();

      LocalPotteryObjects? map;
      await tester.pumpWidget(
        TestLocalPottery(
          overrides: [
            fooPot!.set(() => const Foo(20)),
            barPot!.set(() => const Bar()),
          ],
          disposer: (pots) => map = pots,
        ),
      );
      expect(map, isNull);

      final buttonFinder = find.byType(RemovePotteryButton);
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(map, {fooPot: const Foo(20), barPot: const Bar()});

      // Global pot is still available.
      expect(globallyDisposed, isFalse);
      expect(fooPot!.hasObject, isTrue);
    },
  );

  testWidgets(
    'of() returns the correct object for each LocalPottery sibling and '
    'its descendants',
    (tester) async {
      fooPot = Pot.pending();

      Foo? foo1;
      Foo? foo2;
      Foo? foo3;
      Foo? foo4;
      await tester.pumpWidget(
        Column(
          children: [
            TestLocalPottery(
              overrides: [
                fooPot!.set(() => const Foo(10)),
              ],
              builder: (context1) {
                foo1 = fooPot!.of(context1);
                return Builder(
                  builder: (context2) {
                    foo2 = fooPot!.of(context2);
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
            TestLocalPottery(
              overrides: [
                fooPot!.set(() => const Foo(20)),
              ],
              builder: (context3) {
                foo3 = fooPot!.of(context3);
                return Builder(
                  builder: (context4) {
                    foo4 = fooPot!.of(context4);
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ],
        ),
      );

      expect(foo1!.value, 10);
      expect(foo2!.value, 10);
      expect(foo3!.value, 20);
      expect(foo4!.value, 20);
    },
  );

  testWidgets(
    'When LocalPotteries are nested, of() returns the object from the '
    'nearest ancestor that has the pot in overrides list',
    (tester) async {
      fooPot = Pot.pending();
      barPot = Pot.pending();

      Foo? foo1;
      Foo? foo2;
      Foo? foo3;
      Bar? bar;

      await tester.pumpWidget(
        TestLocalPottery(
          overrides: [
            fooPot!.set(() => const Foo(10)),
          ],
          builder: (context1) {
            foo1 = fooPot!.of(context1);
            return TestLocalPottery(
              overrides: [
                fooPot!.set(() => const Foo(20)),
              ],
              builder: (context2) {
                foo2 = fooPot!.of(context2);
                return TestLocalPottery(
                  overrides: [
                    barPot!.set(() => const Bar()),
                  ],
                  builder: (context3) {
                    foo3 = fooPot!.of(context3);
                    bar = barPot!.of(context3);
                    return const SizedBox.shrink();
                  },
                );
              },
            );
          },
        ),
      );

      expect(foo1!.value, 10);
      expect(foo2!.value, 20);
      expect(foo3!.value, 20);
      expect(bar, const Bar());
    },
  );

  testWidgets('debugFillProperties()', (tester) async {
    fooPot = Pot.pending();
    barPot = Pot.pending(disposer: (_) => fooPot!());

    const foo = Foo(10);
    const bar = Bar();

    final key = GlobalKey();
    await tester.pumpWidget(
      TestLocalPottery(
        localPotteryKey: key,
        overrides: [
          fooPot!.set(() => foo),
          barPot!.set(() => bar),
        ],
      ),
    );

    final builder = DiagnosticPropertiesBuilder();
    key.currentState!.debugFillProperties(builder);

    expect(
      builder.properties.firstWhere((v) => v.name == 'objects').value,
      equals({fooPot: foo, barPot: bar}),
    );
  });
}
