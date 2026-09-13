import 'package:bloc/bloc.dart';
import 'package:bloc_effects/bloc_effects.dart';
import 'package:talker/talker.dart';
import 'package:talker_bloc_effects/src/bloc_effect_log.dart';
import 'package:talker_bloc_effects/src/talker_bloc_effects_settings.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';

/// Logs BLoC lifecycle events and effects to the same Talker instance.
///
/// Assign to `Bloc.observer` before creating any blocs, cubits or effect sources.
/// Standard BLoC logs and settings retain [TalkerBlocObserver]'s behavior.
class TalkerBlocEffectsObserver extends TalkerBlocObserver implements BlocWithEffectsObserver {
  /// Creates an observer, using a new Talker when [talker] is omitted.
  TalkerBlocEffectsObserver({
    Talker? talker,
    TalkerBlocLoggerSettings settings = const TalkerBlocLoggerSettings(),
    TalkerBlocEffectsSettings effectsSettings = const TalkerBlocEffectsSettings(),
  }) : this._(talker ?? Talker(), settings, effectsSettings);

  TalkerBlocEffectsObserver._(
    this._talker,
    TalkerBlocLoggerSettings settings,
    this.effectsSettings,
  ) : super(talker: _talker, settings: settings) {
    _talker.settings.registerKeys([BlocEffectLog.logKey]);
  }

  final Talker _talker;

  /// The shared Talker receiving both standard BLoC logs and effects.
  Talker get talker => _talker;

  /// Settings that apply to effect logs only.
  final TalkerBlocEffectsSettings effectsSettings;

  /// Logs an effect together with the Bloc/Cubit that emitted it.
  @override
  void onBlocEffect(BlocBase<dynamic> bloc, Object? effect) {
    _logEffect(bloc, effect);
  }

  /// Logs an effect whose source is not available.
  @override
  void onEffect<E>(E effect) {
    _logEffect(null, effect);
  }

  void _logEffect(BlocBase<dynamic>? bloc, Object? effect) {
    if (!settings.enabled || !effectsSettings.enabled || !_talker.settings.enabled) {
      return;
    }
    if (!(effectsSettings.effectFilter?.call(bloc, effect) ?? true)) {
      return;
    }
    _talker.logCustom(
      BlocEffectLog(
        bloc: bloc,
        effect: effect,
        printEffectFullData: effectsSettings.printEffectFullData,
      ),
    );
  }
}
