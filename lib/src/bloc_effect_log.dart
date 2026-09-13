import 'package:bloc/bloc.dart';
import 'package:talker/talker.dart';

/// A single effect emission, including its source when available.
class BlocEffectLog extends TalkerLog {
  /// Creates a log using the effect's full text or only its runtime type.
  BlocEffectLog({
    required this.effect,
    this.bloc,
    bool printEffectFullData = true,
  }) : super(
          '${bloc == null ? 'Effect emitted' : '${bloc.runtimeType} emitted effect'}: '
          '${printEffectFullData ? '\n$effect' : effect.runtimeType}',
          key: logKey,
        );

  /// Talker key for filtering effects and customizing their title and color.
  static const logKey = 'bloc-effect';

  /// The emitting Bloc/Cubit, or null for a source without BLoC state.
  final BlocBase<dynamic>? bloc;

  /// The original effect, retained independently of the displayed message.
  final Object? effect;
}
