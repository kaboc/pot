import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:pot/pot.dart' show PotDescription, PotEvent;

typedef LocalObject = ({String potIdentity, String object});

typedef Pots = Map<String, ({DateTime time, PotDescription description})>;
typedef Potteries
    = Map<String, ({DateTime time, List<PotDescription> potDescriptions})>;
typedef LocalPotteries
    = Map<String, ({DateTime time, List<LocalObject> objects})>;

typedef PotEventsNotifier = ValueNotifier<List<PotEvent>>;
typedef PotsNotifier = ValueNotifier<Pots>;
typedef PotteriesNotifier = ValueNotifier<Potteries>;
typedef LocalPotteriesNotifier = ValueNotifier<LocalPotteries>;
