import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:devtools_app_shared/ui.dart';
import 'package:grab/grab.dart';
import 'package:pottery/pottery.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'package:pottery_devtools_extension/src/event_handler.dart';
import 'package:pottery_devtools_extension/src/types.dart';
import 'package:pottery_devtools_extension/src/utils.dart';
import 'package:pottery_devtools_extension/src/widgets/_widgets.dart';

typedef _Selection = ({String id, PotDescription potDescription});

class PotteryView extends StatefulWidget {
  const PotteryView(this.eventHandler);

  final PotteryEventHandler eventHandler;

  @override
  State<PotteryView> createState() => _PotteryViewState();
}

class _PotteryViewState extends State<PotteryView> {
  final _horizontalController = ScrollController();
  final _selectionNotifier = ValueNotifier<_Selection?>(null);

  @override
  void dispose() {
    _horizontalController.dispose();
    _selectionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final length =
        widget.eventHandler.potteriesNotifier.grabAt(context, (s) => s.length);

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
            potteriesNotifier: widget.eventHandler.potteriesNotifier,
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
  final ValueNotifier<_Selection?> selectionNotifier;

  @override
  State<_Table> createState() => _TableState();
}

class _TableState extends State<_Table> {
  Potteries? _prevPotteries;
  bool _initialFetchCompleted = false;

