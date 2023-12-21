import 'dart:async' show StreamSubscription, Timer;

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:pottery/pottery.dart';
import 'package:vm_service/vm_service.dart';

import 'package:pottery_devtools_extension/src/types.dart';
import 'package:pottery_devtools_extension/src/utils.dart';

const _kFetchingDebounceDuration = Duration(milliseconds: 400);

class PotteryEventHandler {
  PotteryEventHandler() {
    _initialize();
  }

  StreamSubscription<Event>? _subscription;
  Timer? _fetchingDebounceTimer;

  PotEventsNotifier? _potEventsNotifier;
  PotsNotifier? _potsNotifier;

  PotEventsNotifier get potEventsNotifier => _potEventsNotifier!;
  PotsNotifier get potsNotifier => _potsNotifier!;

  Future<void> dispose() async {
    _potEventsNotifier?.dispose();
    _potsNotifier?.dispose();

    _fetchingDebounceTimer?.cancel();
    await _subscription?.cancel();
  }

  Future<void> _initialize() async {
    _potEventsNotifier = PotEventsNotifier([]);
    _potsNotifier = PotsNotifier({});

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
        potEventsNotifier.value = [];
      case 'pottery:pot_event':
        final potEvent = PotEvent.fromMap(data);

        if (potEvent.kind != PotEventKind.objectUpdated) {
          final len = potEventsNotifier.value.length;
          potEventsNotifier.value = [
            if (len > 1000)
              ...potEventsNotifier.value.skip(len - 1000)
            else
              ...potEventsNotifier.value,
            potEvent,
          ];
        }

        _scheduleFetching(potEvent);
    }
  }

  void _scheduleFetching(PotEvent event) {
    _fetchingDebounceTimer?.cancel();
    _fetchingDebounceTimer = Timer(_kFetchingDebounceDuration, getPots);
  }

  Future<void> getPots() async {
    final response = await serviceManager
        .callServiceExtensionOnMainIsolate('ext.pottery.getPots');

    final list = response.json?.records ?? [];

    potsNotifier.value = {
      for (final (identity, desc) in list)
        if (desc is Map<String, Object?>)
          identity: (
            time: (desc['time'] as int? ?? 0).toDateTime(),
            description: PotDescription.fromMap(
              desc['potDescription'] as Map<String, Object?>? ?? {},
            ),
          ),
    };
  }

  void clearEvents() {
    potEventsNotifier.value = [];
  }
}
