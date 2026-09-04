import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/home/presentation/home_page.dart';
import 'theme.dart';

class HapaApp extends ConsumerWidget {
  const HapaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Hapa',
      debugShowCheckedModeBanner: false,
      theme: HapaTheme.light,
      home: const HomePage(),
    );
  }
}
