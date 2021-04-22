# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Add query params filtering to Tesla Middleware

### Changed
- Ensure Tesla is loaded before defining MetaLogger middleware to avoid
compilation errors on projects without Tesla.

## [1.1.0] - 2020-12-16
### Added
- Add Tesla middleware to log requests and responses.

### Changed
- Moved from Travis CI to GitHub Actions.

## [1.0.0] - 2020-07-14
### Changed
- Changes the required version of Elixir from 1.9 to 1.10.

### Fixed
- Gets logger metadata from the correct process dictionary key. Elixir 1.10
uses Erlang logger metadata.

## [0.1.0] - 2019-09-13
### Added
- Keep logger metadata from caller processes.

[Unreleased]: https://github.com/FindHotel/meta_logger/compare/1.1.0...HEAD
[1.1.0]: https://github.com/FindHotel/meta_logger/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/FindHotel/meta_logger/compare/0.1.0...1.0.0
[0.1.0]: https://github.com/FindHotel/meta_logger/releases/tag/0.1.0
