import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker/talker.dart';
import 'package:talker_bloc_effects/talker_bloc_effects.dart';
import 'package:talker_bloc_effects_example/main.dart';

void main() {
  testWidgets('increments state, shows Snackbar and logs one effect', (tester) async {
    final previousObserver = Bloc.observer;
    final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    Bloc.observer = TalkerBlocEffectsObserver(
      talker: talker,
      settings: const TalkerBlocLoggerSettings(printChanges: true),
    );
    addTearDown(() => Bloc.observer = previousObserver);

    await tester.pumpWidget(const CounterApp());
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.text('Increment and show effect'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.widgetWithText(SnackBar, 'Counter is 1'), findsOneWidget);
    final log = talker.history.whereType<BlocEffectLog>().single;
    expect(log.bloc, isA<CounterCubit>());
    expect((log.effect! as ShowCounter).value, 1);
    expect(log.message, contains('ShowCounter(value: 1)'));
    expect(talker.history, hasLength(2));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
