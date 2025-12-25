// ignore_for_file: cascade_invocations

import 'package:test/test.dart';

import 'package:pot/pot.dart';
import 'package:pot/src/private/static.dart';
import 'package:pot/src/private/utils.dart';

import 'utils.dart';

void main() {
  tearDown(() {
    Pot.uninitialize();
    resetFoo();
  });

  group('Inheritance', () {
    test('ReplaceablePot is a subtype of Pot', () {
      final replaceablePot = Pot.replaceable(() {});
      expect(replaceablePot, isA<Pot<void>>());
    });
  });

  group('hasObject', () {
    test('hasObject is true when object exists and false after reset()', () {
      final pot = Pot(() => Foo(1));
      expect(pot.hasObject, isFalse);

      pot.create();
      expect(pot.hasObject, isTrue);

      pot.reset();
      expect(pot.hasObject, isFalse);
    });

    test(
      'hasObject is true after create() regardless of whether value of '
      'object is null or not',
      () {
        final pot = Pot(() => null);
        expect(pot.hasObject, isFalse);

        pot.create();
        expect(pot.hasObject, isTrue);

        pot.reset();
        expect(pot.hasObject, isFalse);
      },
    );

    test('replace() does not affect hasObject', () {
      final pot = Pot.replaceable<Foo?>(() => Foo(1));
      expect(pot.hasObject, isFalse);

      pot.replace(() => Foo(2));
      expect(pot.hasObject, isFalse);

      pot.create();
      expect(pot.hasObject, isTrue);

      pot.replace(() => null);
      expect(pot.hasObject, isTrue);
    });
  });

  group('call() / create()', () {
    test(
      'Object is not created in pot immediately when the pot is created',
      () {
        final pot = Pot(() => Foo(1));
        expect(pot.hasObject, isFalse);
        expect(isInitialized, isFalse);
      },
    );

    test('call() creates and returns object', () {
      final pot = Pot(() => Foo(1));
      expect(pot.hasObject, isFalse);
      expect(isInitialized, isFalse);

      final foo = pot();
      expect(pot.hasObject, isTrue);
      expect(isInitialized, isTrue);
      expect(foo.value, 1);
    });

    test('Multiple calls to call() return same instance of object', () {
      final pot = Pot(() => Foo(1));
      final hashCode1 = pot().hashCode;
      final hashCode2 = pot().hashCode;
      expect(hashCode2, hashCode1);
    });

    test('create() creates object', () {
      final pot = Pot(() => Foo(1));
      expect(pot.hasObject, isFalse);
      expect(isInitialized, isFalse);

      pot.create();
      expect(pot.hasObject, isTrue);
      expect(isInitialized, isTrue);
    });
  });

  group('reset()', () {
    test('reset() removes object from pot, whether it has disposer or not', () {
      final pot1 = Pot(() => Foo(1));
      final pot2 = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());

      pot1.create();
      pot2.create();
      expect(pot1.hasObject, isTrue);
      expect(pot2.hasObject, isTrue);

      pot1.reset();
      pot2.reset();
      expect(pot1.hasObject, isFalse);
      expect(pot1.hasObject, isFalse);
    });

    test('reset() triggers disposer', () {
      final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());

      pot.create();
      expect(isDisposed, isFalse);

      pot.reset();
      expect(isDisposed, isTrue);
    });

    test('reset() does not trigger disposer if the pot has no object', () {
      final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
      expect(pot.hasObject, isFalse);
      expect(isDisposed, isFalse);

      pot.reset();
      expect(isDisposed, isFalse);
    });

    test('reset() triggers disposer with null if value of object is null', () {
      Foo? object;
      var called = false;

      final pot = Pot<Foo?>(
        () => null,
        disposer: (f) {
          object = f;
          called = true;
        },
      );

      pot.create();
      expect(object, isNull);
      expect(called, isFalse);
      expect(pot.hasObject, isTrue);

      pot.reset();
      expect(object, isNull);
      expect(called, isTrue);
      expect(pot.hasObject, isFalse);
    });

    test('Object is created again when it is needed after removed', () {
      final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());

      pot.create();
      expect(pot.hasObject, isTrue);

      pot.reset();
      expect(pot.hasObject, isFalse);

      final foo = pot();
      expect(pot.hasObject, isTrue);
      expect(foo.value, 1);
    });

    test(
      'Calling reset() on a pot removes static data for the pot only partially',
      () {
        final pot1 = Pot(() => Foo(1));
        final pot2 = Pot(() => Foo(1));
        final pot3 = Pot(() => Foo(1));

        pot1.create();
        Pot.pushScope();
        pot2.create();
        pot3.create();
        expect(ScopeState.currentScope, 1);
        expect(ScopeState.scopes, [
          [pot1],
          [pot2, pot3],
        ]);
        expect(PotManager.allInstances.keys, [pot1, pot2, pot3]);

        pot2.reset();
        expect(ScopeState.currentScope, 1);
        // The reset pot is removed from scopes list.
        expect(ScopeState.scopes, [
          [pot1],
          [pot3],
        ]);
        // The reset pot remains in allInstances Map.
        expect(PotManager.allInstances.keys, [pot1, pot2, pot3]);
      },
    );
  });

  group('replace()', () {
    test('replace() replaces factory', () {
      final pot = Pot.replaceable(() => Foo(1));
      expect(pot().value, 1);

      pot.replace(() => Foo(2));
      expect(pot().value, 2);
    });

    test('replace() replaces factory regardless of existence of object', () {
      final pot = Pot.replaceable(() => Foo(1));
      expect(pot.hasObject, isFalse);

      pot.replace(() => Foo(2));
      expect(pot().value, 2);
    });

    test('replace() triggers disposer and creates new object', () {
      final pot = Pot.replaceable<Foo>(
        () => Foo(1),
        disposer: (f) => f.dispose(),
      );

      pot.create();
      expect(PotDescription.fromPot(pot).object, 'Foo(1)');
      expect(isDisposed, isFalse);

      pot.replace(() => Foo(2));
      expect(PotDescription.fromPot(pot).object, 'Foo(2)');
      expect(isDisposed, isTrue);
    });

    test('Disposer triggered by replace() is given old object', () {
      var value = 0;

      final pot = Pot.replaceable<Foo>(
        () => Foo(1),
        disposer: (f) => value = f.value,
      );

      pot.create();
      pot.replace(() => Foo(2));
      expect(value, 1);
    });

    test('replace() does not trigger disposer if object does not exist', () {
      final pot = Pot.replaceable<Foo>(
        () => Foo(1),
        disposer: (f) => f.dispose(),
      );
      expect(pot.hasObject, isFalse);

      pot.replace(() => Foo(2));
      expect(isDisposed, isFalse);
    });

    test('replace() triggers disposer with null if object is null', () {
      Foo? object;
      var called = false;

      final pot = Pot.replaceable<Foo?>(
        () => null,
        disposer: (f) {
          object = f;
          called = true;
        },
      );

      pot.create();
      expect(object, isNull);
      expect(called, isFalse);
      expect(pot.hasObject, isTrue);

      pot.reset();
      expect(object, isNull);
      expect(called, isTrue);
      expect(pot.hasObject, isFalse);
    });

    test('replace() does not call new factory if object does not exist', () {
      final pot = Pot.replaceable(() => Foo(1));

      pot.replace(() => Foo(2));
      expect(pot.hasObject, isFalse);
      expect(pot().value, 2);
    });
  });

  group('pending()', () {
    test('Pot created with Pot.pending() throws if used when not ready', () {
      final pot = Pot.pending<Foo>();
      expect(pot.create, throwsA(isA<PotNotReadyException>()));
    });

    test('Factory of pot created with Pot.pending() can be replaced', () {
      final pot = Pot.pending<Foo>();
      pot.replace(() => Foo(1));
      expect(pot().value, 1);
    });
  });

  group('replaceForTesting()', () {
    test('replaceForTesting() works on non-replaceable pot', () {
      final pot = Pot(() => Foo(1));
      expect(pot().value, 1);

      pot.replaceForTesting(() => Foo(2));
      expect(pot().value, 2);
    });

    test(
      'replaceForTesting() replaces factory regardless of existence of object',
      () {
        final pot = Pot(() => Foo(1));
        expect(pot.hasObject, isFalse);

        pot.replaceForTesting(() => Foo(2));
        expect(pot().value, 2);
      },
    );

    test('replaceForTesting() triggers disposer and creates new object', () {
      final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());

      pot.create();
      expect(PotDescription.fromPot(pot).object, 'Foo(1)');
      expect(isDisposed, isFalse);

      pot.replaceForTesting(() => Foo(2));
      expect(PotDescription.fromPot(pot).object, 'Foo(2)');
      expect(isDisposed, isTrue);
    });

    test('Disposer triggered by replaceForTesting() is given old object', () {
      var value = 0;

      final pot = Pot<Foo>(() => Foo(1), disposer: (f) => value = f.value);
      pot.create();

      pot.replaceForTesting(() => Foo(2));
      expect(value, 1);
    });

    test(
      'replaceForTesting() does not trigger disposer if object does not exist',
      () {
        final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
        expect(pot.hasObject, isFalse);

        pot.replaceForTesting(() => Foo(2));
        expect(isDisposed, isFalse);
      },
    );

    test(
      'replaceForTesting() does not call new factory if object does not exist',
      () {
        final pot = Pot(() => Foo(1));

        pot.replaceForTesting(() => Foo(2));
        expect(pot.hasObject, isFalse);
        expect(pot().value, 2);
      },
    );
  });

  group('resetAsPending()', () {
    test('ReplaceablePot becomes pending if resetAsPending() is used', () {
      final pot = Pot.pending<Foo>();
      expect(pot.isPending, isTrue);

      pot.replace(() => Foo(1));
      expect(pot.isPending, isFalse);
      expect(pot().value, 1);

      pot.resetAsPending();
      expect(pot.isPending, isTrue);
      expect(pot.create, throwsA(isA<PotNotReadyException>()));
    });

    test(
      'replaceForTesting() changes isPending to false if pot is ReplaceablePot',
      () {
        final pot = Pot.pending<Foo>();
        expect(pot.isPending, isTrue);

        pot.replaceForTesting(() => Foo(1));
        expect(pot.isPending, isFalse);
        expect(pot().value, 1);
      },
    );
  });

  group('toString()', () {
    test('toString() on pot of type Pot', () {
      final pot = Pot(() => Foo(10), disposer: (_) {});

      pot.create();
      expect(
        pot.toString(),
        'Pot<Foo>#${pot.shortHash()}(isPending: false, isDisposed: false, '
        'hasDisposer: true, hasObject: true, object: Foo(10), scope: 0)',
      );
    });

    test('toString() on pot of type ReplaceablePot', () {
      final pot = Pot.pending<Foo>(disposer: (_) {});

      expect(
        pot.toString(),
        'ReplaceablePot<Foo>#${pot.shortHash()}(isPending: true, '
        'isDisposed: false, hasDisposer: true, hasObject: false, '
        'object: null, scope: null)',
      );
    });
  });

  group('Disposing', () {
    test('Calling dispose() does not throw', () {
      final pot = Pot(() => Foo(1));
      expect(pot.dispose, isNot(throwsA(anything)));
    });

    test('dispose() resets state in pot', () {
      final pot = Pot(() => Foo(1));
      final replaceablePot = Pot.replaceable(() => Foo(1));

      pot.create();
      replaceablePot.create();
      expect(pot.hasObject, isTrue);

      pot.dispose();
      expect(pot.hasObject, isFalse);
      expect(pot.scope, isNull);

      replaceablePot.dispose();
      expect(replaceablePot.hasObject, isFalse);
      expect(replaceablePot.scope, isNull);
      // Not reset as pending. It's unnecessary to replace factory
      // to throw since the pot itself is unusable now.
      expect(replaceablePot.isPending, isFalse);
    });

    test('Calling dispose() again after dispose() does not throw', () {
      final pot = Pot(() => Foo(1));
      pot.dispose();
      expect(pot.dispose, isNot(throwsA(anything)));
    });

    test('Calling call() after dispose() throws', () {
      final pot = Pot(() => Foo(1));
      pot.dispose();
      expect(pot.call, throwsA(isA<StateError>()));
    });

    test('Calling create() after dispose() throws', () {
      final pot = Pot(() => Foo(1));
      pot.dispose();
      expect(pot.create, throwsA(isA<StateError>()));
    });

    test('Calling reset() after dispose() throws', () {
      final pot = Pot(() => Foo(1));
      pot.dispose();
      expect(pot.reset, throwsA(isA<StateError>()));
    });

    test('Calling replace() after dispose() throws', () {
      final pot1 = Pot.replaceable(() => Foo(1));
      final pot2 = Pot(() => Foo(1));

      pot1.dispose();
      expect(
        () => pot1.replace(() => Foo(2)),
        throwsA(isA<StateError>()),
      );

      pot2.dispose();
      expect(
        () => pot2.replaceForTesting(() => Foo(2)),
        throwsA(isA<StateError>()),
      );
    });

    test('Calling notifyObjectUpdate() after dispose() throws', () {
      final pot = Pot(() => Foo(1));
      pot.dispose();
      expect(pot.notifyObjectUpdate, throwsA(isA<StateError>()));
    });

    test('pushScope() after one of pots is disposed does not throw', () {
      final pot = Pot(() => Foo(1));
      pot.create();
      pot.dispose();
      expect(Pot.pushScope, isNot(throwsA(anything)));
    });

    test('popScope() after one of pots is disposed does not throw', () {
      final pot = Pot(() => Foo(1));
      pot.create();
      pot.dispose();
      expect(Pot.popScope, isNot(throwsA(anything)));
    });

    test('resetAllInScope() after one of pots is disposed does not throw', () {
      final pot = Pot(() => Foo(1));
      pot.create();
      pot.dispose();
      expect(Pot.resetAllInScope, isNot(throwsA(anything)));
    });

    test('uninitialize() after one of pots is disposed does not throw', () {
      final pot = Pot(() => Foo(1));
      pot.create();
      pot.dispose();
      expect(Pot.uninitialize, isNot(throwsA(anything)));
    });

    test('Calling dispose() on a pot removes static data for the pot', () {
      final pot1 = Pot(() => Foo(1));
      final pot2 = Pot(() => Foo(2));
      final pot3 = Pot(() => Foo(3));

      pot1.create();
      Pot.pushScope();
      pot2.create();
      pot3.create();
      expect(ScopeState.currentScope, 1);
      expect(ScopeState.scopes, [
        [pot1],
        [pot2, pot3],
      ]);
      expect(PotManager.allInstances.keys, [pot1, pot2, pot3]);

      pot2.dispose();
      expect(ScopeState.currentScope, 1);
      expect(ScopeState.scopes, [
        [pot1],
        [pot3],
      ]);
      expect(PotManager.allInstances.keys, [pot1, pot3]);
    });

    test('uninitialize() clears static data', () {
      final pot1 = Pot(() => Foo(1));
      final pot2 = Pot(() => Foo(2));
      final pot3 = Pot(() => Foo(3));

      pot1.create();
      Pot.pushScope();
      pot2.create();
      pot3.create();
      expect(ScopeState.currentScope, 1);
      expect(ScopeState.scopes, [
        [pot1],
        [pot2, pot3],
      ]);
      expect(PotManager.allInstances.keys, [pot1, pot2, pot3]);

      Pot.uninitialize();
      expect(ScopeState.currentScope, 0);
      expect(ScopeState.scopes, [isEmpty]);
      expect(PotManager.allInstances.keys, isEmpty);
    });

    test(
      'Static data for local pot remains until cleaned up by dispose()',
      () {
        void declarePotLocally({required bool callDispose}) {
          final pot = Pot(() => Foo(1));
          pot.create();
          if (callDispose) {
            pot.dispose();
          }
        }

        expect(ScopeState.scopes[0], isEmpty);
        expect(
          PotManager.allInstances.keys.map(
            (pot) => PotDescription.fromPot(pot).object,
          ),
          isEmpty,
        );

        declarePotLocally(callDispose: false);
        expect(ScopeState.scopes[0], hasLength(1));
        expect(
          PotManager.allInstances.keys.map(
            (pot) => PotDescription.fromPot(pot).object,
          ),
          ['Foo(1)'],
        );

        Pot.uninitialize();
        expect(ScopeState.scopes[0], isEmpty);
        expect(
          PotManager.allInstances.keys.map(
            (pot) => PotDescription.fromPot(pot).object,
          ),
          isEmpty,
        );

        declarePotLocally(callDispose: true);
        expect(ScopeState.scopes[0], isEmpty);
        expect(
          PotManager.allInstances.keys.map(
            (pot) => PotDescription.fromPot(pot).object,
          ),
          isEmpty,
        );
      },
    );
  });
}
