part of '../pot.dart';

extension<T> on _PotBody<T> {
  Never throwStateError() {
    throw StateError(
      'A $runtimeType was used after being disposed.\n'
      'Once you have called dispose() on a $runtimeType, '
      'it can no longer be used.',
    );
  }

  void debugWarning({required bool suppressWarning}) {
    if (suppressWarning) {
      return;
    }

    // ignore: prefer_asserts_with_message
    assert(
      () {
        final prevScope = _prevScope;
        if (prevScope != null && StaticPot.currentScope < prevScope) {
          StaticPot.warningPrinter(
            'A new $T object was created in an older scope than where the '
            'previous object was bound to. It is likely a misuse.\n'
            'If it is not, or if you want to simply suppress this warning, '
            'pass in `suppressWarning: true` to `call()` or `create()`.',
          );
        }
        return true;
      }(),
    );
  }
}
