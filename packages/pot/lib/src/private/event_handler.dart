// ignore_for_file: public_member_api_docs

import 'dart:async' show StreamController;

import '../event.dart';
import '../pot.dart';

class PotEventHandler {
  StreamController<PotEvent>? _streamController;
  int _number = 0;

  bool get hasListener => _streamController?.hasListener ?? false;
  bool get isClosed => _streamController?.isClosed ?? true;

  Future<void> _closeStreamController() async {
    await _streamController?.close();
    _streamController = null;
  }

  PotListenerRemover listen(void Function(PotEvent event) onData) {
    _streamController ??= StreamController<PotEvent>.broadcast();
    final subscription = _streamController?.stream.listen(onData);
    return () async {
      await subscription?.cancel();

      final controller = _streamController;
      if (controller != null && !controller.hasListener) {
        await _closeStreamController();
      }
    };
  }

  void addEvent(
    PotEventKind kind, {
    required Iterable<Pot<Object?>> pots,
  }) {
    final controller = _streamController;
    if (controller == null || !controller.hasListener) {
      return;
    }

    controller.sink.add(
      PotEvent(
        number: ++_number,
        kind: kind,
        time: DateTime.now(),
        currentScope: Pot.currentScope,
        potDescriptions: [
          for (final pot in pots) PotDescription.fromPot(pot),
        ],
      ),
    );
  }
}
