// ignore_for_file: public_member_api_docs

import '../pot.dart';

enum DetailedPotIdentity { notSet, disabled, enabled }

DetailedPotIdentity isDetailedPotIdentityEnabled = DetailedPotIdentity.notSet;

extension ObjectIdentity<T> on Pot<T> {
  String shortHash() {
    return hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
  }

  bool _shouldIncludeGenericTypeInIdentity() {
    if (isDetailedPotIdentityEnabled == DetailedPotIdentity.notSet) {
      // ignore: prefer_asserts_with_message
      assert(() {
        isDetailedPotIdentityEnabled = DetailedPotIdentity.enabled;
        return true;
      }());
    }
    return isDetailedPotIdentityEnabled == DetailedPotIdentity.enabled;
  }

  // Used also by pottery and pottery_devtools_extension.
  String identity() {
    // Uses a predefined name instead of runtimeType for consistency
    // in production.
    var typeName = this is ReplaceablePot ? 'ReplaceablePot' : 'Pot';

    // The generic type from runtimeType is appended to the name
    // only in debug mode or if it is enabled for testing.
    if (_shouldIncludeGenericTypeInIdentity()) {
      // ignore: no_runtimeType_toString
      final runtimeTypeName = '$runtimeType';

      final index = runtimeTypeName.indexOf('<');
      typeName = runtimeTypeName.replaceRange(0, index, typeName);
    }

    return '$typeName#${shortHash()}';
  }
}

// Used also by pottery and pottery_devtools_extension.
Object? convertForDescription(Object? object, {bool quoteString = false}) {
  return switch (object) {
    null || num() || bool() => object,
    String() => quoteString ? '"$object"' : object,
    final List<Object?> list => [
        for (final v in list)
          convertForDescription(v, quoteString: quoteString),
      ],
    final Map<Object?, Object?> map => {
        for (final MapEntry(:key, :value) in map.entries)
          quoteString ? '"$key"' : key:
              convertForDescription(value, quoteString: quoteString),
      },
    // Converts the object to a String because including a non-primitive
    // object in event data carries the risk that receivers of the event
    // might keep a reference to it or modify its content by mistake.
    _ => quoteString ? '"$object"' : '$object',
  };
}
