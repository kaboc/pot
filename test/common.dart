import 'package:meta/meta.dart';

import 'package:pot/pot.dart';

typedef Resetter = void Function();

late bool isInitialized;
late bool isDisposed;
late int valueOfDisposedObject;

void _popAllScopes() {
  for (var i = Pot.currentScope; i >= 0; i--) {
    Pot.popScope();
  }
}

void prepare() {
  _popAllScopes();
  Pot.forTesting = false;

  isInitialized = false;
  isDisposed = false;
  valueOfDisposedObject = -1;
}

@immutable
class Foo {
  Foo(this.value) {
    isInitialized = true;
  }

  final int value;

  @override
  bool operator ==(Object other) =>
      identical(other, this) || other is Foo && value == other.value;

  @override
  int get hashCode => value.hashCode;

  void dispose() {
    isDisposed = true;
    valueOfDisposedObject = value;
  }
}
