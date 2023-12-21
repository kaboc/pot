import 'dart:convert' show jsonDecode;

import 'package:flutter_test/flutter_test.dart';

import 'package:pot/pot.dart';

import 'spy_communicator.dart';

Matcher logContainsEvent(String kind, {String? identity}) =>
    _LogContainsEvent(kind, identity);

class _LogContainsEvent extends Matcher {
  const _LogContainsEvent(this.kind, this.identity);

  final String kind;
  final String? identity;

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is SpyLog) {
      final map = jsonDecode(item.$2 ?? '') as Map<String, Object?>;
      final event = PotEvent.fromMap(map);

      return event.kind.name == kind &&
          (identity == null ||
              event.potDescriptions.elementAtOrNull(0)?.identity == identity);
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description
        .add('log contains an event with the values of ')
        .addDescriptionOf({
      'kind': kind,
      if (identity != null) 'identity': identity,
    });
  }
}
