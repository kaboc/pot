part of 'pot.dart';

// Actual body of Pot.
// This has instance members, whereas Pot has static members.
class _PotBody<T> {
  _PotBody(PotObjectFactory<T> factory, {PotDisposer<T>? disposer})
      : _factory = factory,
        _disposer = disposer;

  PotObjectFactory<T> _factory;
  PotDisposer<T>? _disposer;

  T? _object;
  bool _hasObject = false;
  int? _scope;
  int? _prevScope;
  bool _isDisposed = false;

  @visibleForTesting
  bool $expect(bool Function(T) test) => test(_object as T);

  /// Whether an object has been created by the factory and still exists.
  ///
  /// This returns `true` after a value is created with [call] or [create]
  /// even if the value is `null`.
  bool get hasObject => _hasObject;

  /// The index number of the scope that the object of this pot has
  /// been bound to.
  ///
  /// `null` is returned if there is no binding to a scope.
  ///
  /// {@macro pot.scope}
  ///
  /// This getter is useful when you want to verify in tests that
  /// a pot is associated with a certain scope as expected.
  int? get scope => _scope;

  /// Returns the object of type [T] created by the factory.
  ///
  /// If an object has not been created yet, this triggers the factory,
  /// which was set in the constructor, to create one.
  ///
  /// ```dart
  /// // The factory is not executed immediately when a pot is created.
  /// final counterPot = Pot(() => Counter(0));
  ///
  /// // The factory is triggered when the object is first accessed.
  /// final counter = counterPot();
  /// ```
  ///
  /// It also applies to the first access after a reset.
  ///
  /// ```dart
  /// final counterPot = Pot(() => Counter(0));
  ///
  /// // An object is created.
  /// var counter = counterPot();
  ///
  /// // The object is discarded.
  /// counterPot.reset();
  ///
  /// // A new object is created again.
  /// counter = counterPot();
  /// ```
  ///
  /// The object exists while the scope where it was created exists,
  /// so it is discarded when the scope is removed.
  ///
  /// ```dart
  /// final counterPot = Pot(() => Counter(0));
  ///
  /// void main() {
  ///   // A new scope is added, and the `currentScope` turns 1.
  ///   // The object is not bound to the scope yet because it hasn't created.
  ///   Pot.pushScope();
  ///
  ///   // An object is created and set in the current scope 1.
  ///   final counter = counterPot();
  ///
  ///   // The object is discarded.
  ///   // The scope 1 is removed and the `currentScope` turns 0.
  ///   Pot.popScope();
  /// }
  /// ```
  T call({bool suppressWarning = false}) {
    if (_isDisposed) {
      throwStateError();
    }

    if (!_hasObject) {
      _debugWarning(suppressWarning);

      Pot._scopedResetters
        ..removeFromScope(reset, excludeCurrentScope: true)
        ..addToScope(reset);

      _object = _factory();
      _hasObject = true;
      _scope = Pot._currentScope;
      _prevScope = _scope;
    }
    return _object as T;
  }

  /// Calls the factory to create an object of type [T].
  ///
  /// If this is called, the factory, which was set in the constructor,
  /// is executed to create an object.
  /// Otherwise, an object is not created until it is needed.
  /// Therefore this method is useful when you want to explicitly cause
  /// the creation immediately.
  ///
  /// ```dart
  /// final counterPot = Pot(() => Counter(0));
  ///
  /// void main() {
  ///   counterPot.create();
  ///   ...
  /// }
  /// ```
  ///
  /// [create] is almost the same as [call], only with the difference
  /// that this does not return the object while `call()` does, so
  /// `call()` can also be used for the same purpose instead.
  ///
  /// Note that calling this method has no effect if the object has
  /// already been created.
  void create({bool suppressWarning = false}) =>
      call(suppressWarning: suppressWarning);

  /// Discards resources in the pot.
  ///
  /// Once this is called, the pot is no longer in a usable state, and
  /// calls to its members will throw.
  void dispose() {
    reset();
    Pot._scopedResetters.removeFromScope(reset);
    _scope = null;
    _disposer = null;
    _isDisposed = true;
  }

