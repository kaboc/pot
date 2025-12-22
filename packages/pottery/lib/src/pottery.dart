import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:pot/pot.dart';

import 'extension/extension_manager.dart';
import 'local_pottery.dart';
import 'utils.dart';

/// The signature of a map consisting of replaceable pots and factories.
typedef PotReplacements
    = Map<ReplaceablePot<Object?>, PotObjectFactory<Object?>>;

/// A widget that controls the availability of particular [Pot]s
/// according to the widget lifecycle.
///
/// {@template pottery.class}
/// This widget replaces the factories of [ReplaceablePot]s with new
/// factories as specified in [pots]. For any pot that already holds
/// an object, the object is immediately replaced with a new one created
/// by the new factory. If a pot has no object, a new one is not created
/// until the pot is accessed for the first time.
///
/// If the `Pottery` is removed from the tree permanently, the objects
/// held in the pots are disposed, and the pots are reset to the pending
/// state with no factory. After the removal, trying to access the objects
/// throws a [PotNotReadyException].
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
/// the lifetime of pots' content, which is an important difference
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

  /// Pairs of a replaceable [Pot] and its new factory.
  final PotReplacements pots;

  /// A function called to obtain the child widget.
  final WidgetBuilder builder;

  @override
  State<Pottery> createState() => _PotteryState();

  /// Starts the DevTools extension manually.
  ///
  /// The extension starts automatically in debug mode without this
  /// method, but only when [Pottery] or [LocalPottery] is first used.
  /// This method allows to start it earlier.
  static void startExtension() {
    PotteryExtensionManager.createSingle();
  }
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
    // Some pots may depend on other pots located earlier in
    // the collection, so they must be reset in reverse order.
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
