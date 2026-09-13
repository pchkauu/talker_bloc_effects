import 'package:bloc_effects/bloc_effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker/talker.dart';
import 'package:talker_bloc_effects/talker_bloc_effects.dart';

void main() {
  final talker = Talker();
  Bloc.observer = TalkerBlocEffectsObserver(
    talker: talker,
    settings: const TalkerBlocLoggerSettings(printChanges: true),
  );
  runApp(const CounterApp());
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talker BLoC Effects',
      home: BlocProvider(
        create: (_) => CounterCubit(),
        child: const CounterPage(),
      ),
    );
  }
}

class CounterCubit extends CubitWithEffects<int, ShowCounter> {
  CounterCubit() : super(0);

  void increment() {
    emit(state + 1);
    emitEffect(ShowCounter(state));
  }
}

class ShowCounter {
  const ShowCounter(this.value);
  final int value;

  @override
  String toString() => 'ShowCounter(value: $value)';
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocEffectListener<CounterCubit, ShowCounter>(
      listener: (context, effect) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Counter is ${effect.value}')),
        );
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Talker BLoC Effects')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlocBuilder<CounterCubit, int>(
                builder: (_, count) => Text(
                  '$count',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
              const SizedBox(height: 16),
              const Text('State and effect logs appear in the console.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: context.read<CounterCubit>().increment,
                child: const Text('Increment and show effect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
