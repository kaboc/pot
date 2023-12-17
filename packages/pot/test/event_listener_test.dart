// ignore_for_file: cascade_invocations

import 'dart:async';

import 'package:test/test.dart';

import 'package:pot/pot.dart';

void main() {
  StreamController<PotEvent>? controller;
  var eventsCount = 0;

  setUp(() {
    controller = StreamController<PotEvent>();
  });
  tearDown(() {
    // Don't add `await` here. Future never completes in some cases.
    // ignore: discarded_futures
    controller?.close();
    controller = null;
    eventsCount = 0;
    Pot.resetAll();
  });

  void listener(PotEvent event) {
    controller?.sink.add(event);
    eventsCount++;
  }

  group('hasListener and isClosed', () {
    test(
      'Listening started and ended by listen() and returned callback',
      () async {
        expect(Pot.hasListener, isFalse);

        final removeListener = Pot.listen((_) {});
        expect(Pot.hasListener, isTrue);

        await removeListener();
        expect(Pot.hasListener, isFalse);
      },
    );

    test('StreamController is closed when all listeners are removed', () async {
      expect(Pot.$isEventControllerClosed, isTrue);

      final removeListener = Pot.listen((_) {});
      expect(Pot.$isEventControllerClosed, isFalse);

      await removeListener();
      expect(Pot.$isEventControllerClosed, isTrue);
    });
  });

  group('Methods other than those for scoping', () {
    test('dispose() without create()', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 10, disposer: (_) {});
      pot.dispose();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.disposed),
        ]),
      );
      expect(eventsCount, 2);
    });

    test('create() and dispose() when pot has no disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 10);
      pot.create();
      pot.dispose();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.addedToScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.created),
          predicate<PotEvent>((v) => v.kind == PotEventKind.removedFromScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.reset),
          predicate<PotEvent>((v) => v.kind == PotEventKind.disposed),
        ]),
      );
      expect(eventsCount, 6);
    });

    test('create() and dispose() when pot has disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 10, disposer: (_) {});
      pot.create();
      pot.dispose();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.addedToScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.created),
          predicate<PotEvent>((v) => v.kind == PotEventKind.disposerCalled),
          predicate<PotEvent>((v) => v.kind == PotEventKind.removedFromScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.reset),
          predicate<PotEvent>((v) => v.kind == PotEventKind.disposed),
        ]),
      );
      expect(eventsCount, 7);
    });

    test('reset() without create()', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 10, disposer: (_) {});
      pot.reset();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
        ]),
      );
      expect(eventsCount, 1);
    });

    test('create() and reset() when pot has no disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 10);
      pot.create();
      pot.reset();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.addedToScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.created),
          predicate<PotEvent>((v) => v.kind == PotEventKind.removedFromScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.reset),
        ]),
      );
      expect(eventsCount, 5);
    });

    test('create() and reset() when pot has disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 10, disposer: (_) {});
      pot.create();
      pot.reset();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.addedToScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.created),
          predicate<PotEvent>((v) => v.kind == PotEventKind.disposerCalled),
          predicate<PotEvent>((v) => v.kind == PotEventKind.removedFromScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.reset),
        ]),
      );
      expect(eventsCount, 6);
    });

    test('replace() without create()', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot.replaceable(() => 10, disposer: (_) {});
      pot.replace(() => 20);

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.replaced),
        ]),
      );
      expect(eventsCount, 2);
    });

    test('replace() when pot has no disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot.replaceable(() => 10);
      pot.create();
      pot.replace(() => 20);

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.addedToScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.created),
          predicate<PotEvent>((v) => v.kind == PotEventKind.replaced),
        ]),
      );
      expect(eventsCount, 4);
    });

    test('replace() when pot has disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot.replaceable(() => 10, disposer: (_) {});
      pot.create();
      pot.replace(() => 20);

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.addedToScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.created),
          predicate<PotEvent>((v) => v.kind == PotEventKind.disposerCalled),
          predicate<PotEvent>((v) => v.kind == PotEventKind.replaced),
        ]),
      );
      expect(eventsCount, 5);
    });

    test('resetAsPending() without create()', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot.replaceable(() => 10, disposer: (_) {});
      pot.resetAsPending();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.markedAsPending),
        ]),
      );
      expect(eventsCount, 2);
    });

    test('resetAsPending() when pot has no disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot.replaceable(() => 10);
      pot.create();
      pot.resetAsPending();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.addedToScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.created),
          predicate<PotEvent>((v) => v.kind == PotEventKind.removedFromScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.reset),
          predicate<PotEvent>((v) => v.kind == PotEventKind.markedAsPending),
        ]),
      );
      expect(eventsCount, 6);
    });

    test('resetAsPending() when pot has disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot.replaceable(() => 10, disposer: (_) {});
      pot.create();
      pot.resetAsPending();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.addedToScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.created),
          predicate<PotEvent>((v) => v.kind == PotEventKind.disposerCalled),
          predicate<PotEvent>((v) => v.kind == PotEventKind.removedFromScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.reset),
          predicate<PotEvent>((v) => v.kind == PotEventKind.markedAsPending),
        ]),
      );
      expect(eventsCount, 7);
    });
  });

  group('Scoping', () {
    test('pushScope() without create()', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      Pot(() => 10);
      Pot.pushScope();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.scopePushed),
        ]),
      );
      expect(eventsCount, 2);
    });

    test('create() and pushScope()', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 10);
      pot.create();
      Pot.pushScope();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.addedToScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.created),
          predicate<PotEvent>((v) => v.kind == PotEventKind.scopePushed),
        ]),
      );
      expect(eventsCount, 4);
    });

    test('pushScope() and create()', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 10);
      Pot.pushScope();
      pot.create();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.scopePushed),
          predicate<PotEvent>((v) => v.kind == PotEventKind.addedToScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.created),
        ]),
      );
      expect(eventsCount, 4);
    });

    test('popScope() without create()', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      Pot(() => 10);
      Pot.popScope();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.scopePopped),
        ]),
      );
      expect(eventsCount, 2);
    });

    test('create() and popScope()', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 10);
      pot.create();
      Pot.popScope();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.addedToScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.created),
          predicate<PotEvent>((v) => v.kind == PotEventKind.removedFromScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.reset),
          predicate<PotEvent>((v) => v.kind == PotEventKind.scopePopped),
        ]),
      );
      expect(eventsCount, 6);
    });

    test('pushScope(), create() and then popScope()', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 10);
      Pot.pushScope();
      pot.create();
      Pot.popScope();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.scopePushed),
          predicate<PotEvent>((v) => v.kind == PotEventKind.addedToScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.created),
          predicate<PotEvent>((v) => v.kind == PotEventKind.removedFromScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.reset),
          predicate<PotEvent>((v) => v.kind == PotEventKind.scopePopped),
        ]),
      );
      expect(eventsCount, 7);
    });
  });

  group('Emitting an object event', () {
    test('notifyObjectUpdate()', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot.replaceable(() => 10, disposer: (_) {});
      pot.notifyObjectUpdate();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.objectUpdated),
        ]),
      );
      expect(eventsCount, 2);
    });
  });
}
