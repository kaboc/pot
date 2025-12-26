import 'package:flutter/foundation.dart'
    show DiagnosticPropertiesBuilder, DiagnosticsProperty;
import 'package:flutter/widgets.dart';

import 'package:pot/pot.dart';

import 'common_types.dart';
import 'extension/extension_manager.dart';
import 'pottery.dart';
import 'utils.dart';

/// The signature of a map consisting of pots and the objects they hold.
typedef LocalPotteryObjects = Map<Pot<Object?>, Object?>;

class _InheritedLocalPottery extends InheritedWidget {
  const _InheritedLocalPottery({required this.objects, required super.child});

  final LocalPotteryObjects objects;

  @override
  bool updateShouldNotify(_InheritedLocalPottery oldWidget) {
    return false;
  }
}

/// A widget that associates existing [Pot]s with new values and makes
/// them accessible from descendants in the tree via the pots.
///
/// {@template localPottery.class}
/// This widget defines new factories for existing pots and binds the
/// objects created by them to the pots so that those objects are made
/// available to descendants.
///
/// An important fact is that `LocalPottery`, unlike 'Pottery`, does
/// not replace or override the factories stored in pots. Calling the
/// [Pot.call] method still returns the object held in the pot.
/// Use `of()` instead to obtain the associated object from the nearest
/// `LocalPottery` ancestor that provides it.
///
/// > [!NOTE]
/// > Unlike with [Pottery], pots used in [LocalPottery] are not required
/// > to be of type [ReplaceablePot].
///
/// ```dart
/// final fooPot = Pot(() => Foo(111));
///
/// ...
///
/// class ParentWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return LocalPottery(
///       overrides: [
///         fooPot.set(() => Foo(222)),
///       ],
///       builder: (context) {
///         print(fooPot()); // 111
///         print(fooPot.of(context)); // 222
///
///         return ChildWidget();
///       },
///     );
///   }
/// }
///
/// class ChildWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     print(fooPot()); // 111
///     print(fooPot.of(context)); // 222
///     ...
///   }
/// }
/// ```
///
/// This is useful when you need to use some object locally in a subtree
/// instead of the globally accessible one stored in a pot itself.
///
/// In the following example, a `LocalPottery` provides its descendant
/// (TodoListPage) with a notifier for a specific category. It allows
/// the previous page to control which category the next page is
/// associated with.
///
/// ```dart
/// Navigator.of(context).push(
///   TodoListPage.route(category: Category.housework),
/// );
///
/// ...
///
/// class TodoListPage extends StatelessWidget {
///   const TodoListPage._();
///
///   static Route<void> route({required Category category}) {
///     return MaterialPageRoute(
///       builder: (context) => LocalPottery(
///         overrides: [
///           todosNotifierPot.set(() => TodosNotifierPot(category: category)),
///         ],
///         builder: (context) => const TodoListPage(),
///       ),
///     );
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     // This is a notifier for a list of a specific category.
///     final notifier = todosNotifierPot.of(context);
///
///     return ValueListenableBuilder(
///       valueListenable: notifier,
///       builder: (context, state, child) {
///         return Scaffold(
///           appBar: AppBar(
///             // The title is "Housework" if the current
///             // notifier is for the category of housework.
///             title: Text(state.category.label),
///           ),
///           ...
///         );
///       },
///     );
///   }
/// }
/// ```
///
/// Note that there are several important differences between
/// `LocalPottery` and [Pottery]:
///
/// * [LocalPottery] creates objects immediately and stores them locally,
///   whereas [Pottery] replaces the factories of the pots, and the objects
///   are created by the new factories only when they are accessed.
/// * An object stored by `LocalPottery` is accessible only by calling
///   `of()` on a pot, where the pot acts as the key for the object.
/// * Objects created by `LocalPottery` are not automatically disposed
///   when the `LocalPottery` is removed from the tree. Use
///   the [disposer] provided to [LocalPottery] for clean-up.
///
/// Also note that an error arises only at runtime if the map
/// contains wrong pairs of pot and factory. Make sure to specify
/// a correct factory creating an object of the correct type.
/// {@endtemplate}
class LocalPottery extends StatefulWidget {
  /// Creates a [LocalPottery] widget that associates pots with new values
  /// and makes them accessible from the widget subtree via the pots.
  ///
  /// {@macro localPottery.class}
  const LocalPottery({
    super.key,
    required this.overrides,
    required this.builder,
    this.disposer,
  });

  /// Pairs of a [Pot] and its factory.
  ///
  /// The factories are called immediately to create objects when the
  /// [LocalPottery] is created. The object is accessible by calling
  /// `of()` (not [Pot.call]) on a pot from the widget subtree.
  final List<PotOverride<Object?>> overrides;

  /// A function called to obtain the child widget.
  final WidgetBuilder builder;

