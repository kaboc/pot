import 'package:flutter/material.dart';

import 'package:pottery_devtools_extension/src/utils.dart';
import 'package:pottery_devtools_extension/src/widgets/special_text.dart';

class CellConfig {
  const CellConfig(Object? data, {this.onTap}) : text = '$data';

  final String text;
  final VoidCallback? onTap;
}

class _CellContent extends StatelessWidget {
  const _CellContent({
    required this.config,
    required this.alignment,
    required this.specialTextType,
    required this.textStyle,
    required this.backgroundColor,
  });

  final CellConfig config;
  final Alignment alignment;
  final SpecialTextType? specialTextType;
  final TextStyle? textStyle;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final textType = specialTextType;
    final style = textStyle ?? context.textTheme.bodyMedium;

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.all(8.0),
      color: backgroundColor,
      child: config.onTap == null
          ? textType == null
              ? Text(
                  config.text,
                  style: style,
                  overflow: TextOverflow.ellipsis,
                )
              : IdentityText(
                  config.text,
                  type: textType,
                  style: style,
                )
          : TappableText(
              config.text,
              onTap: () => config.onTap?.call(),
            ),
    );
  }
}

class Cell extends StatelessWidget {
  const Cell(
    this.configs, {
    this.rowNumber,
    this.lineSpan,
    this.specialTextType,
    this.textStyle,
    this.backgroundColor,
  }) : _alignment = Alignment.centerLeft;

  const Cell.center(
    this.configs, {
    this.rowNumber,
    this.lineSpan,
    this.specialTextType,
    this.textStyle,
    this.backgroundColor,
  }) : _alignment = Alignment.center;

  final Iterable<CellConfig> configs;
  final int? rowNumber;
  final int? lineSpan;
  final SpecialTextType? specialTextType;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Alignment _alignment;

  static const double _smallerHeight = 40.0;
  static const double _biggerHeight = 50.0;

  static double calculateHeight({required int lines}) {
    return lines > 1 ? _smallerHeight * lines : _biggerHeight;
  }

  @override
  Widget build(BuildContext context) {
    final color = rowNumber == null
        ? (backgroundColor ?? Colors.transparent)
        : rowNumber!.isEven
            ? context.colorScheme.surfaceVariant.withOpacity(0.5)
            : Colors.transparent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final config in configs)
          SizedBox(
            height: lineSpan == null
                ? (configs.length > 1 ? _smallerHeight : _biggerHeight)
                : (lineSpan! > 1 ? _smallerHeight * lineSpan! : _biggerHeight),
            child: _CellContent(
              config: config,
              specialTextType: specialTextType,
              alignment: _alignment,
              textStyle: textStyle,
              backgroundColor: color,
            ),
          ),
      ],
    );
  }
}

class HeadingCell extends StatelessWidget {
  const HeadingCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Cell.center(
      [CellConfig(text)],
      textStyle: context.textTheme.bodyMedium?.copyWith(
        color: context.colorScheme.onSecondary,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: context.colorScheme.secondary,
    );
  }
}

class BoldCell extends StatelessWidget {
  const BoldCell(
    this.configs, {
    required this.rowNumber,
    this.lineSpan,
    this.specialTextType,
  });

  final Iterable<CellConfig> configs;
  final int rowNumber;
  final int? lineSpan;
  final SpecialTextType? specialTextType;

  @override
  Widget build(BuildContext context) {
    return Cell(
      configs,
      lineSpan: lineSpan,
      specialTextType: specialTextType,
      textStyle: context.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: rowNumber.isEven
          ? context.colorScheme.surfaceVariant
          : context.isDark
              ? Colors.white10
              : context.colorScheme.secondary.withOpacity(0.06),
    );
  }
}
