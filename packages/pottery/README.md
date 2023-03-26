[![Pub Version](https://img.shields.io/pub/v/pottery)](https://pub.dev/packages/pottery)
[![pottery CI](https://github.com/kaboc/pot/actions/workflows/pottery.yml/badge.svg)](https://github.com/kaboc/pot/actions/workflows/pottery.yml)
[![codecov](https://codecov.io/gh/kaboc/pot/branch/main/graph/badge.svg?token=YZMCN6WZKM)](https://codecov.io/gh/kaboc/pot)

**Pottery** is a widget that limits the scope where particular [Pot]s are available
in the widget tree.

## Motivations

### Why is this better than scoping by Pot itself?

The scoping feature of [Pot] is not very suitable for Flutter apps because Pot is
not a package specific to Flutter but for Dart in general and so is the scoping feature.

Pottery makes use of the widget lifecycle to limit the scope of pots. It is more
natural and less error-prone.

### How beneficial is it to use this?

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

## Usage

Create a pot as pending if the pot is not necessary at the beginning of an app.

```dart
final counterNotifierPot = Pot.pending<CounterNotifier>();
```

Use `Pottery` and specify a factory right before you need to use the pot.

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

The factory of each of the pot passed to the `pots` argument as a key in the map becomes
ready with the new factory passed as a value, and it makes the pots available from that
point onwards.

It is easier to understand how to use Pottery if you take it as similar to the usage of
MultiProvider of the provider package, although what they do are quite different in fact.

- MultiProvider
    - Creates objects and provides them so that they are available down the tree.
- Pottery
    - Replaces factories to make pots ready so that they are available after that point.

Removing Pottery (e.g. navigating back from the page where Pottery is used) resets
all pots passed to the `pots` argument and replaces their factories to throw an
[PotNotReadyException].

## Caveats

### Make sure not to specify a factory that returns a wrong type.

The `pots` argument is not type-safe.

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

## Tips

### Using Pottery with Grab

The author created Pot and Pottery mainly for using them in combination with [Grab].
This combination is even more similar to the usage of the provider package and will
be good as an alternative.

However, the extension methods of Grab requires the `BuildContext` of the widget
in which they are used, not the `BuildContext` passed to the `builder` function
of Pottery.

```dart
Pottery(
  pots: { ... },
  builder: (context) {
    // Wrong!!
    final count = context.grab<int>(counterNotifierPot());
  },
)
```

It is necessary to use Pottery before the build method where pots are used is called.

#### Option 1

Using Pottery in the builder function of PageRoute before navigating to the
page that requires pots.

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
  child: ...,
)
```

#### Option 2

Using Pottery in the builder function of PageRoute in a route method.

This is more recommended because Pottery is used in the class of the actual page
where pots are used, which makes more sense and helps you grasp the scope of pots
when you get back to the code after a long while.

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
    final count = context.grab<int>(counterNotifierPot());
  }
}
```

<!-- Links -->

[Pot]: https://pub.dev/packages/pot
[PotNotReadyException]: https://pub.dev/documentation/pot/latest/pot/PotNotReadyException-class.html
[Grab]: https://pub.dev/packages/grab
