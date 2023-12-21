import 'package:flutter/material.dart';

import 'package:devtools_app_shared/ui.dart';
import 'package:grab/grab.dart';

import 'package:pottery_devtools_extension/src/event_handler.dart';
import 'package:pottery_devtools_extension/src/utils.dart';
import 'package:pottery_devtools_extension/src/view_type_notifier.dart';
import 'package:pottery_devtools_extension/src/views/events_view.dart';
import 'package:pottery_devtools_extension/src/views/local_pottery_view.dart';
import 'package:pottery_devtools_extension/src/views/pots_view.dart';
import 'package:pottery_devtools_extension/src/views/pottery_view.dart';

class PotteryExtensionPage extends StatefulWidget with Grabful {
  const PotteryExtensionPage();

  @override
  State<PotteryExtensionPage> createState() => _PotteryExtensionPageState();
}

class _PotteryExtensionPageState extends State<PotteryExtensionPage> {
  final _eventHandler = PotteryEventHandler();
  final _viewTypeNotifier = ViewTypeNotifier();

  @override
  void dispose() {
    _eventHandler.dispose();
    _viewTypeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewType = _viewTypeNotifier.grab(context);
    final potEventsNotifier = _eventHandler.potEventsNotifier;

    return Scaffold(
      body: Split(
        axis: Axis.horizontal,
        minSizes: const [140.0, 240.0],
        initialFractions: const [0.1, 0.9],
        children: [
          OutlineDecoration(
            child: ListView(
              children: [
                for (final type in ViewType.values)
                  ListTile(
                    title: Text(type.menuLabel),
                    selected: viewType == type,
                    selectedColor: context.textTheme.bodyMedium?.color,
                    selectedTileColor: context.colorScheme.secondaryContainer,
                    onTap: () => _viewTypeNotifier.update(type),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              AreaPaneHeader(
                tall: true,
                title: DefaultTextStyle(
                  style: context.textTheme.titleMedium!,
                  child: Text(viewType.title),
                ),
                actions: [
                  if (viewType.refreshable)
                    DevToolsTooltip(
                      message: 'Refresh',
                      child: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          switch (viewType) {
                            case ViewType.pots:
                              _eventHandler.getPots();
                            case ViewType.potteries:
                              _eventHandler.getPotteries();
                            case ViewType.localPotteries:
                              _eventHandler.getLocalPotteries();
                            case ViewType.events:
                              break;
                          }
                        },
                      ),
                    )
                  else if (viewType == ViewType.events)
                    if (potEventsNotifier.grabAt(context, (s) => s.isNotEmpty))
                      DevToolsTooltip(
                        message: 'Clear',
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _eventHandler.clearEvents,
                        ),
                      ),
                  const SizedBox(width: 8.0),
                ],
              ),
              Expanded(
                child: RoundedOutlinedBorder.onlyBottom(
                  child: switch (viewType) {
                    ViewType.pots => PotsView(_eventHandler),
                    ViewType.potteries => PotteryView(_eventHandler),
                    ViewType.localPotteries => LocalPotteryView(_eventHandler),
                    ViewType.events => EventsView(_eventHandler),
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
