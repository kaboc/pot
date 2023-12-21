// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart' show State;

extension MapToRecords<K, V> on Map<K, V> {
  List<(K, V)> get records => [
        for (final MapEntry(:key, :value) in entries) (key, value),
      ];
}

extension ObjectShortHash on Object {
  String shortHash() {
    return hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
  }
}

extension WidgetIdentity on State {
  String widgetIdentity() {
    // ignore: no_runtimeType_toString
    return '${widget.runtimeType}#${widget.shortHash()}';
  }
}

void runIfDebug(void Function() func) {
  // ignore: prefer_asserts_with_message
  assert(
    () {
      func();
      return true;
    }(),
  );
}
