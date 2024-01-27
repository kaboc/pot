import 'package:flutter/material.dart';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:grab/grab.dart';

import 'package:pottery_devtools_extension/src/extension_page.dart';
import 'package:pottery_devtools_extension/src/utils.dart';

void main() {
  runApp(
    const Grab(child: FooDevToolsExtension()),
  );
}

class FooDevToolsExtension extends StatelessWidget {
  const FooDevToolsExtension();

  @override
  Widget build(BuildContext context) {
    return DevToolsExtension(
      child: Builder(
        builder: (context) {
          return Theme(
            data: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: context.baseColor,
                brightness: Theme.of(context).brightness,
              ),
            ),
            child: const PotteryExtensionPage(),
          );
        },
      ),
    );
  }
}
