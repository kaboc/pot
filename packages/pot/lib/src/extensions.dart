part of 'pot.dart';

// Private
extension<T> on _PotBody<T> {
  Never throwStateError() {
    throw StateError(
      'A $runtimeType was used after being disposed.\n'
      'Once you have called dispose() on a $runtimeType, '
      'it can no longer be used.',
    );
  }

  void _debugWarning(bool suppressWarning) {
    if (suppressWarning) {
      return;
    }

    // ignore: prefer_asserts_with_message
    assert(
      () {
        final prevScope = _prevScope;
        if (prevScope != null && Pot._currentScope < prevScope) {
          Pot.$warningPrinter(
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

// Private
extension on _Scopes {
  void createScope() {
    add([]);
    Pot._incrementCurrentScopeNumber();
  }

  void clearScope(int index, {required bool keepScope}) {
    final pots = this[index];
    for (var i = pots.length - 1; i >= 0; i--) {
      pots[i].reset();
    }

    if (index == 0 || keepScope) {
      pots.clear();
    } else {
      removeAt(index);
      Pot._decrementCurrentScopeNumber();
    }
  }

  void addPot<T>(_PotBody<T> pot) {
    final pots = this[Pot._currentScope];
    if (!pots.contains(pot)) {
      pots.add(pot);
    }
  }

  void removePot<T>(_PotBody<T> pot, {bool excludeCurrentScope = false}) {
    final start =
        excludeCurrentScope ? Pot._currentScope - 1 : Pot._currentScope;

    for (var i = start; i >= 0; i--) {
      if (this[i].contains(pot)) {
        this[i].remove(pot);
        break;
      }
    }
  }
}
