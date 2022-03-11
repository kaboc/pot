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
  int? _scope;
  bool _isDisposed = false;

  @visibleForTesting
  bool $expect(T? object) => _object == object;

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

  /// Returns the object created by the factory.
  ///
  /// If an object has not been created yet, this triggers the factory,
  /// which was set in the constructor, to create one.
  ///
  /// ```dart
  /// // The factory is not executed immediately when a pot is created.
  /// final counterPot = Pot<Counter>(() => Counter(0));
  ///
  /// // The factory is triggered when the object is first accessed.
  /// final counter = counterPot.get;
  /// ```
  ///
  /// It also applies to the first access after a reset.
  ///
  /// ```dart
  /// final counterPot = Pot<Counter>(() => Counter(0));
  ///
  /// // An object is created.
  /// var counter = counterPot.get;
  ///
  /// // The object is discarded.
  /// counterPot.reset();
  ///
  /// // A new object is created again.
  /// counter = counterPot.get;
  /// ```
  ///
  /// The object exists while the scope where it was created exists,
  /// so it is discarded when the scope is removed.
  ///
  /// ```dart
  /// final counterPot = Pot<Counter>(() => Counter(0));
  ///
  /// void main() {
  ///   // A new scope is added, and the `currentScope` turns 1.
  ///   // The object is not bound to the scope yet because it hasn't created.
  ///   Pot.pushScope();
  ///
  ///   // An object is created and set in the current scope 1.
  ///   final counter = counterPot.get;
  ///
  ///   // The object is discarded.
  ///   // The scope 1 is removed and the `currentScope` turns 0.
  ///   Pot.popScope();
  /// }
  /// ```
  T get get {
    if (_isDisposed) throwStateError();

    if (_object == null) {
      Pot._scopedResetters
        ..removeFromScope(reset, excludeCurrentScope: true)
        ..addToScope(reset);

      _object = _factory();
      _scope = Pot._currentScope;
    }
    return _object!;
  }

  /// A syntactic sugar for [get].
  ///
  /// ```dart
  /// final counterPot = Pot<Counter>(() => Counter(0));
  /// final counter = counterPot();
  /// ```
  ///
  /// See [get] for details.
  T call() => get;

  /// Calls the factory to create an object.
  ///
  /// If this is called, the factory, which was set in the constructor,
  /// is executed to create an object.
  /// Otherwise, an object is not created until it is needed.
  /// Therefore this method is useful when you want to explicitly cause
  /// the creation immediately.
  ///
  /// ```dart
  /// final counterPot = Pot<Counter>(() => Counter(0));
  ///
  /// void main() {
  ///   counterPot.create();
  ///   ...
  /// }
  /// ```
  ///
  /// [create] is almost the same as [get] and [call], only with the
  /// difference that this does not return the object while they do,
  /// so those can also be used for the same purpose instead.
  ///
  /// Note that calling this method has no effect if the object has
  /// already been created.
  void create() => get;

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

  /// Discards the object that was created by the factory and has been
  /// held in the pot.
  ///
  /// This method triggers the disposer, which was set in the constructor
  /// of [Pot], if the object exists.
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
  /// final counterPot = Pot<Counter>(() => Counter(0));
  ///
  /// void main() {
  ///   // The disposer is not triggered because there is no object yet.
  ///   counterPot.reset();
  /// }
  /// ```
  void reset() {
    if (_isDisposed) throwStateError();

    final object = _object;
    if (object != null) {
      _disposer?.call(object);
      _object = null;
      _scope = null;
    }
    Pot._scopedResetters.removeFromScope(reset);
  }

  /// Replaces the object factory with a new one for testing purposes.
  ///
  /// [ReplaceablePot.replace] is also a method for replacing the factory,
  /// and in fact, it works exactly the same way, but it is not available
  /// to pots created by the default constructor of [Pot].
  /// It is because it should be safer to not have access to a feature
  /// that is not needed usually.
  ///
  /// However, it may be necessary in tests, which are where
  /// [replaceForTesting] comes in handy. Set [Pot.forTesting] to
  /// `true` to use the method, but only when it is really necessary.
  ///
  /// Note that pots created by [Pot.replaceable] can use this method
  /// regardless of whether or not [Pot.forTesting] is enabled.
  ///
  /// For details on how this method is used and what occurs in the
  /// process of replacement, see the document of [ReplaceablePot.replace].
  void replaceForTesting(PotObjectFactory<T> factory) {
    if (!Pot.forTesting && this is! ReplaceablePot) {
      throw PotReplaceError();
    }

    _replace(factory);
  }

  void _replace(PotObjectFactory<T> factory) {
    if (_isDisposed) throwStateError();

    reset();
    _factory = factory;
  }
}

/// A variant of [Pot] with a method for replacing the factory.
///
/// This pot is created through [Pot.replaceable].
///
/// [replaceForTesting] is available on this type of Pot regardless
/// of the flag status of [Pot.forTesting].
@sealed
class ReplaceablePot<T> extends _PotBody<T> {
  @internal
  ReplaceablePot(PotObjectFactory<T> factory, {PotDisposer<T>? disposer})
      : super(factory, disposer: disposer);

  /// Replaces the object factory with new one.
  ///
  /// This method discards the object of type [T] before replacing the
  /// factory, and unsets the object from the scope it was bound to.
  /// A new object is not created until it is first needed.
  ///
  /// It is useful if the object is going to be used only in a
  /// particular scope and therefore you want to set the object in it.
  /// The object is reset when the scope is removed by [Pot.popScope].
  ///
  /// ```dart
  /// final counterPot = Pot<Counter>(() => Counter(0));
  ///
  /// void main() {
  ///   // A new scope is added, and `currentScope` turns 1.
  ///   Pot.pushScope();
  ///
  ///   // The factory is replaced here, but the object does not
  ///   // belong to any scope yet because a Counter object has
  ///   // not been created.
  ///   counterPot.replace(() => Counter(0));
  ///
  ///   // A new object is created by the new factory, and
  ///   // the object gets bound to the current scope 1.
  ///   counterPot.create();
  ///
  ///   // The scope 1 is removed, the object is discarded, and
  ///   // `currentScope` becomes 0.
  ///   // The object is not bound to any scope now.
  ///   Pot.popScope();
  ///
  ///   // A new object is created again because it is accessed.
  ///   // The new object is set in the current scope 0.
  ///   final counter = counterPot.get;
  /// }
  /// ```
  ///
  /// ```dart
  /// final counterPot = Pot<Counter>(() => Counter(0));
  ///
  /// void main() {
  ///   // A Counter object is created and the pot is set
  ///   // in the current scope 0.
  ///   counterPot.create();
  ///
  ///   // A new scope 1 is added.
  ///   Pot.pushScope();
  ///
  ///   // The factory is replaced with new one, so
  ///   // the existing object is discarded.
  ///   counterPot.replace(() => Counter(0));
  ///
  ///   // A new object is created by the new factory, and
  ///   // the object gets bound to the current scope 1.
  ///   counterPot.create();
  /// }
  /// ```
  ///
  /// Note that the `disposer` set in the constructor of [Pot] is not
  /// called if an object has not been created when this method is used.
  ///
  /// Replacing the factory is also convenient in tests. If it is
  /// necessary only in tests and not for some functionality of the
  /// application, [replaceForTesting] is more suitable.
  void replace(PotObjectFactory<T> factory) => _replace(factory);
}
