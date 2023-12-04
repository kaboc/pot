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
