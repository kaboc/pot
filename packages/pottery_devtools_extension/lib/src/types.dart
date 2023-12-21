import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:pot/pot.dart' show PotDescription, PotEvent;

typedef Pots = Map<String, ({DateTime time, PotDescription description})>;

typedef PotEventsNotifier = ValueNotifier<List<PotEvent>>;
typedef PotsNotifier = ValueNotifier<Pots>;
