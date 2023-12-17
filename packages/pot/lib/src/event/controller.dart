part of '../pot.dart';

class _EventController {
  StreamController<PotEvent>? _streamController;
  int _number = 0;

  bool get hasListener => _streamController?.hasListener ?? false;

  Future<void> _closeStreamController() async {
    await _streamController?.close();
    _streamController = null;
  }

  RemovePotListener listen(void Function(PotEvent event) onData) {
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
    required Iterable<_PotBody<Object?>> pots,
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
          for (final pot in pots) PotDescription.fromPot(pot as Pot),
        ],
      ),
    );
  }
}
