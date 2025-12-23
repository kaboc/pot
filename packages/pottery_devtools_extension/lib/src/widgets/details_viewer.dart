import 'package:flutter/material.dart';

import 'package:pottery_devtools_extension/src/utils.dart';
import 'package:pottery_devtools_extension/src/widgets/highlighted_json.dart';

class DetailsViewer extends StatelessWidget {
  const DetailsViewer({
    required this.title,
    required this.time,
    required this.json,
  });

  final String? title;
  final DateTime? time;
  final String? json;

  @override
  Widget build(BuildContext context) {
    return json == null
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
                      HighlightedJson(json!),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
