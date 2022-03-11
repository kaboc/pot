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
}

// Private
extension on _ScopedResetters {
  void createScope() {
    add([]);
  }

  void clearScope(int index, {bool keepScope = false}) {
    for (var i = this[index].length - 1; i >= 0; i--) {
      this[index][i]();
    }

    if (index == 0 || keepScope) {
      this[index].clear();
    } else {
      removeAt(index);
    }
  }

  void addToScope(_Resetter resetter) {
    this[Pot._currentScope].add(resetter);
  }

  void removeFromScope(_Resetter resetter, {bool excludeCurrentScope = false}) {
    final start =
        excludeCurrentScope ? Pot._currentScope - 1 : Pot._currentScope;

    for (var i = start; i >= 0; i--) {
      if (this[i].contains(resetter)) {
        this[i].remove(resetter);
        break;
      }
    }
  }
}
