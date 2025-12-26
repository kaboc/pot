[![Pub Version](https://img.shields.io/pub/v/pottery)](https://pub.dev/packages/pottery)
[![pottery CI](https://github.com/kaboc/pot/actions/workflows/pottery.yml/badge.svg)](https://github.com/kaboc/pot/actions/workflows/pottery.yml)
[![codecov](https://codecov.io/gh/kaboc/pot/branch/main/graph/badge.svg?token=YZMCN6WZKM)](https://codecov.io/gh/kaboc/pot)

## Overview

This package provides two widgets, [Pottery] and [LocalPottery], which manage
the lifetime of [Pot]s (single-type DI containers) according to the lifecycle
of widgets in Flutter.


### Why is this better than the scoping feature of Pot?

[Pot] itself from package:pot has the feature of scoping, but it is a package
for Dart, not specific to Flutter.

`Pottery` is a utility that makes up for it. It makes use of the widget lifecycle
to limit the scope of pots. It is more natural in Flutter and less error-prone.

### How will this make things better?

While it is convenient that you can access a pot stored in a global variable
from anywhere, it gives you too much freedom, making you wonder how pots should
be managed in a Flutter app. For example, you may easily lose track of from
where in your app code a particular pot is used.

`Pottery` makes it possible to manage pots in a similar manner to using package:provider.

## Examples

- [Counters](https://github.com/kaboc/pot/blob/main/packages/pottery/example) - simple
- [pub.dev explorer](https://github.com/kaboc/pubdev-explorer) - advanced

## Usage

### Pottery

Create a [Pot] as "pending" first if it is not necessary yet at the start of
your app. The pot should usually be assigned to a global variable.

```dart
final counterNotifierPot = Pot.pending<CounterNotifier>();
```

Use the `overrides` parameter of `Pottery` to specify pots and their factories
using `set()`. Each of the factories becomes available thereafter for the pot
it is called on.

```dart
Widget build(BuildContext context) {
  // counterNotifierPot does not have a factory yet.
  // Calling `counterNotifierPot()` here throws a PotNotReadyException.

  ...

  return Scaffold(
    body: Pottery(
      overrides: [
        counterNotifierPot.set(CounterNotifier.new),
      ],
      // The new factory specified in `overrides` above is ready
      // before this builder is called for the first time.
      builder: (context) {
        // Methods and getters of counterNotifierPot are now available.
        final count = counterNotifierPot();
        ...
      },
    ),
  ),
);
```

> [!NOTE]
> It is easier to understand how to use `Pottery` by imagining it as something
> similar to `MultiProvider` of the provider package, although they internally
> work quite differently:
>
> - MultiProvider
>     - Creates objects and provides them so that they are available in the subtree.
> - Pottery
>     - Replaces factories to make pots ready so that they are available after
>       that point. The widget tree is only used to manage the lifetime of
>       factories and objects in pots, so pots are still available outside the
>       tree.

Removing `Pottery` from the tree (e.g. navigating back from the page where
`Pottery` is used) resets all pots in the `overrides` list and replaces their
factories to throw an [PotNotReadyException].

> [!NOTE]
> If a target pot is not pending and an object already exists in it when `Pottery`
> is created, `Pottery` immediately replaces the object as well as the factory.

### LocalPottery

This widget defines new factories for existing pots to create objects that are
available only in the subtree.

An important fact is that the existing pots remain unchanged. The factories and
objects are associated with those pots and stored in [LocalPottery] for local
use. Therefore, calling `yourPot()` still returns the globally accessible object
stored in the pot itself.

To obtain the local object, use [of()][of] or [maybeOf()][maybeOf] instead.
These methods look up the widget tree for the nearest `LocalPottery` ancestor
that has the pot in its `overrides` list.

When no relevant `LocalPottery` ancestor is found:
- `of()`: Throws [LocalPotteryNotFoundException].
- `maybeOf()`: Returns `null`.

> [!WARNING]
> When the object type is nullable, `maybeOf()` cannot distinguish between
> "the relevant `LocalPottery` was not found" and "it was found but the
> provided object is null." Use `of()` if the pot is expected to be provided
> by a `LocalPottery` ancestor.

```dart
final fooPot = Pot(() => Foo(111));
```

```dart
class ParentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LocalPottery(
      overrides: [
        fooPot.set(() => Foo(222)),
      ],
      builder: (context) {
        print(fooPot()); // 111
        print(fooPot.of(context)); // 222

        return ChildWidget();
      },
    );
  }
}

class ChildWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print(fooPot()); // 111
    print(fooPot.of(context)); // 222
    ...
  }
}
```

For more practical use cases, see the example in [main2.dart] and the
documentation for [LocalPottery], [of], and [maybeOf].

#### Important differences in [LocalPottery] compared to [Pottery]:

- Objects are created immediately when `LocalPottery` is created, not when objects
  in pots are accessed for the first time.
- Objects created with `LocalPottery` are only accessible with [of()][of] or
  [maybeOf()][maybeOf] in the subtree.
- Objects created within `LocalPottery` are not automatically disposed when
  the `LocalPottery` is removed from the tree. Use the `disposer` argument
  of `LocalPottery` (instead of the disposer in each pot) to define a custom
  clean-up function.

Below is an example of a disposer function that disposes of all ChangeNotifiers
and subtypes:

```dart
LocalPottery(
  overrides: [
    myChangeNotifier.set(() => MyChangeNotifier()),
    intValueNotifier.set(() => ValueNotifier(111)),
  ],
  disposer: (pots) {
    pots.values.whereType<ChangeNotifier>().forEach((v) => v.dispose());
  },
  builder: (context) { ... },
)
```

## DevTools extension

This package includes the DevTools extension.

To use it, run your app in debug mode with Flutter 3.16 or newer and open the
DevTools.

<img src="https://github.com/kaboc/pot/assets/20254485/2a9f6a28-244f-44cc-bc9e-87b958ff4a36">

The extension starts when either [Pottery] or [LocalPottery] is first used.
It is also possible to start it earlier by calling `Pottery.startExtension()`.

> [!NOTE]
> Updates of the object in a pot caused by external factors (e.g. the object is
> a `ValueNotifier` and its value is reassigned) are not automatically reflected
> in the table view until an event of either `Pot`, `Pottery` or `LocalPottery`
> happens. Press the refresh icon button if you want to see the changes quickly,
> or use [notifyObjectUpdate()][notifyObjectUpdate] on a pot to emit an event
> to cause a refresh.

<img src="https://github.com/kaboc/pot/assets/20254485/3e5aa399-8189-4e80-a9f4-d7e35c083f15">

<!-- Links -->

[Pottery]: https://pub.dev/documentation/pottery/latest/pottery/Pottery-class.html
[LocalPottery]: https://pub.dev/documentation/pottery/latest/pottery/LocalPottery-class.html
[of]: https://pub.dev/documentation/pottery/latest/pottery/NearestLocalPotObjectOf/of.html
[maybeOf]: https://pub.dev/documentation/pottery/latest/pottery/NearestLocalPotObjectOf/maybeOf.html
[LocalPotteryNotFoundException]: https://pub.dev/documentation/pot/latest/pot/LocalPotteryNotFoundException-class.html
[Pot]: https://pub.dev/packages/pot
[PotNotReadyException]: https://pub.dev/documentation/pot/latest/pot/PotNotReadyException-class.html
[notifyObjectUpdate]: https://pub.dev/documentation/pottery/latest/pottery/Pot/notifyObjectUpdate.html
[main2.dart]: https://github.com/kaboc/pot/blob/main/packages/pottery/example/lib/main2.dart
