import 'dart:async' show StreamSubscription;

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:pottery/pottery.dart';
import 'package:vm_service/vm_service.dart';

import 'package:pottery_devtools_extension/src/types.dart';

class PotteryEventHandler {
  PotteryEventHandler() {
    _initialize();
  }

  StreamSubscription<Event>? _subscription;

  PotEventsNotifier? _potEventsNotifier;

  PotEventsNotifier get potEventsNotifier => _potEventsNotifier!;

  Future<void> dispose() async {
    _potEventsNotifier?.dispose();
    await _subscription?.cancel();
  }

  Future<void> _initialize() async {
    _potEventsNotifier = PotEventsNotifier([]);

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
    }
  }

  void clearEvents() {
    potEventsNotifier.value = [];
  }
}
