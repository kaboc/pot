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
  );

  const ViewType(this.menuLabel, this.title);

  final String menuLabel;
  final String title;
}

class ViewTypeNotifier extends ValueNotifier<ViewType> {
  ViewTypeNotifier() : super(ViewType.values.first);

  // ignore: use_setters_to_change_properties
  void update(ViewType type) {
    value = type;
  }
}
