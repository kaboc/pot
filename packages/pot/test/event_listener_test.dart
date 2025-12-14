// ignore_for_file: cascade_invocations

import 'dart:async';

import 'package:test/test.dart';

import 'package:pot/pot.dart';
import 'package:pot/src/private/static.dart';

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
    Pot.resetAll(keepScopes: false);
  });

  void listener(PotEvent event) {
    controller?.sink.add(event);
    eventsCount++;
  }

  group('hasListener and isClosed', () {
    test(
      'Calling listen() adds listener and calling returned callback '
      'removes listener',
      () async {
        expect(Pot.hasListener, isFalse);

        final removeListener = Pot.listen((_) {});
        expect(Pot.hasListener, isTrue);

        await removeListener();
        expect(Pot.hasListener, isFalse);
      },
    );

    test('StreamController is closed when all listeners are removed', () async {
      expect(PotManager.eventHandler.isClosed, isTrue);

      final removeListener = Pot.listen((_) {});
      expect(PotManager.eventHandler.isClosed, isFalse);

      await removeListener();
      expect(PotManager.eventHandler.isClosed, isTrue);
    });
  });

  group('Methods other than those for scoping', () {
    test('Calling dispose() without creating object', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 1, disposer: (_) {});
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

    test('Calling create() and dispose() when pot has no disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 1);
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

    test('Calling create() and dispose() when pot has disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 1, disposer: (_) {});
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

    test('Calling reset() without creating object', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 1, disposer: (_) {});
      pot.reset();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
        ]),
      );
      expect(eventsCount, 1);
    });

    test('Calling create() and reset() when pot has no disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 1);
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

    test('Calling create() and reset() when pot has disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 1, disposer: (_) {});
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

    test('Calling replace() without creating object', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot.replaceable(() => 1, disposer: (_) {});
      pot.replace(() => 2);

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.replaced),
        ]),
      );
      expect(eventsCount, 2);
    });

    test('Calling replace() when pot has no disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot.replaceable(() => 1);
      pot.create();
      pot.replace(() => 2);

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

    test('Calling replace() when pot has disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot.replaceable(() => 1, disposer: (_) {});
      pot.create();
      pot.replace(() => 2);

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

    test('Calling resetAsPending() without creating object', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot.replaceable(() => 1, disposer: (_) {});
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

    test('Calling resetAsPending() when pot has no disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot.replaceable(() => 1);
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

    test('Calling resetAsPending() when pot has disposer', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot.replaceable(() => 1, disposer: (_) {});
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
    test('Calling pushScope() without creating object', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      Pot(() => 1);
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

    test('Calling create() and pushScope()', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 1);
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

    test('Calling pushScope() and create()', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 1);
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

    test('Calling popScope() without creating object', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      Pot(() => 1);
      Pot.popScope();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.scopeCleared),
        ]),
      );
      expect(eventsCount, 2);
    });

    test('Calling create() and popScope()', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 1);
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
          predicate<PotEvent>((v) => v.kind == PotEventKind.scopeCleared),
        ]),
      );
      expect(eventsCount, 6);
    });

    test('Calling pushScope(), create() and then popScope()', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot = Pot(() => 1);
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

      final pot = Pot.replaceable(() => 1, disposer: (_) {});
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
