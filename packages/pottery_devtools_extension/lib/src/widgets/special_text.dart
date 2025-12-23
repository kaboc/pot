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
              shownText: (element) => '${element.groups.first!} ',
            ),
            TextDefinition(
              matcher: const PatternMatcher('#.+'),
              matchStyle: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.outline.withValues(alpha: 0.7),
              ),
            ),
          ],
        SpecialTextType.genericType => [
            SelectiveDefinition(
              matcher: const PatternMatcher('(?:.+?)<(.+)>(?:.+)'),
              shownText: (element) => element.groups.first!,
            ),
          ],
      },
      style: style,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class TappableText extends StatelessWidget {
  const TappableText(this.text, {required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final linkStyle = context.textTheme.bodyMedium?.copyWith(
      color: context.colorScheme.primary,
    );

    return CustomText(
      text,
      definitions: const [
        TextDefinition(matcher: PatternMatcher('.*')),
      ],
      style: linkStyle,
      hoverStyle: linkStyle?.copyWith(
        color: linkStyle.color?.withValues(alpha: 0.7),
      ),
      overflow: TextOverflow.ellipsis,
      onTap: (_) => onTap(),
    );
  }
}
