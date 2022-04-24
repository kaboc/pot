## 0.2.1

- Include type name in assert message.
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
