/// Exception thrown if a pot with no factory is used.
class PotNotReadyException implements Exception {
  @override
  // coverage:ignore-line
  String toString() =>
      'PotNotReadyException: The pot is not ready for use. Set a valid '
      'factory with `Pot.replace()`.';
}
