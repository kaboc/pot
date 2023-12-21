import 'package:flutter/material.dart';

import 'package:custom_text/custom_text.dart';
import 'package:highlight/highlight.dart';

import 'package:pottery_devtools_extension/src/utils.dart';

class HighlightedJson extends StatelessWidget {
  const HighlightedJson(this.jsonText);

  final String jsonText;

  @override
  Widget build(BuildContext context) {
    return CustomText(
      jsonText,
      parserOptions: const ParserOptions.external(_parseJson),
      definitions: [
        TextDefinition(
          matcher: const AttrMatcher(),
          matchStyle: TextStyle(color: context.colorScheme.primary),
        ),
        TextDefinition(
          matcher: const LiteralMatcher(),
          matchStyle: TextStyle(color: context.colorScheme.secondary),
        ),
        TextDefinition(
          matcher: const NumberMatcher(),
          matchStyle: TextStyle(color: context.colorScheme.secondary),
        ),
        TextDefinition(
          matcher: const StringMatcher(),
          matchStyle: TextStyle(color: context.colorScheme.tertiary),
        ),
        TextDefinition(
          matcher: const UrlMatcher(),
          matchStyle: TextStyle(
            color: context.colorScheme.tertiary,
            backgroundColor: context.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}

Future<List<TextElement>> _parseJson(String text) async {
  final result = highlight.parse(text, language: 'json');
  return _buildElements(result.nodes);
}

Future<List<TextElement>> _buildElements(
  List<Node>? nodes, [
  int offset = 0,
  String? className,
]) async {
  if (nodes == null) {
    return [];
  }

  final elements = <TextElement>[];
  var currentOffset = offset;

  for (final node in nodes) {
    if (node.children == null) {
      final value = node.value;
      if (value != null && value.isNotEmpty) {
        elements.addAll(
          await _buildValueElements(value, currentOffset, className),
        );
      }
    } else {
      elements.addAll(
        await _buildElements(node.children, currentOffset, node.className),
      );
    }
    if (elements.isNotEmpty) {
      currentOffset = elements.last.offset + elements.last.text.length;
    }
  }

  return elements;
}

Future<List<TextElement>> _buildValueElements(
  String text,
  int offset,
  String? className,
) async {
  final parser = TextParser(matchers: const [UrlMatcher()]);
  var elements = await parser.parse(text, useIsolate: false);

  final matcherType = _mappings[className] ?? TextMatcher;
  if (!elements.containsMatcherType<UrlMatcher>()) {
    return [TextElement(text, matcherType: matcherType, offset: offset)];
  }

  elements = elements.reassignOffsets(startingOffset: offset).toList();
  return [
    for (final elm in elements)
      if (elm.matcherType == UrlMatcher)
        elm
      else
        elm.copyWith(matcherType: matcherType),
  ];
}

const _mappings = {
  'attr': AttrMatcher,
  'literal': LiteralMatcher,
  'number': NumberMatcher,
  'string': StringMatcher,
  'link': UrlMatcher,
};

class AttrMatcher extends TextMatcher {
  const AttrMatcher() : super('');
}

class LiteralMatcher extends TextMatcher {
  const LiteralMatcher() : super('');
}

class NumberMatcher extends TextMatcher {
  const NumberMatcher() : super('');
}

class StringMatcher extends TextMatcher {
  const StringMatcher() : super('');
}
