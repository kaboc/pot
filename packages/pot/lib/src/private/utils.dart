// ignore_for_file: public_member_api_docs

import '../pot.dart';

extension ObjectIdentity<T> on Pot<T> {
  // Used also from package:pottery.
  String identity() {
    // ignore: no_runtimeType_toString
    return '$runtimeType'
        '#${hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0')}';
  }
}
