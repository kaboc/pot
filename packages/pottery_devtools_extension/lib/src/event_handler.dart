import 'dart:async' show StreamSubscription, Timer;

import 'package:devtools_app_shared/service.dart';
import 'package:pottery/pottery.dart';
import 'package:vm_service/vm_service.dart';

import 'package:pottery_devtools_extension/src/types.dart';
import 'package:pottery_devtools_extension/src/utils.dart';

class PotteryEventHandler {
  PotteryEventHandler({
    required this.serviceManager,
    required this.fetchingDebounceDuration,
  }) {
    _initialize();
  }

  final ServiceManager serviceManager;
  final Duration fetchingDebounceDuration;

  StreamSubscription<Event>? _subscription;
  Timer? _fetchingDebounceTimer;

  PotEventsNotifier? _potEventsNotifier;
  PotsNotifier? _potsNotifier;
  PotteriesNotifier? _potteriesNotifier;
  LocalPotteriesNotifier? _localPotteriesNotifier;

  PotEventsNotifier get potEventsNotifier => _potEventsNotifier!;
  PotsNotifier get potsNotifier => _potsNotifier!;
  PotteriesNotifier get potteriesNotifier => _potteriesNotifier!;
  LocalPotteriesNotifier get localPotteriesNotifier => _localPotteriesNotifier!;

  Future<void> dispose() async {
    _potEventsNotifier?.dispose();
    _potsNotifier?.dispose();
    _potteriesNotifier?.dispose();
    _localPotteriesNotifier?.dispose();

    _fetchingDebounceTimer?.cancel();
    await _subscription?.cancel();
  }

  Future<void> _initialize() async {
    _potEventsNotifier = PotEventsNotifier([]);
    _potsNotifier = PotsNotifier({});
    _potteriesNotifier = PotteriesNotifier({});
    _localPotteriesNotifier = LocalPotteriesNotifier({});

    await serviceManager.onServiceAvailable;

    _subscription = serviceManager.service?.onExtensionEvent.listen((event) {
      final kind = event.extensionKind ?? '';
      if (kind.startsWith('pottery:')) {
        _extensionEventHandler(event);
      }
    });
  }

  void _extensionEventHandler(Event event) {
    final data = event.extensionData?.data;
    if (data == null) {
      return;
    }

    switch (event.extensionKind) {
      case 'pottery:initialize':
        potsNotifier.value = {};
        potteriesNotifier.value = {};
        localPotteriesNotifier.value = {};
        potEventsNotifier.value = [];
      case 'pottery:pot_event':
        final len = potEventsNotifier.value.length;
        potEventsNotifier.value = [
          if (len > 1000)
            ...potEventsNotifier.value.skip(len - 1000)
          else
            ...potEventsNotifier.value,
          PotEvent.fromMap(data),
        ];

        _scheduleFetching();
    }
  }

  void _scheduleFetching() {
    _fetchingDebounceTimer?.cancel();
    _fetchingDebounceTimer = Timer(fetchingDebounceDuration, () async {
      await Future.wait([
        getPots(),
        getPotteries(),
        getLocalPotteries(),
      ]);
    });
  }

  Future<void> getPots() async {
    final response = await serviceManager
        .callServiceExtensionOnMainIsolate('ext.pottery.getPots');

    final entries = response.json?.entries ?? [];

    potsNotifier.value = {
      for (final MapEntry(key: identity, value: desc) in entries)
        if (desc is Map<String, Object?>)
          identity: (
            time: (desc['time'] as int? ?? 0).toDateTime(),
            description: PotDescription.fromMap(
              desc['potDescription'] as Map<String, Object?>? ?? {},
            ),
          ),
    };
  }

  Future<void> getPotteries() async {
    final response = await serviceManager
        .callServiceExtensionOnMainIsolate('ext.pottery.getPotteries');

    potteriesNotifier.value = response.json._toPotteries();
  }

  Future<void> getLocalPotteries() async {
    final response = await serviceManager
        .callServiceExtensionOnMainIsolate('ext.pottery.getLocalPotteries');

    localPotteriesNotifier.value = response.json._toLocalPotteries();
  }

  void clearEvents() {
    potEventsNotifier.value = [];
  }
}

extension on Map<String, Object?>? {
  Potteries _toPotteries() {
    final entries = (this ?? <String, Object>{}).entries;

    return {
      for (final MapEntry(key: id, value: data) in entries)
        if (data
            case {
              'time': final int? time,
              'potDescriptions': final List<Object?>? descs,
            })
          id: (
            time: time.toDateTime(),
            potDescriptions: [
              if (descs != null)
                for (final desc in descs)
                  if (desc is Map<String, Object?>)
                    PotDescription.fromMap(desc),
            ],
          ),
    };
  }

  LocalPotteries _toLocalPotteries() {
    final entries = (this ?? <String, Object>{}).entries;

    return {
      for (final MapEntry(key: id, value: data) in entries)
        if (data
            case {
              'time': final int? time,
              'objects': final List<Object?>? objects,
            })
          id: (
            time: time.toDateTime(),
            objects: [
              if (objects != null)
                for (final object in objects)
                  if (object
                      case {
                        'potIdentity': final String? potIdentity,
                        'object': final String? object,
                      })
                    (potIdentity: potIdentity ?? '', object: object ?? ''),
            ],
          ),
    };
  }
}
