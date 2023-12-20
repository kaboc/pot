part of '../pot.dart';

/// A class that describes the details of a [Pot].
@immutable
class PotDescription {
  /// Creates a [PotDescription] that describes the details of a [Pot].
  const PotDescription({
    required this.identity,
    required this.isPending,
    required this.isDisposed,
    required this.hasObject,
    required this.object,
    required this.scope,
  });

  /// Creates a [PotDescription] from a Map.
  factory PotDescription.fromMap(Map<String, Object?> map) {
    return PotDescription(
      identity: map['identity'] as String? ?? '',
      isPending: map['isPending'] as bool?,
      isDisposed: map['isDisposed'] as bool? ?? false,
      hasObject: map['hasObject'] as bool? ?? false,
      object: map['object'] as String? ?? 'null',
      scope: map['scope'] as int?,
    );
  }

  /// Creates a [PotDescription] from a Pot.
  factory PotDescription.fromPot(Pot<Object?> pot) {
    return PotDescription(
      identity: pot.identity(),
      isPending: pot is ReplaceablePot ? pot.isPending : null,
      isDisposed: pot._isDisposed,
      hasObject: pot._hasObject,
      object: '${pot._object}',
      scope: pot._scope,
    );
  }

  /// A summary of the runtime type and hash code of the pot.
  final String identity;

  /// Whether the pot is in the state of pending.
  final bool? isPending;

  /// Whether the pot has already been disposed.
  final bool isDisposed;

  /// Whether an object has been created in the pot.
  final bool hasObject;

  /// The object held in the pot.
  final String object;

  /// The number of the scope the pot is bound to.
  final int? scope;

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      other is PotDescription &&
          identity == other.identity &&
          isPending == other.isPending &&
          isDisposed == other.isDisposed &&
          hasObject == other.hasObject &&
          object == other.object &&
          scope == other.scope;

  @override
  int get hashCode => Object.hashAll([
        identity,
        isPending,
        isDisposed,
        hasObject,
        object,
        scope,
      ]);

  @override
  String toString() {
    return 'PotDescription('
        'identity: $identity, '
        'isPending: $isPending, '
        'isDisposed: $isDisposed, '
        'hasObject: $hasObject, '
        'object: $object, '
        'scope: $scope'
        ')';
  }

  /// Converts a [PotDescription] to a Map.
  Map<String, Object?> toMap() {
    return {
      'identity': identity,
      'isPending': isPending,
      'isDisposed': isDisposed,
      'hasObject': hasObject,
      'object': object,
      'scope': scope,
    };
  }
}
