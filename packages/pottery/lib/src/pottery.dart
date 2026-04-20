import 'package:flutter/foundation.dart'
    show DiagnosticPropertiesBuilder, IterableProperty;
import 'package:flutter/widgets.dart';

import 'package:pot/pot.dart';

import 'common_types.dart';
import 'extension/extension_manager.dart';
import 'local_pottery.dart';
import 'utils.dart';

/// A widget that controls the availability of particular [Pot]s
/// according to the widget lifecycle.
///
/// {@template pottery.class}
/// This widget replaces the factories of [ReplaceablePot]s with new
/// factories as specified in [overrides]. For any pot that already holds
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
///   overrides: [
///     notesNotifierPot.set(NotesNotifier.new),
///     notesRepositoryPot.set(NotesRepository.new),
///   ],
///   builder: (context) {
///     return ChildWidget();
///   },
/// ),
/// ```
///
/// > [!NOTE]
/// > [Pottery] does not bind pots to the widget tree. It only uses the
/// > lifecycle of itself in the tree to control the lifetime of pots'
/// > content, which is an important difference from [LocalPottery].
///
/// > [!WARNING]
/// > Do not manually reset or replace a pot used by a `Pottery`. Also,
/// > do not let a `Pottery` take over pots already managed by another
/// > `Pottery`. Doing so skips the reset that should happen when the
/// > original `Pottery` is disposed.
/// {@endtemplate}
class Pottery extends StatefulWidget {
  /// Creates a [Pottery] widget that limits the lifespan of the
  /// factory and the object of particular [Pot]s according to
  /// its own lifespan.
  ///
  /// {@macro pottery.class}
  const Pottery({
    super.key,
    required this.overrides,
    required this.builder,
  });

  /// Pairs of a replaceable [Pot] and its new factory.
  final List<PotReplacement<Object?>> overrides;

  /// A function called to obtain the child widget.
  final WidgetBuilder builder;

  @override
  State<Pottery> createState() => _PotteryState();

  /// Starts the DevTools extension manually.
  ///
  /// The extension starts automatically in debug mode without this
  /// method, but only when [Pottery] or [LocalPottery] is first used.
  /// This method allows to start it earlier.
  ///
  /// This method does nothing in non-debug mode.
  static void startExtension() {
    runIfDebug(PotteryExtensionManager.createSingle);
  }
}

class _PotteryState extends State<Pottery> {
  final Map<ReplaceablePot<Object?>, int> _factoryHashCodes = {};

  PotteryExtensionManager? _extensionManager;

  @override
  void initState() {
    super.initState();

    runIfDebug(() {
      _extensionManager = PotteryExtensionManager.createSingle()
        ..onPotteryCreated(this, widget.overrides.map((repl) => repl.pot));
    });

    for (final repl in widget.overrides) {
      repl.pot.replace(repl.factory);
      _factoryHashCodes[repl.pot] = repl.factory.hashCode;
    }
  }

  @override
  void dispose() {
    final pots = widget.overrides.map((v) => v.pot).toList();
    final removedPots = <ReplaceablePot<Object?>>[];

    // Some pots may depend on other pots located earlier in
    // the collection, so they must be reset in reverse order.
    for (var i = pots.length - 1; i >= 0; i--) {
      final pot = pots[i];

      // If the factory's hash code has changed, another Pottery has
      // probably replaced the factory. In that case, the pot has already
      // been reset by the replacement. Resetting it here would make the
      // pot unusable for the new screen, so it must be skipped.
      //
      // This can happen when a new instance of the same Pottery is
      // created before the previous screen finishes its closing animation.
      // Then dispose() of the old instance may run after initState() of
      // the new one.
      //
      // ignore: invalid_use_of_internal_member
      if (pot.factoryHashCode == _factoryHashCodes[pot]) {
        pot.resetAsPending();
        removedPots.add(pot);
      }
    }
    _extensionManager?.onPotteryRemoved(this, removedPots);

    _factoryHashCodes.clear();
    _extensionManager = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      IterableProperty<PotReplacement<Object?>>('overrides', widget.overrides),
    );
  }
}
