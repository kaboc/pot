[![Pub Version](https://img.shields.io/pub/v/pot)](https://pub.dev/packages/pot)
[![pot CI](https://github.com/kaboc/pot/actions/workflows/pot.yml/badge.svg)](https://github.com/kaboc/pot/actions/workflows/pot.yml)
[![codecov](https://codecov.io/gh/kaboc/pot/branch/main/graph/badge.svg?token=YZMCN6WZKM)](https://codecov.io/gh/kaboc/pot)

An easy and safe DI (Dependency Injection) solution for Dart.

## What is a pot?

[Pot] is a single-type DI container holding an object of a particular type.

Each pot has a Singleton factory function triggered to create an object as
needed. It is possible to replace the factory or remove the object in a pot at
your preferred timing, which is useful for testing as well as for implementing
app features.

> [!NOTE]
> A pot is usually assigned to a global variable.

### Advantages

- Easy
    - Straightforward because it is specialised for DI, without other features.
    - Simple API that you can be sure how to use.
    - A pot as a global variable is easy to handle; auto-completion works in IDEs.
- Safe
    - Not dependent on types.
        - No runtime error basically. The object always exists when it is
          accessed as long as the pot has a valid factory.
    - Not dependent on strings.
        - Pot does not provide a dangerous way to access the content like
          referencing it by type name.

## Examples

- [Todo](https://github.com/kaboc/pot/blob/main/packages/pot/example/pot_example.dart) - Dart (simple)
- [pub.dev explorer](https://github.com/kaboc/pubdev-explorer) - Flutter (advanced)

## Related package

- [Pottery]
    - A package that helps you use pots in Flutter by allowing to limit the scope
      of pots in the widget tree.
    - Whether to use this is up to you. It is just an additional utility.

## Usage

Create a pot with a so-called Singleton factory that instantiates an object.

```dart
final counterPot = Pot(() => Counter(0));
```

Now you can use the pot in whatever file importing the above declaration.

> [!NOTE]
> The created pot should be assigned to a global variable unless there is a
> special reason against it.

### Getting the object

Calling [call()][call] triggers the factory to create an object in the pot on
the fly if no object has been created yet or one has already been removed.
Otherwise, the existing object is returned.

The `call()` method is a special function in Dart that allows a class instance
to be called like a function, so instead of `counterPot.call()`, you can write
it as follows:

```dart
void main() {
  final counter = counterPot();
  ...
}
```

### Creating an object

Use [create()][create] if you want to instantiate an object without obtaining it.

This is practically the same as [call()][call], except that `create()` does not
return the created object while `call()` does. It has no effect if the pot
already has an object.

```dart
void main() {
  counterPot.create();
  ...
}
```

### Removing the object from a pot

You can remove the object with several methods like [reset()][reset]. The
resources are saved if objects are properly removed when they become unnecessary.

Even if an object is removed, the pot itself remains. A new object is created
when it is needed again.

If a callback function is passed to the `disposer` parameter of the
[constructor][Pot-constructor], it is triggered when the object is removed from
the pot. Use it for doing a clean-up related to the object.

```dart
final counterPot = Pot(
  () => Counter(0),
  disposer: (counter) => counter.dispose(),
);
```

```dart
void main() {
  final counter = counterPot();
  counter.increment();
  ...

  // Removes the Counter object from the pot and triggers the disposer function.
  counterPot.reset();
}
```

The [replace()][replace], [Pot.popScope()][popScope], [Pot.resetAllInScope()][resetAllInScope]
and [Pot.uninitialize()][uninitialize] methods also remove existing objects.
These will be explained in later sections of this document.

## Advanced usage

### Replacing factory and object

Pots created by [Pot.replaceable()][replaceable] or [Pot.pending()][pending]
have the [replace()][replace] method. It replaces the object factory function,
which was set in the constructor of [Pot], and the object held in the pot if
existing.

```dart
final userPot = Pot.replaceable(() => User.none());
```

```dart
Future<User> signIn() async {
  final userId = await Auth.signIn(...);
  userPot.replace(() => User(id: userId));
  return userPot();
}
```

> [!NOTE]
> The [replace()][replace] method removes the existing object, triggering the
> disposer, but only if the pot has an object. It behaves differently depending
> on whether the object exists. See the document of [replace()][replace] for
> details on the behaviour.

### Creating a pot with no factory

[Pot.pending()][pending] is an alternative to [Pot.replaceable()][replaceable],
useful if the object is unnecessary or the factory is unavailable until some point.

> [!NOTE]
> [PotNotReadyException] occurs if the pot is used before a valid factory is
> set with [replace()][replace].

```dart
final userPot = Pot.pending<User>();
// final user = userPot(); // PotNotReadyException

...

userPot.replace(() => User(id: userId));
final user = userPot();
```

It is also possible to remove the existing factory of a replaceable pot by
[resetAsPending()][resetAsPending] to switch the state of the pot to pending.

### Replacements for testing

If you need to replace the factory function only in tests, you may want to
use a non-replaceable pot and to use [replaceForTesting()][replaceForTesting]
instead of [replace()][replace]. This helps prevent accidentally calling
`replace` outside of tests in test-only scenarios.

The `replaceForTesting` method is available even on a non-replaceable pot.
Using it outside of a test will be flagged by static analysis.


```dart
final counterPot = Pot(() => Counter(0)); // Non-replaceable pot
```

```dart
void main() {
  test('Some test', () {
    counterPot.replaceForTesting(() => Counter(100));
    ...
  });
}
```

### Listening for events

The static method `listen()` allows you to listen for events related to pots.
See the document of [PotEventKind] for event types, such as `instantiated`
and `reset`.

```dart
final removeListener = Pot.listen((event) {
  ...
});

// Don't forget to stop listening when it is no longer necessary.
removeListener();
```

> [!NOTE]
> - Events of changes in the objects held in pots are not emitted automatically.
>     - Call `notifyObjectUpdate()` to manually emit those events if necessary.
> - There is no guarantee that the event data format remains unchanged in the
>   future. Use the method and the data passed to the callback function only
>   for debugging purposes.

## Even more advanced usage

### Scoping

#### Pot or Pottery

The scoping feature of this package is for Dart in general, not designed for
Flutter. In Flutter, consider using [Pottery] instead. It is a utility wrapping
this pot package for Flutter. It limits the lifespan of pots according to the
lifecycle of widgets, which is more natural in Flutter and less error-prone.

#### What is scoping

A "scope" in this package is a notion related to the lifespan of an object
held in a pot. It is given a sequential number starting from `0`. Adding a
scope increments the index number of the current scope, and removing one
decrements it.

For example, if a scope is added when the current index number is 0, the
number turns 1. If an object is then created, it gets bound to the current
scope 1. It means the object exists while the current scope is 1 or newer,
so when the scope 1 is removed, the object is removed and the disposer is
triggered. The current index number goes back to 0.

```dart
final counterPot = Pot(() => Counter());
```

```dart
void main() {
  print(Pot.currentScope);     // 0

  Pot.pushScope();
  print(Pot.currentScope);     // 1

  // The Counter object is created here, and it gets bound to scope 1.
  final counter = counterPot();
  print(counterPot.hasObject); // true

  // The scope 1 is removed, causing the object to be removed.
  Pot.popScope();
  print(Pot.currentScope);     // 0
  print(counterPot.hasObject); // false
}
```

Just calling [Pot.popScope()][popScope] resets all pots bound to the current
scope.

### Combining replace() with scoping

If an object is used only from some point onwards, you can make use of
[Pot.popScope()][popScope] and [replace()][replace].

Declare a pot with [Pot.pending()][pending] initially, and replace the factory
with the actual one after adding a scope. It allows a factory to be set only
in a specific scope, and enables the object to be removed from the pot by
removal of the scope.

```dart
// A dummy factory for the moment, which only throws an exception if called.
final userPot = Pot.pending<User>();

...

// A new scope is added, and the dummy factory is replaced with the actual one.
Pot.pushScope();
todoPot.replace(() => User(id, name));

// The User object is created and gets bound to the current scope.
final user = userPot();

...

// The scope is removed and the object is removed from the pot.
// It is a good practice to remove the factory so that it throws
// if called unexpectedly after this.
Pot.popScope();
userPot.resetAsPending();
```

### Resetting pots in the current scope

[Pot.resetAllInScope()][resetAllInScope] resets all pots bound to the current
scope, removing all objects from the pots. The scope itself is not removed.

The behaviour of each reset caused by this method is the same as when you call
[reset()][reset] manually for each pot; the disposer is triggered in the same way.

### Resetting pots in all scopes

[Pot.uninitialize()][uninitialize] removes all scopes and resets all pots.
This is useful to reset all pots and scopes to the initial state for testing.
It may also be used to make the app behave as if it has restarted.

## Caveats

### DON'T declare a pot locally

All pots should usually be declared globally, although it is possible to declare
them locally. It is because the data related to scoping is stored statically,
and forgetting to manually remove scopes causes some resources to remain until
the end of the program. Make sure to call [reset()][reset] or one of the other
methods that have the same effect if you declare pots locally.

<details>
<summary>Example code (Click to open)</summary>

```dart
void main() {
  final myClass = MyClass();
  ...
  myClass.dispose();
}
```

```dart
class MyClass {
  // Locally declared pot
  final servicePot = Pot(() => MyService());

  // Use reset() in a disposing method like this
  // and make sure to call it at some point.
  void dispose() {
    servicePot.reset();
  }

  void someMethod() {
    final service = servicePot();
    ...
  }
}
```
</details>

[Pot]: https://pub.dev/documentation/pot/latest/pot/Pot-class.html
[Pottery]: https://pub.dev/packages/pottery
[Pot-constructor]: https://pub.dev/documentation/pot/latest/pot/Pot/Pot.html
[call]: https://pub.dev/documentation/pot/latest/pot/Pot/call.html
[create]: https://pub.dev/documentation/pot/latest/pot/Pot/create.html
[reset]: https://pub.dev/documentation/pot/latest/pot/Pot/reset.html
[replace]: https://pub.dev/documentation/pot/latest/pot/ReplaceablePot/replace.html
[popScope]: https://pub.dev/documentation/pot/latest/pot/Pot/popScope.html
[resetAllInScope]: https://pub.dev/documentation/pot/latest/pot/Pot/resetAllInScope.html
[uninitialize]: https://pub.dev/documentation/pot/latest/pot/Pot/uninitialize.html
[replaceable]: https://pub.dev/documentation/pot/latest/pot/Pot/replaceable.html
[pending]: https://pub.dev/documentation/pot/latest/pot/Pot/pending.html
[resetAsPending]: https://pub.dev/documentation/pot/latest/pot/ReplaceablePot/resetAsPending.html
[PotNotReadyException]: https://pub.dev/documentation/pot/latest/pot/PotNotReadyException-class.html
[replaceForTesting]: https://pub.dev/documentation/pot/latest/pot/Pot/replaceForTesting.html
[PotEventKind]: https://pub.dev/documentation/pot/latest/pot/PotEventKind.html
