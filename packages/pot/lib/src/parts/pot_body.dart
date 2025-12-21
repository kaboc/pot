part of '../pot.dart';

// Actual implementation of Pot.
// This has instance members, whereas Pot has static members.
class _PotBody<T> {
  _PotBody(PotObjectFactory<T> factory, {PotDisposer<T>? disposer})
      : _factory = factory,
        _disposer = disposer {
    PotManager.allInstances[_pot] = DateTime.now();
    PotManager.eventHandler.addEvent(PotEventKind.instantiated, pots: [_pot]);
  }

  PotObjectFactory<T> _factory;
  PotDisposer<T>? _disposer;

  T? _object;
  int? _scope;
  int? _prevScope;
  bool _hasObject = false;
  bool _isDisposed = false;

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

  Pot<T> get _pot => this as Pot<T>;

  @override
  String toString() {
    final self = this;

    return '${_pot.identity()}('
        'isPending: ${self is ReplaceablePot<T> && self._isPending}, '
        'isDisposed: $_isDisposed, '
        'hasDisposer: ${_disposer != null}, '
        'hasObject: $_hasObject, '
        'object: $_object, '
        'scope: $_scope'
        ')';
  }

  void _callDisposer() {
    if (_disposer != null) {
      _disposer?.call(_object as T);
      PotManager.eventHandler
          .addEvent(PotEventKind.disposerCalled, pots: [_pot]);
    }
  }

