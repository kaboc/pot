// ignore_for_file: cascade_invocations

import 'package:test/test.dart';

import 'package:pot/pot.dart';

import 'common.dart';

void main() {
  setUp(prepare);

  group('Scope', () {
    test('pushScope() adds new scope', () {
      expect(Pot.currentScope, equals(0));

      Pot.pushScope();
      expect(Pot.currentScope, equals(1));
    });

    test('Dimension for new scope is added before object is accessed', () {
      expect(Pot.$scopedResetters, hasLength(1));

      Pot.pushScope();
      expect(Pot.$scopedResetters, hasLength(2));
    });

    test('Resetter is not added before object is accessed', () {
      Pot.pushScope();
      Pot<Foo>(() => Foo(1));
      expect(Pot.currentScope, equals(1));
      expect(Pot.$scopedResetters, equals(<List<Resetter>>[[], []]));
    });

    test('Resetter is added to scope where object is first accessed', () {
      final pot = Pot<Foo>(() => Foo(101), disposer: (f) => f.dispose());
      expect(Pot.currentScope, equals(0));
      expect(Pot.$scopedResetters[0], isEmpty);

      Pot.pushScope();
      pot.create();
      expect(Pot.currentScope, equals(1));
      expect(Pot.$scopedResetters[0], isEmpty);
      expect(Pot.$scopedResetters[1], hasLength(1));

      Pot.$scopedResetters[1][0]();
      expect(valueOfDisposedObject, equals(101));
    });

    test('`scope` of pot is set when an object is created', () {
      final pot = Pot<Foo>(() => Foo(1));
      expect(pot.scope, isNull);

      pot.create();
      expect(pot.scope, equals(0));
    });

    test('`scope` of pot has index of scope the object is bound to', () {
      final pot = Pot<Foo>(() => Foo(1));
      expect(pot.scope, isNull);

      Pot.pushScope();
      expect(pot.scope, isNull);

      pot.create();
      expect(pot.scope, equals(1));
    });

    test('`scope` of pot does not change when scope is added', () {
      final pot = Pot<Foo>(() => Foo(1));
      pot.create();
      expect(pot.scope, equals(0));

      Pot.pushScope();
      expect(pot.scope, equals(0));
    });
  });

  group('Scope - reset()', () {
    test('reset() removes resetter from scopedResetters', () {
      final pot1 = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
      final pot2 = Pot<Foo>(() => Foo(2), disposer: (f) => f.dispose());
      final pot3 = Pot<Foo>(() => Foo(3), disposer: (f) => f.dispose());
      pot1.create();
      pot2.create();
      pot3.create();
      expect(Pot.$scopedResetters[0], hasLength(3));

      pot2.reset();
      expect(valueOfDisposedObject, equals(2));
      expect(Pot.$scopedResetters[0], hasLength(2));

      Pot.$scopedResetters[0][0]();
      expect(valueOfDisposedObject, equals(1));

      Pot.$scopedResetters[0][0]();
      expect(valueOfDisposedObject, equals(3));

      expect(Pot.$scopedResetters, equals(<List<Resetter>>[[]]));
    });

    test('reset() removes resetter even if current scope is different', () {
      final pot1 = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
      final pot2 = Pot<Foo>(() => Foo(2), disposer: (f) => f.dispose());
      pot1.create();
      pot2.create();
      expect(Pot.$scopedResetters[0], hasLength(2));

      Pot.pushScope();
      expect(Pot.$scopedResetters[0], hasLength(2));
      expect(Pot.$scopedResetters[1], isEmpty);

      pot1.reset();
      expect(valueOfDisposedObject, equals(1));
      expect(Pot.$scopedResetters[0], hasLength(1));
      expect(Pot.$scopedResetters[1], isEmpty);

      Pot.$scopedResetters[0][0]();
      expect(valueOfDisposedObject, equals(2));

      expect(Pot.$scopedResetters, equals(<List<Resetter>>[[], []]));
    });

    test('reset() resets `scope` of pot to null', () {
      final pot = Pot<Foo>(() => Foo(1));
      pot.create();
      expect(pot.scope, equals(0));

      pot.reset();
      expect(pot.scope, isNull);
    });
  });

  group('Scope - resetAllInScope()', () {
    test(
      'resetAllInScope() calls resetter of each pot in the scope in desc order',
      () {
        final values = <int>[];
        void disposer(Foo foo) => values.add(foo.value);

        final pot1 = Pot<Foo>(() => Foo(1), disposer: disposer);
        final pot2 = Pot<Foo>(() => Foo(2), disposer: disposer);
        pot1.create();
        pot2.create();
        Pot.pushScope();
        final pot3 = Pot<Foo>(() => Foo(3), disposer: disposer);
        final pot4 = Pot<Foo>(() => Foo(4), disposer: disposer);
        pot3.create();
        pot4.create();
        expect(pot3.$expect(Foo(3)), isTrue);
        expect(pot4.$expect(Foo(4)), isTrue);
        expect(Pot.$scopedResetters[0], hasLength(2));
        expect(Pot.$scopedResetters[1], hasLength(2));
        expect(values, equals(<int>[]));

        Pot.resetAllInScope();
        expect(pot3.$expect(null), isTrue);
        expect(pot4.$expect(null), isTrue);
        expect(Pot.$scopedResetters[0], hasLength(2));
        expect(Pot.$scopedResetters[1], isEmpty);
        expect(values, equals(<int>[4, 3]));
      },
    );

    test('resetAllInScope() does not affect number of scopes', () {
      expect(Pot.currentScope, equals(0));
      expect(Pot.$scopedResetters, equals(<List<Resetter>>[[]]));

      final pot1 = Pot<Foo>(() => Foo(1));
      final pot2 = Pot<Foo>(() => Foo(2));
      pot1.create();
      pot2.create();
      Pot.pushScope();
      final pot3 = Pot<Foo>(() => Foo(3));
      final pot4 = Pot<Foo>(() => Foo(4));
      pot3.create();
      pot4.create();
      expect(Pot.currentScope, equals(1));
      expect(Pot.$scopedResetters, hasLength(2));

      Pot.resetAllInScope();
      expect(Pot.currentScope, equals(1));
      expect(Pot.$scopedResetters, hasLength(2));
    });

    test('resetAllInScope() does not remove root scope', () {
      expect(Pot.currentScope, equals(0));
      expect(Pot.$scopedResetters, equals(<List<Resetter>>[[]]));

      final pot1 = Pot<Foo>(() => Foo(1));
      final pot2 = Pot<Foo>(() => Foo(2));
      pot1.create();
      pot2.create();
      expect(Pot.$scopedResetters, hasLength(1));
      expect(Pot.$scopedResetters[0], hasLength(2));

      Pot.resetAllInScope();
      expect(Pot.$scopedResetters, <List<Resetter>>[[]]);
    });

    test('resetAllInScope() resets `scope` of pot to null', () {
      final pot = Pot<Foo>(() => Foo(1));
      pot.create();
      expect(pot.scope, equals(0));

      Pot.resetAllInScope();
      expect(pot.scope, isNull);
    });
  });

  group('Scope - resetAll()', () {
    test('resetAll() calls resetter of every pot in desc order', () {
      final values = <int>[];
      void disposer(Foo foo) => values.add(foo.value);

      final pot1 = Pot<Foo>(() => Foo(1), disposer: disposer);
      final pot2 = Pot<Foo>(() => Foo(2), disposer: disposer);
      pot1.create();
      pot2.create();
      Pot.pushScope();
      final pot3 = Pot<Foo>(() => Foo(3), disposer: disposer);
      final pot4 = Pot<Foo>(() => Foo(4), disposer: disposer);
      pot3.create();
      pot4.create();
      expect(pot3.$expect(Foo(3)), isTrue);
      expect(pot4.$expect(Foo(4)), isTrue);
      expect(Pot.$scopedResetters[0], hasLength(2));
      expect(Pot.$scopedResetters[1], hasLength(2));
      expect(values, equals(<int>[]));

      Pot.resetAll();
      expect(pot3.$expect(null), isTrue);
      expect(pot4.$expect(null), isTrue);
      expect(Pot.$scopedResetters[0], isEmpty);
      expect(Pot.$scopedResetters[1], isEmpty);
      expect(values, equals(<int>[4, 3, 2, 1]));
    });

    test('resetAll() does not affect number of scopes', () {
      expect(Pot.currentScope, equals(0));
      expect(Pot.$scopedResetters, equals(<List<Resetter>>[[]]));

      final pot1 = Pot<Foo>(() => Foo(1));
      final pot2 = Pot<Foo>(() => Foo(2));
      pot1.create();
      pot2.create();
      Pot.pushScope();
      final pot3 = Pot<Foo>(() => Foo(3));
      final pot4 = Pot<Foo>(() => Foo(4));
      pot3.create();
      pot4.create();
      expect(Pot.currentScope, equals(1));
      expect(Pot.$scopedResetters, hasLength(2));

      Pot.resetAll();
      expect(Pot.currentScope, equals(1));
      expect(Pot.$scopedResetters, hasLength(2));
    });

    test('resetAll() does not remove root scope', () {
      expect(Pot.currentScope, equals(0));
      expect(Pot.$scopedResetters, equals(<List<Resetter>>[[]]));

      final pot1 = Pot<Foo>(() => Foo(1));
      final pot2 = Pot<Foo>(() => Foo(2));
      pot1.create();
      pot2.create();
      expect(Pot.$scopedResetters, hasLength(1));
      expect(Pot.$scopedResetters[0], hasLength(2));

      Pot.resetAll();
      expect(Pot.$scopedResetters, <List<Resetter>>[[]]);
    });

    test('resetAll() resets `scope` of pot to null', () {
      final pot = Pot<Foo>(() => Foo(1));
      pot.create();
      expect(pot.scope, equals(0));

      Pot.resetAll();
      expect(pot.scope, isNull);
    });
  });

  group('Scope - popScope()', () {
    test(
      'popScope() calls resetter of each pot in the scope in desc order',
      () {
        final values = <int>[];
        void disposer(Foo foo) => values.add(foo.value);

        final pot1 = Pot<Foo>(() => Foo(1), disposer: disposer);
        final pot2 = Pot<Foo>(() => Foo(2), disposer: disposer);
        pot1.create();
        pot2.create();
        Pot.pushScope();
        final pot3 = Pot<Foo>(() => Foo(3), disposer: disposer);
        final pot4 = Pot<Foo>(() => Foo(4), disposer: disposer);
        pot3.create();
        pot4.create();
        expect(pot3.$expect(Foo(3)), isTrue);
        expect(pot4.$expect(Foo(4)), isTrue);
        expect(Pot.$scopedResetters, hasLength(2));
        expect(Pot.$scopedResetters[0], hasLength(2));
        expect(Pot.$scopedResetters[1], hasLength(2));
        expect(values, equals(<int>[]));

        Pot.popScope();
        expect(pot3.$expect(null), isTrue);
        expect(pot4.$expect(null), isTrue);
        expect(Pot.$scopedResetters, hasLength(1));
        expect(Pot.$scopedResetters[0], hasLength(2));
        expect(values, equals(<int>[4, 3]));
      },
    );

    test(
      'popScope() removes resetters in root scope but the scope remains',
      () {
        expect(Pot.currentScope, equals(0));
        expect(Pot.$scopedResetters, equals(<List<Resetter>>[[]]));

        final pot1 = Pot<Foo>(() => Foo(1));
        final pot2 = Pot<Foo>(() => Foo(2));
        pot1.create();
        pot2.create();
        expect(Pot.$scopedResetters, hasLength(1));
        expect(Pot.$scopedResetters[0], hasLength(2));

        Pot.popScope();
        expect(Pot.currentScope, equals(0));
        expect(Pot.$scopedResetters, <List<Resetter>>[[]]);
      },
    );

    test('popScope() removes the scope if it is not root', () {
      expect(Pot.currentScope, equals(0));
      expect(Pot.$scopedResetters, equals(<List<Resetter>>[[]]));

      final pot1 = Pot<Foo>(() => Foo(1));
      final pot2 = Pot<Foo>(() => Foo(2));
      pot1.create();
      pot2.create();
      Pot.pushScope();
      final pot3 = Pot<Foo>(() => Foo(3));
      final pot4 = Pot<Foo>(() => Foo(4));
      pot3.create();
      pot4.create();
      expect(Pot.currentScope, equals(1));
      expect(Pot.$scopedResetters, hasLength(2));

      Pot.popScope();
      expect(Pot.currentScope, equals(0));
      expect(Pot.$scopedResetters, hasLength(1));
    });

    test('popScope() resets `scope` of pot to null', () {
      final pot = Pot<Foo>(() => Foo(1));
      Pot.pushScope();
      pot.create();
      expect(pot.scope, equals(1));

      Pot.popScope();
      expect(pot.scope, isNull);
    });
  });

  group('Scope - replace()', () {
    test('replace() in new scope triggers resetter', () {
      final pot = Pot.replaceable<Foo>(
        () => Foo(201),
        disposer: (f) => f.dispose(),
      );
      expect(Pot.currentScope, equals(0));
      pot.create();
      expect(pot.$expect(Foo(201)), isTrue);
      expect(valueOfDisposedObject, equals(-1));

      Pot.pushScope();
      pot.replace(() => Foo(202));
      expect(Pot.currentScope, equals(1));
      expect(pot.$expect(null), isTrue);
      expect(valueOfDisposedObject, equals(201));
    });

    test('replace() in new scope removes existing resetter', () {
      final pot = Pot.replaceable<Foo>(
        () => Foo(201),
        disposer: (f) => f.dispose(),
      );
      expect(Pot.currentScope, equals(0));
      pot.create();
      expect(Pot.$scopedResetters[0], hasLength(1));

      Pot.pushScope();
      pot.replace(() => Foo(202));
      expect(Pot.currentScope, equals(1));
      expect(Pot.$scopedResetters[0], isEmpty);
      expect(Pot.$scopedResetters[1], isEmpty);
    });

    test('After replace(), resetter is set when object is accessed', () {
      final pot = Pot.replaceable<Foo>(
        () => Foo(201),
        disposer: (f) => f.dispose(),
      );
      expect(Pot.currentScope, equals(0));
      pot.create();
      expect(Pot.$scopedResetters, hasLength(1));
      expect(Pot.$scopedResetters[0], hasLength(1));

      Pot.pushScope();
      pot.replace(() => Foo(202));
      expect(Pot.currentScope, equals(1));
      expect(Pot.$scopedResetters, <List<Resetter>>[[], []]);

      pot.create();
      expect(Pot.$scopedResetters[0], isEmpty);
      expect(Pot.$scopedResetters[1], hasLength(1));

      Pot.$scopedResetters[1][0]();
      expect(valueOfDisposedObject, equals(202));
    });

    test('replace() resets `scope` of pot to null', () {
      final pot = Pot.replaceable<Foo>(() => Foo(1));
      pot.create();
      expect(pot.scope, equals(0));

      Pot.pushScope();
      pot.replace(() => Foo(2));
      expect(pot.scope, isNull);
    });
  });

  group('Scope - replaceForTesting()', () {
    setUp(() => Pot.forTesting = true);

    test('replaceForTesting() in new scope triggers resetter', () {
      final pot = Pot<Foo>(
        () => Foo(201),
        disposer: (f) => f.dispose(),
      );
      expect(Pot.currentScope, equals(0));
      pot.create();
      expect(pot.$expect(Foo(201)), isTrue);
      expect(valueOfDisposedObject, equals(-1));

      Pot.pushScope();
      pot.replaceForTesting(() => Foo(202));
      expect(Pot.currentScope, equals(1));
      expect(pot.$expect(null), isTrue);
      expect(valueOfDisposedObject, equals(201));
    });

    test('replaceForTesting() in new scope removes existing resetter', () {
      final pot = Pot<Foo>(
        () => Foo(201),
        disposer: (f) => f.dispose(),
      );
      expect(Pot.currentScope, equals(0));
      pot.create();
      expect(Pot.$scopedResetters[0], hasLength(1));

      Pot.pushScope();
      pot.replaceForTesting(() => Foo(202));
      expect(Pot.currentScope, equals(1));
      expect(Pot.$scopedResetters[0], isEmpty);
      expect(Pot.$scopedResetters[1], isEmpty);
    });

    test(
      'After replaceForTesting(), resetter is set when object is accessed',
      () {
        final pot = Pot<Foo>(
          () => Foo(201),
          disposer: (f) => f.dispose(),
        );
        expect(Pot.currentScope, equals(0));
        pot.create();
        expect(Pot.$scopedResetters, hasLength(1));
        expect(Pot.$scopedResetters[0], hasLength(1));

        Pot.pushScope();
        pot.replaceForTesting(() => Foo(202));
        expect(Pot.currentScope, equals(1));
        expect(Pot.$scopedResetters, <List<Resetter>>[[], []]);

        pot.create();
        expect(Pot.$scopedResetters[0], isEmpty);
        expect(Pot.$scopedResetters[1], hasLength(1));

        Pot.$scopedResetters[1][0]();
        expect(valueOfDisposedObject, equals(202));
      },
    );

    test('replaceForTesting() resets `scope` of pot to null', () {
      final pot = Pot<Foo>(() => Foo(1));
      pot.create();
      expect(pot.scope, equals(0));

      Pot.pushScope();
      pot.replaceForTesting(() => Foo(2));
      expect(pot.scope, isNull);
    });
  });
}
