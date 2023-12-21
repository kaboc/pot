import 'package:flutter/foundation.dart' show ValueNotifier;

enum ViewType {
  pots(
    'Pots',
    'Pot instances (in order of creation)',
  ),
  potteries(
    'Pottery',
    'Pots per Pottery',
  ),
  localPotteries(
    'LocalPottery',
    'Local objects per LocalPottery',
  ),
  events(
    'Events',
    'Pot events',
    refreshable: false,
  );

  const ViewType(this.menuLabel, this.title, {this.refreshable = true});

  final String menuLabel;
  final String title;
  final bool refreshable;
}

class ViewTypeNotifier extends ValueNotifier<ViewType> {
  ViewTypeNotifier() : super(ViewType.values.first);

  // ignore: use_setters_to_change_properties
  void update(ViewType type) {
    value = type;
  }
}
