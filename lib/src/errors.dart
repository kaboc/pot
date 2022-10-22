import 'pot.dart';

/// Error thrown if `replaceForTesting` is used when [Pot.forTesting]
/// is not enabled.
class PotReplaceError extends Error {
  @override
  String toString() =>
      'PotReplaceError: `replaceForTesting()` is not available with '
      'the current setting.\n'
      'If a replacement is necessary for testing, set `Pot.forTesting` '
      'to `true`. Or if it is for functionality of the application, '
      'use the `Pot.replaceable()` instead.';
}

/// Exception thrown if a pot with no factory is used.
class PotNotReadyException implements Exception {
  @override
  String toString() =>
      'PotNotReadyException: The pot is not ready for use. Set a valid '
      'factory with `Pot.replace()`.';
}
