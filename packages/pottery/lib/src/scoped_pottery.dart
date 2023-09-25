// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

import 'package:pot/pot.dart';

typedef PotOverrides = Map<Pot<Object?>, PotObjectFactory<Object?>>;
typedef ScopedPots = Map<Pot<Object?>, Object?>;

class ScopedPottery extends StatefulWidget {
  const ScopedPottery({
    super.key,
    required this.pots,
    required this.builder,
    this.disposer,
  });

  final PotOverrides pots;
  final WidgetBuilder builder;
  final void Function(ScopedPots)? disposer;

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
}

extension NearestPotOf<T> on Pot<T> {
  MapEntry<Pot<Object?>, Object?>? _findEntry(BuildContext element) {
    if (element.widget is ScopedPottery) {
      final state = (element as StatefulElement).state;
      final pots = (state as _ScopedPotteryState)._scopedPots;

      for (final entry in pots.entries) {
        if (entry.key == this) {
          // Returns MapEntry instead of entry.value
          // because it is impossible to distinguish `null`
          // from "not found" if T is nullable.
          return entry;
        }
      }
    }

    return null;
  }

  T of(BuildContext context) {
    // Checks the current context too so that the scoped pot
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
