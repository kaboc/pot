// ignore_for_file: public_member_api_docs

import '../pot.dart';
import 'event_handler.dart';

typedef Scopes = List<List<Pot<Object?>>>;

// ignore: avoid_classes_with_only_static_members
abstract final class ScopeState {
  static final Scopes scopes = [[]];

  static int currentScope = 0;
}

// ignore: avoid_classes_with_only_static_members
abstract final class PotManager {
  static final eventHandler = PotEventHandler();

  // For debugging and testing
  static void Function(Object?) warningPrinter = print;

  // For Pottery DevTools extension
  static final Map<Pot<Object?>, DateTime> allInstances = {};
}
