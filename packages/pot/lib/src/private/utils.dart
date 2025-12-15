// ignore_for_file: public_member_api_docs

import '../pot.dart' show Pot;

extension ObjectIdentity<T> on Pot<T> {
  String shortHash() {
    return hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
  }

  // Used also from package:pottery.
  String identity() {
    // ignore: no_runtimeType_toString
    return '$runtimeType#${shortHash()}';
  }
}
