import 'package:flutter/material.dart';

import 'package:devtools_app_shared/ui.dart';
import 'package:grab/grab.dart';
import 'package:pottery/pottery.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'package:pottery_devtools_extension/src/event_handler.dart';
import 'package:pottery_devtools_extension/src/types.dart';
import 'package:pottery_devtools_extension/src/utils.dart';
import 'package:pottery_devtools_extension/src/widgets/_widgets.dart';

class PotsView extends StatefulWidget {
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

    return SplitPane(
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

class _Table extends StatefulWidget {
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
  Pots? _prevPots;
  bool _initialFetchCompleted = false;

  @override
  void initState() {
    super.initState();

    widget.eventHandler
      ..potsNotifier.addListener(_updatePrevAfterFrame)
      ..getPots().then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initialFetchCompleted = true;
          _updatePrev();
        });
      });
  }

  @override
  void dispose() {
    widget.eventHandler.potsNotifier.removeListener(_updatePrevAfterFrame);
    _prevPots?.clear();

    super.dispose();
  }

  void _updatePrev() {
    _prevPots = Map.of(widget.eventHandler.potsNotifier.value);
  }

  void _updatePrevAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePrev());
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
            0 => const TableViewCell(child: HeadingCell('Pot type')),
            1 => const TableViewCell(child: HeadingCell('Created at')),
            2 => const TableViewCell(child: HeadingCell('Object type')),
            3 => const TableViewCell(child: HeadingCell('isPending')),
            4 => const TableViewCell(child: HeadingCell('isDisposed')),
            5 => const TableViewCell(child: HeadingCell('hasObject')),
            6 => const TableViewCell(child: HeadingCell('object')),
            _ => const TableViewCell(child: SizedBox.shrink()),
          };
        }

        final pot = pots.values.elementAt(vicinity.row - 1);
        final desc = pot.description;

        final prevPot = _prevPots?[desc.identity];
        final isNew = prevPot == null;
        final prevDesc = prevPot?.description;

        return switch (vicinity.column) {
          0 => TableViewCell(
              child: BoldCell(
                [
                  CellConfig(
                    desc.identity,
                    highlight: _initialFetchCompleted && isNew,
                  ),
                ],
                rowNumber: vicinity.row,
                specialTextType: SpecialTextType.identity,
              ),
            ),
          1 => TableViewCell(
              child: Cell.center(
                [
                  CellConfig(
                    pot.time,
                    highlight: _initialFetchCompleted && isNew,
                  ),
                ],
                rowNumber: vicinity.row,
              ),
            ),
          2 => TableViewCell(
              child: Cell(
                [
                  CellConfig(
                    desc.identity,
                    highlight: _initialFetchCompleted && isNew,
                  ),
                ],
                rowNumber: vicinity.row,
                specialTextType: SpecialTextType.genericType,
              ),
            ),
          3 => TableViewCell(
              child: Cell.center(
                [
                  CellConfig(
                    desc.isPending ?? '--',
                    highlight: _initialFetchCompleted &&
                        (isNew || desc.isPending != prevDesc?.isPending),
                  ),
                ],
                rowNumber: vicinity.row,
              ),
            ),
          4 => TableViewCell(
              child: Cell.center(
                [
                  CellConfig(
                    desc.isDisposed,
                    highlight: _initialFetchCompleted &&
                        desc.isDisposed != prevDesc?.isDisposed,
                  ),
                ],
                rowNumber: vicinity.row,
              ),
            ),
          5 => TableViewCell(
              child: Cell.center(
                [
                  CellConfig(
                    desc.hasObject,
                    highlight: _initialFetchCompleted &&
                        desc.hasObject != prevDesc?.hasObject,
                  ),
                ],
                rowNumber: vicinity.row,
              ),
            ),
          6 => TableViewCell(
              child: Cell(
                [
                  CellConfig(
                    desc.object,
                    highlight: _initialFetchCompleted &&
                        (isNew || desc.object != prevDesc?.object),
                    onTap: () => widget.selectionNotifier.value = desc,
                  ),
                ],
                rowNumber: vicinity.row,
              ),
            ),
          _ => const TableViewCell(child: SizedBox.shrink()),
        };
      },
    );
  }
}

class _Details extends StatelessWidget {
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
