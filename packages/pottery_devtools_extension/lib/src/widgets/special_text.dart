import 'package:flutter/widgets.dart';

import 'package:custom_text/custom_text.dart';

import 'package:pottery_devtools_extension/src/utils.dart';

enum SpecialTextType { identity, genericType }

class IdentityText extends StatelessWidget {
  const IdentityText(
    this.identity, {
    required this.type,
    this.style,
  });

  final String identity;
  final SpecialTextType type;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return CustomText(
      identity,
      definitions: switch (type) {
        SpecialTextType.identity => [
            SelectiveDefinition(
              matcher: const PatternMatcher('(.+?)(<.+>|(?=#.+))'),
              shownText: (groups) => '${groups.first!} ',
            ),
            TextDefinition(
              matcher: const PatternMatcher('#.+'),
              matchStyle: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.outline.withOpacity(0.7),
              ),
            ),
          ],
        SpecialTextType.genericType => [
            SelectiveDefinition(
              matcher: const PatternMatcher('(?:.+?)<(.+)>(?:.+)'),
              shownText: (groups) => groups.first!,
            ),
          ],
      },
      style: style,
      overflow: TextOverflow.ellipsis,
    );
  }
}
