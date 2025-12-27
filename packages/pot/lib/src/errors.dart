/// Exception thrown if a pot with no factory is used.
class PotNotReadyException implements Exception {
  // coverage:ignore-start
  @override
  String toString() =>
      'PotNotReadyException: The pot is not ready for use. Set a valid '
      'factory with `Pot.replace()`.';
  // coverage:ignore-end
}
