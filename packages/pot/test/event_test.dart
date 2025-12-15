// ignore_for_file: cascade_invocations

import 'dart:async';

import 'package:test/test.dart';

import 'package:pot/pot.dart';
import 'package:pot/src/private/static.dart';
import 'package:pot/src/private/utils.dart';

void main() {
  StreamController<PotEvent>? controller;
  final events = <PotEvent>[];

  setUp(() {
    PotManager.allInstances.clear();
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

  group('Converters', () {
    test('PotDescription.fromMap', () {
      final desc = PotDescription.fromMap(const {
        'identity': 'aaa',
        'isPending': false,
        'isDisposed': false,
        'hasObject': true,
        'object': null,
        'scope': 10,
      });

      expect(desc.identity, 'aaa');
      expect(desc.isPending, isFalse);
      expect(desc.isDisposed, isFalse);
      expect(desc.hasObject, isTrue);
      expect(desc.object, 'null');
      expect(desc.scope, 10);
    });

    test('PotDescription.toMap', () {
      final map = const PotDescription(
        identity: 'aaa',
        isPending: false,
        isDisposed: false,
        hasObject: true,
        object: 'null',
        scope: 10,
      ).toMap();

      expect(map['identity'], 'aaa');
      expect(map['isPending'], isFalse);
      expect(map['isDisposed'], isFalse);
      expect(map['hasObject'], isTrue);
      expect(map['object'], 'null');
      expect(map['scope'], 10);
    });

    test('PotEvent.fromMap', () {
      final now = DateTime.now();

      final event = PotEvent.fromMap({
        'number': 10,
        'kind': 'reset',
        'time': now.microsecondsSinceEpoch,
        'currentScope': 20,
        'potDescriptions': [
          {
            'identity': 'aaa',
            'isPending': true,
            'isDisposed': true,
            'hasObject': false,
            'object': 'bbb',
            'scope': 30,
          },
        ],
      });

      expect(event.number, 10);
      expect(event.kind, PotEventKind.reset);
      expect(event.time, now);
      expect(event.currentScope, 20);
      expect(event.potDescriptions.first.identity, 'aaa');
      expect(event.potDescriptions.first.object, 'bbb');
    });

    test('PotEvent.toMap', () {
      final now = DateTime.now();

      final map = PotEvent(
        number: 10,
        kind: PotEventKind.created,
        time: now,
        currentScope: 20,
        potDescriptions: const [
          PotDescription(
            identity: 'aaa',
            isPending: false,
            isDisposed: false,
            hasObject: true,
            object: 'bbb',
            scope: 30,
          ),
        ],
      ).toMap();

      expect(map['number'], 10);
      expect(map['kind'], 'created');
      expect(map['time'], now.microsecondsSinceEpoch);
      expect(map['currentScope'], 20);

      final descs = map['potDescriptions'] as List?;
      final desc = descs?.first as Map<String, Object?>?;
      expect(desc?['identity'], 'aaa');
      expect(desc?['object'], 'bbb');
    });
  });

  group('toString()', () {
    test('PotDescription.toString()', () {
      const desc = PotDescription(
        identity: 'aaa',
        isPending: false,
        isDisposed: false,
        hasObject: true,
        object: 'null',
        scope: 10,
      );

      expect(
        desc.toString(),
        'PotDescription(identity: aaa, isPending: false, isDisposed: false, '
        'hasObject: true, object: null, scope: 10)',
      );
    });

    test('PotEvent.toString()', () {
      final now = DateTime.now();
      const desc = PotDescription(
        identity: 'aaa',
        isPending: true,
        isDisposed: false,
        hasObject: false,
        object: 'bbb',
        scope: 30,
      );

      final event = PotEvent(
        number: 10,
        kind: PotEventKind.markedAsPending,
        time: now,
        currentScope: 20,
        potDescriptions: const [desc],
      );

      expect(
        event.toString(),
        'PotEvent(number: 10, kind: markedAsPending, time: $now, '
        'currentScope: 20, potDescriptions: [$desc])',
      );
    });
  });

  group('Equality and hash code', () {
    test('Two PotDescriptions with same values are equal', () {
      final pot1 = Pot(() => 1);
      expect(PotDescription.fromPot(pot1), PotDescription.fromPot(pot1));
    });

    test('Two PotDescriptions with same values have same hash code', () {
      final pot1 = Pot(() => 1);
      expect(
        PotDescription.fromPot(pot1).hashCode,
        PotDescription.fromPot(pot1).hashCode,
      );
    });
  });

  group('PotEvent data other than potDescription', () {
    test('number, time and currentScope', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final time1 = DateTime.now();
      Pot(() => 1);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      final time2 = DateTime.now();
      Pot.pushScope();

      await Future<void>.delayed(const Duration(milliseconds: 10));
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
        closeTo(time1.millisecondsSinceEpoch, 5),
      );
      expect(events[1].number, 2);
      expect(events[1].currentScope, 1);
      expect(
        events[1].time.millisecondsSinceEpoch,
        closeTo(time2.millisecondsSinceEpoch, 5),
      );
      expect(events[2].number, 3);
      expect(events[2].currentScope, 0);
      expect(
        events[2].time.millisecondsSinceEpoch,
        closeTo(time3.millisecondsSinceEpoch, 5),
      );
    });

    group('potDescription', () {
      test('identity', () async {
        final removeListener = Pot.listen(listener);
        addTearDown(removeListener);

        final pot = Pot(() => 1);

        await expectLater(
          controller?.stream,
          emitsInOrder([
            predicate<PotEvent>((v) => v.kind == PotEventKind.instantiated),
          ]),
        );

        expect(events, hasLength(1));
        expect(events[0].potDescriptions, hasLength(1));
        expect(events[0].potDescriptions[0].identity, pot.identity());
      });

      test('isPending', () async {
        final removeListener = Pot.listen(listener);
        addTearDown(removeListener);

        final pot = Pot.pending<int>();
        pot.replace(() => 1);
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

        Pot(() => 1);

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

        final pot = Pot(() => 1);
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

        expect(events, hasLength(5));
        expect(events[0].potDescriptions[0].hasObject, false);
        expect(events[0].potDescriptions[0].object, 'null');
        expect(events[1].potDescriptions[0].hasObject, false);
        expect(events[1].potDescriptions[0].object, 'null');
        expect(events[2].potDescriptions[0].hasObject, true);
        expect(events[2].potDescriptions[0].object, '1');
        expect(events[3].potDescriptions[0].hasObject, false);
        expect(events[3].potDescriptions[0].object, 'null');
        expect(events[4].potDescriptions[0].hasObject, false);
        expect(events[4].potDescriptions[0].object, 'null');
      });

      test('allPotDescriptions returns descriptions of all pots', () {
        final pot1 = Pot(() => 1);
        final pot2 = Pot.pending<int?>();

        final pots = PotManager.allInstances.keys;
        expect(pots.length, 2);

        final desc1 = PotDescription.fromPot(pots.elementAt(0));
        final desc2 = PotDescription.fromPot(pots.elementAt(1));
        expect(desc1.identity, pot1.identity());
        expect(desc1.isPending, isNull);
        expect(desc2.identity, pot2.identity());
        expect(desc2.isPending, isTrue);
      });
    });

    test('scope', () async {
      final removeListener = Pot.listen(listener);
      addTearDown(removeListener);

      final pot1 = Pot(() => 1);
      final pot2 = Pot(() => 1);
      final pot3 = Pot(() => 1);

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
