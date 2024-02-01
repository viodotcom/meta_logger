# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- New `MetaLogger.warning/2` function.
- New `@specs` for:
  - `MetaLogger.debug/2`
  - `MetaLogger.info/2`
  - `MetaLogger.warn/2`
  - `MetaLogger.warning/2`
  - `MetaLogger.error/2`
  - `MetaLogger.log/1`

### Changed

- `MetaLogger.warn/2` is now deprecated.

## [1.6.1] - 2021-11-05

### Changed

- Update documentation.

## [1.6.0] - 2021-11-05

### Added

- Add the contributing guide.

### Changed

- Update dependencies.
- Update documentation.
- Rename GitHub Action workflow.

### Fixed

- Format query string in Tesla Middleware logs.
  [Issue #13](https://github.com/FindHotel/meta_logger/issues/13)

## [1.5.0] - 2021-08-26

### Added

- Add `MetaLogger.metadata/0` function to return the logger metadata from the current process and
  caller processes.

## [1.4.1] - 2021-06-21

### Changed

- Update `ex_doc`.

## [1.4.0] - 2021-06-21

### Added

- Add MetaLogger.Slicer to slice log entries.
- Add body filtering to Tesla Middleware.
- Slice log entries on Tesla Middleware.

## [1.3.1] - 2021-06-03

### Added

- Custom replacements for filter patterns.

## [1.3.0] - 2021-06-02

### Added

- Add MetaLogger.Formatter protocol.
- `log\3` accepts a list as the payload. Each element of the list will be logged separately.

## [1.2.0] - 2021-04-23

### Added

- Add query params filtering to Tesla Middleware.

### Changed

- Ensure Tesla is loaded before defining MetaLogger middleware to avoid compilation errors on
  projects without Tesla.

## [1.1.0] - 2020-12-16

### Added

- Add Tesla middleware to log requests and responses.

### Changed

- Moved from Travis CI to GitHub Actions.

## [1.0.0] - 2020-07-14

### Changed

- Changes the required version of Elixir from 1.9 to 1.10.

### Fixed

- Gets logger metadata from the correct process dictionary key. Elixir 1.10 uses Erlang logger
  metadata.

## [0.1.0] - 2019-09-13

### Added

- Keep logger metadata from caller processes.

[Unreleased]: https://github.com/FindHotel/meta_logger/compare/1.6.1...HEAD
[1.6.1]: https://github.com/FindHotel/meta_logger/compare/1.6.0...1.6.1
[1.6.0]: https://github.com/FindHotel/meta_logger/compare/1.5.0...1.6.0
[1.5.0]: https://github.com/FindHotel/meta_logger/compare/1.4.1...1.5.0
[1.4.1]: https://github.com/FindHotel/meta_logger/compare/1.4.0...1.4.1
[1.4.0]: https://github.com/FindHotel/meta_logger/compare/1.3.1...1.4.0
[1.3.1]: https://github.com/FindHotel/meta_logger/compare/1.3.0...1.3.1
[1.3.0]: https://github.com/FindHotel/meta_logger/compare/1.2.0...1.3.0
[1.2.0]: https://github.com/FindHotel/meta_logger/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/FindHotel/meta_logger/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/FindHotel/meta_logger/compare/0.1.0...1.0.0
[0.1.0]: https://github.com/FindHotel/meta_logger/releases/tag/0.1.0
