[![Pub Version](https://img.shields.io/pub/v/pot)](https://pub.dev/packages/pot)
[![Dart CI](https://github.com/kaboc/pot/workflows/Dart%20CI/badge.svg)](https://github.com/kaboc/pot/actions)
[![codecov](https://codecov.io/gh/kaboc/pot/branch/main/graph/badge.svg?token=YZMCN6WZKM)](https://codecov.io/gh/kaboc/pot)

An easy and safe DI (Dependency Injection) solution for Dart with support for scoping.

## Introduction

A [Pot][Pot] is a sort of service locator, but a single pot is for a single type.
An object of a certain type is created in a pot as needed and kept until it is discarded.

- Easy
    - Straightforward because it is specialised for DI, without other features.
    - Simple API that you can be sure with confidence how to use.
    - A pot as a global variable is easy to handle, and can take help from IDEs.
- Safe
    - Not dependent on types. 
        - No runtime error basically. The object always exists when it is accessed
          as long as the pot has a valid factory.
    - Not dependent on strings either.
        - Features to access an object or a scope by name were excluded on purpose.
        - More of other similar design decisions for safety.

### Policy

This package will not adopt new features easily so that it'll be kept simple to use.
The focus will be more on enhancing stability and robustness.

## Usage

Create a pot with a so-called Singleton factory that instantiates an object.

```dart
final counterPot = Pot(() => Counter(0));
```

Now you can use the pot whatever file importing the above declaration.

Note that the created pot should be assigned to a global variable unless there is some
special reason not to.

### Getting the object

Call the [call()][call] method.

An object is created on the fly by the factory. If no object has been created yet, one is
created when it is first accessed, and the same object is returned from next time onwards.

`call()` is a special function of Dart that allows a class instance to be called like
a function, so you can omit the method name like below.

```dart
void main() {
  final counter = counterPot();
  ...
}
```

### Creating an object

Use [create()][create] if you want to instantiate an object without obtaining it.

This is practically the same as [call()][call], except whether the created object is
returned or not.

```dart
void main() {
  counterPot.create();
  ...
}
```

### Discarding the object

You can discard the object with several methods like [reset()][reset]. The resources are saved
if objects are properly discarded when they become unnecessary.

Even if an object is discarded, the pot itself is not discarded. A new object is created when
it is needed again, so no worry that the object may be no longer accessible.

If a callback function is passed to the `disposer` of the [constructor][Pot-constructor] of Pot,
it is triggered when the object in the pot is discarded. Use it for doing a clean-up related to
the object.

```dart
final counterPot = Pot<Counter>(
  () => Counter(0),
  disposer: (counter) => counter.dispose(),
);
```

```dart
void main() {
  final counter = counterPot();
  counter.increment();
  ...

  // Discards the Counter object and triggers the disposer function.
  counterPot.reset();
}
```

[replace()][replace], [Pot.popScope()][popScope], [Pot.resetAllInScope()][resetAllInScope]
and [Pot.resetAll()][resetAll] also discard existing object(s). These will be explained in
later sections of this document.

## Advanced usage

### Replacing factory and object

Pots created by [Pot.replaceable()][replaceable] have the [replace()][replace] method.
It replaces the object factory, which was set in the constructor of [Pot][Pot], and
the object held in a pot. Otherwise, the [replace()][replace] method is not available.

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

Note that the [replace()][replace] method discards an existing object, triggering the
disposer, but only if an object has already been created. It behaves differently depending
on whether the object exists. See the document of [replace()][replace] for details on the
behaviour.

### Creating a pot with no factory

[Pot.pending()][pending] is an alternative to [Pot.replaceable()][replaceable], useful
if the object is unnecessary or the factory is unavailable until some point.

Note that a [PotNotReadyException][PotNotReadyException] occurs if the pot is used before
a valid factory is set.

```dart
final userPot = Pot.pending<User>();
// final user = userPot(); // PotNotReadyException

...

userPot.replace(() => User(id: userId));
final user = userPot();
```

### Replacements for testing

If replacements are only necessary in tests, avoid using [Pot.replaceable][replaceable]
for safety. Instead, enable the use of [replaceForTesting()][replaceForTesting] by setting
[Pot.forTesting][forTesting] to `true`.

```dart
final counterPot = Pot(() => Counter(0));
```

```dart
void main() {
  Pot.forTesting = true;

  test('Some test', () {
    counterPot.replaceForTesting(() => Counter(100));
    ...
  });
}
```

### Scoping

A "scope" in this package is a notion related to the lifespan of an object held in a pot.
It is given a sequential number starting from `0`. Adding a scope increments the index
number of the current scope, and removing one decrements it.

For example, if a scope is added when the current index number is 0, the number turns 1.
If an object is created then, it gets bound to the current scope 1. It means the object
exists while the current scope is 1 or newer, so it is discarded and the disposer is
triggered when the scope 1 is removed. The current index number goes back to 0.

```dart
final counterPot = Pot<Counter>(
  () => Counter(),
  disposer: (counter) => counter.dispose(),
);
```

```dart
void main() {
  print(Pot.currentIndex); // 0
  // At this point, the counter object is not bound to the scope 0
  // because the object has not been created yet.

  Pot.pushScope();
  print(Pot.currentIndex); // 1

  // The counter object is created here, and it gets bound to scope 1.
  final counter = counterPot();

  // The scope 2 is removed and the counter object is discarded.
  // In addition, the disposer is triggered.
  Pot.popScope();
  print(Pot.currentIndex); // 0
}
```

If multiple objects are bound to the current scope, you can discard all of them by just
calling [Pot.popScope()][popScope].

### Combining replace() with scoping

If an object is used only from some point onwards, you can make use of
[Pot.popScope()][popScope] and [replace()][replace].

Declare a pot with [Pot.pending()][pending] initially, and replace the factory with
the actual one after adding a scope. It allows a factory to be set only at a specific
scope, and enables the object to be discarded by removal of the scope.

<details>
<summary>Example code (Click to open)</summary>

An example of an app using Flutter:

```dart
// 1. A dummy factory for the moment, which only throws an exception if called.
final todoPot = Pot.pending<Todo>();
```

```dart
class TodoPage extends StatefulWidget {
  const TodoPage({required this.todoId});

  final String todoId;

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  @override
  void initState() {
    super.initState();

    // 2. A new scope is added, and the dummy factory is replaced with the actual one.
    Pot.pushScope();
    todoPot.replace(() => Todo(widget.todoId));
  }

  @override
  void dispose() {
    // 4. The Todo object is discarded when the page is navigated away from.
    Pot.popScope();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3. The Todo object is created and gets bound to the current scope.
    final todo = todoPot();
    ...
  }
}
```
</details>

### Resetting objects without removing a scope

[Pot.resetAllInScope()][resetAllInScope] discards all the objects bound to the current scope,
but the scope is not removed.

The behaviour of a reset of each object is the same as [reset()][reset]; the disposer is
triggered in the same way.

### Resetting objects in all scopes

[Pot.resetAll()][resetAll] discards all the objects that are bound to any scope. This is
useful to reset all for testing.

By default, this method does not remove scopes themselves. If you want both objects and scopes
to be reset, call it with `keepScopes: false`. It may be used for clearing the state to make
the app behave as if it has restarted.

## Caveats

### DON'T declare a pot locally

All pots should usually be declared globally. It is possible to declare pots locally as long as
their resources are properly discarded, but it is almost meaningless to use it like the code below.
There isn't much difference from having the MyService object directly as a property of MyClass.

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

This brings the danger that its partial data remains until the end of the program because
the data related to scoping is stored globally even if the pot is assigned to a local variable,
and it is not automatically discarded when the variable goes out of use. It therefore must be
discarded manually with [reset()][reset] or other methods that have the same effect.

[Pot]: https://pub.dev/documentation/pot/latest/pot/Pot-class.html
[Pot-constructor]: https://pub.dev/documentation/pot/latest/pot/Pot/Pot.html
[call]: https://pub.dev/documentation/pot/latest/pot/Pot/call.html
[create]: https://pub.dev/documentation/pot/latest/pot/Pot/create.html
[reset]: https://pub.dev/documentation/pot/latest/pot/Pot/reset.html
[replace]: https://pub.dev/documentation/pot/latest/pot/ReplaceablePot/replace.html
[popScope]: https://pub.dev/documentation/pot/latest/pot/Pot/popScope.html
[resetAllInScope]: https://pub.dev/documentation/pot/latest/pot/Pot/resetAllInScope.html
[resetAll]: https://pub.dev/documentation/pot/latest/pot/Pot/resetAll.html
[replaceable]: https://pub.dev/documentation/pot/latest/pot/Pot/replaceable.html
[pending]: https://pub.dev/documentation/pot/latest/pot/Pot/pending.html
[PotNotReadyException]: https://pub.dev/documentation/pot/latest/pot/PotNotReadyException-class.html
[forTesting]: https://pub.dev/documentation/pot/latest/pot/Pot/forTesting.html
[replaceForTesting]: https://pub.dev/documentation/pot/latest/pot/Pot/replaceForTesting.html
