import 'package:flutter/material.dart';

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
