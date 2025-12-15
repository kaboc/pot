import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:pot/pot.dart';

import 'extension/extension_manager.dart';
import 'pottery.dart';
import 'utils.dart';

/// An alias of [LocalPottery].
@Deprecated(
  'Use LocalPottery instead. '
  'This was deprecated as of pottery 0.2.0.',
)
typedef ScopedPottery = LocalPottery;

/// The signature of a map consisting of pots and factories.
typedef PotOverrides = Map<Pot<Object?>, PotObjectFactory<Object?>>;

/// The signature of a map consisting of pots and the objects they hold.
typedef LocalPotteryObjects = Map<Pot<Object?>, Object?>;

/// A widget that associates existing pots with new values and makes
/// them accessible from descendants in the tree via the pots.
///
/// {@template localPottery.class}
/// This widget defines new factories for existing pots and binds the
/// objects created by them to the pots so that those objects are made
/// available to descendants.
///
/// An important fact is that the factories of the existing pots are
/// not actually replaced, therefore calling the [Pot.call] method
/// still returns the object held in the global pot. Use [NearestPotOf.of]
/// instead to obtain the local object from the nearest `LocalPottery`
/// ancestor. The example below illustrates the behaviour.
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
///       pots: {
///         fooPot: () => Foo(222),
///       },
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
/// This is useful when you need in descendants some objects that are
/// different from the ones held in global pots but of the same type.
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
///         pots: {
///           todosNotifierPot: () => TodosNotifierPot(category: category),
///         },
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
/// * `LocalPottery` creates an object immediately, whereas
///   `Pottery` creates (replaces, more precisely) an object only
///   if the relevant Pot already have one.
/// * As already mentioned, objects created by `LocalPottery` are
///   only accessible with [NearestPotOf.of].
/// * Objects created by `LocalPottery` are not automatically
///   discarded when the `LocalPottery` is removed from the tree.
///   Use [disposer] to do clean-up.
///
/// Also note that an error arises only at runtime if the map
/// contains wrong pairs of pot and factory. Make sure to specify
/// a correct factory creating an object of the correct type.
///
/// It is advised that `LocalPottery` be used only where it is
/// absolutely necessary. Using it too much may make it harder to
/// follow the code of your app.
/// {@endtemplate}
class LocalPottery extends StatefulWidget {
  /// Creates a [LocalPottery] widget that associates existing pots
  /// with new values and makes them accessible from descendants in
  /// the tree via the pots.
  ///
  /// {@macro localPottery.class}
  const LocalPottery({
    super.key,
    required this.pots,
    required this.builder,
    this.disposer,
  });

  /// A map of pots and factories.
  ///
  /// The factories are called immediately to create objects when
  /// the [LocalPottery] is created. The objects are accessible
  /// with [NearestPotOf.of] (not with [Pot.call]) from the
  /// descendants.
  final PotOverrides pots;

  /// A function called to obtain the child widget.
  final WidgetBuilder builder;

  /// A function called when this [LocalPottery] is removed from
  /// the tree permanently.
  ///
  /// [LocalPottery], unlike [Pottery], does not automatically
  /// discard the objects that were created by the factories passed
  /// to the [pots] argument. Use this disposer to specify a callback
  /// function to clean up the objects like ValueNotifiers, which are
  /// supposed to be disposed of when no longer used.
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
      for (final (pot, objectFactory) in widget.pots.records)
        pot: objectFactory(),
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
    return widget.builder(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<LocalPotteryObjects>('objects', _objects));
  }
}

/// Extension on [Pot] used in relation to [LocalPottery].
extension NearestPotOf<T> on Pot<T> {
  ({Object? object, bool found}) _findObject(BuildContext context) {
    if (context.widget is LocalPottery) {
      final state = (context as StatefulElement).state;
      final pots = (state as _LocalPotteryState)._objects;

      for (final (pot, object) in pots.records) {
        if (pot == this) {
          // `found` flag is necessary because it is impossible
          // to distinguish `null` in object from "not found"
          // when T is nullable.
          return (object: object, found: true);
        }
      }
    }

    return (object: null, found: false);
  }

  /// An extension method of [Pot] that recursively visits ancestors
  /// to find the nearest [LocalPottery] and obtains the object bound
  /// locally to the pot.
  ///
  /// If the pot which this method is called on is contained as a key
  /// in the `pots` map of a [LocalPottery] located up in the tree,
  /// the value corresponding to the key is obtained from there.
  ///
  /// If no such `LocalPottery` is found, the object held in the global
  /// pot is returned, in which case, the return value is the same as
  /// that of the [Pot.call] method.
  ///
  /// See the document of [LocalPottery] for usage.
  ///
  /// Note that calling this method is relatively expensive (O(N) in
  /// the depth of the tree). Only call it if the distance from the
  /// widget associated with the [BuildContext] to the desired ancestor
  /// is known to be small and bounded.
  T of(BuildContext context) {
    // Targets the current BuildContext too so that the local objects
    // become available from within the builder callback.
    var (:object, :found) = _findObject(context);

    if (!found) {
      context.visitAncestorElements((element) {
        // Suppresses false positive warning
        // ignore: unnecessary_statements
        (:object, :found) = _findObject(element);
        return !found;
      });
    }

    return found ? object as T : this();
  }
}
