# talker_bloc_effects

One [Talker](https://pub.dev/packages/talker) observer for standard BLoC logs and
[bloc_effects](https://pub.dev/packages/bloc_effects) emissions. Each effect log
includes its emitting Bloc/Cubit, when available.

## Install

```yaml
dependencies:
  talker_bloc_effects: ^0.1.0
```

Requires Flutter 3.24 or later and Dart 3.5 or later. Supports Talker 5.1.20+,
bloc_effects 2.1.0+, and BLoC 9 within their respective major versions.
Flutter SDK is required because bloc_effects depends on Flutter.

## Connect the observer

```dart
import 'package:bloc/bloc.dart';
import 'package:talker/talker.dart';
import 'package:talker_bloc_effects/talker_bloc_effects.dart';

final talker = Talker();

void main() {
  Bloc.observer = TalkerBlocEffectsObserver(talker: talker);
  // Create your blocs/cubits and start the application here.
}
```

Declare packages you import directly in your application's dependencies.
Install the observer **before creating any Bloc, Cubit, or Effects source**:
these objects capture the observer at construction time.

The observer extends `TalkerBlocObserver` and also implements
`BlocWithEffectsObserver`. Assign it directly to `Bloc.observer`; wrapping it in
a standard `MultiBlocObserver` does not forward effect callbacks.

When `talker` is omitted, one instance is created and shared by all logs. Access
it through `observer.talker` to read its history or connect a Talker screen.

## Emit an effect

```dart
import 'package:bloc_effects/bloc_effects.dart';

class CounterCubit extends CubitWithEffects<int, String> {
  CounterCubit() : super(0);

  void increment() {
    emit(state + 1);
    emitEffect('Counter is $state');
  }
}
```

The effect appears under the `bloc-effect` key, for example:

```text
CounterCubit emitted effect:
Counter is 1
```

`BlocWithEffects` and the `Effects` mixin are supported too. An Effects source
that is not a Bloc/Cubit has a null `BlocEffectLog.bloc`. Null effects and repeated
identical effects are logged individually.

Logging observes emission. It does not subscribe to the effect stream, replay
effects, or confirm that a UI listener handled them. Effects are logged even when
there are no active listeners.

## Settings

```dart
Bloc.observer = TalkerBlocEffectsObserver(
  talker: talker,
  settings: const TalkerBlocLoggerSettings(
    printChanges: true,
    printCreations: true,
    printClosings: true,
  ),
  effectsSettings: TalkerBlocEffectsSettings(
    enabled: true,
    printEffectFullData: false,
    effectFilter: (bloc, effect) => bloc is CounterCubit,
  ),
);
```

Effect logging and full `toString()` messages are enabled by default. Set
`printEffectFullData: false` to display only the runtime type. This changes the
message, not the original `effect` retained in `BlocEffectLog`. Use `effectFilter`
to exclude an effect completely. It receives a nullable source and runs before
formatting; disabling logging also skips the filter and formatting.

Standard BLoC settings retain upstream defaults: events and transitions are
enabled; changes, creations, and closings are disabled. Errors retain their
original stack traces. Setting `effectsSettings.enabled` to false disables only
effects. Setting `settings.enabled` to false disables BLoC activity and effects,
but **keeps error logging**, matching `TalkerBlocObserver`.

Use `talker.disable()` to stop all logs and `talker.enable()` to resume them.
Filters and effect `toString()` methods run synchronously; exceptions they throw
propagate to the caller, as with standard Talker BLoC logging.

## Titles, colors, and TalkerScreen

The effect key is registered automatically for Talker's log filters. Customize
it through the same settings as other Talker logs:

```dart
final talker = Talker(
  settings: TalkerSettings(
    titles: {BlocEffectLog.logKey: 'UI effect'},
    colors: {BlocEffectLog.logKey: AnsiPen()..magenta()},
  ),
);
```

For a Flutter log screen, add `talker_flutter` to your application and use the
same Talker instance. This integration does not depend on talker_flutter itself;
that package may require a newer Flutter SDK.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_bloc_effects/talker_bloc_effects.dart';
import 'package:talker_flutter/talker_flutter.dart';

final talker = TalkerFlutter.init();

void main() {
  Bloc.observer = TalkerBlocEffectsObserver(talker: talker);
  runApp(MaterialApp(home: TalkerScreen(talker: talker)));
}
```

## Example

The [example](example) increments a counter, shows a Snackbar through
`BlocEffectListener`, and logs state changes and effects to a shared Talker.

```sh
cd example
flutter pub get
flutter run -d chrome
```

## Development

From the package root:

```sh
flutter pub get
dart format --line-length=120 --output=none --set-exit-if-changed lib test example/lib example/test
flutter analyze
flutter test
flutter pub downgrade
flutter analyze
flutter test
flutter pub upgrade
flutter pub publish --dry-run
```

From `example`, run `flutter pub get`, `flutter analyze`, `flutter test`, and
`flutter build web`. CI checks the package on Flutter 3.24.0 and current stable;
the stable job also tests and builds the example and validates the publication
archive. No workflow publishes a release.
