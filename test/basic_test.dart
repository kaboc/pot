// ignore_for_file: cascade_invocations

import 'package:test/test.dart';

import 'package:pot/pot.dart';

import 'common.dart';

void main() {
  setUp(prepare);

  group('call() / create()', () {
    test('Object is not created right away', () {
      final pot = Pot(() => Foo(1));
      expect(pot.$expect((o) => o == null), isTrue);
      expect(isInitialized, isFalse);
    });

    test('call() creates and returns object', () {
      final pot = Pot(() => Foo(1));
      expect(pot.$expect((o) => o == null), isTrue);
      expect(isInitialized, isFalse);

      final foo = pot();
      expect(isInitialized, isTrue);
      expect(pot.$expect((o) => o!.value == 1), isTrue);
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
      expect(pot.$expect((o) => o == null), isTrue);
      expect(isInitialized, isFalse);

      pot.create();
      expect(isInitialized, isTrue);
      expect(pot.$expect((o) => o!.value == 1), isTrue);
    });
  });

  group('reset()', () {
    test('reset() resets object  to null', () {
      final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
      pot.create();
      expect(pot.$expect((o) => o!.value == 1), isTrue);

      pot.reset();
      expect(pot.$expect((o) => o == null), isTrue);
    });

    test('Object after reset is different from previous one', () {
      final pot = Pot<Foo>(() => Foo(1));
      final hashCode1 = pot().hashCode;

      pot.reset();
      final hashCode2 = pot().hashCode;

      expect(hashCode2, isNot(equals(hashCode1)));
    });

    test('reset() resets object to null even if disposer() is not set', () {
      final pot = Pot<Foo>(() => Foo(1));
      pot.create();
      expect(pot.$expect((o) => o!.value == 1), isTrue);

      pot.reset();
      expect(pot.$expect((o) => o == null), isTrue);
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
      expect(pot.$expect((o) => o == null), isTrue);
      expect(isDisposed, isFalse);

      pot.reset();
      expect(isDisposed, isFalse);
    });

    test('Object is created again when it is needed after reset', () {
      final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
      pot.create();
      expect(pot.$expect((o) => o!.value == 1), isTrue);

      pot.reset();
      expect(pot.$expect((o) => o == null), isTrue);

      final foo = pot();
      expect(pot.$expect((o) => o!.value == 1), isTrue);
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
      expect(pot.$expect((o) => o == null), isTrue);

      pot.replace(() => Foo(2));
      final foo = pot();
      expect(foo.value, equals(2));
    });

    test('replace() resets object and triggers disposer', () {
      final pot =
          Pot.replaceable<Foo>(() => Foo(1), disposer: (f) => f.dispose());
      pot.create();
      expect(pot.$expect((o) => o!.value == 1), isTrue);
      expect(isDisposed, isFalse);

      pot.replace(() => Foo(2));
      expect(pot.$expect((o) => o == null), isTrue);
      expect(isDisposed, isTrue);
    });

    test('replace() does not trigger disposer if object is null', () {
      final pot =
          Pot.replaceable<Foo>(() => Foo(1), disposer: (f) => f.dispose());
      expect(pot.$expect((o) => o == null), isTrue);

      pot.replace(() => Foo(2));
      expect(isDisposed, isFalse);
    });

    test('replace() does not call new factory right away', () {
      final pot =
          Pot.replaceable<Foo>(() => Foo(1), disposer: (f) => f.dispose());

      pot.replace(() => Foo(2));
      expect(pot.$expect((o) => o == null), isTrue);

      final foo = pot();
      expect(foo.value, equals(2));
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
        expect(pot.$expect((o) => o == null), isTrue);

        pot.replaceForTesting(() => Foo(2));
        final foo = pot();
        expect(foo.value, equals(2));
      },
    );

    test('replaceForTesting() resets object and triggers disposer', () {
      Pot.forTesting = true;
      final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
      pot.create();
      expect(pot.$expect((o) => o!.value == 1), isTrue);
      expect(isDisposed, isFalse);

      pot.replaceForTesting(() => Foo(2));
      expect(pot.$expect((o) => o == null), isTrue);
      expect(isDisposed, isTrue);
    });

    test('replaceForTesting() does not trigger disposer if object is null', () {
      Pot.forTesting = true;
      final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());
      expect(pot.$expect((o) => o == null), isTrue);

      pot.replaceForTesting(() => Foo(2));
      expect(isDisposed, isFalse);
    });

    test('replaceForTesting() does not call new factory right away', () {
      Pot.forTesting = true;
      final pot = Pot<Foo>(() => Foo(1), disposer: (f) => f.dispose());

      pot.replaceForTesting(() => Foo(2));
      expect(pot.$expect((o) => o == null), isTrue);

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

    test('Thrown if create() is called after pot is dispose', () {
      final pot1 = Pot<Foo>(() => Foo(1));
      pot1.dispose();
      expect(pot1.create, throwsA(isA<StateError>()));
    });

    test('Thrown if reset() is called after pot is dispose', () {
      final pot1 = Pot<Foo>(() => Foo(1));
      pot1.dispose();
      expect(pot1.reset, throwsA(isA<StateError>()));
    });

    test('Thrown if replace() is called after pot is dispose', () {
      final pot1 = Pot.replaceable<Foo>(() => Foo(1));
      pot1.dispose();
      expect(() => pot1.replace(() => Foo(2)), throwsA(isA<StateError>()));
    });

    test('Thrown if replace() is called after pot is dispose', () {
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
