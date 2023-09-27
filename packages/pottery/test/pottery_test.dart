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
  const Bar([this.value]);
  final int? value;
}

void main() {
  setUp(() {
    fooPot = null;
    barPot = null;
  });

  testWidgets(
    'Pots become available by Pottery and unavailable again by removal',
    (tester) async {
      var fooDisposed = false;
      var barDisposed = false;
      fooPot = Pot.pending<Foo>(disposer: (_) => fooDisposed = true);
      barPot = Pot.pending<Bar>(disposer: (_) => barDisposed = true);

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
      expect(fooPot?.call(), const Foo(10));

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
      expect(foo, const Foo(20));
    },
  );

  testWidgets(
    'PotNotReadyException is thrown when Pottery calls reset() '
    'of a pot that depends on a pot located later in the map',
    (tester) async {
      fooPot = Pot.pending<Foo>(disposer: (_) => barPot!.call());
      barPot = Pot.pending<Bar>();

      await tester.pumpWidget(
        TestPottery(
          pots: {
            fooPot!: Foo.new,
            barPot!: Bar.new,
          },
        ),
      );

      fooPot!.create();
      barPot!.create();

      expect(fooPot!(), isA<Foo>());
      expect(barPot!(), isA<Bar>());

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
      fooPot = Pot.pending<Foo>();
      barPot = Pot.pending<Bar>(disposer: (_) => fooPot!.call());

      await tester.pumpWidget(
        TestPottery(
          pots: {
            fooPot!: Foo.new,
            barPot!: Bar.new,
          },
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
}
