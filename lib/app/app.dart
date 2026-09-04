import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/auth_gate.dart';
import 'theme.dart';

class HapaApp extends ConsumerWidget {
  const HapaApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'Hapa',
    debugShowCheckedModeBanner: false,
    theme: HapaTheme.light,
    home: const AuthGate(),
  );
}
