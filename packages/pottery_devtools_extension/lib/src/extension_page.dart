import 'package:flutter/material.dart';

import 'package:devtools_app_shared/ui.dart';
import 'package:grab/grab.dart';

import 'package:pottery_devtools_extension/src/utils.dart';
import 'package:pottery_devtools_extension/src/view_type_notifier.dart';

class PotteryExtensionPage extends StatefulWidget with Grabful {
  const PotteryExtensionPage();

  @override
  State<PotteryExtensionPage> createState() => _PotteryExtensionPageState();
}

class _PotteryExtensionPageState extends State<PotteryExtensionPage> {
  final _viewTypeNotifier = ViewTypeNotifier();

  @override
  void dispose() {
    _viewTypeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewType = _viewTypeNotifier.grab(context);

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
              ),
              Expanded(
                child: RoundedOutlinedBorder.onlyBottom(
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
