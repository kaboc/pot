import 'dart:convert' show JsonEncoder;

import 'package:flutter/material.dart';

import 'package:pottery/pottery.dart' show PotDescription;

extension ThemeGetter on BuildContext {
  Color get baseColor => Colors.cyan;

  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  bool get isDark => theme.brightness == Brightness.dark;
}

extension MapToRecord<K, V> on Map<K, V> {
  Iterable<(K, V)> get records =>
      entries.map((entry) => (entry.key, entry.value));
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
