import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:pot/pot.dart';

import 'extension/extension_manager.dart';
import 'local_pottery.dart';
import 'utils.dart';

/// The signature of a map consisting of replaceable pots and factories.
typedef PotReplacements
    = Map<ReplaceablePot<Object?>, PotObjectFactory<Object?>>;

/// A widget that controls the availability of particular pots
/// according to the widget lifecycle.
///
/// {@template pottery.class}
/// The factory of the [ReplaceablePot] specified as the key in the
/// map ([pots]) is replaced with the [PotObjectFactory] specified
/// as its value. An existing object is also replaced immediately
/// with a new one created by the new factory if one has already
/// existed. If there was no object, a new one is not created soon
/// but only when it is accessed for the first time.
///
/// If the pottery is removed from the tree permanently, the object
/// is discarded and the factory is removed. After the removal,
/// trying to access the object throws [PotNotReadyException].
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
///
/// Note that [Pottery] does not bind pots to the widget tree.
/// It only uses the lifecycle of itself in the tree to control
/// the lifespan of pots' content, which is an important difference
/// from [LocalPottery].
///
/// Also note that an error arises only at runtime if the map
/// contains wrong pairs of pot and factory. Make sure to specify
/// a correct factory creating an object of the right type.
/// {@endtemplate}
class Pottery extends StatefulWidget {
  /// Creates a [Pottery] widget that limits the lifespan of the
  /// factory and the object of particular [Pot]s according to
  /// its own lifespan.
  ///
  /// {@macro pottery.class}
  const Pottery({
    super.key,
    required this.pots,
    required this.builder,
  });

  /// A map of replaceable pots and factories.
  final PotReplacements pots;

  /// A function called to obtain the child widget.
  final WidgetBuilder builder;

  @override
  State<Pottery> createState() => _PotteryState();
}

class _PotteryState extends State<Pottery> {
  PotteryExtensionManager? _extensionManager;

  @override
  void initState() {
    super.initState();

    runIfDebug(() {
      _extensionManager = PotteryExtensionManager.createSingle()
        ..onPotteryCreated(this, widget.pots.keys);
    });
    widget.pots.forEach((pot, factory) => pot.replace(factory));
  }

  @override
  void dispose() {
    // Some pots may depend on other pots located earlier
    // in the map, so they must be reset in reverse order.
    widget.pots.keys.toList().reversed.forEach((pot) {
      pot.resetAsPending();
    });
    _extensionManager?.onPotteryRemoved(this, widget.pots.keys);

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
