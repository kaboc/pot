// ignore_for_file: public_member_api_docs

import '../pot.dart';
import 'event_handler.dart';

typedef Scopes = List<List<Pot<Object?>>>;

// ignore: avoid_classes_with_only_static_members
class StaticPot {
  static final Scopes scopes = [[]];

  static int currentScope = 0;

  // For Pottery DevTools extension
  static final Map<Pot<Object?>, DateTime> allInstances = {};

  // For Pottery DevTools extension
  static final eventHandler = PotEventHandler();

  // Mainly for tests
  static void Function(Object?) warningPrinter = print;
}
