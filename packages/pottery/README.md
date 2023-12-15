[![Pub Version](https://img.shields.io/pub/v/pottery)](https://pub.dev/packages/pottery)
[![pottery CI](https://github.com/kaboc/pot/actions/workflows/pottery.yml/badge.svg)](https://github.com/kaboc/pot/actions/workflows/pottery.yml)
[![codecov](https://codecov.io/gh/kaboc/pot/branch/main/graph/badge.svg?token=YZMCN6WZKM)](https://codecov.io/gh/kaboc/pot)

## Overview

A package that provides two widgets, `Pottery` and `LocalPottery`.

They limit the scope where particular [Pot]s are available in the widget tree.
Using them make it clearer from which point onwards pots are used.

### Why is this better than the scoping feature of Pot?

[Pot] is not a package specific to Flutter but it is for Dart in general, therefore
its scoping feature is not designed for Flutter either.

Pottery makes use of the widget lifecycle to limit the scope of pots. It is more
natural in Flutter and less error-prone.

### How is this beneficial?

It is convenient that you can access a pot stored in a global variable from anywhere,
but it gives you too much freedom, making it difficult to keep the architecture of
your app well-organised.

By using Pottery, it becomes possible to manage pots in a similar manner to using
package:provider. See the example described later in this document.

## Getting started

This package contains the [pot] package and exposes it. It is enough to only add
pottery without pot to pubspec.yaml.

```yaml
dependencies:
  pottery: ^x.x.x
```

## Examples

- [Counters](https://github.com/kaboc/pot/blob/main/packages/pottery/example) - simple
- [pub.dev explorer](https://github.com/kaboc/pubdev-explorer) - advanced

## Usage

This package comes with two widgets:

- [Pottery]
- [LocalPottery]

### Pottery

Create a pot as pending if it is not necessary yet at the start of an app.

```dart
final counterNotifierPot = Pot.pending<CounterNotifier>();
```

Use [Pottery] and specify a factory right before you need to use the pot.

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
    - Replaces factories to make pots ready so that they are available after that point.
      The widget tree is only used to manage the lifespan of factories and objects in
      Pots, so Pots are still available outside the tree. 
      

Removing Pottery from the tree (e.g. navigating back from the page where Pottery is used)
resets all pots in the `pots` map and replaces their factories to throw an
[PotNotReadyException].

### LocalPottery

This widget defines new factories for existing pots to create objects that are available
only in the subtree.

An important fact is that the factories of the existing pots are not replaced, but
new factories are associated with those pots. Therefore, calling the [call()] method
of a pot still returns the object held in the global pot. Use [of()] instead to obtain
the local object. The example below illustrates the behaviour.

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
- Objects created with `LocalPottery` are not automatically discarded when the
  `LocalPottery` is removed from the tree. Use the `disposer` argument to specify a
  callback function to clean them up. Below is an example where the disposer function
  disposes of all ChangeNotifier subtypes.

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

The `pots` argument is not type-safe as it uses a generic Map.

```dart
final counterNotifierPot = Pot.pending<CounterNotifier>();
```

```dart
pots: {
  counterNotifierPot: TodoNotifier.new,
}
```

In this example, the factory of counterNotifierPot must be a function that returns
CounterNotifier. However, the static analysis does not tell you it is wrong to specify
a factory that creates TodoNotifier. The error only occurs at runtime.

## Usage with Grab

The author created Pot and Pottery mainly for using them in combination with [Grab].
You can use Pottery + Grab as an alternative to package:provider.

There is however an important thing to remember. The extension methods of Grab require
the `BuildContext` of the widget that has the Grab mixin, not the one passed to the
`builder` function of [Pottery].

```dart
class MyWidget extends StatelessWidget with Grab {
  const MyWidget();

  @override
  Widget build(BuildContext context) {
    return Pottery(
      pots: { ... },
      builder: (context) {
        // The BuildContext passed to this callback
        // cannot be used for methods of Grab.
        final count = counterNotifierPot().grab(context); // Bad
      },
    )
  }
}
```

It is actually possible to get around it by using the outer BuildContext instead.

```dart
Widget build(BuildContext context) {
  return Pottery(
    pots: { ... },
    builder: (innerContext) {
      // Grab works if you use the `context` passed to
      // the build method instead of `innerContext`.
      final count = counterNotifierPot().grab(context);
    },
  );
)
```

However, using grab methods this way is discouraged as it is confusing and can
easily lead to a bug. If you are using [grab_lints], it will warn you about it.

Make sure to use `Pottery` a little earlier to get pots ready before they are used
in a build method. Here are two options for it.

### Option 1

Using `Pottery` in the builder function of PageRoute before navigation.

```dart
ElevatedButton(
  onPressed: () => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Pottery(
        pots: { ... },
        builder: (_) => const CounterPage(),
      ),
    ),
  ),
  child: const Text('To CounterPage'),
)
```

### Option 2

Using `Pottery` in the builder function of PageRoute in a route method.

This is essentially the same as Option 1, but more recommended because Pottery
is used in the class of the actual page where pots are used. It makes more sense
and helps you easily grasp the scope of pots when you get back to the code after
a long while.

```dart
class CounterPage extends StatelessWidget {
  const CounterPage._();

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => Pottery(
        pots: { ... },
        builder: (_) => const CounterPage._(),
      ),
    );
  }

  Widget build(BuildContext context) {
    final count = counterNotifierPot().grab(context);
  }
}
```

```dart
ElevatedButton(
  onPressed: () => Navigator.of(context).push(CounterPage.route()),
  child: const Text('To CounterPage'),
)
```

<!-- Links -->

[Pottery]: https://pub.dev/documentation/pottery/latest/pottery/Pottery-class.html
[LocalPottery]: https://pub.dev/documentation/pottery/latest/pottery/LocalPottery-class.html
[of()]: https://pub.dev/documentation/pottery/latest/pottery/NearestPotOf/of.html
[call()]: https://pub.dev/documentation/pot/latest/pot/Pot/call.html
[Pot]: https://pub.dev/packages/pot
[Grab]: https://pub.dev/packages/grab
[grab_lints]: https://pub.dev/packages/grab_lints
[PotNotReadyException]: https://pub.dev/documentation/pot/latest/pot/PotNotReadyException-class.html
[main2.dart]: https://github.com/kaboc/pot/blob/main/packages/pottery/example/lib/main2.dart
