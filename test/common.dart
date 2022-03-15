import 'package:meta/meta.dart';

import 'package:pot/pot.dart';

typedef Resetter = void Function();

late bool isInitialized;
late bool isDisposed;
late int valueOfDisposedObject;

Object? warning;

void _popAllScopes() {
  for (var i = Pot.currentScope; i >= 0; i--) {
    Pot.popScope();
  }
}

void prepare() {
  _popAllScopes();
  Pot.forTesting = false;
  Pot.$warningPrinter = (w) => warning = w;

  isInitialized = false;
  isDisposed = false;
  valueOfDisposedObject = -1;
  warning = null;
}

@immutable
class Foo {
  Foo(this.value)
      : uid = Object().hashCode ^ DateTime.now().millisecondsSinceEpoch {
    isInitialized = true;
  }

  final int uid;
  final int value;

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      other is Foo && uid == other.uid && value == other.value;

  @override
  int get hashCode => Object.hashAll([uid, value]);

  void dispose() {
    isDisposed = true;
    valueOfDisposedObject = value;
  }
}
