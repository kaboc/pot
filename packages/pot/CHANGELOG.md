## 0.9.0

- Update minimum Dart SDK version to 3.6.2.
- Fix missing state cleanup in `uninitialize()`.
- Perform internal refactoring.
- **Breaking**:
    - Remove deprecated `resetAll()`.
        - Use `uninitialize()` instead.
    - Remove public default constructor from `PotDescription`.
        - This class is primarily for internal use. This change should not affect most users.
    - Change `PotDescription.object` from `String` to `Object?`.
        - This may only affect those who process events received via `listen()`.

## 0.8.0

- Add `Pot.uninitialize()`.
- Deprecate `Pot.resetAll()` in favor of `Pot.uninitialize()`.
- Annotate `replaceForTesting()` with `@VisibleForTesting`.
- Improve behaviors related to `dispose()`:
    - Fix issue where `notifyObjectUpdate()` did not throw when called after `dispose()`.
    - Allow calling `dispose()` on already disposed pot.
- Perform internal refactoring.
- **Breaking**:
    - Remove `forTesting` and `PotReplaceError`.
        - To migrate, remove usage of `forTesting`.
        - `replaceForTesting()` is now always available in tests.

## 0.7.1

- Fix the `fromMap` constructor and `toString()` of `PotDescription`.
- Add missing tests.

## 0.7.0

- Add `Pot.listen()`. ([#8])
    - `hasListener` and `notifyObjectUpdate()` are also available.
- Add `toString()` so that the content of a pot is visible by print.
- Fix the document of `resetAll()`.
    - The meaning of `keepScope` was oppositely explained.
- Improve the overall structure.

## 0.6.0

- Add `resetAsPending()` and `isPending` to `ReplaceablePot`.

## 0.5.0

- Raise minimum Dart version to 2.19 for better type inference and to align with Pottery.
- Fix the bug of Pot not properly handling a factory that returns null. ([#3])
- Improve documentation.

## 0.4.2+1

- Change the project structure.
- Add an introduction of Pottery to README.

## 0.4.2

- Add `keepScopes` to `resetAll()`.
    - No change in the default behavior.
    - If `false` is passed, not only objects but also scopes are reset.
- Fix a warning and add a missing rule to analysis_options.yaml.
- Improve documentation.

## 0.4.1

- Downgrade `meta` and `test` to resolve issue in Dart 2.17 / Flutter 3.0.
- Update analysis_options.yaml.

## 0.4.0

- Add `pending()` and `PotNotReadyException`.
- Raise minimum Dart version to 2.17.
- Improve documentation.

## 0.3.2

- Improve example.

## 0.3.1

- Add `hasObject` that shows whether an object has been created.

## 0.3.0

- Make ReplaceablePot a subtype of Pot.
- Minor changes in tests.

## 0.2.1

- Include type name in assertion error message.
- Improve documentation.
- Update dev dependency.

## 0.2.0

- **Breaking changes**
    - Remove `get` getter.
    - Change `replace()` and `replaceForTest()` to replace not only factory but also object.
        - Before
            - The existing object is discarded and a new object is not created.
        - Now
            - If there was an object, it is discarded and a new object is created.
            - If there was no object, a new object is not created.
- Warn when new object is created in older scope than where previous object was bound to.
- Minor refactoring of `reset()`.
- Refactor tests and add some more.
- Improve documentation.

## 0.1.1

- Fix and improve documentation.

## 0.1.0

- Initial version.

[#3]: https://github.com/kaboc/pot/pull/3
[#8]: https://github.com/kaboc/pot/pull/8
