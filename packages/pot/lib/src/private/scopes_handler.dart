// ignore_for_file: public_member_api_docs

import '../event.dart';
import '../pot.dart';
import 'static.dart';

extension ScopesHandler on Scopes {
  void createScope() {
    add([]);
    StaticPot.currentScope++;
    StaticPot.eventHandler.addEvent(PotEventKind.scopePushed, pots: []);
  }

  void clearScope(int index, {required bool keepScope}) {
    final pots = this[index];
    for (var i = pots.length - 1; i >= 0; i--) {
      pots[i].reset();
    }

    if (index == 0 || keepScope) {
      pots.clear();
      StaticPot.eventHandler.addEvent(PotEventKind.scopeCleared, pots: []);
    } else {
      removeAt(index);
      StaticPot.currentScope--;
      StaticPot.eventHandler.addEvent(PotEventKind.scopePopped, pots: []);
    }
  }

  void addPot<T>(Pot<T> pot) {
    final pots = this[StaticPot.currentScope];
    if (!pots.contains(pot)) {
      pots.add(pot);
      StaticPot.eventHandler.addEvent(PotEventKind.addedToScope, pots: [pot]);
    }
  }

  void removePot<T>(Pot<T> pot, {bool excludeCurrentScope = false}) {
    final start = excludeCurrentScope
        ? StaticPot.currentScope - 1
        : StaticPot.currentScope;

    for (var i = start; i >= 0; i--) {
      if (this[i].contains(pot)) {
        this[i].remove(pot);

        StaticPot.eventHandler
            .addEvent(PotEventKind.removedFromScope, pots: [pot]);

        break;
      }
    }
  }
}