  @override
  void initState() {
    super.initState();

    widget.eventHandler
      ..potteriesNotifier.addListener(_updatePrevAfterFrame)
      ..getPotteries().then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initialFetchCompleted = true;
          _updatePrev();
        });
      });
  }

  @override
  void dispose() {
    widget.eventHandler.potteriesNotifier.removeListener(_updatePrevAfterFrame);
    _prevPotteries?.clear();

    super.dispose();
  }

  void _updatePrev() {
    _prevPotteries = Map.of(widget.eventHandler.potteriesNotifier.value);
  }

  void _updatePrevAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePrev());
  }

  @override
  Widget build(BuildContext context) {
    final potteries = widget.eventHandler.potteriesNotifier.grab(context);

    return TableView.builder(
      primary: true,
      columnCount: 8,
      rowCount: potteries.length + 1,
      pinnedColumnCount: 2,
      pinnedRowCount: 1,
      horizontalDetails: ScrollableDetails.horizontal(
        controller: widget.horizontalController,
      ),
      columnBuilder: (index) {
        return TableSpan(
          extent: switch (index) {
            0 => const FixedTableSpanExtent(120),
            1 => const FixedTableSpanExtent(170),
            2 => const FixedTableSpanExtent(190),
            3 => const FixedTableSpanExtent(200),
            4 => const FixedTableSpanExtent(100),
            5 => const FixedTableSpanExtent(100),
            6 => const FixedTableSpanExtent(100),
            7 => const MaxTableSpanExtent(
                FixedTableSpanExtent(280),
                RemainingTableSpanExtent(),
              ),
            _ => const FixedTableSpanExtent(0),
          },
        );
      },
      rowBuilder: (index) {
        final lines = index == 0
            ? 1
            : potteries.values.elementAt(index - 1).potDescriptions.length;

        return TableSpan(
          extent: FixedTableSpanExtent(
            Cell.calculateHeight(lines: lines),
          ),
        );
      },
      cellBuilder: (context, vicinity) {
        if (vicinity.row == 0) {
          return switch (vicinity.column) {
            0 => const TableViewCell(child: HeadingCell('Identity')),
            1 => const TableViewCell(child: HeadingCell('Pot type')),
            2 => const TableViewCell(child: HeadingCell('Created at')),
            3 => const TableViewCell(child: HeadingCell('Object type')),
            4 => const TableViewCell(child: HeadingCell('isPending')),
            5 => const TableViewCell(child: HeadingCell('isDisposed')),
            6 => const TableViewCell(child: HeadingCell('hasObject')),
            7 => const TableViewCell(child: HeadingCell('object')),
            _ => const TableViewCell(child: SizedBox.shrink()),
          };
        }

        final MapEntry(key: id, value: (:time, potDescriptions: descs)) =
            potteries.entries.elementAt(vicinity.row - 1);

        final prevDescs = _prevPotteries?[id]?.potDescriptions;
        final isNew = prevDescs == null;

        return switch (vicinity.column) {
          0 => TableViewCell(
              child: BoldCell(
                [
                  CellConfig(
                    id,
                    highlight: _initialFetchCompleted && isNew,
                  ),
                ],
                rowNumber: vicinity.row,
                lineSpan: descs.length,
                specialTextType: SpecialTextType.identity,
              ),
            ),
          1 => TableViewCell(
              child: BoldCell(
                [
                  for (final (i, desc) in descs.indexed)
                    CellConfig(
                      desc.identity,
                      highlight: _initialFetchCompleted &&
                          !descs.same(i, prevDescs, (v) => v?.identity),
                    ),
                ],
                rowNumber: vicinity.row,
                specialTextType: SpecialTextType.identity,
              ),
            ),
          2 => TableViewCell(
              child: Cell.center(
                [
                  CellConfig(
                    time,
                    highlight: _initialFetchCompleted && isNew,
                  ),
                ],
                rowNumber: vicinity.row,
                lineSpan: descs.length,
              ),
            ),
          3 => TableViewCell(
              child: Cell(
                [
                  for (final (i, desc) in descs.indexed)
                    CellConfig(
                      desc.identity,
                      highlight: _initialFetchCompleted &&
                          !descs.same(i, prevDescs, (v) => v?.identity),
                    ),
                ],
                rowNumber: vicinity.row,
                specialTextType: SpecialTextType.genericType,
              ),
            ),
          4 => TableViewCell(
              child: Cell.center(
                [
                  for (final (i, desc) in descs.indexed)
                    CellConfig(
                      desc.isPending,
                      highlight: _initialFetchCompleted &&
                          !descs.same(i, prevDescs, (v) => v?.isPending),
                    ),
                ],
                rowNumber: vicinity.row,
              ),
            ),
          5 => TableViewCell(
              child: Cell.center(
                [
                  for (final (i, desc) in descs.indexed)
                    CellConfig(
                      desc.isDisposed,
                      highlight: _initialFetchCompleted &&
                          !descs.same(i, prevDescs, (v) => v?.isDisposed),
                    ),
                ],
                rowNumber: vicinity.row,
              ),
            ),
          6 => TableViewCell(
              child: Cell.center(
                [
                  for (final (i, desc) in descs.indexed)
                    CellConfig(
                      desc.hasObject,
                      highlight: _initialFetchCompleted &&
                          (isNew ||
                              !descs.same(i, prevDescs, (v) => v?.hasObject)),
                    ),
                ],
                rowNumber: vicinity.row,
              ),
            ),
          7 => TableViewCell(
              child: Cell(
                [
                  for (final (i, desc) in descs.indexed)
                    CellConfig(
                      desc.object,
                      highlight: _initialFetchCompleted &&
                          !descs.same(i, prevDescs, (v) => v?.object),
                      onTap: () => widget.selectionNotifier.value =
                          (id: id, potDescription: desc),
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
    required this.potteriesNotifier,
  });

  final ValueNotifier<_Selection?> selectionNotifier;
  final ValueNotifier<Potteries> potteriesNotifier;

  @override
  Widget build(BuildContext context) {
    final selection = selectionNotifier.grab(context);
    final entry = potteriesNotifier.grabAt(
      context,
      (s) => s.entries.firstWhereOrNull((v) => v.key == selection?.id),
    );

    return DetailsViewer(
      title: entry?.key,
      time: entry?.value.time,
      data: entry?.value.potDescriptions
          .firstWhereOrNull(
            (v) => v.identity == selection?.potDescription.identity,
          )
          ?.toMap(),
    );
  }
}
