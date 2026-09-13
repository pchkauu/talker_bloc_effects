import 'package:bloc/bloc.dart';
import 'package:bloc_effects/bloc_effects.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker/talker.dart';
import 'package:talker_bloc_effects/talker_bloc_effects.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';

void main() {
  late Talker talker;
  late BlocObserver previousObserver;

  setUp(() {
    previousObserver = Bloc.observer;
    talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    Bloc.observer = TalkerBlocEffectsObserver(talker: talker);
  });

  tearDown(() {
    Bloc.observer = previousObserver;
  });

  test('Cubit logs each emission once without stream listeners', () async {
    final cubit = _CounterCubit();
    final effect = _Effect('saved');
    cubit
      ..send(effect)
      ..send(effect)
      ..send(null);

    final logs = talker.history.whereType<BlocEffectLog>().toList();
    expect(logs, hasLength(3));
    expect(logs.map((log) => log.bloc), everyElement(same(cubit)));
    expect(logs.map((log) => log.effect), [effect, effect, null]);
    expect(logs.first.message, '_CounterCubit emitted effect: \nsaved');
    expect(logs.last.message, '_CounterCubit emitted effect: \nnull');
    await cubit.close();
  });

  test('Bloc preserves standard logs and logs the effect once', () async {
    final bloc = _CounterBloc();
    final effect = _Effect('saved');
    final nextState = bloc.stream.first;
    bloc.add(_EmitEffect(effect));
    expect(await nextState, 1);

    expect(talker.history.whereType<BlocEventLog>(), hasLength(1));
    expect(talker.history.whereType<BlocStateLog>(), hasLength(1));
    final log = talker.history.whereType<BlocEffectLog>().single;
    expect(log.bloc, same(bloc));
    expect(log.effect, same(effect));
    await bloc.close();
  });

  test('Effects mixin preserves source and delivery to active listeners', () async {
    final cubit = _MixinCubit();
    final received = <Object?>[];
    final subscription = cubit.effectsStream.listen(received.add);
    final effect = _Effect('saved');
    cubit
      ..send(effect)
      ..send(effect);
    await cubit.close();
    await subscription.cancel();

    expect(received, [effect, effect]);
    final logs = talker.history.whereType<BlocEffectLog>();
    expect(logs, hasLength(2));
    expect(logs.map((log) => log.bloc), everyElement(same(cubit)));
  });

  test('a non-BLoC Effects source logs and filters with a null source', () async {
    final effects = <Object?>[];
    Bloc.observer = TalkerBlocEffectsObserver(
      talker: talker,
      effectsSettings: TalkerBlocEffectsSettings(
        effectFilter: (bloc, effect) {
          expect(bloc, isNull);
          effects.add(effect);
          return true;
        },
      ),
    );
    final source = _PlainSource()
      ..send('saved')
      ..send(null);
    expect(effects, ['saved', null]);
    final logs = talker.history.whereType<BlocEffectLog>();
    expect(logs, hasLength(2));
    expect(logs.map((log) => log.bloc), everyElement(isNull));
    expect(logs.first.message, 'Effect emitted: \nsaved');
    await source.close();
  });

  test('type-only output never calls toString and retains the effect', () async {
    Bloc.observer = TalkerBlocEffectsObserver(
      talker: talker,
      effectsSettings: const TalkerBlocEffectsSettings(
        printEffectFullData: false,
      ),
    );
    final cubit = _CounterCubit();
    final effect = _UnprintableEffect();
    cubit
      ..send(effect)
      ..send(null);
    final logs = talker.history.whereType<BlocEffectLog>().toList();
    expect(logs.first.message, '_CounterCubit emitted effect: _UnprintableEffect');
    expect(logs.first.effect, same(effect));
    expect(logs.last.message, '_CounterCubit emitted effect: Null');
    await cubit.close();
  });

  test('effect filter receives the source and runs before formatting', () async {
    final sources = <BlocBase<dynamic>?>[];
    Bloc.observer = TalkerBlocEffectsObserver(
      talker: talker,
      effectsSettings: TalkerBlocEffectsSettings(
        effectFilter: (bloc, effect) {
          sources.add(bloc);
          return effect == 'accepted';
        },
      ),
    );
    final cubit = _CounterCubit()
      ..send(_UnprintableEffect())
      ..send('accepted');
    expect(sources, [cubit, cubit]);
    expect(talker.history.whereType<BlocEffectLog>().single.effect, 'accepted');
    await cubit.close();
  });

  for (final disabled in ['effects', 'bloc', 'talker']) {
    test('$disabled switch skips effects before filtering and formatting', () async {
      Bloc.observer = TalkerBlocEffectsObserver(
        talker: talker,
        settings: TalkerBlocLoggerSettings(enabled: disabled != 'bloc'),
        effectsSettings: TalkerBlocEffectsSettings(
          enabled: disabled != 'effects',
          effectFilter: (_, __) => throw StateError('Filter must not run'),
        ),
      );
      if (disabled == 'talker') talker.disable();
      final cubit = _CounterCubit()..send(_UnprintableEffect());
      expect(talker.history, isEmpty);
      await cubit.close();
    });
  }

  test('Talker can resume effects on an existing cubit', () async {
    final cubit = _CounterCubit();
    talker.disable();
    cubit.send('hidden');
    talker.enable();
    cubit.send('visible');
    expect(talker.history.whereType<BlocEffectLog>().single.effect, 'visible');
    await cubit.close();
  });

  test('default Talker is shared by inherited logs and effects', () async {
    final observer = TalkerBlocEffectsObserver();
    observer.talker.configure(settings: TalkerSettings(useConsoleLogs: false));
    Bloc.observer = observer;
    final bloc = _CounterBloc();
    final nextState = bloc.stream.first;
    bloc.add(const _EmitEffect('saved'));
    await nextState;
    expect(observer.talker.history.whereType<BlocEventLog>(), hasLength(1));
    expect(observer.talker.history.whereType<BlocStateLog>(), hasLength(1));
    expect(observer.talker.history.whereType<BlocEffectLog>(), hasLength(1));
    await bloc.close();
  });

  test('lifecycle settings and error stack traces retain upstream behavior', () async {
    Bloc.observer = TalkerBlocEffectsObserver(
      talker: talker,
      settings: const TalkerBlocLoggerSettings(
        printChanges: true,
        printCreations: true,
        printClosings: true,
      ),
    );
    final cubit = _CounterCubit();
    final bloc = _CounterBloc();
    cubit.increment();
    final nextState = bloc.stream.first;
    bloc.add(const _EmitEffect('saved'));
    await nextState;
    final error = StateError('failed');
    final stackTrace = StackTrace.current;
    cubit.reportError(error, stackTrace);
    await cubit.close();
    await bloc.close();

    expect(talker.history.whereType<BlocCreateLog>(), hasLength(2));
    expect(talker.history.whereType<BlocCloseLog>(), hasLength(2));
    expect(talker.history.whereType<BlocChangeLog>(), hasLength(2));
    expect(talker.history.whereType<BlocEventLog>(), hasLength(1));
    expect(talker.history.whereType<BlocStateLog>(), hasLength(1));
    final errorLog = talker.history.singleWhere((log) => log.exception == error);
    expect(errorLog.stackTrace, same(stackTrace));
    expect(errorLog.logLevel, LogLevel.error);
  });

  test('disabled BLoC settings still report errors until Talker is disabled', () async {
    Bloc.observer = TalkerBlocEffectsObserver(
      talker: talker,
      settings: const TalkerBlocLoggerSettings(enabled: false),
    );
    final cubit = _CounterCubit();
    final error = StateError('failed');
    final stackTrace = StackTrace.current;
    cubit
      ..increment()
      ..send('hidden')
      ..reportError(error, stackTrace);
    expect(talker.history, hasLength(1));
    expect(talker.history.single.exception, same(error));
    expect(talker.history.single.stackTrace, same(stackTrace));
    talker.disable();
    cubit.reportError(StateError('hidden'), stackTrace);
    expect(talker.history, hasLength(1));
    await cubit.close();
  });

  test('inherited event and transition filters are respected', () async {
    Bloc.observer = TalkerBlocEffectsObserver(
      talker: talker,
      settings: TalkerBlocLoggerSettings(
        eventFilter: (_, __) => false,
        transitionFilter: (_, __) => false,
      ),
    );
    final bloc = _CounterBloc();
    final nextState = bloc.stream.first;
    bloc.add(const _EmitEffect('saved'));
    await nextState;
    expect(talker.history, hasLength(1));
    expect(talker.history.single, isA<BlocEffectLog>());
    await bloc.close();
  });

  test('registers the effect key once and honors Talker title and color', () async {
    final titles = Map<String, String>.of(talker.settings.titles);
    final colors = Map<String, AnsiPen>.of(talker.settings.colors);
    addTearDown(() {
      talker.settings.titles
        ..clear()
        ..addAll(titles);
      talker.settings.colors
        ..clear()
        ..addAll(colors);
    });
    final pen = AnsiPen()..magenta();
    talker.settings.titles[BlocEffectLog.logKey] = 'UI effect';
    talker.settings.colors[BlocEffectLog.logKey] = pen;
    final observer = TalkerBlocEffectsObserver(talker: talker);
    expect(observer.talker, same(talker));
    expect(
      talker.settings.registeredKeys.where((key) => key == BlocEffectLog.logKey),
      hasLength(1),
    );
    final cubit = _CounterCubit()..send('saved');
    final log = talker.history.whereType<BlocEffectLog>().single;
    expect(log.key, BlocEffectLog.logKey);
    expect(log.title, 'UI effect');
    expect(log.pen, same(pen));
    expect(log.generateTextMessage(), contains('[UI effect]'));
    await cubit.close();
  });
}

class _Effect {
  _Effect(this.message);
  final String message;

  @override
  String toString() => message;
}

class _UnprintableEffect {
  @override
  String toString() => throw StateError('toString must not run');
}

class _CounterCubit extends CubitWithEffects<int, Object?> {
  _CounterCubit() : super(0);

  void send(Object? effect) => emitEffect(effect);
  void increment() => emit(state + 1);
  void reportError(Object error, StackTrace stackTrace) => addError(error, stackTrace);
}

class _MixinCubit extends Cubit<int> with Effects<Object?> {
  _MixinCubit() : super(0);

  void send(Object? effect) => emitEffect(effect);
}

class _EmitEffect {
  const _EmitEffect(this.effect);
  final Object? effect;
}

class _CounterBloc extends BlocWithEffects<_EmitEffect, int, Object?> {
  _CounterBloc() : super(0) {
    on<_EmitEffect>((event, emit) {
      emit(state + 1);
      emitEffect(event.effect);
    });
  }
}

class _Closable implements Closable {
  @override
  bool get isClosed => _closed;
  bool _closed = false;

  @override
  Future<void> close() async => _closed = true;
}

class _PlainSource extends _Closable with Effects<Object?> {
  void send(Object? effect) => emitEffect(effect);
}
