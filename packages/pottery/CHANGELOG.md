## 0.2.0

- **Breaking**
    - Rename `ScopedPottery` to `LocalPottery`. (#7)
        - This is to avoid it being confused with the scoping feature of package:pot.
        - `ScopedPottery` now exists as an alias, but will be removed.
    - Rename `ScopedPots` to `LocalPotteryObjects`. (#7)
        - This is the type name of the `builder` parameter of `LocalPottery`.
- Raise the minimum Flutter SDK version to 3.10.0.

## 0.1.1

- Bump pot version to 0.6.0.

## 0.1.0

- **Breaking**
    - Rename `PotsMap` to `PotReplacements`.
- Add `ScopedPottery` ([#4]).
- Implement `debugFillProperties()`.
- Bump pot version to 0.5.0.
- Add new tests to ensure correct behaviours.
- Improve existing tests.
- Improve documentation.

## 0.0.1+3

- Update README and example.

## 0.0.1+2

- Improve README.

## 0.0.1+1

- Change the project structure.

## 0.0.1

- Initial release.

[#4]: https://github.com/kaboc/pot/pull/4
[#7]: https://github.com/kaboc/pot/pull/7