  /// Discards the object of type [T] that was created by the factory
  /// and has been held in the pot.
  ///
  /// This method triggers the disposer, which was set in the constructor
  /// of [Pot], if an object exists.
  ///
  /// This does not discard the pot itself, so a new object is created
  /// again when it is need. Use this when the object is not used any more
  /// for now, and get a new object when it is necessary again.
  ///
  /// ```dart
  /// final counterPot = Pot<Counter>(
  ///   () => Counter(0),
  ///   disposer: (counter) => print('Discarded'),
  /// );
  ///
  /// void main() {
  ///   var counter = counterPot();
  ///   counter.increment();
  ///   print(counter.value); // 1
  ///
  ///   // Discards the existing object that has been held in the pot,
  ///   // and calls the disposer, printing "Discarded".
  ///   counterPot.reset();
  ///
  ///   // A new object is created if it is accessed.
  ///   counter = counterPot();
  ///   print(counter.value); // 0
  /// }
  /// ```
  ///
  /// Note that calling this method has no effect if the object has
  /// not been created.
  ///
  /// ```dart
  /// final counterPot = Pot(() => Counter(0));
  ///
  /// void main() {
  ///   // The disposer is not triggered because there is no object yet.
  ///   counterPot.reset();
  /// }
  /// ```
  void reset() {
    if (_isDisposed) {
      throwStateError();
    }

    if (_hasObject) {
      _disposer?.call(_object as T);
      _object = null;
      _hasObject = false;
      _scope = null;
      Pot._scopedResetters.removeFromScope(reset);
    }
  }

  /// Replaces the factory set in the constructor with a new one, and/or
  /// creates a new object using the new factory, for testing purposes.
  ///
  /// [ReplaceablePot.replace] is another method for replacements, and
  /// in fact, it works exactly the same way, but it is not available
  /// to pots created by the default constructor of [Pot].
  /// It is because it should be safer to not have access to a feature
  /// that is not needed usually.
  ///
  /// However, it may be necessary in tests, which are where
  /// [replaceForTesting] comes in handy. Set [Pot.forTesting] to
  /// `true` to use the method, but only when it is really necessary.
  ///
  /// {@template pot.replaceForTesting.example}
  /// ```dart
  /// final counterPot = Pot(() => Counter(0));
  ///
  /// void main() {
  ///   Pot.forTesting = true;
  ///
  ///   test('Counter test', () {
  ///     counterPot.replaceForTesting(() => Counter(100));
  ///   });
  /// }
  /// ```
  /// {@endtemplate}
  ///
  /// Note that pots created by [Pot.replaceable] can use this method
  /// regardless of whether or not [Pot.forTesting] is enabled.
  ///
  /// For details on how this method is used and what occurs in the
  /// process of a replacement, see the document of [ReplaceablePot.replace].
  void replaceForTesting(PotObjectFactory<T> factory) {
    if (!Pot.forTesting && this is! ReplaceablePot) {
      throw PotReplaceError();
    }

    _replace(factory);
  }

  void _replace(PotObjectFactory<T> factory) {
    if (_isDisposed) {
      throwStateError();
    }

    _factory = factory;

    final self = this;
    if (self is ReplaceablePot<T>) {
      self._isPending = false;
    }

    if (_hasObject) {
      _disposer?.call(_object as T);
      _object = factory();
    }
  }
}

/// A variant of [Pot] with the [replace] method for replacing its
/// factory and the object of type [T] created by the factory.
///
/// This pot is created through [Pot.replaceable].
///
/// {@template pot.replaceablePot}
/// ```dart
/// // This pot does not have the replace() method.
/// final pot = Pot(() => Counter());
///
/// // This pot has the replace() method.
/// final replaceablePot = Pot.replaceable(() => Counter());
/// ```
/// {@endtemplate}
///
/// [replaceForTesting] is available on this type of Pot regardless
/// of the flag status of [Pot.forTesting].
@sealed
class ReplaceablePot<T> extends Pot<T> {
  // ignore: public_member_api_docs
  @internal
  ReplaceablePot(super.factory, {super.disposer});

  bool _isPending = false;

  /// Whether the pot is in the pending state.
  ///
  /// If this is true, it means the pot is not ready because a factory
  /// has not been set since the pot was created by [Pot.pending]
  /// or since an existing factory was removed by [resetAsPending].
  bool get isPending => _isPending;

  /// Replaces the factory in a replaceable pot with a new one, and/or
  /// creates a new object using the new factory.
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
  /// * The disposer of the old object is triggered.
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
  ///   // The existing object is discarded and the disposer is triggered.
  ///   // A new object is immediately created by the new factory.
  ///   pot.replace(() => User(id: 200));
  /// }
  /// ```
  ///
  /// If replacements are only necessary for testing, it is safer to make
  /// [ReplaceablePot.replace] unavailable by using a non-replaceable pot.
  /// You can use [replaceForTesting] on a non-replaceable pot instead if
  /// [Pot.forTesting] is set to `true`.
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
      replace(() => throw PotNotReadyException());
      _isPending = true;
    }
  }
}
