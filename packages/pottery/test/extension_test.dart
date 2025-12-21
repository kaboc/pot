import 'dart:convert' show jsonEncode;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pot/src/private/static.dart';
import 'package:pot/src/private/utils.dart';

import 'package:pottery/pottery.dart';
import 'package:pottery/src/extension/extension_manager.dart';
import 'package:pottery/src/utils.dart';

import 'spy_communicator.dart';
import 'utils.dart';

class Foo {
  Foo([this.value]);
  int? value;

  @override
  String toString() => 'Foo($value)';
}

void main() {
  late PotteryExtensionManager extensionManager;
  late SpyExtensionCommunicator communicator;

  ReplaceablePot<int>? pot1;
  ReplaceablePot<int>? pot2;
  ReplaceablePot<Foo>? fooPot;

  setUp(() {
    communicator = SpyExtensionCommunicator();
    PotteryExtensionManager.setCommunicator(communicator);
    extensionManager = PotteryExtensionManager.createSingle();
  });
  tearDown(() {
    extensionManager.dispose();
    communicator.dispose();

    pot1?.dispose();
    pot2?.dispose();
    fooPot?.dispose();
    pot1 = pot2 = fooPot = null;
  });

  group('Initialization', () {
    test('"pottery:initialize" event is posted on initialization', () {
      expect(communicator.log, hasLength(1));
      expect(communicator.log[0], ('pottery:initialize', '{}'));
    });

    test('Calling createSingle() many times does not create new manager', () {
      final extensionManager2 = PotteryExtensionManager.createSingle();
      expect(extensionManager2, extensionManager);
      expect(communicator.log, hasLength(1));
      expect(communicator.log[0], ('pottery:initialize', '{}'));
    });

    test('startExtension()', () {
      expect(communicator.log, hasLength(1));

      extensionManager.dispose();
      communicator.dispose();
      expect(communicator.log, isEmpty);

      communicator = SpyExtensionCommunicator();
      PotteryExtensionManager.setCommunicator(communicator);
      Pottery.startExtension();
      addTearDown(() {
        // Gets existing instance and calls dispose() on it.
        PotteryExtensionManager.createSingle().dispose();
      });

      expect(communicator.log, hasLength(1));
      expect(communicator.log[0], ('pottery:initialize', '{}'));
    });
  });

  group('Scoping of package:pot', () {
    testWidgets('Events related to scoping is ignored', (tester) async {
      final events = <PotEventKind>[];
      final listenerRemover = Pot.listen((event) => events.add(event.kind));
      addTearDown(listenerRemover);

      pot1 = Pot.replaceable(() => 10);
      Pot.pushScope();

      await tester.pump();

      expect(events, [PotEventKind.instantiated, PotEventKind.scopePushed]);
      expect(communicator.log, hasLength(2));
      expect(communicator.log[0], ('pottery:initialize', '{}'));
      expect(communicator.log[1], logContainsEvent('instantiated'));
    });
  });

  group('Response to request from extension', () {
    testWidgets(
      '"ext.pottery.getPots" responses with correct data',
      (tester) async {
        pot1 = Pot.pending();
        pot2 = Pot.pending();

        await tester.pump();

        expect(communicator.log, hasLength(3));
        expect(communicator.log[0], ('pottery:initialize', '{}'));
        expect(
          communicator.log[1],
          logContainsEvent('instantiated', identity: pot1!.identity()),
        );
        expect(
          communicator.log[2],
          logContainsEvent('instantiated', identity: pot2!.identity()),
        );

        communicator.request('ext.pottery.getPots');

        expect(communicator.log, hasLength(4));
        expect(
          communicator.log[3],
          (
            'ext.pottery.getPots',
            jsonEncode({
              pot1!.identity(): {
                'time': StaticPot.allInstances[pot1]!.microsecondsSinceEpoch,
                'potDescription': PotDescription.fromPot(pot1!).toMap(),
              },
              pot2!.identity(): {
                'time': StaticPot.allInstances[pot2]!.microsecondsSinceEpoch,
                'potDescription': PotDescription.fromPot(pot2!).toMap(),
              },
            }),
          ),
        );
      },
    );

    testWidgets(
      '"ext.pottery.getPotteries" responses with correct data',
      (tester) async {
        pot1 = Pot.pending<int>();
        pot2 = Pot.pending<int>();

        await tester.pumpWidget(
          Pottery(
            pots: {
              pot1!: () => 10,
              pot2!: () => 20,
            },
            builder: (context) {
              pot1!.create();
              pot2!.create();
              return const SizedBox.shrink();
            },
          ),
        );

        final desc1 = PotDescription.fromPot(pot1!);
        final desc2 = PotDescription.fromPot(pot2!);
        expect(desc1.object, '10');
        expect(desc2.object, '20');

        expect(communicator.log, hasLength(8));
        expect(communicator.log[0], ('pottery:initialize', '{}'));
        expect(communicator.log[1], logContainsEvent('instantiated'));
        expect(communicator.log[2], logContainsEvent('instantiated'));
        expect(communicator.log[3], logContainsEvent('potteryCreated'));
        expect(communicator.log[4], logContainsEvent('replaced'));
        expect(communicator.log[5], logContainsEvent('replaced'));
        expect(communicator.log[6], logContainsEvent('created'));
        expect(communicator.log[7], logContainsEvent('created'));

        communicator.request('ext.pottery.getPotteries');

        expect(communicator.log, hasLength(9));
        expect(
          communicator.log[8],
          (
            'ext.pottery.getPotteries',
            jsonEncode({
              for (final (state, data) in extensionManager.potteries.records)
                state.widgetIdentity(): {
                  'time': data.time.microsecondsSinceEpoch,
                  'potDescriptions': [
                    desc1.toMap(),
                    desc2.toMap(),
                  ],
                },
            }),
          ),
        );
      },
    );

    testWidgets(
      '"ext.pottery.getLocalPotteries" responses with correct data',
      (tester) async {
        pot1 = Pot.pending<int>();
        pot2 = Pot.pending<int>();

        await tester.pumpWidget(
          LocalPottery(
            pots: {
              pot1!: () => 10,
              pot2!: () => 20,
            },
            builder: (context) => const SizedBox.shrink(),
          ),
        );

        expect(communicator.log, hasLength(4));
        expect(communicator.log[0], ('pottery:initialize', '{}'));
        expect(communicator.log[1], logContainsEvent('instantiated'));
        expect(communicator.log[2], logContainsEvent('instantiated'));
        expect(communicator.log[3], logContainsEvent('localPotteryCreated'));

        communicator.request('ext.pottery.getLocalPotteries');

        expect(communicator.log, hasLength(5));
        expect(
          communicator.log[4],
          (
            'ext.pottery.getLocalPotteries',
            jsonEncode({
              for (final (state, data)
                  in extensionManager.localPotteries.records)
                state.widgetIdentity(): {
                  'time': data.time.microsecondsSinceEpoch,
                  'objects': [
                    {
                      'potIdentity': pot1!.identity(),
                      'object': '10',
                    },
                    {
                      'potIdentity': pot2!.identity(),
                      'object': '20',
                    },
                  ],
                },
            }),
          ),
        );
      },
    );

    testWidgets(
      'Response reflects updates of pot after creation of Pottery',
      (tester) async {
        fooPot = Pot.pending<Foo>();

        await tester.pumpWidget(
          Pottery(
            pots: {
              fooPot!: () => Foo(20),
            },
            builder: (context) {
              fooPot!().value = 30;
              return const SizedBox.shrink();
            },
          ),
        );

        final desc = PotDescription.fromPot(fooPot!);
        expect(desc.object, 'Foo(30)');

        expect(communicator.log, hasLength(5));
        expect(communicator.log[0], ('pottery:initialize', '{}'));
        expect(communicator.log[1], logContainsEvent('instantiated'));
        expect(communicator.log[2], logContainsEvent('potteryCreated'));
        expect(communicator.log[3], logContainsEvent('replaced'));
        expect(communicator.log[4], logContainsEvent('created'));

        communicator.request('ext.pottery.getPotteries');

        expect(communicator.log, hasLength(6));
        expect(
          communicator.log[5],
          (
            'ext.pottery.getPotteries',
            jsonEncode({
              for (final (state, data) in extensionManager.potteries.records)
                state.widgetIdentity(): {
                  'time': data.time.microsecondsSinceEpoch,
                  'potDescriptions': [desc.toMap()],
                },
            }),
          ),
        );
      },
    );

    testWidgets(
      'Response reflects updates of pot after creation of LocalPottery',
      (tester) async {
        fooPot = Pot.pending<Foo>();

        await tester.pumpWidget(
          LocalPottery(
            pots: {
              fooPot!: () => Foo(20),
            },
            builder: (context) {
              fooPot!.of(context).value = 30;
              return const SizedBox.shrink();
            },
          ),
        );

        expect(communicator.log, hasLength(3));
        expect(communicator.log[0], ('pottery:initialize', '{}'));
        expect(communicator.log[1], logContainsEvent('instantiated'));
        expect(communicator.log[2], logContainsEvent('localPotteryCreated'));

        communicator.request('ext.pottery.getLocalPotteries');

        expect(communicator.log, hasLength(4));
        expect(
          communicator.log[3],
          (
            'ext.pottery.getLocalPotteries',
            jsonEncode({
              for (final (state, data)
                  in extensionManager.localPotteries.records)
                state.widgetIdentity(): {
                  'time': data.time.microsecondsSinceEpoch,
                  'objects': [
                    {
                      'potIdentity': fooPot!.identity(),
                      'object': 'Foo(30)',
                    },
                  ],
                },
            }),
          ),
        );
      },
    );
  });
}
