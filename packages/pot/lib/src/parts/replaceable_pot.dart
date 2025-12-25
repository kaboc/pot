part of '../pot.dart';

/// A variant of [Pot] with the [replace] method that allows its
/// factory to be replaced.
///
/// This type of pot is created through either [Pot.replaceable] or
/// [Pot.pending].
///
/// {@template pot.replaceablePot}
/// ```dart
/// // replace() is not available in this pot.
/// final pot = Pot(() => Counter());
///
/// // replace() is available in these pots.
/// final replaceablePot1 = Pot.replaceable(() => Counter());
/// final replaceablePot2 = Pot.pending<Counter>();
///
/// ...
///
/// replaceablePot2.replace(() => SubtypeOfCounter());
/// ```
/// {@endtemplate}
@sealed
class ReplaceablePot<T> extends Pot<T> {
  ReplaceablePot._(super.factory, {super.disposer, bool isPending = false})
      : _isPending = isPending;

  factory ReplaceablePot._pending({PotDisposer<T>? disposer}) {
    return ReplaceablePot._(
      () => throw PotNotReadyException(),
      disposer: disposer,
      isPending: true,
    );
  }

  bool _isPending = false;

  /// Whether the pot is in the pending state.
  ///
  /// If this is true, it means the pot is not ready because a factory
  /// has not been set since the pot was created by [Pot.pending]
  /// or since an existing factory was removed by [resetAsPending].
  bool get isPending => _isPending;

  /// Overrides the factory function and refreshes the existing object
  /// using the new factory, if any.
  ///
  /// This behaves differently depending on the existence of the object.
  ///
  /// If no object has been created:
  /// * Only the factory is replaced.
  /// * A new object is not created.
  /// * The disposer is not triggered.
  ///
  /// ```dart
  /// final pot = Pot.replaceable(() => User(id: 100));
  ///
  /// void main() {
  ///   // The factory is replaced.
  ///   // The pot has no User object yet.
  ///   pot.replace(() => User(id: 200));
  ///
  ///   // The object is created.
  ///   final user = pot();
  ///
  ///   print(user.id); // 200
  /// }
  /// ```
  ///
  /// If the pot has an object:
  /// * Both the factory and the object are replaced.
  /// * The disposer is triggered for the old object.
  ///
  /// ```dart
  /// final pot = Pot.replaceable<User>(
  ///   () => User(id: 100),
  ///   disposer: (user) => user.dispose(),
  /// );
  ///
  /// void main() {
  ///   // The object is created.
  ///   pot.create();
  ///
  ///   // The factory is replaced.
  ///   // The existing object is removed and the disposer is triggered.
  ///   // A new object is immediately created by the new factory.
  ///   pot.replace(() => User(id: 200));
  /// }
  /// ```
  ///
  /// > [!TIP]
  /// > If you need to replace the factory only in tests, you may want
  /// > to use a non-replaceable pot and to use
  /// > [replaceForTesting()][replaceForTesting] instead of this method.
  /// > It ensures that factory replacement is restricted to testing
  /// > and prevents its misuse in application logic. Conveniently,
  /// > `replaceForTesting()` is available even on a non-replaceable pot.
  void replace(PotObjectFactory<T> factory) => _replace(factory);

  /// Calls [reset] and also removes the existing factory to switch
  /// the state of the ReplaceablePot to pending.
  ///
  /// After a call to this method, a new factory must be set with
  /// [ReplaceablePot.replace] before the pot is used. Otherwise the
  /// [PotNotReadyException] is thrown.
  void resetAsPending() {
    if (!_isPending) {
      reset();
      _replace(() => throw PotNotReadyException(), asPending: true);
    }
  }
}
