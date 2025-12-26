import 'package:pot/pot.dart' show Pot, PotObjectFactory, ReplaceablePot;

import 'local_pottery.dart';
import 'pottery.dart';

/// The signature of the pair of a pot and its factory used for [LocalPottery].
class PotOverride<T> {
  /// Creates [PotOverride] that has the pair of a pot and its factory
  /// used for [LocalPottery].
  const PotOverride({required this.pot, required this.factory});

  /// A [Pot] used as the key for an object created by the associated
  /// [factory] and stored/provided by [LocalPottery] to the widget subtree.
  final Pot<T> pot;

  /// A factory function used by [LocalPottery] to create an object
  /// for the [pot].
  final PotObjectFactory<T> factory;
}

/// The signature of the pair of a replaceable pot and its new factory
/// used for [Pottery].
//
// Note:
// This class extends PotOverride so LocalPottery can accept the result
// regardless of whether set() on a ReplaceablePot resolves to either
// the Pot or ReplaceablePot extension.
class PotReplacement<T> extends PotOverride<T> {
  /// Creates [PotReplacement] that has the pair of a replaceable pot
  /// and its new factory used for [Pottery].
  const PotReplacement({
    required ReplaceablePot<T> super.pot,
    required super.factory,
  });

  /// A [ReplaceablePot] whose factory is replaced with the [factory]
  /// function by [Pottery].
  @override
  ReplaceablePot<T> get pot => super.pot as ReplaceablePot<T>;

  /// A factory function that replaces the object factory associated
  /// with [pot].
  @override
  PotObjectFactory<T> get factory => super.factory;
}

/// Extension on [Pot], used for [LocalPottery].
extension PotExtensionForLocalPottery<T> on Pot<T> {
  /// Specifies the pair of a pot and a factory function for [LocalPottery].
  PotOverride<T> set(PotObjectFactory<T> factory) {
    return PotOverride(pot: this, factory: factory);
  }
}

/// Extension on [ReplaceablePot], used for [Pottery].
extension PotExtensionForPottery<T> on ReplaceablePot<T> {
  /// Specifies the pair of a replaceable pot and a factory function
  /// for [Pottery].
  PotReplacement<T> set(PotObjectFactory<T> factory) {
    return PotReplacement(pot: this, factory: factory);
  }
}
