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

Pottery is a utility that makes up for it. It makes use of the widget lifecycle
to limit the scope of Pots. It is more natural in Flutter and less error-prone.

### How will this make things better?

While it is convenient that you can access a [Pot] stored in a global variable
from anywhere, it gives you too much freedom, making you wonder how Pots should
be managed in a Flutter app. For example, you may easily lose track of from
where in your app code a particular Pot is used.

Pottery makes it possible to manage Pots in a similar manner to using package:provider.
See the example described later in this document.

## Examples

- [Counters](https://github.com/kaboc/pot/blob/main/packages/pottery/example) - simple
- [pub.dev explorer](https://github.com/kaboc/pubdev-explorer) - advanced

## Getting started

```yaml
dependencies:
  pottery: ^x.x.x
```

## Usage

### Pottery

Create a [Pot] as "pending" first if it is not necessary yet at the start of
your app. The Pot should usually be assigned to a global variable.

```dart
final counterNotifierPot = Pot.pending<CounterNotifier>();
```

Use [Pottery] and specify a factory right before you need to start using the Pot.

```dart
Widget build(BuildContext context) {
  // counterNotifierPot does not have a factory yet.
  // Calling `counterNotifierPot()` here throws a PotNotReadyException.

  ...

  return Scaffold(
    body: Pottery(
      pots: {
        counterNotifierPot: CounterNotifier.new,
      },
      // The new factory specified in the pots argument above is ready
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

`pots` is a Map with key-value pairs of a Pot and a factory. Each of the factories
becomes available for a corresponding Pot thereafter.

It is easier to understand how to use Pottery by imagining it as something similar to
`MultiProvider` of the provider package, although they internally work quite differently.

- MultiProvider
    - Creates objects and provides them so that they are available down the tree.
- Pottery
    - Replaces factories to make Pots ready so that they are available after that point.
      The widget tree is only used to manage the lifespan of factories and objects in
      Pots, so Pots are still available outside the tree. 
      

Removing Pottery from the tree (e.g. navigating back from the page where Pottery is used)
resets all Pots in the `pots` map and replaces their factories to throw an
[PotNotReadyException].

**Note:**

If a target Pot is not pending and an object already exists in it when Pottery
is created, Pottery replaces the object as well as the factory immediately. 

### LocalPottery

This widget defines new factories for existing Pots to create objects that are
available only in the subtree.

An important fact is that the factories of the existing Pots are not replaced,
but new separate factories are associated with those Pots for local use only.
Therefore, calling a Pot still returns the object held globally in the Pot.
Use [of()] instead to obtain the local object. The example below illustrates
the behaviour.

```dart
final fooPot = Pot(() => Foo(111));
```

```dart
class ParentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LocalPottery(
      pots: {
        fooPot: () => Foo(222),
      },
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

See the examples in [main2.dart] and in the document of [LocalPottery] for usage in
more practical use cases.

Note that there are several important differences between `LocalPottery` and [Pottery]:

- Objects are created immediately when `LocalPottery` is created, not when objects
  in Pots are accessed for the first time.
- As already mentioned, objects created with `LocalPottery` are only accessible with
  [of()].
- Objects created with `LocalPottery` are not automatically disposed when the
  `LocalPottery` is removed from the tree. Use `disposer` to specify a callback
  function to clean them up. Below is an example where the disposer function
  disposes all ChangeNotifier subtypes.

```dart
LocalPottery(
  pots: {
    myChangeNotifier: () => MyChangeNotifier(),
    intValueNotifier: () => ValueNotifier(111),
  },
  disposer: (pots) {
    pots.values.whereType<ChangeNotifier>().forEach((v) => v.dispose());
  },
  builder: (context) { ... },
)
```

## Caveats

### Make sure to specify a factory that returns a correct type.

Key-value pairs passed to `pots` are not type-safe.

In the following example, a function returning an `int` value is specified as
a new factory of a Pot for `String`. Although it is obviously wrong, the static
analysis does not tell you about the mistake. The error only occurs at runtime.

```dart
final stringPot = Pot.pending<String>();
```

```dart
pots: {
  stringPot: () => 123,
}
```

## DevTools extension

This package includes the DevTools extension.

To use it, run your app in debug mode with Flutter 3.16 or newer and open the
DevTools.

<img src="https://github.com/kaboc/pot/assets/20254485/2a9f6a28-244f-44cc-bc9e-87b958ff4a36">

The extension starts when either [Pottery] or [LocalPottery] is first used.
It is also possible to start it earlier by calling `Pottery.startExtension()`.

Note that updates of objects in Pot are not automatically reflected in the
table view until an event of either `Pot`, `Pottery` or `LocalPottery` happens.
Press the refresh icon button if you want to see the changes quickly, or use
`notifyObjectUpdate()` on a Pot to manually emit an event to cause a refresh.

<img src="https://github.com/kaboc/pot/assets/20254485/3e5aa399-8189-4e80-a9f4-d7e35c083f15">

<!-- Links -->

[Pottery]: https://pub.dev/documentation/pottery/latest/pottery/Pottery-class.html
[LocalPottery]: https://pub.dev/documentation/pottery/latest/pottery/LocalPottery-class.html
[of()]: https://pub.dev/documentation/pottery/latest/pottery/NearestPotOf/of.html
[Pot]: https://pub.dev/packages/pot
[PotNotReadyException]: https://pub.dev/documentation/pot/latest/pot/PotNotReadyException-class.html
[main2.dart]: https://github.com/kaboc/pot/blob/main/packages/pottery/example/lib/main2.dart
