import 'pot.dart';

/// Error thrown if `replaceForTesting` is used when [Pot.forTesting]
/// is not enabled.
class PotReplaceError extends Error {
  @override
  String toString() => 'PotReplaceError: '
      '`replaceForTesting()` cannot be used for this pot.\n'
      'If replacement of the factory is necessary for testing, set `true` '
      'to `Pot.forTesting`. If it is for functionality of the application, '
      'use the `Pot.replaceable` constructor instead.';
}
