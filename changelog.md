# Change Log

## Unreleased

- Update all dependencies
- Change `object` events in Kotlin to `data object` as an improvement brought by Kotlin 2.0

### Breaking Changes
- Fix deprecation warnings
- Set minimum ruby version as 3.2

## [0.4.4] - 2024-10-16

### Breaking Changes
- Update to Kotlin 2.0 notation which doesn't require a ';' in the last item of an enum

## [0.4.3] - 2023-09-14
- Put class properties in newline for Kotlin

## [0.4.2] - 2022-01-05
- Fix kotlin generation changes in 0.4.0

## [0.4.1] - 2021-12-23
- Changes swift implementation so that destinations belong to EventType/PropertyType instead of Event/Property

## [0.4.0] - 2021-12-21
- Adds type to people properties
- Adds a list of destinations to events and people properties

## [0.3.0] - 2021-12-16
- Revamp Android generator to generate events as classes instead of methods.

## [0.2.0] - 2021-08-30
- Google Spreadsheet option stopped working due to a change in the API. This version fixes that.

Note: You'll need a new setup. View README.

## [0.1.4.4] - 2019-02-04
 - Adds support for dynamic android package name

## [0.1.4.3] - 2018-10-12
 - Fixes swift and kotlin tabs, indentation and property names
 - Merges all special enums in a single file

## [0.1.4.2] - 2018-02-14
 - Replaces Swift headers

## [0.1.4.1] - 2018-02-08
- DRYs methods in swift event generation

## [0.1.4] - 2018-02-08
- Removes not needed enum file on Swift generator
- Removes Long type on Swift generator
- More tabbing fixes according to #9

## [0.1.3] - 2018-02-08
- Fixes quotations and spacing on Swift code generation

## [0.1.2] - 2018-01-25
- Improves swift code generation

## [0.1.1] - 2017-11-07
- Fixes mismatch between file name and class name generated.

## [0.1.0] - 2017-10-26
- Initial Release.

