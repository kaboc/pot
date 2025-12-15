import 'pot.dart' show Pot, PotDescription;

/// The types of events that can occur in relation to [Pot].
enum PotEventKind {
  /// A value that represents an unknown event.
  unknown,

  /// A value that represents an event when a [Pot] was instantiated.
  instantiated,

  /// A value that represents an event when an object was created in a [Pot].
  created,

  /// A value that represents an event when the factory of a [Pot] was replaced.
  replaced,

  /// A value that represents an event when a [Pot] was reset.
  reset,

  /// A value that represents an event when the disposer of a [Pot] was called.
  disposerCalled,

  /// A value that represents an event when a [Pot] was marked as pending.
  markedAsPending,

  /// A value that represents an event when a [Pot] was disposed.
  disposed,

  /// A value that represents an event when a new scope was created.
  scopePushed(isScopeEvent: true),

  /// A value that represents an event when all [Pot]s in a scope were reset.
  scopeCleared(isScopeEvent: true),

  /// A value that represents an event when all [Pot]s in a scope were reset
  /// and the scope was removed.
  scopePopped(isScopeEvent: true),

  /// A value that represents an event when a [Pot] was associated with the
  /// current scope.
  addedToScope(isScopeEvent: true),

  /// A value that represents an event when a [Pot] was unassociated from
  /// a scope.
  removedFromScope(isScopeEvent: true),

  /// A value that represents an event when the object held in a [Pot] was
  /// updated.
  objectUpdated,

  /// A value that represents an event when a `Pottery` of package:pottery
  /// was inserted into the tree.
  potteryCreated,

  /// A value that represents an event when a `Pottery` of package:pottery
  /// was removed from the tree.
  potteryRemoved,

  /// A value that represents an event when a `LocalPottery` of
  /// package:pottery was inserted into the tree.
  localPotteryCreated,

  /// A value that represents an event when a `LocalPottery` of
  /// package:pottery was removed from the tree.
  localPotteryRemoved;

  // ignore: public_member_api_docs
  const PotEventKind({this.isScopeEvent = false});

  /// Whether the event is related to scoping.
  final bool isScopeEvent;
}

/// A class that represents an event related to [Pot].
class PotEvent {
  /// Creates a [PotEvent] that represents an event related to [Pot].
  const PotEvent({
    required this.number,
    required this.kind,
    required this.time,
    required this.currentScope,
    required this.potDescriptions,
  });

  /// Creates a PotEvent from a Map.
  factory PotEvent.fromMap(Map<String, Object?> map) {
    final kindName = map['kind'] as String? ?? '';
    final descriptions = map['potDescriptions'] as List<Object?>? ?? [];

    return PotEvent(
      number: map['number'] as int? ?? 0,
      kind: PotEventKind.values.asNameMap()[kindName] ?? PotEventKind.unknown,
      time: DateTime.fromMicrosecondsSinceEpoch(map['time'] as int? ?? 0),
      currentScope: map['currentScope'] as int? ?? 0,
      potDescriptions: [
        for (final desc in descriptions)
          if (desc != null)
            PotDescription.fromMap(desc as Map<String, Object?>),
      ],
    );
  }

  /// A sequence number.
  final int number;

  /// The kind of the event.
  final PotEventKind kind;

  /// The time when the event occurred.
  final DateTime time;

  /// The number of the scope as of when the event occurred.
  final int currentScope;

  /// The details of the pot where the event occurred.
  final List<PotDescription> potDescriptions;

  @override
  String toString() {
    return 'PotEvent('
        'number: $number, '
        'kind: ${kind.name}, '
        'time: $time, '
        'currentScope: $currentScope, '
        // ignore: missing_whitespace_between_adjacent_strings
        'potDescriptions: [${potDescriptions.map((v) => '$v').join(', ')}]'
        ')';
  }

  /// Converts a [PotEvent] to a Map.
  Map<String, Object?> toMap() {
    return {
      'number': number,
      'kind': kind.name,
      'time': time.microsecondsSinceEpoch,
      'currentScope': currentScope,
      'potDescriptions': [
        for (final desc in potDescriptions) desc.toMap(),
      ],
    };
  }
}
