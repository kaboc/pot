import 'package:meta/meta.dart' show immutable;

import 'package:pot/pot.dart';

extension PotObjectString<T> on Pot<T> {
  String objectString() {
    final desc = PotDescription.fromPot(this);
    return desc.object;
  }
}

bool isInitialized = false;
bool isDisposed = false;
int valueOfDisposedObject = -1;

void resetFoo() {
  isInitialized = false;
  isDisposed = false;
  valueOfDisposedObject = -1;
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
  int get hashCode => Object.hash(uid, value);

  @override
  String toString() {
    return 'Foo($value)';
  }

  void dispose() {
    isDisposed = true;
    valueOfDisposedObject = value;
  }
}
