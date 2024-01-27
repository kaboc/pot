import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:devtools_app_shared/ui.dart';
import 'package:grab/grab.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'package:pottery_devtools_extension/src/event_handler.dart';
import 'package:pottery_devtools_extension/src/types.dart';
import 'package:pottery_devtools_extension/src/utils.dart';
import 'package:pottery_devtools_extension/src/widgets/_widgets.dart';

typedef _Selection = ({String id, LocalObject? object});

class LocalPotteryView extends StatefulWidget {
  const LocalPotteryView(this.eventHandler);

  final PotteryEventHandler eventHandler;

  @override
  State<LocalPotteryView> createState() => _LocalPotteryViewState();
}

class _LocalPotteryViewState extends State<LocalPotteryView> {
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
    final length = widget.eventHandler.localPotteriesNotifier
        .grabAt(context, (s) => s.length);

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
            localPotteriesNotifier: widget.eventHandler.localPotteriesNotifier,
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
  LocalPotteries? _prevPotteries;
  bool _initialFetchCompleted = false;

  @override
  void initState() {
    super.initState();

    widget.eventHandler
      ..localPotteriesNotifier.addListener(_updatePrevAfterFrame)
      ..getLocalPotteries().then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initialFetchCompleted = true;
          _updatePrev();
        });
      });
  }

  @override
  void dispose() {
    widget.eventHandler.localPotteriesNotifier
        .removeListener(_updatePrevAfterFrame);
    _prevPotteries?.clear();

    super.dispose();
  }

  void _updatePrev() {
    _prevPotteries = Map.of(widget.eventHandler.localPotteriesNotifier.value);
  }

  void _updatePrevAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePrev());
  }

  @override
  Widget build(BuildContext context) {
    final potteries = widget.eventHandler.localPotteriesNotifier.grab(context);

    return TableView.builder(
      primary: true,
      columnCount: 5,
      rowCount: potteries.length + 1,
      pinnedColumnCount: 1,
      pinnedRowCount: 1,
      horizontalDetails: ScrollableDetails.horizontal(
        controller: widget.horizontalController,
      ),
      columnBuilder: (index) {
        return TableSpan(
          extent: switch (index) {
            0 => const FixedTableSpanExtent(155),
            1 => const FixedTableSpanExtent(190),
            2 => const FixedTableSpanExtent(170),
            3 => const FixedTableSpanExtent(200),
            4 => const MaxTableSpanExtent(
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
            : potteries.values.elementAt(index - 1).objects.length;

        return TableSpan(
          extent: FixedTableSpanExtent(
            Cell.calculateHeight(lines: lines),
          ),
        );
      },
      cellBuilder: (context, vicinity) {
        if (vicinity.row == 0) {
          return switch (vicinity.column) {
            0 => const HeadingCell('Identity'),
            1 => const HeadingCell('Created at'),
            2 => const HeadingCell('Pot type'),
            3 => const HeadingCell('Generic type'),
            4 => const HeadingCell('object'),
            _ => const SizedBox.shrink(),
          };
        }

        final (id, (:objects, :time)) =
            potteries.records.elementAt(vicinity.row - 1);

        final prevObjects = _prevPotteries?[id]?.objects;
        final isNew = prevObjects == null;

        return switch (vicinity.column) {
          0 => BoldCell(
              [
                CellConfig(
                  id,
                  highlight: _initialFetchCompleted && isNew,
                ),
              ],
              rowNumber: vicinity.row,
              lineSpan: objects.length,
              specialTextType: SpecialTextType.identity,
            ),
          1 => Cell.center(
              [
                CellConfig(
                  time,
                  highlight: _initialFetchCompleted && isNew,
                ),
              ],
              rowNumber: vicinity.row,
              lineSpan: objects.length,
            ),
          2 => Cell(
              [
                for (final (i, object) in objects.indexed)
                  CellConfig(
                    object.potIdentity,
                    highlight: _initialFetchCompleted &&
                        !objects.same(i, prevObjects, (v) => v?.potIdentity),
                  ),
              ],
              rowNumber: vicinity.row,
              specialTextType: SpecialTextType.identity,
            ),
          3 => Cell(
              [
                for (final (i, object) in objects.indexed)
                  CellConfig(
                    object.potIdentity,
                    highlight: _initialFetchCompleted &&
                        !objects.same(i, prevObjects, (v) => v?.potIdentity),
                  ),
              ],
              rowNumber: vicinity.row,
              specialTextType: SpecialTextType.genericType,
            ),
          4 => Cell(
              [
                for (final (i, object) in objects.indexed)
                  CellConfig(
                    object.object,
                    highlight: _initialFetchCompleted &&
                        (isNew ||
                            !objects.same(i, prevObjects, (v) => v?.object)),
                    onTap: () => widget.selectionNotifier.value =
                        (id: id, object: objects.elementAt(i)),
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

class _Details extends StatelessWidget {
  const _Details({
    required this.selectionNotifier,
    required this.localPotteriesNotifier,
  });

  final ValueNotifier<_Selection?> selectionNotifier;
  final ValueNotifier<LocalPotteries> localPotteriesNotifier;

  @override
  Widget build(BuildContext context) {
    final selection = selectionNotifier.grab(context);
    final entry = localPotteriesNotifier.grabAt(
      context,
      (s) => s.entries.firstWhereOrNull((v) => v.key == selection?.id),
    );

    return DetailsViewer(
      title: entry?.key,
      time: entry?.value.time,
      json: entry?.value.objects
          .firstWhereOrNull(
            (v) => v.potIdentity == selection?.object?.potIdentity,
          )
          ?.toFormattedJson(),
    );
  }
}
