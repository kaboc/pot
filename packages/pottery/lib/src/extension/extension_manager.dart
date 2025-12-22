// ignore: lines_longer_than_80_chars
// ignore_for_file: implementation_imports, library_private_types_in_public_api, public_member_api_docs

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show State;

import 'package:pot/pot.dart';
import 'package:pot/src/private/static.dart';
import 'package:pot/src/private/utils.dart';

import '../local_pottery.dart';
import '../pottery.dart';
import '../utils.dart';
import 'communicator.dart';

typedef _Pots = Iterable<Pot<Object?>>;
typedef _Potteries = Map<State<Pottery>, ({DateTime time, _Pots pots})>;
typedef _LocalPotteries = Map<State<LocalPottery>,
    ({DateTime time, List<({Pot<Object?> pot, Object? localObject})> list})>;

class PotteryExtensionManager {
  PotteryExtensionManager._() {
    _communicator ??= const ExtensionCommunicator();
    _initialize();
  }

  factory PotteryExtensionManager.createSingle() {
    return _instance ??= PotteryExtensionManager._();
  }

  static PotteryExtensionManager? _instance;
  static ExtensionCommunicator? _communicator;

  bool _initialized = false;
  Future<void> Function()? _listenerRemover;

  final _Potteries _potteries = {};
  final _LocalPotteries _localPotteries = {};

  @visibleForTesting
  _Potteries get potteries => Map.of(_potteries);
  @visibleForTesting
  _LocalPotteries get localPotteries => Map.of(_localPotteries);

  void dispose() {
    _listenerRemover?.call();
    _listenerRemover = null;

    _instance = null;
    _communicator = null;
    _initialized = false;

    _potteries.clear();
    _localPotteries.clear();
  }

  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void setCommunicator(ExtensionCommunicator communicator) {
    _communicator = communicator;
  }

  void _runIfDebugAndInitialized(void Function() func) {
    runIfDebug(() {
      if (_initialized) {
        func();
      }
    });
  }

  void _initialize() {
    if (_initialized) {
      return;
    }
    _initialized = true;

    _runIfDebugAndInitialized(() {
      _communicator?.post('pottery:initialize');

      _listenerRemover = Pot.listen((event) {
        if (!event.kind.isScopeEvent) {
          _communicator?.post('pottery:pot_event', event.toMap());
        }
      });

      _communicator
        ?..onRequest('ext.pottery.getPots', () {
          return {
            for (final (pot, time) in PotManager.allInstances.records)
              pot.identity(): {
                'time': time.microsecondsSinceEpoch,
                'potDescription': PotDescription.fromPot(pot).toMap(),
              },
          };
        })
        ..onRequest('ext.pottery.getPotteries', () {
          return {
            for (final (state, data) in _potteries.records)
              state.widgetIdentity(): {
                'time': data.time.microsecondsSinceEpoch,
                'potDescriptions': [
                  for (final pot in data.pots)
                    PotDescription.fromPot(pot).toMap(),
                ],
              },
          };
        })
        ..onRequest('ext.pottery.getLocalPotteries', () {
          return {
            for (final (state, data) in _localPotteries.records)
              state.widgetIdentity(): {
                'time': data.time.microsecondsSinceEpoch,
                'objects': [
                  for (final v in data.list)
                    {
                      // ignore: invalid_use_of_internal_member
                      'potIdentity': v.pot.identity(),
                      'object': '${v.localObject}',
                    },
                ],
              },
          };
        });
    });
  }

  void onPotteryCreated(State<Pottery> state, _Pots pots) {
    _runIfDebugAndInitialized(() {
      PotManager.eventHandler.addEvent(
        PotEventKind.potteryCreated,
        pots: pots,
      );

      _potteries[state] = (time: DateTime.now(), pots: pots);
    });
  }

  void onPotteryRemoved(State<Pottery> state, _Pots pots) {
    _runIfDebugAndInitialized(() {
      PotManager.eventHandler.addEvent(
        PotEventKind.potteryRemoved,
        pots: pots,
      );

      _potteries.remove(state);
    });
  }

  void onLocalPotteryCreated(
    State<LocalPottery> state,
    LocalPotteryObjects objects,
  ) {
    _runIfDebugAndInitialized(() {
      PotManager.eventHandler.addEvent(
        PotEventKind.localPotteryCreated,
        pots: objects.keys,
      );

      _localPotteries[state] = (
        time: DateTime.now(),
        list: [
          for (final (pot, object) in objects.records)
            // The object is converted to a string when used, but the
            // conversion must not be here. Having in the form of a
            // fixed string means newer changes will not be reflected.
            (pot: pot, localObject: object),
        ],
      );
    });
  }

  void onLocalPotteryRemoved(
    State<LocalPottery> state,
    LocalPotteryObjects objects,
  ) {
    _runIfDebugAndInitialized(() {
      PotManager.eventHandler.addEvent(
        PotEventKind.localPotteryRemoved,
        pots: objects.keys,
      );

      _localPotteries.remove(state);
    });
  }
}