  /// A function called when this [LocalPottery] is removed from
  /// the tree permanently.
  ///
  /// [LocalPottery], unlike [Pottery], does not automatically call
  /// the disposer of each pot. Use this [disposer] to define a custom
  /// clean-up function (e.g. disposing of a `ValueNotifier`).
  /// It receives the objects created within this `LocalPottery` so
  /// that they can be disposed of manually.
  final void Function(LocalPotteryObjects)? disposer;

  @override
  State<LocalPottery> createState() => _LocalPotteryState();
}

class _LocalPotteryState extends State<LocalPottery> {
  late final LocalPotteryObjects _objects;

  // Only used in debug mode
  PotteryExtensionManager? _extensionManager;

  @override
  void initState() {
    super.initState();

    _objects = {
      for (final PotOverride(:pot, :factory) in widget.overrides)
        pot: factory(),
    };

    runIfDebug(() {
      _extensionManager = PotteryExtensionManager.createSingle()
        ..onLocalPotteryCreated(this, _objects);
    });
  }

  @override
  void dispose() {
    widget.disposer?.call(_objects);
    _extensionManager?.onLocalPotteryRemoved(this, _objects);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedLocalPottery(
      objects: _objects,
      child: Builder(
        builder: (context) {
          return widget.builder(context);
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<LocalPotteryObjects>('objects', _objects));
  }
}

/// An extension on [Pot] to integrate with [LocalPottery].
extension NearestLocalPotObjectOf<T> on Pot<T> {
  ({Object? object, bool found}) _findObject(BuildContext context) {
    // Apparently, this lookup returns the current element
    // if no matching ancestor is found.
    final element = context
        .getElementForInheritedWidgetOfExactType<_InheritedLocalPottery>();

    if (element == null || element == context) {
      return (object: null, found: false);
    }

    final inheritedLocalPottery = element.widget as _InheritedLocalPottery;
    for (final (pot, object) in inheritedLocalPottery.objects.records) {
      if (pot == this) {
        // The `found` flag is necessary as a null value cannot
        // be distinguished from "not found" when T is nullable.
        return (object: object, found: true);
      }
    }

    return _findObject(element);
  }

  ({Object? object, bool found}) _recursivelyFindObject(BuildContext context) {
    // Targets the current BuildContext too so that the local objects
    // become available from within the builder callback.
    var (:object, :found) = _findObject(context);

    if (!found) {
      context.visitAncestorElements((element) {
        (:object, :found) = _findObject(element);
        return !found;
      });
    }

    return (object: object, found: found);
  }

  /// Returns the object provided by the nearest [LocalPottery] ancestor
  /// that has this [Pot] in its `overrides` list, if any.
  ///
  /// Unlike [of], this method returns `null` if no such `LocalPottery`
  /// ancestor is found.
  ///
  /// This method efficiently looks up the widget tree to find a localized
  /// instance of the object associated with this pot.
  ///
  /// See also:
  /// * [of], which throws instead of returning `null` if no relevant
  ///   `LocalPottery` ancestor is found.
  /// * [LocalPottery], which provides the object that the `of()` and
  ///   `maybeOf` methods obtain.
  T? maybeOf(BuildContext context) {
    final (:object, :found) = _recursivelyFindObject(context);
    return found ? object as T : null;
  }

  /// Returns the object provided by the nearest [LocalPottery] ancestor
  /// that has this [Pot] in its 'overrides' list.
  ///
  /// Unlike [maybeOf], this method throws if no such `LocalPottery` ancestor
  /// is found.
  ///
  /// This method efficiently looks up the widget tree to find a localized
  /// instance of the object associated with this pot.
  ///
  /// See also:
  /// * [maybeOf], which doesn't throw if no relevant `LocalPottery`
  ///   ancestor is found. It returns null instead.
  /// * [LocalPottery], which provides the object that the `of()` and
  ///   `maybeOf` methods obtain.
  T of(BuildContext context) {
    final (:object, :found) = _recursivelyFindObject(context);
    if (found) {
      return object as T;
    }

    throw LocalPotteryNotFoundException(
      this is ReplaceablePot ? 'ReplaceablePot' : 'Pot',
    );
  }
}

/// The error that is thrown when `of` is called but no surrounding
/// [LocalPottery] ancestor provides a localized value for the pot.
///
/// This usually happens when the [BuildContext] passed to `of()` is
/// not a descendant of a `LocalPottery` that contains an entry for
/// the requested pot in its `overrides` list.
class LocalPotteryNotFoundException implements Exception {
  /// Creates a [LocalPotteryNotFoundException] with the type of the pot
  /// for which a localized value was not found.
  const LocalPotteryNotFoundException(this.potTypeName);

  /// The type of the pot used as a key to find the localized object.
  final String potTypeName;

  @override
  // coverage:ignore-line
  String toString() => '''
Error: No localized value found for $potTypeName.

To fix this, please ensure that:
  * The widget tree contains a LocalPottery widget above the one calling of().
  * The LocalPottery includes an entry for $potTypeName in its `overrides` list to provide a localized value.
''';
}
