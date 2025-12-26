import 'package:flutter/material.dart';

// ignore: depend_on_referenced_packages, implementation_imports
import 'package:pot/src/private/utils.dart' show convertForDescription;

import 'package:pottery_devtools_extension/src/utils.dart';

class DetailsViewer extends StatelessWidget {
  const DetailsViewer({
    required this.title,
    required this.time,
    required this.data,
  });

  final String? title;
  final DateTime? time;
  final Map<String, Object?>? data;

  @override
  Widget build(BuildContext context) {
    return data == null
        ? const SizedBox.shrink()
        : LayoutBuilder(
            builder: (context, constraints) {
              return SelectionArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (time != null) ...[
                        const SizedBox(height: 4.0),
                        Text('$time'),
                      ],
                      const SizedBox(height: 16.0),
                      _BulletedDataList(data!),
                    ],
                  ),
                ),
              );
            },
          );
  }
}

class _BulletedDataList extends StatelessWidget {
  const _BulletedDataList(this.data);

  final Map<String, Object?> data;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const <int, TableColumnWidth>{
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: [
        for (final MapEntry(:key, :value) in data.entries)
          if (key != 'scope')
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8.0),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 4.0,
                              end: 6.0,
                            ),
                            child: Container(
                              width: 4.0,
                              height: 4.0,
                              decoration: ShapeDecoration(
                                shape: const CircleBorder(),
                                color: context.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                        TextSpan(
                          text: '$key:',
                          style: TextStyle(
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                  child: Text(
                    '${convertForDescription(value, quoteString: true)}',
                    style: TextStyle(
                      color: context.colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
      ],
    );
  }
}
