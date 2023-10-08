import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:pot/pot.dart';

import 'pottery.dart';

/// The signature of a map consisting of pots and factories.
typedef PotOverrides = Map<Pot<Object?>, PotObjectFactory<Object?>>;

/// The signature of a map consisting of pots and the objects they hold.
typedef ScopedPots = Map<Pot<Object?>, Object?>;

/// A widget that associates existing pots with new values and makes
/// them accessible from descendants in the tree via the pots.
///
/// {@template scopedPottery.class}
/// This widget defines new factories for existing pots and binds the
/// objects created by them to the pots so that those objects are made
/// available to descendants.
///
/// An important fact is that the factories of the existing pots are
/// not actually replaced, therefore calling the [Pot.call] method
/// still returns the object held in the global pot. Use [NearestPotOf.of]
/// instead to obtain the scoped object. The example below illustrates
/// the behaviour.
///
/// ```dart
/// final fooPot = Pot(() => Foo(111));
///
/// ...
///
/// class ParentWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return ScopedPottery(
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
/// In the following example, a `ScopedPottery` provides its descendant
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
///       builder: (context) => ScopedPottery(
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
/// `ScopedPottery` and [Pottery]:
///
/// * Objects are created immediately when `ScopedPottery` is created.
/// * As already mentioned, objects created with `ScopedPottery` are
///   only accessible with [NearestPotOf.of].
/// * Objects created with `ScopedPottery` are not automatically
///   discarded when the `ScopedPottery` is removed from the tree.
///   Use [disposer] to do clean-up.
///
/// Also note that an error arises only at runtime if the map
/// contains wrong pairs of pot and factory. Make sure to specify
/// a correct factory creating an object of the correct type.
///
/// It is advised that `ScopedPottery` be used only where it is
/// absolutely necessary. Using it too much may make it harder to
/// follow the code of your app.
/// {@endtemplate}
class ScopedPottery extends StatefulWidget {
  /// Creates a [ScopedPottery] widget that associates existing pots
  /// with new values and makes them accessible from descendants in
  /// the tree via the pots.
  ///
  /// {@macro scopedPottery.class}
  const ScopedPottery({
    super.key,
    required this.pots,
    required this.builder,
    this.disposer,
  });

  /// A map of pots and factories.
  ///
  /// The factories are called immediately to create objects when
  /// the [ScopedPottery] is created. The objects are accessible
  /// with [NearestPotOf.of] (not with [Pot.call]) from the descendants.
  final PotOverrides pots;

  /// A builder function called to obtain the child widget.
  final WidgetBuilder builder;

  /// A function called when this [ScopedPottery] is removed from
  /// the tree permanently.
  ///
  /// [ScopedPottery], unlike [Pottery], does not automatically
  /// discard the objects that were created by the factories passed
  /// to the [pots] argument. Use this disposer to specify a callback
  /// function to clean up the objects like ValueNotifiers, which are
  /// supposed to be disposed of when no longer used.
  final ValueSetter<ScopedPots>? disposer;

  @override
  State<ScopedPottery> createState() => _ScopedPotteryState();
}

class _ScopedPotteryState extends State<ScopedPottery> {
  late final ScopedPots _scopedPots;

  @override
  void initState() {
    super.initState();
    _scopedPots = {
      for (final entry in widget.pots.entries) entry.key: entry.value(),
    };
  }

  @override
  void dispose() {
    widget.disposer?.call(_scopedPots);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ScopedPots>('scopedPots', _scopedPots));
  }
}

/// Extension on [Pot] used in relation to [ScopedPottery].
extension NearestPotOf<T> on Pot<T> {
  MapEntry<Pot<Object?>, Object?>? _findEntry(BuildContext element) {
    if (element.widget is ScopedPottery) {
      final state = (element as StatefulElement).state;
      final pots = (state as _ScopedPotteryState)._scopedPots;

      for (final entry in pots.entries) {
        if (entry.key == this) {
          // Returns MapEntry instead of entry.value because
          // it is impossible to distinguish `null` from "not found"
          // if T (the type of the value) is nullable.
          return entry;
        }
      }
    }

    return null;
  }

  /// An extension method of [Pot] that finds the nearest [ScopedPottery]
  /// from ancestors and obtains the object locally bound to the pot.
  ///
  /// If the pot which this method is called on is contained as a key
  /// in the `pots` map of a [ScopedPottery] located up in the tree,
  /// the value corresponding to the key is obtained from there.
  ///
  /// If no such `ScopedPottery` is found, the object held in the global
  /// pot is returned, in which case, the return value is the same as
  /// that of the [Pot.call] method.
  ///
  /// See the document of [ScopedPottery] for usage.
  ///
  /// Note that calling this method is relatively expensive (O(N) in
  /// the depth of the tree). Only call it if the distance from the
  /// widget associated with the [BuildContext] to the desired ancestor
  /// is known to be small and bounded.
  T of(BuildContext context) {
    // Targets the current BuildContext too so that the scoped pot
    // becomes available from within the builder callback.
    var entry = _findEntry(context);

    if (entry == null) {
      context.visitAncestorElements((element) {
        entry = _findEntry(element);
        return entry == null;
      });
    }

    return entry == null ? this() : entry!.value as T;
  }
}
