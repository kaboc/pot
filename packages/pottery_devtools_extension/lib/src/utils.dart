import 'dart:convert' show JsonEncoder;

import 'package:flutter/material.dart';

import 'package:pottery/pottery.dart' show PotDescription;

import 'package:pottery_devtools_extension/src/types.dart';

extension ThemeGetter on BuildContext {
  Color get baseColor => Colors.cyan;

  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => ColorScheme.of(this);
  TextTheme get textTheme => TextTheme.of(this);

  bool get isDark => theme.brightness == Brightness.dark;
}

extension IterableComparison<S, T> on Iterable<S> {
  bool same(int index, Iterable<S>? other, T Function(S?) propSelector) {
    return propSelector(elementAtOrNull(index)) ==
        propSelector(other?.elementAtOrNull(index));
  }
}

extension MicrosecondsToDateTime on int? {
  DateTime toDateTime() {
    return DateTime.fromMicrosecondsSinceEpoch(this ?? 0);
  }
}

extension PotDescriptionText on PotDescription {
  String toFormattedJson() {
    final map = toMap()..remove('scope');
    return const JsonEncoder.withIndent('    ').convert(map);
  }
}

extension LocalObjectText on LocalObject {
  String toFormattedJson() {
    return const JsonEncoder.withIndent('    ').convert({
      'potIdentity': potIdentity,
      'object': object,
    });
  }
}
