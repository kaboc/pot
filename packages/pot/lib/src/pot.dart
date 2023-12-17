import 'dart:async' show StreamController;

import 'package:meta/meta.dart' show internal, sealed, visibleForTesting;

import 'errors.dart';

part 'event/controller.dart';
part 'event/data.dart';
part 'extensions.dart';
part 'pot_body.dart';

/// The signature of a callback that creates and returns an object
/// of type [T].
typedef PotObjectFactory<T> = T Function();

/// The signature of a callback that receives an object of type [T]
/// to be disposed of.
typedef PotDisposer<T> = void Function(T);

/// The signature of a function that removes the listener added
/// by `listen()`.
typedef RemovePotListener = Future<void> Function();

typedef _Scopes = List<List<_PotBody<Object?>>>;

/// A class that instantiates and caches an object of type [T] until
/// it is discarded.
///
/// {@template pot.class}
/// A [Pot] is a holder that keeps an object instance.
///
/// The `factory` provided to the constructor instantiates an object.
/// It always works in a lazy manner; it does not create an object
/// until it is first needed. The object is cached, so once it is
/// created, a new one is not created unless the pot is reset or the
/// factory is replaced.
///
/// The `disposer` is triggered when the object is disposed by
/// methods such as [reset] and [ReplaceablePot.replace].
///
/// ```dart
/// final counterPot = Pot<Counter>(
///   () => Counter(),
///   disposer: (counter) => counter.dispose(),
/// );
///
/// void main() {
///   // The factory has not been called yet at this point.
///   ...
///
///   // The factory creates a Counter object.
///   final counter = counterPot();
///   ...
///
///   // The object is discarded and the disposer function is called.
///   counterPot.reset();
/// }
/// ```
///
/// instead of:
///
/// ```dart
/// final counter = Counter();
/// ```
///
/// It is possible to replace the factory and/or the object with
/// [ReplaceablePot.replace].
///
/// ```dart
/// final counterPot = Pot.replaceable<User>(() => User.none());
///
/// void main() {
///   counterPot.replace(() => User(id: 100));
/// }
/// ```
///
/// or with [replaceForTesting] if the pot is not the one created by
/// [Pot.replaceable]:
///
/// ```dart
/// final counterPot = Pot(() => Counter());
///
/// void main() {
///   Pot.forTesting = true;
///
///   test('Some test', () {
///     counterPot.replaceForTesting(() => MockCounter());
///   });
/// }
/// ```
///
/// It is easy to discard the object when it becomes no longer necessary.
///
/// ```dart
/// final counter = counterPot();
/// final repository = repositoryPot();
/// ...
/// Pot.resetAll();
/// ```
///
/// The [Pot] class also provides the feature of scoping the range
/// where particular objects exist.
///
/// ```dart
/// // The index of the current scope changes from 0 to 1.
/// Pot.pushScope();
///
/// // A counter object is created in the scope 1.
/// counterPot.create();
///
/// // The object is discarded when the scope 1 is removed.
/// Pot.popScope();
/// ```
/// {@endtemplate}
@sealed
class Pot<T> extends _PotBody<T> {
  /// Creates a Pot that instantiates and caches an object of type [T]
  /// until it is discarded.
  ///
  /// {@macro pot.class}
  Pot(super.factory, {super.disposer});

  static int _currentScope = 0;
  static final _Scopes _scopes = [[]];
  static final _eventController = _EventController();

  @visibleForTesting
  // ignore: library_private_types_in_public_api, public_member_api_docs
  static List<List<void Function()>> get $scopedResetters => [
        for (final pots in _scopes) [for (final pot in pots) pot.reset],
      ];

  @internal
  @visibleForTesting
  // ignore: public_member_api_docs
  static void Function(Object?) $warningPrinter = print;

  /// The flag that shows whether [replaceForTesting] is enabled.
  ///
  /// Defaults to `false`, which means disabled.
  /// If this is set to `true`, [replaceForTesting] becomes available
  /// also on non-replaceable pots.
  ///
  /// {@macro pot.replaceForTesting.example}
  ///
  /// See [replaceForTesting] for more details.
  static bool forTesting = false;

  /// The index number of the current scope.
  ///
  /// The number starts from 0.
  ///
  /// {@macro pot.scope}
  ///
  /// ```dart
  /// void main() {
  ///   print(Pot.currentScope); // 0
  ///
  ///   Pot.pushScope();
  ///   print(Pot.currentScope); // 1
  ///
  ///   Pot.popScope();
  ///   print(Pot.currentScope); // 0
  /// }
  /// ```
  static int get currentScope => _currentScope;

  /// Creates a pot of type [ReplaceablePot] that has the ability
  /// to replace its factory with another one of type [T].
  ///
  /// {@macro pot.replaceablePot}
  ///
  /// Replacements are only available for this type of pots.
  ///
  /// See [ReplaceablePot.replace] for more details.
  static ReplaceablePot<T> replaceable<T>(
    PotObjectFactory<T> factory, {
    PotDisposer<T>? disposer,
  }) {
    return ReplaceablePot<T>._(factory, disposer: disposer);
  }