  void _replace(PotObjectFactory<T> factory, {bool asPending = false}) {
    if (_isDisposed) {
      throwStateError();
    }

    _factory = factory;

    final self = this;
    if (self is ReplaceablePot<T>) {
      self._isPending = asPending;
    }

    if (_hasObject) {
      _callDisposer();
      _object = factory();
    }

    PotManager.eventHandler.addEvent(
      asPending ? PotEventKind.markedAsPending : PotEventKind.replaced,
      pots: [_pot],
    );
  }

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
  /// // The object is removed from the pot.
  /// counterPot.reset();
  ///
  /// // A new object is created again.
  /// counter = counterPot();
  /// ```
  ///
  /// The object exists only while the scope where it was created exists,
  /// so it is removed when the scope is removed.
  ///
  /// ```dart
  /// final counterPot = Pot(() => Counter(0));
  ///
  /// void main() {
  ///   // A new scope is added, and the `currentScope` turns 1.
  ///   // The object is not bound to the scope yet because it hasn't created.
  ///   Pot.pushScope();
  ///
  ///   // The pot is bound to the current scope 1 and an object is created.
  ///   final counter = counterPot();
  ///
  ///   // The scope 1 is removed and the `currentScope` turns 0.
  ///   // The pot is unbound and the object is removed from the pot.
  ///   Pot.popScope();
  /// }
  /// ```
  ///
  /// {@template pot.suppressWarning}
  /// The `suppressWarning` flag disables the printing of misuse warnings
  /// to the console when set to `true`. Omitting the setting or specifying
  /// `false` keeps warnings active, but they are automatically suppressed
  /// in production.
  /// {@endtemplate}
  T call({bool suppressWarning = false}) {
    if (_isDisposed) {
      throwStateError();
    }

    if (!_hasObject) {
      debugWarning(suppressWarning: suppressWarning);

      _scope = ScopeState.currentScope;
      _prevScope = _scope;

      ScopeState.scopes
        ..removePot(_pot, excludeCurrentScope: true)
        ..addPot(_pot);

      _object = _factory();
      _hasObject = true;

      PotManager.eventHandler.addEvent(PotEventKind.created, pots: [_pot]);
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
  /// This method is essentially the same as [call], with only the difference
  /// that this does not return the object while `call()` does, so `call()`
  /// can also be used to create an object.
  ///
  /// {@macro pot.suppressWarning}
  ///
  /// > [!NOTE]
  /// > Calling this method has no effect if the pot already has an object.
  void create({bool suppressWarning = false}) {
    call(suppressWarning: suppressWarning);
  }

  /// Discards resources in the pot.
  ///
  /// Once this is called, the pot is no longer in a usable state, and
  /// subsequent calls to most of its members will throw.
  ///
  /// > [!NOTE]
  /// > This method internally calls the [reset] method, which triggers
  /// > the disposer.
  void dispose() {
    if (!_isDisposed) {
      reset();
      _isDisposed = true;
      _scope = null;
      _disposer = null;
      ScopeState.scopes.removePot(_pot);
      PotManager.allInstances.remove(_pot);
      PotManager.eventHandler.addEvent(PotEventKind.disposed, pots: [_pot]);
    }
  }

  /// Remove the object of type [T] that was created by the factory
  /// and has been held in the pot.
  ///
  /// This method triggers the disposer, which was set in the constructor
  /// of [Pot], if an object exists.
  ///
  /// This does not dispose of the pot itself, so a new object is created
  /// again when it is need. Use this when the object is not used any more
  /// for now, and get a new object when it is necessary again.
  ///
  /// ```dart
  /// final counterPot = Pot<Counter>(
  ///   () => Counter(0),
  ///   disposer: (counter) => print('Object removed'),
  /// );
  ///
  /// void main() {
  ///   var counter = counterPot();
  ///   counter.increment();
  ///   print(counter.value); // 1
  ///
  ///   // Removes the existing object from the pot,
  ///   // and calls the disposer, printing "Object removed".
  ///   counterPot.reset();
  ///
  ///   // A new object is created if it is accessed.
  ///   counter = counterPot();
  ///   print(counter.value); // 0
  /// }
  /// ```
  ///
  /// > [!NOTE]
  /// > Calling this method has no effect if the pot does not have an object.
  /// >
  /// > ```dart
  /// > final counterPot = Pot(() => Counter(0));
  /// >
  /// > void main() {
  /// >   // The disposer is not triggered because there is no object yet.
  /// >   counterPot.reset();
  /// > }
  /// ```
  void reset() {
    if (_isDisposed) {
      throwStateError();
    }

    if (_hasObject) {
      _callDisposer();
      _object = null;
      _hasObject = false;
      _scope = null;
      ScopeState.scopes.removePot(_pot);
      PotManager.eventHandler.addEvent(PotEventKind.reset, pots: [_pot]);
    }
  }

  /// Overrides the factory function and refreshes the existing object using
  /// the new factory, if any, specifically for testing purposes.
  ///
  /// ```dart
  /// final counterPot = Pot(() => Counter(0));
  ///
  /// void main() {
  ///   test('Counter test', () {
  ///     counterPot.replaceForTesting(() => Counter(100));
  ///   });
  /// }
  /// ```
  ///
  /// This method is available even on non-replaceable pots. Using it instead
  /// of `replace()` ensures that factory replacement is restricted to testing
  /// and prevents accidental misuse in application logic.
  ///
  /// > [!NOTE]
  /// > You will get a warning from static analysis if you use it outside
  /// > of a test.
  ///
  /// See also:
  /// * [ReplaceablePot.replace], the standard method for replacing factories
  ///   in non-test scenarios.
  @visibleForTesting
  void replaceForTesting(PotObjectFactory<T> factory) {
    _replace(factory);
  }

  /// Notifies listeners that the object inside the pot has been updated.
  ///
  /// The pot automatically notifies listeners only about changes to the
  /// pot itself (e.g., created, reset). It does not automatically notify
  /// listeners when the object it holds changes or when the object's
  /// internal state changes.
  ///
  /// Call this method when you need to notify listeners about changes that
  /// happen within the held object.
  ///
  /// > [!NOTE]
  /// > This notification affects not only the listeners you add via
  /// > [Pot.listen], but also the Pottery DevTools extension. For example,
  /// > if a pot holds a `ValueNotifier`, neither changes to the notifier
  /// > nor changes in its value are reflected in the extension page unless
  /// > you call this method.
  void notifyObjectUpdate() {
    if (_isDisposed) {
      throwStateError();
    }

    PotManager.eventHandler.addEvent(PotEventKind.objectUpdated, pots: [_pot]);
  }
}

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
