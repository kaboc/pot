import 'package:flutter/material.dart';

import 'package:devtools_app_shared/ui.dart';
import 'package:grab/grab.dart';
import 'package:pottery/pottery.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'package:pottery_devtools_extension/src/event_handler.dart';
import 'package:pottery_devtools_extension/src/types.dart';
import 'package:pottery_devtools_extension/src/utils.dart';
import 'package:pottery_devtools_extension/src/widgets/_widgets.dart';

class PotsView extends StatefulWidget with Grabful {
  const PotsView(this.eventHandler);

  final PotteryEventHandler eventHandler;

  @override
  State<PotsView> createState() => _PotsViewState();
}

class _PotsViewState extends State<PotsView> {
  final _horizontalController = ScrollController();
  final _selectionNotifier = ValueNotifier<PotDescription?>(null);

  @override
  void dispose() {
    _horizontalController.dispose();
    _selectionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final length =
        widget.eventHandler.potsNotifier.grabAt(context, (s) => s.length);

    return Split(
      axis: Axis.vertical,
      minSizes: const [200.0, 100.0],
      initialFractions: const [0.75, 0.25],
      children: [
        OutlineDecoration(
          showLeft: false,
          showRight: false,
          showTop: false,
          child: AutoScroller(
            itemCount: length,
            child: Scrollbar(
              child: Scrollbar(
                controller: _horizontalController,
                child: _Table(
                  eventHandler: widget.eventHandler,
                  horizontalController: _horizontalController,
                  selectionNotifier: _selectionNotifier,
                ),
              ),
            ),
          ),
        ),
        OutlineDecoration(
          showLeft: false,
          showRight: false,
          showBottom: false,
          child: _Details(
            selectionNotifier: _selectionNotifier,
            potsNotifier: widget.eventHandler.potsNotifier,
          ),
        ),
      ],
    );
  }
}

class _Table extends StatefulWidget with Grabful {
  const _Table({
    required this.eventHandler,
    required this.horizontalController,
    required this.selectionNotifier,
  });

  final PotteryEventHandler eventHandler;
  final ScrollController horizontalController;
  final ValueNotifier<PotDescription?> selectionNotifier;

  @override
  State<_Table> createState() => _TableState();
}

class _TableState extends State<_Table> {
  @override
  void initState() {
    super.initState();
    widget.eventHandler.getPots();
  }

  @override
  Widget build(BuildContext context) {
    final pots = widget.eventHandler.potsNotifier.grab(context);

    return TableView.builder(
      primary: true,
      columnCount: 7,
      rowCount: pots.length + 1,
      pinnedColumnCount: 1,
      pinnedRowCount: 1,
      horizontalDetails: ScrollableDetails.horizontal(
        controller: widget.horizontalController,
      ),
      columnBuilder: (index) {
        return TableSpan(
          extent: switch (index) {
            0 => const FixedTableSpanExtent(170),
            1 => const FixedTableSpanExtent(190),
            2 => const FixedTableSpanExtent(200),
            3 => const FixedTableSpanExtent(100),
            4 => const FixedTableSpanExtent(100),
            5 => const FixedTableSpanExtent(100),
            6 => const MaxTableSpanExtent(
                FixedTableSpanExtent(320),
                RemainingTableSpanExtent(),
              ),
            _ => const FixedTableSpanExtent(0),
          },
        );
      },
      rowBuilder: (index) {
        return const TableSpan(
          extent: FixedTableSpanExtent(50.0),
        );
      },
      cellBuilder: (context, vicinity) {
        if (vicinity.row == 0) {
          return switch (vicinity.column) {
            0 => const HeadingCell('Pot type'),
            1 => const HeadingCell('Created at'),
            2 => const HeadingCell('Generic type'),
            3 => const HeadingCell('isPending'),
            4 => const HeadingCell('isDisposed'),
            5 => const HeadingCell('hasObject'),
            6 => const HeadingCell('object'),
            _ => const SizedBox.shrink(),
          };
        }

        final pot = pots.values.elementAt(vicinity.row - 1);
        final desc = pot.description;

        return switch (vicinity.column) {
          0 => BoldCell(
              [
                CellConfig(
                  desc.identity,
                ),
              ],
              rowNumber: vicinity.row,
              specialTextType: SpecialTextType.identity,
            ),
          1 => Cell.center(
              [
                CellConfig(
                  pot.time,
                ),
              ],
              rowNumber: vicinity.row,
            ),
          2 => Cell(
              [
                CellConfig(
                  desc.identity,
                ),
              ],
              rowNumber: vicinity.row,
              specialTextType: SpecialTextType.genericType,
            ),
          3 => Cell.center(
              [
                CellConfig(
                  desc.isPending ?? '--',
                ),
              ],
              rowNumber: vicinity.row,
            ),
          4 => Cell.center(
              [
                CellConfig(
                  desc.isDisposed,
                ),
              ],
              rowNumber: vicinity.row,
            ),
          5 => Cell.center(
              [
                CellConfig(
                  desc.hasObject,
                ),
              ],
              rowNumber: vicinity.row,
            ),
          6 => Cell(
              [
                CellConfig(
                  desc.object,
                  onTap: () => widget.selectionNotifier.value = desc,
                ),
              ],
              rowNumber: vicinity.row,
            ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}

class _Details extends StatelessWidget with Grab {
  const _Details({
    required this.selectionNotifier,
    required this.potsNotifier,
  });

  final ValueNotifier<PotDescription?> selectionNotifier;
  final ValueNotifier<Pots> potsNotifier;

  @override
  Widget build(BuildContext context) {
    final id = selectionNotifier.grabAt(context, (s) => s?.identity);
    final pots = potsNotifier.grabAt(context, (s) => s[id]);

    return DetailsViewer(
      title: pots?.description.identity,
      time: pots?.time,
      json: pots?.description == null
          ? null
          : pots!.description.toFormattedJson(),
    );
  }
}
