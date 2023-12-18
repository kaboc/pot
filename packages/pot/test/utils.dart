import 'package:meta/meta.dart';

import 'package:pot/pot.dart';
import 'package:pot/src/private/static.dart';

typedef Resetter = void Function();

extension PotObjectString<T> on Pot<T> {
  String objectString() {
    final desc = PotDescription.fromPot(this);
    return desc.object;
  }
}

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
  StaticPot.warningPrinter = (w) => warning = w;

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

  @override
  String toString() {
    return 'Foo($value)';
  }

  void dispose() {
    isDisposed = true;
    valueOfDisposedObject = value;
  }
}
