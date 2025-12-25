part of '../pot.dart';

/// A class that describes the details of a [Pot].
@immutable
class PotDescription {
  /// Creates a [PotDescription] that describes the details of a [Pot].
  const PotDescription._({
    required this.identity,
    required this.isPending,
    required this.isDisposed,
    required this.hasObject,
    required this.object,
    required this.scope,
  });

  /// Creates a [PotDescription] from a Map.
  // Used also by pottery and pottery_devtools_extension.
  factory PotDescription.fromMap(Map<String, Object?> map) {
    return PotDescription._(
      identity: map['identity'] as String? ?? '',
      isPending: map['isPending'] as bool?,
      isDisposed: map['isDisposed'] as bool? ?? false,
      hasObject: map['hasObject'] as bool? ?? false,
      object: convertForDescription(map['object']),
      scope: map['scope'] as int?,
    );
  }

  /// Creates a [PotDescription] from a Pot.
  // Used also by pottery and pottery_devtools_extension.
  factory PotDescription.fromPot(Pot<Object?> pot) {
    return PotDescription._(
      identity: pot.identity(),
      isPending: pot is ReplaceablePot ? pot.isPending : null,
      isDisposed: pot._isDisposed,
      hasObject: pot._hasObject,
      object: convertForDescription(pot._object),
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
  ///
  /// This is not always the original object; some types are converted
  /// to [String] for representation and for safety.
  final Object? object;

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
