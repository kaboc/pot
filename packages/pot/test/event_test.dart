// ignore_for_file: cascade_invocations

import 'dart:async';

import 'package:test/test.dart';

import 'package:pot/pot.dart';

void main() {
  StreamController<PotEvent>? controller;
  final events = <PotEvent>[];

  setUp(() {
    controller = StreamController<PotEvent>();
  });
  tearDown(() {
    // Future never completes in some cases if `await` is added here.
    // ignore: discarded_futures
    controller?.close();
    controller = null;
    events.clear();
    Pot.resetAll(keepScopes: false);
  });

  void listener(PotEvent event) {
    controller?.sink.add(event);
    events.add(event);
  }

  group('Getter and method', () {
    test('isScopeEvent', () {
      expect(PotEventKind.unknown.isScopeEvent, isFalse);
      expect(PotEventKind.instantiated.isScopeEvent, isFalse);
      expect(PotEventKind.scopePushed.isScopeEvent, isTrue);
      expect(PotEventKind.scopeCleared.isScopeEvent, isTrue);
      expect(PotEventKind.scopePopped.isScopeEvent, isTrue);
      expect(PotEventKind.addedToScope.isScopeEvent, isTrue);
      expect(PotEventKind.removedFromScope.isScopeEvent, isTrue);
    });
  });

  group('PotEvent data other than potDescription', () {
    test('number, time and currentScope', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final time1 = DateTime.now();
      Pot(() => 10);

      await Future<void>.delayed(const Duration(milliseconds: 5));
      final time2 = DateTime.now();
      Pot.pushScope();

      await Future<void>.delayed(const Duration(milliseconds: 5));
      final time3 = DateTime.now();
      Pot.popScope();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.scopePushed),
          predicate<PotEvent>((v) => v.kind == PotEventKind.scopePopped),
        ]),
      );

      expect(events, hasLength(3));
      expect(events[0].number, 1);
      expect(events[0].currentScope, 0);
      expect(
        events[0].time.millisecondsSinceEpoch,
        closeTo(time1.millisecondsSinceEpoch, 3),
      );
      expect(events[1].number, 2);
      expect(events[1].currentScope, 1);
      expect(
        events[1].time.millisecondsSinceEpoch,
        closeTo(time2.millisecondsSinceEpoch, 3),
      );
      expect(events[2].number, 3);
      expect(events[2].currentScope, 0);
      expect(
        events[2].time.millisecondsSinceEpoch,
        closeTo(time3.millisecondsSinceEpoch, 3),
      );
    });

    group('potDescription', () {
      test('identity', () async {
        final removeListener = Pot.listen(listener);
        addTearDown(removeListener);

        final pot = Pot(() => 10);

        await expectLater(
          controller?.stream,
          emitsInOrder([
            predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          ]),
        );

        expect(events, hasLength(1));
        expect(events[0].potDescriptions, hasLength(1));
        expect(events[0].potDescriptions[0].identity, pot.$identity());
      });

      test('isPending', () async {
        final removeListener = Pot.listen(listener);
        addTearDown(removeListener);

        final pot = Pot.pending<int>();
        pot.replace(() => 10);
        pot.resetAsPending();

        await expectLater(
          controller?.stream,
          emitsInOrder([
            predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
            predicate<PotEvent>((v) => v.kind == PotEventKind.replaced),
            predicate<PotEvent>((v) => v.kind == PotEventKind.markedAsPending),
          ]),
        );

        expect(events, hasLength(3));
        expect(events[0].potDescriptions[0].isPending, isTrue);
        expect(events[1].potDescriptions[0].isPending, isFalse);
        expect(events[2].potDescriptions[0].isPending, isTrue);
      });

      test('isPending is null if pot is not of type ReplaceablePot', () async {
        final removeListener = Pot.listen(listener);
        addTearDown(removeListener);

        Pot(() => 10);

        await expectLater(
          controller?.stream,
          emitsInOrder([
            predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          ]),
        );

        expect(events, hasLength(1));
        expect(events[0].potDescriptions[0].isPending, isNull);
      });

      test('isDisposed', () async {
        final removeListener = Pot.listen(listener);
        addTearDown(removeListener);

        final pot = Pot(() => 10);
        pot.dispose();

        await expectLater(
          controller?.stream,
          emitsInOrder([
            predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
            predicate<PotEvent>((v) => v.kind == PotEventKind.disposed),
          ]),
        );

        expect(events, hasLength(2));
        expect(events[0].potDescriptions[0].isDisposed, isFalse);
        expect(events[1].potDescriptions[0].isDisposed, isTrue);
      });

      test('hasObject and object', () async {
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

        expect(events, hasLength(5));
        expect(events[0].potDescriptions[0].hasObject, false);
        expect(events[0].potDescriptions[0].object, 'null');
        expect(events[1].potDescriptions[0].hasObject, false);
        expect(events[1].potDescriptions[0].object, 'null');
        expect(events[2].potDescriptions[0].hasObject, true);
        expect(events[2].potDescriptions[0].object, '10');
        expect(events[3].potDescriptions[0].hasObject, false);
        expect(events[3].potDescriptions[0].object, 'null');
        expect(events[4].potDescriptions[0].hasObject, false);
        expect(events[4].potDescriptions[0].object, 'null');
      });

      test('allPotDescriptions returns descriptions of all pots', () {
        final prevLen = Pot.$allPotDescriptions.length;

        final pot1 = Pot(() => 10);
        final pot2 = Pot.pending<int?>();

        final descs = Pot.$allPotDescriptions.keys;
        final len = descs.length;

        expect(len - prevLen, 2);
        expect(descs.elementAt(len - 2).identity, pot1.$identity());
        expect(descs.elementAt(len - 2).isPending, isNull);
        expect(descs.elementAt(len - 1).identity, pot2.$identity());
        expect(descs.elementAt(len - 1).isPending, isTrue);
      });
    });

    test('scope', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot1 = Pot(() => 10);
      final pot2 = Pot(() => 10);
      final pot3 = Pot(() => 10);
      pot1.create();
      Pot.pushScope();
      pot2.create();
      pot3.create();
      Pot.resetAllInScope();
      Pot.popScope();
      Pot.resetAllInScope();

      await expectLater(
        controller?.stream,
        emitsInOrder([
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          predicate<PotEvent>((v) => v.kind == PotEventKind.addedToScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.created),
          predicate<PotEvent>((v) => v.kind == PotEventKind.scopePushed),
          predicate<PotEvent>((v) => v.kind == PotEventKind.addedToScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.created),
          predicate<PotEvent>((v) => v.kind == PotEventKind.addedToScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.created),
          predicate<PotEvent>((v) => v.kind == PotEventKind.removedFromScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.reset),
          predicate<PotEvent>((v) => v.kind == PotEventKind.removedFromScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.reset),
          predicate<PotEvent>((v) => v.kind == PotEventKind.scopeCleared),
          predicate<PotEvent>((v) => v.kind == PotEventKind.scopePopped),
          predicate<PotEvent>((v) => v.kind == PotEventKind.removedFromScope),
          predicate<PotEvent>((v) => v.kind == PotEventKind.reset),
          predicate<PotEvent>((v) => v.kind == PotEventKind.scopeCleared),
        ]),
      );

      expect(events, hasLength(19));
      expect(events[0].potDescriptions[0].scope, null);
      expect(events[1].potDescriptions[0].scope, null);
      expect(events[2].potDescriptions[0].scope, null);
      expect(events[3].potDescriptions[0].scope, 0);
      expect(events[4].potDescriptions[0].scope, 0);
      expect(events[5].potDescriptions, isEmpty);
      expect(events[6].potDescriptions[0].scope, 1);
      expect(events[7].potDescriptions[0].scope, 1);
      expect(events[8].potDescriptions[0].scope, 1);
      expect(events[9].potDescriptions[0].scope, 1);
      expect(events[10].potDescriptions[0].scope, null);
      expect(events[11].potDescriptions[0].scope, null);
      expect(events[12].potDescriptions[0].scope, null);
      expect(events[13].potDescriptions[0].scope, null);
      expect(events[14].potDescriptions, isEmpty);
      expect(events[15].potDescriptions, isEmpty);
      expect(events[16].potDescriptions[0].scope, null);
      expect(events[17].potDescriptions[0].scope, null);
      expect(events[18].potDescriptions, isEmpty);
    });
  });
}
