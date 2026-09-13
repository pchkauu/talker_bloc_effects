import 'package:bloc/bloc.dart';

/// Controls which effects are logged and how their messages are displayed.
class TalkerBlocEffectsSettings {
  /// Creates effect settings. Effects and their full data are enabled by default.
  const TalkerBlocEffectsSettings({
    this.enabled = true,
    this.printEffectFullData = true,
    this.effectFilter,
  });

  /// Whether effect logging is enabled.
  ///
  /// The observer's BLoC settings and Talker must also be enabled.
  final bool enabled;

  /// Whether to display the effect's `toString()` instead of its runtime type.
  ///
  /// This only controls the message. The log still retains the original effect.
  final bool printEffectFullData;

  /// Returns whether an effect should be logged, before message formatting.
  ///
  /// The source is null for an `Effects` implementation that is not a Bloc/Cubit.
  /// An absent filter accepts every effect, including null.
  final bool Function(BlocBase<dynamic>? bloc, Object? effect)? effectFilter;
}
