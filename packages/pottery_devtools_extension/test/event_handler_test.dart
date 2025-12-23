import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:pot/src/private/utils.dart';
import 'package:pottery/pottery.dart';
import 'package:pottery/src/extension/extension_manager.dart';
import 'package:pottery/src/utils.dart';

import 'package:pottery_devtools_extension/src/event_handler.dart';

import 'fake.dart';

const _kFetchingDebounceDuration = Duration(milliseconds: 50);

void main() {
  late PotteryExtensionManager extensionManager;
  late FakeExtensionCommunicator communicator;

  late PotteryEventHandler eventHandler;
  late FakeServiceManager serviceManager;

  ReplaceablePot<int>? pot1;
  ReplaceablePot<int>? pot2;
  ReplaceablePot<int>? pot3;

  setUp(() {
    serviceManager = FakeServiceManager();
    eventHandler = PotteryEventHandler(
      serviceManager: serviceManager,
      fetchingDebounceDuration: _kFetchingDebounceDuration,
    );

    communicator = FakeExtensionCommunicator();
    PotteryExtensionManager.setCommunicator(communicator);
    extensionManager = PotteryExtensionManager.createSingle();
  });
  tearDown(() async {
    await eventHandler.dispose();
    serviceManager.dispose();

    extensionManager.dispose();
    communicator.dispose();
    await Future<void>.delayed(Duration.zero);

    pot1?.dispose();
    pot1 = null;
    pot2?.dispose();
    pot2 = null;
    pot3?.dispose();
    pot3 = null;
  });

  group('pottery:initialize', () {
    test(
      'Creating new PotteryExtensionManager posts initialize event, '
      'causing all data to be cleared',
      () async {
        pot1 = Pot.pending();

        eventHandler.potsNotifier.value = {
          pot1!.identity(): (
            time: DateTime.now(),
            description: PotDescription.fromPot(pot1!),
          ),
        };
        eventHandler.potteriesNotifier.value = {
          'dummy': (
            time: DateTime.now(),
            potDescriptions: [PotDescription.fromPot(pot1!)],
          ),
        };
        eventHandler.localPotteriesNotifier.value = {
          'dummy': (
            time: DateTime.now(),
            objects: [(potIdentity: pot1!.identity(), object: '')],
          ),
        };
        eventHandler.potEventsNotifier.value = [
          PotEvent(
            number: 1,
            kind: PotEventKind.instantiated,
            time: DateTime.now(),
            currentScope: 1,
            potDescriptions: [PotDescription.fromPot(pot1!)],
          ),
        ];

        expect(eventHandler.potsNotifier.value, isNotEmpty);
        expect(eventHandler.potteriesNotifier.value, isNotEmpty);
        expect(eventHandler.localPotteriesNotifier.value, isNotEmpty);
        expect(eventHandler.potEventsNotifier.value, isNotEmpty);

        extensionManager.dispose();
        PotteryExtensionManager.setCommunicator(communicator);
        extensionManager = PotteryExtensionManager.createSingle();
        await Future<void>.delayed(Duration.zero);

        expect(eventHandler.potsNotifier.value, isEmpty);
        expect(eventHandler.potteriesNotifier.value, isEmpty);
        expect(eventHandler.localPotteriesNotifier.value, isEmpty);
        expect(eventHandler.potEventsNotifier.value, isEmpty);
      },
    );
  });

  group('pottery:pot_event', () {
    test('Pot events are stored in potEventsNotifier', () async {
      pot1 = Pot.replaceable(() => 10);
      await Future<void>.delayed(Duration.zero);

      final potEvents = eventHandler.potEventsNotifier.value;
      expect(potEvents, hasLength(1));
      expect(potEvents[0].kind, PotEventKind.instantiated);
      expect(potEvents[0].potDescriptions[0], PotDescription.fromPot(pot1!));
    });

    test('clearEvents() clears data in potEventsNotifier', () async {
      pot1 = Pot.replaceable(() => 10);
      await Future<void>.delayed(Duration.zero);
      expect(eventHandler.potEventsNotifier.value, hasLength(1));

      eventHandler.clearEvents();
      expect(eventHandler.potEventsNotifier.value, isEmpty);
    });
  });

  group('ext.pottery.getPots', () {
    test('Fetching of Pots triggered by events are debounced', () async {
      pot1 = Pot.replaceable(() => 10);

      await Future<void>.delayed(
        Duration(milliseconds: _kFetchingDebounceDuration.inMilliseconds ~/ 2),
      );
      expect(eventHandler.potsNotifier.value, isEmpty);

      pot2 = Pot.replaceable(() => 20);

      await Future<void>.delayed(
        _kFetchingDebounceDuration - const Duration(milliseconds: 10),
      );
      expect(eventHandler.potsNotifier.value, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(eventHandler.potsNotifier.value, hasLength(2));
    });

    test('getPots()', () async {
      pot1 = Pot.replaceable(() => 10);
      pot2 = Pot.replaceable(() => 20);

      await Future<void>.delayed(
        _kFetchingDebounceDuration + const Duration(milliseconds: 10),
      );
      expect(eventHandler.potsNotifier.value, hasLength(2));

      eventHandler.potsNotifier.value = {};
      expect(eventHandler.potsNotifier.value, isEmpty);

      await eventHandler.getPots();

      final data = eventHandler.potsNotifier.value;
      expect(data, hasLength(2));
      expect(data.values.first.description, PotDescription.fromPot(pot1!));
      expect(data.values.last.description, PotDescription.fromPot(pot2!));
    });
  });

  group('ext.pottery.getPotteries', () {
    testWidgets(
      'Fetching of LocalPotteries triggered by events are debounced',
      (tester) async {
        pot1 = Pot.pending();

        await tester.pumpWidget(
          Pottery(
            pots: {pot1!: () => 10},
            builder: (context) => const SizedBox.shrink(),
          ),
        );

        await tester.runAsync(() async {
          await Future<void>.delayed(
            Duration(
              milliseconds: _kFetchingDebounceDuration.inMilliseconds ~/ 2,
            ),
          );
          expect(eventHandler.potteriesNotifier.value, isEmpty);

          pot2 = Pot.pending();

          await Future<void>.delayed(
            _kFetchingDebounceDuration - const Duration(milliseconds: 10),
          );
          expect(eventHandler.potteriesNotifier.value, isEmpty);

          await Future<void>.delayed(const Duration(milliseconds: 20));
          expect(eventHandler.potteriesNotifier.value, hasLength(1));
        });
      },
    );

    testWidgets('getPotteries()', (tester) async {
      pot1 = Pot.pending();
      pot2 = Pot.pending();
      pot3 = Pot.pending();

      await tester.pumpWidget(
        Column(
          children: [
            Pottery(
              pots: {
                pot1!: () => 10,
                pot2!: () => 20,
              },
              builder: (context) => const SizedBox.shrink(),
            ),
            Pottery(
              pots: {
                pot3!: () => 30,
              },
              builder: (context) => const SizedBox.shrink(),
            ),
          ],
        ),
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(
          _kFetchingDebounceDuration + const Duration(milliseconds: 10),
        );
      });
      expect(eventHandler.potteriesNotifier.value, hasLength(2));

      eventHandler.potteriesNotifier.value = {};
      expect(eventHandler.potteriesNotifier.value, isEmpty);

      await eventHandler.getPotteries();

      final potteryFinder = find.byType(Pottery).evaluate();
      final pottery1 = potteryFinder.first.widget;
      final pottery2 = potteryFinder.last.widget;
      final data = eventHandler.potteriesNotifier.value;

      expect(data, hasLength(2));
      expect(
        data['Pottery#${pottery1.shortHash()}']?.potDescriptions,
        [PotDescription.fromPot(pot1!), PotDescription.fromPot(pot2!)],
      );
      expect(
        data['Pottery#${pottery2.shortHash()}']?.potDescriptions,
        [PotDescription.fromPot(pot3!)],
      );
    });
  });

  group('ext.pottery.getLocalPotteries', () {
    testWidgets(
      'Fetching of LocalPotteries triggered by events are debounced',
      (tester) async {
        pot1 = Pot.pending();

        await tester.pumpWidget(
          LocalPottery(
            pots: {pot1!: () => 10},
            builder: (context) => const SizedBox.shrink(),
          ),
        );

        await tester.runAsync(() async {
          await Future<void>.delayed(
            Duration(
              milliseconds: _kFetchingDebounceDuration.inMilliseconds ~/ 2,
            ),
          );
          expect(eventHandler.localPotteriesNotifier.value, isEmpty);

          pot2 = Pot.pending();

          await Future<void>.delayed(
            _kFetchingDebounceDuration - const Duration(milliseconds: 10),
          );
          expect(eventHandler.localPotteriesNotifier.value, isEmpty);

          await Future<void>.delayed(const Duration(milliseconds: 20));
          expect(eventHandler.localPotteriesNotifier.value, hasLength(1));
        });
      },
    );

    testWidgets('getLocalPotteries()', (tester) async {
      pot1 = Pot.pending();
      pot2 = Pot.pending();
      pot3 = Pot.pending();

      await tester.pumpWidget(
        Column(
          children: [
            LocalPottery(
              pots: {
                pot1!: () => 10,
                pot2!: () => 20,
              },
              builder: (context) => const SizedBox.shrink(),
            ),
            LocalPottery(
              pots: {
                pot3!: () => 30,
              },
              builder: (context) => const SizedBox.shrink(),
            ),
          ],
        ),
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(
          _kFetchingDebounceDuration + const Duration(milliseconds: 10),
        );
      });
      expect(eventHandler.localPotteriesNotifier.value, hasLength(2));

      eventHandler.localPotteriesNotifier.value = {};
      expect(eventHandler.localPotteriesNotifier.value, isEmpty);

      await eventHandler.getLocalPotteries();

      final localPotteryFinder = find.byType(LocalPottery).evaluate();
      final localPottery1 = localPotteryFinder.first.widget;
      final localPottery2 = localPotteryFinder.last.widget;
      final data = eventHandler.localPotteriesNotifier.value;

      expect(data, hasLength(2));
      expect(
        data['LocalPottery#${localPottery1.shortHash()}']?.objects,
        [
          (potIdentity: pot1!.identity(), object: '10'),
          (potIdentity: pot2!.identity(), object: '20'),
        ],
      );
      expect(
        data['LocalPottery#${localPottery2.shortHash()}']?.objects,
        [
          (potIdentity: pot3!.identity(), object: '30'),
        ],
      );
    });
  });
}
