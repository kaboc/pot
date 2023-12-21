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

extension PotDescriptionText on PotDescription {
  String toFormattedJson() {
    final map = toMap()..remove('scope');
    return const JsonEncoder.withIndent('    ').convert(map);
  }
}
