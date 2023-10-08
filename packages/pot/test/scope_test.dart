// ignore_for_file: cascade_invocations

import 'package:test/test.dart';

import 'package:pot/pot.dart';

import 'utils.dart';

void main() {
  setUp(prepare);

  group('Scope', () {
    test('pushScope() adds new scope', () {
      expect(Pot.currentScope, 0);

      Pot.pushScope();
      expect(Pot.currentScope, 1);
    });

    test('Dimension for new scope is added before object is accessed', () {
      expect(Pot.$scopedResetters, hasLength(1));

      Pot.pushScope();
      expect(Pot.$scopedResetters, hasLength(2));
    });

    test('Resetter is not added before object is accessed', () {
      Pot.pushScope();
      Pot(() => Foo(1));
      expect(Pot.currentScope, 1);
      expect(Pot.$scopedResetters, <List<Resetter>>[[], []]);
    });

    test('Resetter is added to scope where object is first accessed', () {
      final pot = Pot<Foo>(() => Foo(101), disposer: (f) => f.dispose());
      expect(Pot.currentScope, 0);
      expect(Pot.$scopedResetters[0], isEmpty);

      Pot.pushScope();
      pot.create();
      expect(Pot.currentScope, 1);
      expect(Pot.$scopedResetters[0], isEmpty);
      expect(Pot.$scopedResetters[1], hasLength(1));

      Pot.$scopedResetters[1][0]();
      expect(valueOfDisposedObject, 101);
    });

    test('`scope` of pot is set when an object is created', () {
      final pot = Pot(() => Foo(1));
      expect(pot.scope, isNull);

      pot.create();
      expect(pot.scope, 0);
    });

    test('`scope` of pot has index of scope the object is bound to', () {
      final pot = Pot(() => Foo(1));
      expect(pot.scope, isNull);

      Pot.pushScope();
      expect(pot.scope, isNull);

      pot.create();
      expect(pot.scope, 1);
    });

    test('`scope` of pot does not change when scope is added', () {
      final pot = Pot(() => Foo(1));
      pot.create();
      expect(pot.scope, 0);

      Pot.pushScope();
      expect(pot.scope, 0);
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
      expect(valueOfDisposedObject, 2);
      expect(Pot.$scopedResetters[0], hasLength(2));

      Pot.$scopedResetters[0][0]();
      expect(valueOfDisposedObject, 1);

      Pot.$scopedResetters[0][0]();
      expect(valueOfDisposedObject, 3);

      expect(Pot.$scopedResetters, <List<Resetter>>[[]]);
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
      expect(valueOfDisposedObject, 1);
      expect(Pot.$scopedResetters[0], hasLength(1));
      expect(Pot.$scopedResetters[1], isEmpty);

      Pot.$scopedResetters[0][0]();
      expect(valueOfDisposedObject, 2);

      expect(Pot.$scopedResetters, <List<Resetter>>[[], []]);
    });

    test('reset() resets `scope` of pot to null', () {
      final pot = Pot(() => Foo(1));
      pot.create();
      expect(pot.scope, 0);

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
        expect(pot3.$expect((o) => o.value == 3), isTrue);
        expect(pot4.$expect((o) => o.value == 4), isTrue);
        expect(Pot.$scopedResetters[0], hasLength(2));
        expect(Pot.$scopedResetters[1], hasLength(2));
        expect(values, <int>[]);

        Pot.resetAllInScope();
        expect(pot3.hasObject, isFalse);
        expect(pot4.hasObject, isFalse);
        expect(Pot.$scopedResetters[0], hasLength(2));
        expect(Pot.$scopedResetters[1], isEmpty);
        expect(values, <int>[4, 3]);
      },
    );

    test('resetAllInScope() does not affect number of scopes', () {
      expect(Pot.currentScope, 0);
      expect(Pot.$scopedResetters, <List<Resetter>>[[]]);

      final pot1 = Pot(() => Foo(1));
      final pot2 = Pot(() => Foo(2));
      pot1.create();
      pot2.create();
      Pot.pushScope();
      final pot3 = Pot(() => Foo(3));
      final pot4 = Pot(() => Foo(4));
      pot3.create();
      pot4.create();
      expect(Pot.currentScope, 1);
      expect(Pot.$scopedResetters, hasLength(2));

      Pot.resetAllInScope();
      expect(Pot.currentScope, 1);
      expect(Pot.$scopedResetters, hasLength(2));
    });

    test('resetAllInScope() does not remove root scope', () {
      expect(Pot.currentScope, 0);
      expect(Pot.$scopedResetters, <List<Resetter>>[[]]);

      final pot1 = Pot(() => Foo(1));
      final pot2 = Pot(() => Foo(2));
      pot1.create();
      pot2.create();
      expect(Pot.$scopedResetters, hasLength(1));
      expect(Pot.$scopedResetters[0], hasLength(2));

      Pot.resetAllInScope();
      expect(Pot.$scopedResetters, <List<Resetter>>[[]]);
    });

    test('resetAllInScope() resets `scope` of pot to null', () {
      final pot = Pot(() => Foo(1));
      pot.create();
      expect(pot.scope, 0);

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
      expect(pot3.$expect((o) => o.value == 3), isTrue);
      expect(pot4.$expect((o) => o.value == 4), isTrue);
      expect(Pot.$scopedResetters[0], hasLength(2));
      expect(Pot.$scopedResetters[1], hasLength(2));
      expect(values, <int>[]);

      Pot.resetAll();
      expect(pot3.hasObject, isFalse);
      expect(pot4.hasObject, isFalse);
      expect(Pot.$scopedResetters[0], isEmpty);
      expect(Pot.$scopedResetters[1], isEmpty);
      expect(values, <int>[4, 3, 2, 1]);
    });

    test('resetAll() does not affect number of scopes', () {
      expect(Pot.currentScope, 0);
      expect(Pot.$scopedResetters, <List<Resetter>>[[]]);

      final pot1 = Pot(() => Foo(1));
      final pot2 = Pot(() => Foo(2));
      pot1.create();
      pot2.create();
      Pot.pushScope();
      final pot3 = Pot(() => Foo(3));
      final pot4 = Pot(() => Foo(4));
      pot3.create();
      pot4.create();
      expect(Pot.currentScope, 1);
      expect(Pot.$scopedResetters, hasLength(2));

      Pot.resetAll();
      expect(Pot.currentScope, 1);
      expect(Pot.$scopedResetters, hasLength(2));
    });

    test('resetAll() does not remove root scope', () {
      expect(Pot.currentScope, 0);
      expect(Pot.$scopedResetters, <List<Resetter>>[[]]);

      final pot1 = Pot(() => Foo(1));
      final pot2 = Pot(() => Foo(2));
      pot1.create();
      pot2.create();
      expect(Pot.$scopedResetters, hasLength(1));
      expect(Pot.$scopedResetters[0], hasLength(2));

      Pot.resetAll();
      expect(Pot.$scopedResetters, <List<Resetter>>[[]]);
    });

    test('resetAll() resets `scope` of pot to null', () {
      final pot = Pot(() => Foo(1));
      pot.create();
      expect(pot.scope, 0);

      Pot.resetAll();
      expect(pot.scope, isNull);
    });

    test('resetAll(keepScopes: false) removes objects and scopes except 0', () {
      expect(Pot.currentScope, 0);
      expect(Pot.$scopedResetters, <List<Resetter>>[[]]);

      final pot1 = Pot(() => Foo(1));
      final pot2 = Pot(() => Foo(2));
      pot1.create();
      pot2.create();
      Pot.pushScope();
      final pot3 = Pot(() => Foo(3));
      final pot4 = Pot(() => Foo(4));
      pot3.create();
      pot4.create();
      expect(Pot.currentScope, 1);
      expect(Pot.$scopedResetters, hasLength(2));

      Pot.resetAll(keepScopes: false);
      expect(Pot.currentScope, 0);
      expect(Pot.$scopedResetters, <List<Resetter>>[[]]);
      expect(pot1.scope, isNull);
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
        expect(pot3.$expect((o) => o.value == 3), isTrue);
        expect(pot4.$expect((o) => o.value == 4), isTrue);
        expect(Pot.$scopedResetters, hasLength(2));
        expect(Pot.$scopedResetters[0], hasLength(2));
        expect(Pot.$scopedResetters[1], hasLength(2));
        expect(values, <int>[]);

        Pot.popScope();
        expect(pot3.hasObject, isFalse);
        expect(pot4.hasObject, isFalse);
        expect(Pot.$scopedResetters, hasLength(1));
        expect(Pot.$scopedResetters[0], hasLength(2));
        expect(values, <int>[4, 3]);
      },
    );

    test(
      'popScope() removes resetters in root scope but the scope remains',
      () {
        expect(Pot.currentScope, 0);
        expect(Pot.$scopedResetters, <List<Resetter>>[[]]);

        final pot1 = Pot(() => Foo(1));
        final pot2 = Pot(() => Foo(2));
        pot1.create();
        pot2.create();
        expect(Pot.$scopedResetters, hasLength(1));
        expect(Pot.$scopedResetters[0], hasLength(2));

        Pot.popScope();
        expect(Pot.currentScope, 0);
        expect(Pot.$scopedResetters, <List<Resetter>>[[]]);
      },
    );

    test('popScope() removes the scope if it is not root', () {
      expect(Pot.currentScope, 0);
      expect(Pot.$scopedResetters, <List<Resetter>>[[]]);

      final pot1 = Pot(() => Foo(1));
      final pot2 = Pot(() => Foo(2));
      pot1.create();
      pot2.create();
      Pot.pushScope();
      final pot3 = Pot(() => Foo(3));
      final pot4 = Pot(() => Foo(4));
      pot3.create();
      pot4.create();
      expect(Pot.currentScope, 1);
      expect(Pot.$scopedResetters, hasLength(2));

      Pot.popScope();
      expect(Pot.currentScope, 0);
      expect(Pot.$scopedResetters, hasLength(1));
    });

    test('popScope() resets `scope` of pot to null', () {
      final pot = Pot(() => Foo(1));
      Pot.pushScope();
      pot.create();
      expect(pot.scope, 1);

      Pot.popScope();
      expect(pot.scope, isNull);
    });

    test('Warned if new object is created in older scope than before', () {
      Pot.pushScope();
      final pot = Pot(() => Foo(1));
      pot.create();
      expect(warning, isNull);

      Pot.popScope();
      pot.create();
      expect(warning, isNotNull);
    });

    test('Warning is suppressed if suppressWarning is true', () {
      Pot.pushScope();
      final pot = Pot(() => Foo(1));
      pot.create();

      Pot.popScope();
      pot.create(suppressWarning: true);
      expect(warning, isNull);
    });
  });

  group('Scope - replace()', () {
    test('replace() in new scope replaces object in original scope', () {
      final pot = Pot.replaceable<Foo>(
        () => Foo(201),
        disposer: (f) => f.dispose(),
      );
      pot.create();
      expect(Pot.currentScope, 0);
      expect(pot.$expect((o) => o.value == 201), isTrue);
      expect(pot.scope, 0);
      expect(Pot.$scopedResetters, hasLength(1));
      expect(Pot.$scopedResetters[0], hasLength(1));
      expect(valueOfDisposedObject, -1);

      Pot.pushScope();
      pot.replace(() => Foo(202));
      expect(Pot.currentScope, 1);
      expect(pot.$expect((o) => o.value == 202), isTrue);
      expect(pot.scope, 0);
      expect(Pot.$scopedResetters[0], hasLength(1));
      expect(Pot.$scopedResetters[1], hasLength(0));
      expect(valueOfDisposedObject, 201);
    });

    test('replace() in new scope only replaces factory if no object', () {
      final pot = Pot.replaceable(() => Foo(201));
      expect(Pot.currentScope, 0);
      expect(Pot.$scopedResetters[0], hasLength(0));

      Pot.pushScope();
      pot.replace(() => Foo(202));
      expect(Pot.currentScope, 1);
      expect(pot.hasObject, isFalse);
      expect(Pot.$scopedResetters[0], isEmpty);
      expect(Pot.$scopedResetters[1], isEmpty);
    });

    test('Resetter is lazily set after replace() if pot has no object', () {
      final pot = Pot.replaceable<Foo>(
        () => Foo(201),
        disposer: (f) => f.dispose(),
      );
      expect(Pot.currentScope, 0);
      expect(Pot.$scopedResetters, <List<Resetter>>[[]]);

      Pot.pushScope();
      pot.replace(() => Foo(202));
      expect(Pot.currentScope, 1);
      expect(Pot.$scopedResetters, <List<Resetter>>[[], []]);

      final foo = pot();
      expect(foo.value, 202);
      expect(Pot.$scopedResetters[0], isEmpty);
      expect(Pot.$scopedResetters[1], hasLength(1));

      Pot.$scopedResetters[1][0]();
      expect(valueOfDisposedObject, 202);
    });
  });

  group('Scope - replaceForTesting()', () {
    setUp(() => Pot.forTesting = true);

    test(
      'replaceForTesting() in new scope replaces object in original scope',
      () {
        final pot = Pot<Foo>(() => Foo(201), disposer: (f) => f.dispose());
        pot.create();
        expect(Pot.currentScope, 0);
        expect(pot.$expect((o) => o.value == 201), isTrue);
        expect(pot.scope, 0);
        expect(Pot.$scopedResetters, hasLength(1));
        expect(Pot.$scopedResetters[0], hasLength(1));
        expect(valueOfDisposedObject, -1);

        Pot.pushScope();
        pot.replaceForTesting(() => Foo(202));
        expect(Pot.currentScope, 1);
        expect(pot.$expect((o) => o.value == 202), isTrue);
        expect(pot.scope, 0);
        expect(Pot.$scopedResetters[0], hasLength(1));
        expect(Pot.$scopedResetters[1], hasLength(0));
        expect(valueOfDisposedObject, 201);
      },
    );

    test(
      'replaceForTesting() in new scope only replaces factory if no object',
      () {
        final pot = Pot(() => Foo(201));
        expect(Pot.currentScope, 0);
        expect(Pot.$scopedResetters[0], hasLength(0));

        Pot.pushScope();
        pot.replaceForTesting(() => Foo(202));
        expect(Pot.currentScope, 1);
        expect(pot.hasObject, isFalse);
        expect(Pot.$scopedResetters[0], isEmpty);
        expect(Pot.$scopedResetters[1], isEmpty);
      },
    );

    test(
      'Resetter is lazily set after replaceForTesting() if pot has no object',
      () {
        final pot = Pot<Foo>(() => Foo(201), disposer: (f) => f.dispose());
        expect(Pot.currentScope, 0);
        expect(Pot.$scopedResetters, <List<Resetter>>[[]]);

        Pot.pushScope();
        pot.replaceForTesting(() => Foo(202));
        expect(Pot.currentScope, 1);
        expect(Pot.$scopedResetters, <List<Resetter>>[[], []]);

        final foo = pot();
        expect(foo.value, 202);
        expect(Pot.$scopedResetters[0], isEmpty);
        expect(Pot.$scopedResetters[1], hasLength(1));

        Pot.$scopedResetters[1][0]();
        expect(valueOfDisposedObject, 202);
      },
    );
  });
}
