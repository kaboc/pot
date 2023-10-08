import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:pot/pot.dart';

/// The signature of a map consisting of replaceable pots and factories.
typedef PotReplacements
    = Map<ReplaceablePot<Object?>, PotObjectFactory<Object?>>;

/// A widget that limits the scope where particular [Pot]s are
/// available in the widget tree.
///
/// {@template pottery.class}
/// The factory of the [ReplaceablePot] specified as the key in the
/// map ([pots]) is replaced with the [PotObjectFactory] specified as
/// its value, and the factory creates an object inside the pot when
/// the [Pottery] is inserted into the tree.
///
/// If the pottery is removed from the tree, the object is discarded
/// and the factory is removed. After the removal, trying to access
/// the object throws [PotNotReadyException].
///
/// ```dart
/// final notesNotifierPot = Pot.pending<NotesNotifier>(
///   disposer: (notifier) => notifier.dispose(),
/// );
/// final notesRepositoryPot = Pot.pending<NotesRepository>(
///   disposer: (repository) => repository.dispose(),
/// );
///
/// ...
///
///
/// child: Pottery(
///   pots: {
///     notesNotifierPot: NotesNotifier.new,
///     notesRepositoryPot: NotesRepository.new,
///   },
///   builder: (context) {
///     return ChildWidget();
///   },
/// ),
/// ```
/// {@endtemplate}
class Pottery extends StatefulWidget {
  /// Creates a [Pottery] widget that limits the scope where
  /// particular pots are available in the widget tree.
  ///
  /// {@macro pottery.class}
  const Pottery({
    super.key,
    required this.pots,
    required this.builder,
  });

  /// A map of replaceable pots and factories.
  ///
  /// {@macro pottery.class}
  ///
  /// Note that there is no warning even if you specify a factory
  /// that creates a wrong type of object. Make sure to specify a
  /// correct factory to avoid an error being thrown at runtime.
  final PotReplacements pots;

  /// Called to obtain the child widget.
  final WidgetBuilder builder;

  @override
  State<Pottery> createState() => _PotteryState();
}

class _PotteryState extends State<Pottery> {
  @override
  void initState() {
    super.initState();
    widget.pots.forEach((pot, factory) => pot.replace(factory));
  }

  @override
  void dispose() {
    // Some pots may depend on other pots located earlier
    // in the map, so they must be reset in reverse order.
    widget.pots.keys.toList().reversed.forEach((pot) {
      pot
        ..reset()
        ..replace(() => throw PotNotReadyException());
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<PotReplacements>('pots', widget.pots));
  }
}
