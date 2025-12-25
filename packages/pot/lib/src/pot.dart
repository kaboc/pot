import 'package:meta/meta.dart' show immutable, sealed, visibleForTesting;

import 'errors.dart';
import 'event.dart';
import 'private/scope_controller.dart';
import 'private/static.dart';
import 'private/utils.dart';

part 'parts/description.dart';
part 'parts/error_utils.dart';
part 'parts/pot_body.dart';

/// The signature of a Singleton factory that creates and returns
/// an object of type [T].
typedef PotObjectFactory<T> = T Function();

/// The signature of a callback that receives an object of type [T]
/// to clean up resources associated with it.
typedef PotDisposer<T> = void Function(T);

/// The signature of a function that removes the listener added
/// by `listen()`.
typedef PotListenerRemover = Future<void> Function();

/// A class that instantiates and caches an object of type [T] until
/// it is removed.
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
/// The `disposer` is triggered when the object is removed by methods
/// such as [reset] and [ReplaceablePot.replace].
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
///   // The object is removed and the disposer function is called.
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
/// It is possible to replace the factory and the object (if existing)
/// using [ReplaceablePot.replace]:
///
/// ```dart
/// final counterPot = Pot.replaceable<User>(() => User.none());
///
/// void main() {
///   counterPot.replace(() => User(id: 100));
/// }
/// ```
///
/// or with [replaceForTesting] (only in tests) if the pot is not of
/// type [ReplaceablePot] created by [Pot.replaceable] or [Pot.pending]:
///
/// ```dart
/// final counterPot = Pot(() => Counter());
///
/// void main() {
///   test('Some test', () {
///     counterPot.replaceForTesting(() => MockCounter());
///   });
/// }
/// ```
///
/// It is easy to remove the object when it becomes no longer necessary.
///
/// ```dart
/// final counter = counterPot();
/// final repository = repositoryPot();
///
/// // Resetting a particular pot to remove the factory and the held object.
/// counterPot.reset();
///
/// // Or resetting all pots (and also scopes) to the initial state.
/// Pot.uninitialize();
/// ```
///
/// The [Pot] class also provides the feature of scoping the range
/// where particular objects exist.
///
/// ```dart
/// // The index of the current scope changes from 0 to 1.
/// Pot.pushScope();
///
/// // The pot is bound to the scope 1 and a Counter is created in the pot.
/// counterPot.create();
///
/// // The pot is reset and the object is removed automatically
/// // when the scope 1 is removed.
/// Pot.popScope();
/// ```
/// {@endtemplate}
@sealed
class Pot<T> extends _PotBody<T> {
  /// Creates a [Pot] that instantiates and caches an object of type [T]
  /// until it is removed.
  ///
  /// {@macro pot.class}
  Pot(super.factory, {super.disposer});

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
  static int get currentScope => ScopeState.currentScope;

  /// Creates a pot of type [ReplaceablePot] that has the ability
  /// to replace its factory with another one of type [T].
  ///
  /// {@macro pot.replaceablePot}
  ///
  /// Replacements are only available for this type of pots.
  ///
  /// See also:
  /// * [ReplaceablePot.replace], which replaces the factory function.
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

  /// Adds a new scope to the stack of scopes.
  ///
  /// {@template pot.scope}
  /// A "scope" here is a notion related to the lifespan of an object
  /// created by and held in a pot.
  ///
  /// For example, if the index number of the current scope is 2 and
  /// the factory set in the constructor is triggered for the first time,
  /// an object is created by the factory and gets bound to the scope 2.
  /// The object exists only while the current scope is 2 or newer, so
  /// it is removed when the scope 2 is removed.
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
  ///   // The object is removed.
  ///   // The scope 1 is removed and the `currentScope` turns 0.
  ///   Pot.popScope();
  /// }
  /// ```
  static void pushScope() {
    ScopeState.scopes.createScope();
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
  ///   // The pots are not bound to the scope at this point because
  ///   // objects haven't been created yet.
  ///   Pot.pushScope();
  ///
  ///   // Pots are bound to the current scope 1 and objects are created.
  ///   final counter1 = counterPot1();
  ///   final counter2 = counterPot2();
  ///
  ///   // The scope 1 is removed.
  ///   // The pots are unbound and the objects are removed from both pots.
  ///   Pot.popScope();
  /// }
  /// ```
  ///
  /// If this is used in the root scope, the index number remains `0`
  /// although every pot in the scope is reset and its disposer is called.
  static void popScope() {
    ScopeState.scopes.clearScope(ScopeState.currentScope, keepScope: false);
  }

  /// Resets all pots in the current scope.
  ///
  /// This removes all objects in the pots bound to the current scope,
  /// and triggers the disposer of each pot.
  ///
  /// Calling this does not affect the scope itself. The index number
  /// of the current scope stays the same.
  ///
  /// See also:
  /// * [reset], which resets a single pot..
  static void resetAllInScope() {
    ScopeState.scopes.clearScope(ScopeState.currentScope, keepScope: true);
  }

  /// Resets the state of all pots and scopes to their initial state.
  ///
  /// This removes all existing scopes and resets the scope index back to 0.
  /// It causes all pots to be reset. For any pot that holds an object,
  /// the disposer is called to allow for manual cleanup when the object is
  /// removed from the pot.
  ///
  /// See also:
  /// * [resetAllInScope], which only resets pots within the current scope.
  static void uninitialize() {
    final count = ScopeState.currentScope;
    for (var i = count; i >= 0; i--) {
      ScopeState.scopes.clearScope(i, keepScope: false);
    }
    PotManager.allInstances.clear();
  }

  /// Starts listening for events related to pots.
  ///
  /// This adds a listener. It should be removed when listening is
  /// no longer necessary. Use the function returned by this method
  /// to remove the added listener.
  ///
  /// ```dart
  /// final removeListener = Pot.listen((event) {
  ///   ...
  /// });
  ///
  /// // Don't forget to stop listening when it is no longer necessary.
  /// removeListener();
  /// ```
  ///
  /// The event data of type [PotEvent] passed to the callback is
  /// subject to change. It is advised not to use this method for
  /// purposes other than debugging.
  static PotListenerRemover listen(void Function(PotEvent event) onData) {
    return PotManager.eventHandler.listen(onData);
  }

  /// Whether there is a listener of Pot events.
  static bool get hasListener => PotManager.eventHandler.hasListener;
}