  /// Creates a pot of type [ReplaceablePot] where its factory of
  /// type [T] is yet to be set.
  ///
  /// This is an alternative to [Pot.replaceable] for convenience,
  /// useful if the object is unnecessary or the factory is unavailable
  /// until some point.
  ///
  /// A factory must be set with [ReplaceablePot.replace] before
  /// the pot is used. Otherwise the [PotNotReadyException] is thrown.
  static ReplaceablePot<T> pending<T>({PotDisposer<T>? disposer}) {
    return ReplaceablePot._pending(disposer: disposer);
  }

  static void _incrementCurrentScopeNumber() {
    _currentScope++;
  }

  static void _decrementCurrentScopeNumber() {
    _currentScope--;
  }

  /// Adds a new scope to the stack of scopes.
  ///
  /// {@template pot.scope}
  /// A "scope" here is a notion related to the lifespan of an object
  /// created by and held in a pot.
  ///
  /// For example, if the index number of the current scope is 2 and
  /// the factory set in the constructor is triggered for the first time,
  /// an object is created by the factory and gets bound to the scope 2.
  /// The object exists while the current scope is 2 or newer, so it is
  /// discarded when the scope 2 is removed.
  /// {@endtemplate}
  ///
  /// ```dart
  /// final counterPot = Pot(() => Counter(0));
  ///
  /// void main() {
  ///   // A new scope is added, and the `currentScope` turns 1.
  ///   // The object is not bound to the scope yet because it hasn't created.
  ///   Pot.pushScope();
  ///
  ///   // An object is created and set in the current scope.
  ///   final counter = counterPot();
  ///
  ///   // The object is discarded.
  ///   // The scope 1 is removed and the `currentScope` turns 0.
  ///   Pot.popScope();
  /// }
  /// ```
  static void pushScope() {
    _scopes.createScope();
  }

  /// Removes the current scope from the stack of scopes.
  ///
  /// This resets all pots in the current scope, triggers the disposer of
  /// each of them, and decrements the index number of the current scope.
  ///
  /// ```dart
  /// final counterPot1 = Pot(() => Counter(0));
  /// final counterPot2 = Pot(() => Counter(0));
  ///
  /// void main() {
  ///   // A new scope is added, and the `currentScope` turns 1.
  ///   // The objects are not bound to the scope yet because
  ///   // they haven't created.
  ///   Pot.pushScope();
  ///
  ///   // Object are created and set in the current scope 1.
  ///   final counter1 = counterPot1();
  ///   final counter2 = counterPot2();
  ///
  ///   // The scope 1 is removed, and the objects in both
  ///   // of the two pots are discarded.
  ///   Pot.popScope();
  /// }
  /// ```
  ///
  /// If this is used in the root scope, the index number remains `0`
  /// although every pot in the scope is reset and its disposer is called.
  static void popScope() {
    _scopes.clearScope(_currentScope, keepScope: false);
  }

  /// Resets all pots in the current scope.
  ///
  /// This discards all the objects bound to the current scope, and
  /// triggers the disposer of each pot.
  ///
  /// Calling this does not affect the scope itself. The index number
  /// of the current scope stays the same.
  ///
  /// See [reset] for details on a reset of an object.
  static void resetAllInScope() {
    _scopes.clearScope(_currentScope, keepScope: true);
  }

  /// Resets all pots of all scopes.
  ///
  /// This discards all the objects bound to any scopes, and triggers
  /// the disposer of each pot.
  ///
  /// If `keepScopes` is `false` or not specified, calling this method
  /// does not affect the scopes themselves; the index number of the
  /// current scope stays the same. Otherwise, the index is reset to 0.
  ///
  /// See [reset] for details on a reset of an object.
  static void resetAll({bool keepScopes = true}) {
    final count = _currentScope;
    for (var i = count; i >= 0; i--) {
      _scopes.clearScope(i, keepScope: keepScopes);
    }
  }

  /// Starts listening for events related to pots.
  ///
  /// This adds a listener. It should be removed when listening is
  /// no longer necessary. Use the function returned by this method
  /// to remove the added listener.
  ///
  /// The event data of type [PotEvent] passed to the callback of this
  /// method is subject to change. It is advised not to use the method
  /// for purposes other than debugging.
  static RemovePotListener listen(void Function(PotEvent event) onData) {
    return _eventController.listen(onData);
  }

  /// Whether there is a listener of Pot events.
  static bool get hasListener => _eventController.hasListener;

  // Used from package:pottery.
  @internal
  // ignore: public_member_api_docs
  static void $addEvent(
    PotEventKind kind, {
    required Iterable<Pot<Object?>> pots,
  }) {
    Pot._eventController.addEvent(kind, pots: pots);
  }
}
