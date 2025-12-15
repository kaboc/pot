// ignore_for_file: public_member_api_docs

import '../event.dart' show PotEventKind;
import '../pot.dart' show Pot;
import 'static.dart';

extension ScopeController on Scopes {
  void createScope() {
    add([]);
    ScopeState.currentScope++;
    PotManager.eventHandler.addEvent(PotEventKind.scopePushed, pots: []);
  }

  void clearScope(int index, {required bool keepScope}) {
    final pots = this[index];
    for (var i = pots.length - 1; i >= 0; i--) {
      pots[i].reset();
    }

    if (index == 0 || keepScope) {
      pots.clear();
      PotManager.eventHandler.addEvent(PotEventKind.scopeCleared, pots: []);
    } else {
      removeAt(index);
      ScopeState.currentScope--;
      PotManager.eventHandler.addEvent(PotEventKind.scopePopped, pots: []);
    }
  }

  void addPot<T>(Pot<T> pot) {
    final pots = this[ScopeState.currentScope];
    if (!pots.contains(pot)) {
      pots.add(pot);
      PotManager.eventHandler.addEvent(PotEventKind.addedToScope, pots: [pot]);
    }
  }

  void removePot<T>(Pot<T> pot, {bool excludeCurrentScope = false}) {
    final start = excludeCurrentScope
        ? ScopeState.currentScope - 1
        : ScopeState.currentScope;

    for (var i = start; i >= 0; i--) {
      if (this[i].contains(pot)) {
        this[i].remove(pot);

        PotManager.eventHandler
            .addEvent(PotEventKind.removedFromScope, pots: [pot]);

        break;
      }
    }
  }
}
