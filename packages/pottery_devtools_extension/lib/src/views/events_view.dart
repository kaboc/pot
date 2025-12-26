import 'package:flutter/material.dart';

import 'package:devtools_app_shared/ui.dart';
import 'package:grab/grab.dart';
import 'package:pottery/pottery.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'package:pottery_devtools_extension/src/event_handler.dart';
import 'package:pottery_devtools_extension/src/utils.dart';
import 'package:pottery_devtools_extension/src/widgets/_widgets.dart';

typedef _Selection = ({PotEvent event, PotDescription potDescription});

class EventsView extends StatefulWidget {
  const EventsView(this.eventHandler);

  final PotteryEventHandler eventHandler;

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
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
        widget.eventHandler.potEventsNotifier.grabAt(context, (s) => s.length);

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
  List<PotEvent>? _prevEvents;

  @override
  void initState() {
    super.initState();

    widget.eventHandler.potEventsNotifier.addListener(_updatePrevAfterFrame);
    _updatePrev();
  }

  @override
  void dispose() {
    widget.eventHandler.potEventsNotifier.removeListener(_updatePrevAfterFrame);
    _prevEvents?.clear();

    super.dispose();
  }

  void _updatePrev() {
    _prevEvents = List.of(widget.eventHandler.potEventsNotifier.value);
  }

  void _updatePrevAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePrev());
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.eventHandler.potEventsNotifier.grab(context);

    return TableView.builder(
      primary: true,
      columnCount: 8,
      rowCount: events.length + 1,
      pinnedColumnCount: 2,
      pinnedRowCount: 1,
      horizontalDetails: ScrollableDetails.horizontal(
        controller: widget.horizontalController,
      ),
      columnBuilder: (index) {
        return TableSpan(
          extent: switch (index) {
            0 => const FixedTableSpanExtent(170),
            1 => const FixedTableSpanExtent(160),
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
        final lines = index == 0 ? 1 : events[index - 1].potDescriptions.length;

        return TableSpan(
          extent: FixedTableSpanExtent(
            Cell.calculateHeight(lines: lines),
          ),
        );
      },
      cellBuilder: (context, vicinity) {
        if (vicinity.row == 0) {
          return switch (vicinity.column) {
            0 => const TableViewCell(child: HeadingCell('Pot type')),
            1 => const TableViewCell(child: HeadingCell('Event')),
            2 => const TableViewCell(child: HeadingCell('Occurred at')),
            3 => const TableViewCell(child: HeadingCell('Object type')),
            4 => const TableViewCell(child: HeadingCell('isPending')),
            5 => const TableViewCell(child: HeadingCell('isDisposed')),
            6 => const TableViewCell(child: HeadingCell('hasObject')),
            7 => const TableViewCell(child: HeadingCell('object')),
            _ => const TableViewCell(child: SizedBox.shrink()),
          };
        }

        final event = events[vicinity.row - 1];
        final descs = event.potDescriptions;

        final isNew = _prevEvents?.any((v) => v.number == event.number) != true;
        final isLocalPottery = event.kind == PotEventKind.localPotteryCreated ||
            event.kind == PotEventKind.localPotteryRemoved;

        return switch (vicinity.column) {
          0 => TableViewCell(
              child: BoldCell(
                [
                  for (final desc in descs)
                    CellConfig(
                      desc.identity,
                      highlight: isNew,
                    ),
                ],
                rowNumber: vicinity.row,
                specialTextType: SpecialTextType.identity,
              ),
            ),
          1 => TableViewCell(
              child: BoldCell(
                [
                  CellConfig(
                    event.kind.name,
                    highlight: isNew,
                  ),
                ],
                rowNumber: vicinity.row,
                lineSpan: descs.length,
              ),
            ),
          2 => TableViewCell(
              child: Cell.center(
                [
                  CellConfig(
                    event.time,
                    highlight: isNew,
                  ),
                ],
                rowNumber: vicinity.row,
                lineSpan: descs.length,
              ),
            ),
          3 => TableViewCell(
              child: Cell(
                [
                  for (final desc in descs)
                    CellConfig(
                      desc.identity,
                      highlight: isNew,
                    ),
                ],
                rowNumber: vicinity.row,
                specialTextType: SpecialTextType.genericType,
              ),
            ),
          4 => TableViewCell(
              child: Cell.center(
                [
                  for (final desc in descs)
                    CellConfig(
                      isLocalPottery ? '--' : desc.isPending ?? '--',
                      highlight: isNew,
                    ),
                ],
                rowNumber: vicinity.row,
              ),
            ),
          5 => TableViewCell(
              child: Cell.center(
                [
                  for (final desc in descs)
                    CellConfig(
                      isLocalPottery ? '--' : desc.isDisposed,
                      highlight: isNew,
                    ),
                ],
                rowNumber: vicinity.row,
              ),
            ),
          6 => TableViewCell(
              child: Cell.center(
                [
                  for (final desc in descs)
                    CellConfig(
                      isLocalPottery ? '--' : desc.hasObject,
                      highlight: isNew,
                    ),
                ],
                rowNumber: vicinity.row,
              ),
            ),
          7 => TableViewCell(
              child: Cell(
                [
                  for (final desc in descs)
                    CellConfig(
                      isLocalPottery ? '--' : desc.object,
                      highlight: isNew,
                      onTap: isLocalPottery
                          ? null
                          : () => widget.selectionNotifier.value =
                              (event: event, potDescription: desc),
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
  const _Details({required this.selectionNotifier});

  final ValueNotifier<_Selection?> selectionNotifier;

  @override
  Widget build(BuildContext context) {
    final selection = selectionNotifier.grab(context);

    return DetailsViewer(
      title: selection?.event.kind.name,
      time: selection?.event.time,
      json: selection?.potDescription.toFormattedJson(),
    );
  }
}
