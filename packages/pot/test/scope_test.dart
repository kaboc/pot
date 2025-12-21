// ignore_for_file: cascade_invocations

import 'package:test/test.dart';

import 'package:pot/pot.dart';
import 'package:pot/src/private/static.dart';

import 'utils.dart';

void main() {
  Object? warning;

  setUpAll(() {
    PotManager.warningPrinter = (w) => warning = w;
  });
  tearDown(() {
    Pot.uninitialize();
    resetFoo();
    warning = null;
  });

  group('Scope', () {
    test('pushScope() adds new scope', () {
      expect(Pot.currentScope, 0);

      Pot.pushScope();
      expect(Pot.currentScope, 1);
    });

    test('Dimension for new scope is added before object is accessed', () {
      expect(ScopeState.scopes, hasLength(1));

      Pot.pushScope();
      expect(ScopeState.scopes, hasLength(2));
    });

    test('Pot is not bound to scope before object is accessed', () {
      Pot.pushScope();
      Pot(() => Foo(1));
      expect(Pot.currentScope, 1);
      expect(ScopeState.scopes, <List<Pot<Object?>>>[[], []]);
    });

    test('Pot is bound to scope where object in the pot is first accessed', () {
      final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
      expect(Pot.currentScope, 0);
      expect(ScopeState.scopes, [<Pot<Object?>>[]]);

      Pot.pushScope();
      pot.create();
      expect(Pot.currentScope, 1);
      expect(ScopeState.scopes, [
        <Pot<Object?>>[],
        [pot],
      ]);
    });

    test('pot.scope is null until an object is created in the pot', () {
      final pot = Pot(() => Foo(1));
      expect(pot.scope, isNull);

      pot.create();
      expect(pot.scope, 0);
    });

    test(
      'pot.scope has index of scope where object was created in the pot',
      () {
        final pot = Pot(() => Foo(1));
        expect(pot.scope, isNull);

        Pot.pushScope();
        expect(pot.scope, isNull);

        pot.create();
        expect(pot.scope, 1);
      },
    );

    test('pot.scope does not change when scope is added', () {
      final pot = Pot(() => Foo(1));

      pot.create();
      expect(pot.scope, 0);

      Pot.pushScope();
      expect(pot.scope, 0);
    });
  });

  group('Scope - reset()', () {
    test('reset() removes pot from bound scope', () {
      final pot1 = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
      final pot2 = Pot<Foo>(() => Foo(2), disposer: (f) => f.dispose());

      pot1.create();
      pot2.create();
      expect(ScopeState.scopes, [
        [pot1, pot2],
      ]);

      pot2.reset();
      expect(ScopeState.scopes, [
        [pot1],
      ]);

      pot1.reset();
      expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);
    });

    test(
      'reset() removes pot from bound scope even if current scope is different',
      () {
        final pot1 = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
        final pot2 = Pot<Foo>(() => Foo(2), disposer: (f) => f.dispose());

        pot1.create();
        pot2.create();
        expect(ScopeState.scopes, [
          [pot1, pot2],
        ]);

        Pot.pushScope();
        expect(ScopeState.scopes, [
          [pot1, pot2],
          <Pot<Object?>>[],
        ]);

        pot1.reset();
        expect(ScopeState.scopes, [
          [pot2],
          <Pot<Object?>>[],
        ]);
      },
    );

    test('reset() resets pot.scope to null', () {
      final pot = Pot(() => Foo(1));

      pot.create();
      expect(pot.scope, 0);

      pot.reset();
      expect(pot.scope, isNull);
    });
  });

  group('Scope - resetAllInScope()', () {
    test(
      'resetAllInScope() calls reset() on each pot in the scope in '
      'reverse order',
      () {
        final values = <int>[];
        void disposer(Foo foo) => values.add(foo.value);

        final pot1 = Pot<Foo>(() => Foo(1), disposer: disposer);
        final pot2 = Pot<Foo>(() => Foo(2), disposer: disposer);
        final pot3 = Pot<Foo>(() => Foo(3), disposer: disposer);
        final pot4 = Pot<Foo>(() => Foo(4), disposer: disposer);

        pot1.create();
        pot2.create();
        Pot.pushScope();
        pot3.create();
        pot4.create();

        expect(pot3.objectString(), 'Foo(3)');
        expect(pot4.objectString(), 'Foo(4)');
        expect(ScopeState.scopes, [
          [pot1, pot2],
          [pot3, pot4],
        ]);
        expect(values, <int>[]);

        Pot.resetAllInScope();

        expect(pot3.hasObject, isFalse);
        expect(pot4.hasObject, isFalse);
        expect(ScopeState.scopes, [
          [pot1, pot2],
          <Pot<Object?>>[],
        ]);
        expect(values, [4, 3]);
      },
    );

    test('resetAllInScope() does not affect number of scopes', () {
      expect(Pot.currentScope, 0);
      expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);

      final pot1 = Pot(() => Foo(1));
      final pot2 = Pot(() => Foo(2));
      final pot3 = Pot(() => Foo(3));
      final pot4 = Pot(() => Foo(4));

      pot1.create();
      pot2.create();
      Pot.pushScope();
      pot3.create();
      pot4.create();

      expect(Pot.currentScope, 1);
      expect(ScopeState.scopes, [
        [pot1, pot2],
        [pot3, pot4],
      ]);

      Pot.resetAllInScope();

      expect(Pot.currentScope, 1);
      expect(ScopeState.scopes, [
        [pot1, pot2],
        <Pot<Object?>>[],
      ]);
    });

    test(
      'Calling resetAllInScope() when only the root scope exists does not '
      'remove the scope',
      () {
        expect(Pot.currentScope, 0);
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);

        final pot1 = Pot(() => Foo(1));
        final pot2 = Pot(() => Foo(2));

        pot1.create();
        pot2.create();
        expect(ScopeState.scopes, [
          [pot1, pot2],
        ]);

        Pot.resetAllInScope();
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);
      },
    );

    test('resetAllInScope() resets pot.scope to null', () {
      final pot = Pot(() => Foo(1));

      pot.create();
      expect(pot.scope, 0);

      Pot.resetAllInScope();
      expect(pot.scope, isNull);
    });
  });

  group('Scope - resetAll()', () {
    test('resetAll() calls reset() on each pot in reverse order', () {
      final values = <int>[];
      void disposer(Foo foo) => values.add(foo.value);

      final pot1 = Pot<Foo>(() => Foo(1), disposer: disposer);
      final pot2 = Pot<Foo>(() => Foo(2), disposer: disposer);
      final pot3 = Pot<Foo>(() => Foo(3), disposer: disposer);
      final pot4 = Pot<Foo>(() => Foo(4), disposer: disposer);

      pot1.create();
      pot2.create();
      Pot.pushScope();
      pot3.create();
      pot4.create();

      expect(pot3.objectString(), 'Foo(3)');
      expect(pot4.objectString(), 'Foo(4)');
      expect(ScopeState.scopes, [
        [pot1, pot2],
        [pot3, pot4],
      ]);
      expect(values, <int>[]);

      // ignore: deprecated_member_use_from_same_package
      Pot.resetAll();

      expect(pot3.hasObject, isFalse);
      expect(pot4.hasObject, isFalse);
      expect(ScopeState.scopes, <List<Pot<Object?>>>[[], []]);
      expect(values, [4, 3, 2, 1]);
    });

    test('resetAll() does not affect number of scopes', () {
      expect(Pot.currentScope, 0);
      expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);

      final pot1 = Pot(() => Foo(1));
      final pot2 = Pot(() => Foo(2));
      final pot3 = Pot(() => Foo(3));
      final pot4 = Pot(() => Foo(4));

      pot1.create();
      pot2.create();
      Pot.pushScope();
      pot3.create();
      pot4.create();

      expect(Pot.currentScope, 1);
      expect(ScopeState.scopes, [
        [pot1, pot2],
        [pot3, pot4],
      ]);

      // ignore: deprecated_member_use_from_same_package
      Pot.resetAll();

      expect(Pot.currentScope, 1);
      expect(ScopeState.scopes, <List<Pot<Object?>>>[[], []]);
    });

    test(
      'resetAll() does not remove the scope when only the root scope exists',
      () {
        expect(Pot.currentScope, 0);
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);

        final pot1 = Pot(() => Foo(1));
        final pot2 = Pot(() => Foo(2));

        pot1.create();
        pot2.create();
        expect(ScopeState.scopes, [
          [pot1, pot2],
        ]);

        // ignore: deprecated_member_use_from_same_package
        Pot.resetAll();
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);
      },
    );

    test('resetAll() resets pot.scope to null', () {
      final pot = Pot(() => Foo(1));

      pot.create();
      expect(pot.scope, 0);

      // ignore: deprecated_member_use_from_same_package
      Pot.resetAll();
      expect(pot.scope, isNull);
    });
  });

  group('Scope - uninitialize()', () {
    test(
      'uninitialize() removes non-root scopes and resets pot in reverse order',
      () {
        final values = <int>[];
        void disposer(Foo foo) => values.add(foo.value);

        final pot1 = Pot<Foo>(() => Foo(1), disposer: disposer);
        final pot2 = Pot<Foo>(() => Foo(2), disposer: disposer);
        final pot3 = Pot<Foo>(() => Foo(3), disposer: disposer);
        final pot4 = Pot<Foo>(() => Foo(4), disposer: disposer);
        final pot5 = Pot<Foo>(() => Foo(5), disposer: disposer);
        final pot6 = Pot<Foo>(() => Foo(6), disposer: disposer);

        pot1.create();
        pot2.create();
        Pot.pushScope();
        pot3.create();
        pot4.create();
        Pot.pushScope();
        pot5.create();
        pot6.create();

        expect(pot1.objectString(), 'Foo(1)');
        expect(pot2.objectString(), 'Foo(2)');
        expect(pot3.objectString(), 'Foo(3)');
        expect(pot4.objectString(), 'Foo(4)');
        expect(pot5.objectString(), 'Foo(5)');
        expect(pot6.objectString(), 'Foo(6)');
        expect(pot1.scope, 0);
        expect(pot2.scope, 0);
        expect(pot3.scope, 1);
        expect(pot4.scope, 1);
        expect(pot5.scope, 2);
        expect(pot6.scope, 2);
        expect(ScopeState.scopes, [
          [pot1, pot2],
          [pot3, pot4],
          [pot5, pot6],
        ]);
        expect(Pot.currentScope, 2);
        expect(values, isEmpty);

        Pot.uninitialize();

        expect(pot1.hasObject, isFalse);
        expect(pot2.hasObject, isFalse);
        expect(pot3.hasObject, isFalse);
        expect(pot4.hasObject, isFalse);
        expect(pot5.hasObject, isFalse);
        expect(pot6.hasObject, isFalse);
        expect(pot1.scope, isNull);
        expect(pot2.scope, isNull);
        expect(pot3.scope, isNull);
        expect(pot4.scope, isNull);
        expect(pot5.scope, isNull);
        expect(pot6.scope, isNull);
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);
        expect(Pot.currentScope, 0);
        expect(values, [6, 5, 4, 3, 2, 1]);
      },
    );

    test(
      'When only root scope exists, uninitialize() only resets and clears pots',
      () {
        expect(Pot.currentScope, 0);
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);

        final values = <int>[];
        void disposer(Foo foo) => values.add(foo.value);

        final pot = Pot(() => Foo(1), disposer: disposer);
        pot.create();
        expect(ScopeState.scopes, [
          [pot]
        ]);
        expect(values, isEmpty);

        Pot.uninitialize();
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);
        expect(values, [1]);
      },
    );
  });

  group('Scope - popScope()', () {
    test(
      'popScope() calls reset() on each pot in the scope in reverse order',
      () {
        final values = <int>[];
        void disposer(Foo foo) => values.add(foo.value);

        final pot1 = Pot<Foo>(() => Foo(1), disposer: disposer);
        final pot2 = Pot<Foo>(() => Foo(2), disposer: disposer);
        final pot3 = Pot<Foo>(() => Foo(3), disposer: disposer);
        final pot4 = Pot<Foo>(() => Foo(4), disposer: disposer);

        pot1.create();
        pot2.create();
        Pot.pushScope();
        pot3.create();
        pot4.create();

        expect(pot3.objectString(), 'Foo(3)');
        expect(pot4.objectString(), 'Foo(4)');
        expect(ScopeState.scopes, [
          [pot1, pot2],
          [pot3, pot4],
        ]);
        expect(values, <int>[]);

        Pot.popScope();

        expect(pot3.hasObject, isFalse);
        expect(pot4.hasObject, isFalse);
        expect(ScopeState.scopes, [
          [pot1, pot2],
        ]);
        expect(values, [4, 3]);
      },
    );

    test(
      'Calling popScope() in root scope removes pots but the scope remains',
      () {
        expect(Pot.currentScope, 0);
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);

        final pot1 = Pot(() => Foo(1));
        final pot2 = Pot(() => Foo(2));

        pot1.create();
        pot2.create();
        expect(ScopeState.scopes, [
          [pot1, pot2],
        ]);

        Pot.popScope();
        expect(Pot.currentScope, 0);
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);
      },
    );

    test('Calling popScope() in non-root scope removes the scope', () {
      expect(Pot.currentScope, 0);
      expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);

      final pot1 = Pot(() => Foo(1));
      final pot2 = Pot(() => Foo(2));
      final pot3 = Pot(() => Foo(3));
      final pot4 = Pot(() => Foo(4));

      pot1.create();
      pot2.create();
      Pot.pushScope();
      pot3.create();
      pot4.create();

      expect(Pot.currentScope, 1);
      expect(ScopeState.scopes, [
        [pot1, pot2],
        [pot3, pot4],
      ]);

      Pot.popScope();

      expect(Pot.currentScope, 0);
      expect(ScopeState.scopes, [
        [pot1, pot2],
      ]);
    });

    test('popScope() resets pot.scope to null', () {
      final pot = Pot(() => Foo(1));

      Pot.pushScope();
      pot.create();
      expect(pot.scope, 1);

      Pot.popScope();
      expect(pot.scope, isNull);
    });

    test('Warned if new object is created in older scope than before', () {
      final pot = Pot(() => Foo(1));

      Pot.pushScope();
      pot.create();
      expect(warning, isNull);

      Pot.popScope();
      pot.create();
      expect(warning, isNotNull);
    });

    test('Warning is suppressed if suppressWarning is true', () {
      final pot = Pot(() => Foo(1));

      Pot.pushScope();
      pot.create();

      Pot.popScope();
      pot.create(suppressWarning: true);
      expect(warning, isNull);
    });
  });

  group('Scope - replace()', () {
    test(
      'Calling replace() on pot bound to previous scope after adding scope '
      'replaces object, but the pot is still bound to original scope',
      () {
        final pot = Pot.replaceable<Foo>(
          () => Foo(1),
          disposer: (f) => f.dispose(),
        );

        pot.create();
        expect(Pot.currentScope, 0);
        expect(pot.scope, 0);
        expect(pot.objectString(), 'Foo(1)');
        expect(ScopeState.scopes, [
          [pot],
        ]);
        expect(valueOfDisposedObject, -1);

        Pot.pushScope();
        expect(Pot.currentScope, 1);
        expect(pot.scope, 0);
        expect(pot.objectString(), 'Foo(1)');

        pot.replace(() => Foo(2));
        expect(Pot.currentScope, 1);
        expect(pot.scope, 0);
        expect(pot.objectString(), 'Foo(2)');
        expect(ScopeState.scopes, [
          [pot],
          <Pot<Object?>>[],
        ]);
        expect(valueOfDisposedObject, 1);
      },
    );

    test(
      'Calling replace() on pot after adding scope only replaces factory '
      'if the pot has no object',
      () {
        final pot = Pot.replaceable(() => Foo(1));
        expect(Pot.currentScope, 0);
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);

        Pot.pushScope();
        pot.replace(() => Foo(2));
        expect(Pot.currentScope, 1);
        expect(pot.hasObject, isFalse);
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[], []]);
      },
    );

    test(
      'Pot is lazily bound to scope after replace() if the pot has no object',
      () {
        final pot = Pot.replaceable<Foo>(
          () => Foo(1),
          disposer: (f) => f.dispose(),
        );
        expect(Pot.currentScope, 0);
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);

        Pot.pushScope();
        pot.replace(() => Foo(2));
        expect(Pot.currentScope, 1);
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[], []]);

        final foo = pot();
        expect(foo.value, 2);
        expect(ScopeState.scopes, [
          <Pot<Object?>>[],
          [pot],
        ]);
      },
    );
  });

  group('Scope - replaceForTesting()', () {
    test(
      'Calling replaceForTesting() on pot bound to previous scope after adding '
      'scope replaces object, but the pot is still bound to original scope',
      () {
        final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());

        pot.create();
        expect(Pot.currentScope, 0);
        expect(pot.scope, 0);
        expect(pot.objectString(), 'Foo(1)');
        expect(ScopeState.scopes, [
          [pot],
        ]);
        expect(valueOfDisposedObject, -1);

        Pot.pushScope();
        expect(Pot.currentScope, 1);
        expect(pot.scope, 0);
        expect(pot.objectString(), 'Foo(1)');

        pot.replaceForTesting(() => Foo(2));
        expect(Pot.currentScope, 1);
        expect(pot.scope, 0);
        expect(pot.objectString(), 'Foo(2)');
        expect(ScopeState.scopes, [
          [pot],
          <Pot<Object?>>[],
        ]);
        expect(valueOfDisposedObject, 1);
      },
    );

    test(
      'Calling replaceForTesting() on pot after adding scope only replaces '
      'factory if pot has no object',
      () {
        final pot = Pot(() => Foo(1));
        expect(Pot.currentScope, 0);
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);

        Pot.pushScope();
        pot.replaceForTesting(() => Foo(2));
        expect(Pot.currentScope, 1);
        expect(pot.hasObject, isFalse);
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[], []]);
      },
    );

    test(
      'Pot is lazily bound to scope after replaceForTesting() if the pot '
      'has no object',
      () {
        final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
        expect(Pot.currentScope, 0);
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[]]);

        Pot.pushScope();
        pot.replaceForTesting(() => Foo(2));
        expect(Pot.currentScope, 1);
        expect(ScopeState.scopes, <List<Pot<Object?>>>[[], []]);

        final foo = pot();
        expect(foo.value, 2);
        expect(ScopeState.scopes, [
          <Pot<Object?>>[],
          [pot],
        ]);
      },
    );
  });
}
