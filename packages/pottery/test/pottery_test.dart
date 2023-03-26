import 'package:flutter_test/flutter_test.dart';

import 'package:pottery/pottery.dart';

import 'widgets.dart';

ReplaceablePot<Foo>? fooPot;
ReplaceablePot<Bar>? barPot;

class Foo {
  const Foo();
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
    'Pots become available by Pottery and unavailable again by removal',
    (tester) async {
      fooPot = Pot.pending<Foo>();
      barPot = Pot.pending<Bar>();

      expect(fooPot?.create, throwsA(isA<PotNotReadyException>()));
      expect(barPot?.create, throwsA(isA<PotNotReadyException>()));

      await tester.pumpWidget(
        TestWidget(
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

      expect(fooPot!.create, throwsA(isA<PotNotReadyException>()));
      expect(barPot!.create, throwsA(isA<PotNotReadyException>()));
      expect(fooPot!.hasObject, isFalse);
      expect(barPot!.hasObject, isFalse);
    },
  );

  testWidgets(
    'PotNotReadyException is thrown when Pottery calls reset() '
    'of a pot that depends on a pot located later in the map',
    (tester) async {
      fooPot = Pot.pending<Foo>(disposer: (_) => barPot!.call());
      barPot = Pot.pending<Bar>();

      await tester.pumpWidget(
        TestWidget(
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
        TestWidget(
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
