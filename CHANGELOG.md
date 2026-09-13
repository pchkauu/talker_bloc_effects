# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-09-14

### Added

- `TalkerBlocEffectsObserver` for standard BLoC logs and effect emissions through
  one shared Talker instance.
- `BlocEffectLog` with the original effect and its emitting Bloc/Cubit when
  available, including support for null and repeated effects.
- `TalkerBlocEffectsSettings` for effect filtering, enabling logging, and choosing
  full or type-only messages.
- The `bloc-effect` key for Talker filtering, titles, and colors.
- A Flutter web example demonstrating counter changes and Snackbar effects.
- Package and widget tests, strict analysis rules, and CI checks for the minimum
  supported Flutter SDK and current stable.

[unreleased]: https://github.com/pchkauu/talker_bloc_effects/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/pchkauu/talker_bloc_effects/tree/v0.1.0
