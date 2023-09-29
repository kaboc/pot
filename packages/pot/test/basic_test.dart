// ignore_for_file: cascade_invocations

import 'package:test/test.dart';

import 'package:pot/pot.dart';

import 'utils.dart';

void main() {
  setUp(prepare);

  group('Inheritance', () {
    test('ReplaceablePot is a subtype of Pot', () {
      final replaceablePot = Pot.replaceable<void>(() {});
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

    test('hasObject is true after create() whether object is null or not', () {
      final pot = Pot(() => null);
      expect(pot.hasObject, isFalse);

      pot.create();
      expect(pot.hasObject, isTrue);

      pot.reset();
      expect(pot.hasObject, isFalse);
    });

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
    test('Object is not created right away', () {
      final pot = Pot(() => Foo(1));
      expect(pot.hasObject, isFalse);
      expect(isInitialized, isFalse);
    });

    test('call() creates and returns object', () {
      final pot = Pot(() => Foo(1));
      expect(pot.hasObject, isFalse);
      expect(isInitialized, isFalse);

      final foo = pot();
      expect(pot.hasObject, isTrue);
      expect(isInitialized, isTrue);
      expect(foo.value, 1);
    });

    test('call() returns same object', () {
      final pot = Pot(() => Foo(1));
      final hashCode1 = pot().hashCode;
      final hashCode2 = pot().hashCode;
      expect(hashCode2, equals(hashCode1));
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
    test('reset() resets object to null', () {
      final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
      pot.create();
      expect(pot.hasObject, isTrue);

      pot.reset();
      expect(pot.hasObject, isFalse);
    });

    test('Pot has a new object created after reset', () {
      final pot = Pot<Foo>(() => Foo(1));
      final hashCode1 = pot().hashCode;

      pot.reset();
      final hashCode2 = pot().hashCode;

      expect(hashCode2, isNot(equals(hashCode1)));
    });

    test('reset() resets object to null even if disposer() is not set', () {
      final pot = Pot<Foo>(() => Foo(1));
      pot.create();
      expect(pot.hasObject, isTrue);

      pot.reset();
      expect(pot.hasObject, isFalse);
    });

    test('reset() triggers disposer', () {
      final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
      pot.create();
      expect(isDisposed, isFalse);

      pot.reset();
      expect(isDisposed, isTrue);
    });

    test('reset() does not trigger Disposer if object is null', () {
      final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
      expect(pot.hasObject, isFalse);
      expect(isDisposed, isFalse);

      pot.reset();
      expect(isDisposed, isFalse);
    });

    test('Object is created again when it is needed after reset', () {
      final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
      pot.create();
      expect(pot.hasObject, isTrue);

      pot.reset();
      expect(pot.hasObject, isFalse);

      final foo = pot();
      expect(pot.hasObject, isTrue);
      expect(foo.value, equals(1));
    });
  });

  group('replace()', () {
    test('replace() replaces factory', () {
      final pot = Pot.replaceable<Foo>(() => Foo(1));
      var foo = pot();
      expect(foo.value, equals(1));

      pot.replace(() => Foo(2));
      foo = pot();
      expect(foo.value, equals(2));
    });

    test('replace() replaces factory regardless of existence of object', () {
      final pot = Pot.replaceable<Foo>(() => Foo(1));
      expect(pot.hasObject, isFalse);

      pot.replace(() => Foo(2));
      final foo = pot();
      expect(foo.value, equals(2));
    });

    test('replace() triggers disposer and creates new object', () {
      final pot = Pot.replaceable<Foo>(
        () => Foo(1),
        disposer: (f) => f.dispose(),
      );
      pot.create();
      expect(pot.$expect((o) => o.value == 1), isTrue);
      expect(isDisposed, isFalse);

      pot.replace(() => Foo(2));
      expect(pot.$expect((o) => o.value == 2), isTrue);
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
      expect(value, equals(1));
    });

    test('replace() does not trigger disposer if object is null', () {
      final pot = Pot.replaceable<Foo>(
        () => Foo(1),
        disposer: (f) => f.dispose(),
      );
      expect(pot.hasObject, isFalse);

      pot.replace(() => Foo(2));
      expect(isDisposed, isFalse);
    });

    test('replace() does not call new factory if object is null', () {
      final pot = Pot.replaceable<Foo>(() => Foo(1));

      pot.replace(() => Foo(2));
      expect(pot.hasObject, isFalse);

      final foo = pot();
      expect(foo.value, equals(2));
    });
  });

  group('pending()', () {
    test('Pot created with Pot.pending() throws if used when not ready.', () {
      final pot = Pot.pending<Foo>();
      expect(pot.create, throwsA(isA<PotNotReadyException>()));
    });

    test('Factory of pot created with Pot.pending() can be replaced.', () {
      final pot = Pot.pending<Foo>();
      pot.replace(() => Foo(1));
      final foo = pot();
      expect(foo.value, equals(1));
    });
  });

  group('forTesting / replaceForTesting()', () {
    test('replaceForTesting() throws if forTesting is false', () {
      final pot = Pot<Foo>(() => Foo(1));
      expect(
        () => pot.replaceForTesting(() => Foo(2)),
        throwsA(isA<PotReplaceError>()),
      );
    });

    test(
      'replaceForTesting() works on replaceable pot regardless of forTesting',
      () {
        expect(Pot.forTesting, isFalse);

        final pot = Pot.replaceable<Foo>(() => Foo(1));
        var foo = pot();
        expect(foo.value, equals(1));

        pot.replaceForTesting(() => Foo(2));
        foo = pot();
        expect(foo.value, equals(2));
      },
    );

    test(
      'replaceForTesting() works on non-replaceable pot if forTesting is true',
      () {
        Pot.forTesting = true;
        final pot = Pot<Foo>(() => Foo(1));
        var foo = pot();
        expect(foo.value, equals(1));

        pot.replaceForTesting(() => Foo(2));
        foo = pot();
        expect(foo.value, equals(2));
      },
    );

    test(
      'replaceForTesting() replaces factory regardless of existence of object',
      () {
        Pot.forTesting = true;
        final pot = Pot<Foo>(() => Foo(1));
        expect(pot.hasObject, isFalse);

        pot.replaceForTesting(() => Foo(2));
        final foo = pot();
        expect(foo.value, equals(2));
      },
    );

    test('replaceForTesting() triggers disposer and creates new object', () {
      Pot.forTesting = true;
      final pot = Pot<Foo>(
        () => Foo(1),
        disposer: (f) => f.dispose(),
      );
      pot.create();
      expect(pot.$expect((o) => o.value == 1), isTrue);
      expect(isDisposed, isFalse);

      pot.replaceForTesting(() => Foo(2));
      expect(pot.$expect((o) => o.value == 2), isTrue);
      expect(isDisposed, isTrue);
    });

    test('Disposer triggered by replaceForTesting() is given old object', () {
      var value = 0;

      Pot.forTesting = true;
      final pot = Pot<Foo>(
        () => Foo(1),
        disposer: (f) => value = f.value,
      );
      pot.create();

      pot.replaceForTesting(() => Foo(2));
      expect(value, equals(1));
    });

    test('replaceForTesting() does not trigger disposer if object is null', () {
      Pot.forTesting = true;
      final pot = Pot<Foo>(
        () => Foo(1),
        disposer: (f) => f.dispose(),
      );
      expect(pot.hasObject, isFalse);

      pot.replaceForTesting(() => Foo(2));
      expect(isDisposed, isFalse);
    });

    test('replaceForTesting() does not call new factory if object is null', () {
      Pot.forTesting = true;
      final pot = Pot<Foo>(() => Foo(1));

      pot.replaceForTesting(() => Foo(2));
      expect(pot.hasObject, isFalse);

      final foo = pot();
      expect(foo.value, equals(2));
    });
  });

  group('Disposing', () {
    test('Calling dispose() does not throw', () {
      final pot1 = Pot<Foo>(() => Foo(1));
      expect(pot1.dispose, isNot(throwsA(anything)));
    });

    test('Thrown if call() is called after pot is disposed', () {
      final pot1 = Pot<Foo>(() => Foo(1));
      pot1.dispose();
      expect(pot1.call, throwsA(isA<StateError>()));
    });

    test('Thrown if create() is called after pot is disposed', () {
      final pot1 = Pot<Foo>(() => Foo(1));
      pot1.dispose();
      expect(pot1.create, throwsA(isA<StateError>()));
    });

    test('Thrown if reset() is called after pot is disposed', () {
      final pot1 = Pot<Foo>(() => Foo(1));
      pot1.dispose();
      expect(pot1.reset, throwsA(isA<StateError>()));
    });

    test('Thrown if replace() is called after pot is disposed', () {
      final pot1 = Pot.replaceable<Foo>(() => Foo(1));
      pot1.dispose();
      expect(() => pot1.replace(() => Foo(2)), throwsA(isA<StateError>()));
    });

    test('Thrown if replace() is called after pot is disposed', () {
      Pot.forTesting = true;
      final pot1 = Pot<Foo>(() => Foo(1));
      pot1.dispose();
      expect(
        () => pot1.replaceForTesting(() => Foo(2)),
        throwsA(isA<StateError>()),
      );
    });

    test('pushScope() after one of pots is disposed does not throw', () {
      final pot1 = Pot<Foo>(() => Foo(1));
      pot1.create();
      pot1.dispose();
      expect(Pot.pushScope, isNot(throwsA(anything)));
    });

    test('popScope() after one of pots is disposed does not throw', () {
      final pot1 = Pot<Foo>(() => Foo(1));
      pot1.create();
      pot1.dispose();
      expect(Pot.popScope, isNot(throwsA(anything)));
    });

    test('resetAllInScope() after one of pots is disposed does not throw', () {
      final pot1 = Pot<Foo>(() => Foo(1));
      pot1.create();
      pot1.dispose();
      expect(Pot.resetAllInScope, isNot(throwsA(anything)));
    });

    test('resetAll() after one of pots is disposed does not throw', () {
      final pot1 = Pot<Foo>(() => Foo(1));
      pot1.create();
      pot1.dispose();
      expect(Pot.resetAll, isNot(throwsA(anything)));
    });

    test(
      'Globally stored data for local pot is not discarded automatically',
      () {
        void declarePotLocally() {
          final pot1 = Pot<Foo>(() => Foo(1));
          pot1.create();
        }

        expect(Pot.$scopedResetters[0], isEmpty);
        declarePotLocally();
        expect(Pot.$scopedResetters[0], hasLength(1));
      },
    );
  });
}
