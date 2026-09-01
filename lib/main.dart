import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/service_locator.dart';
import 'design_system/gapsi_design_system.dart';
import 'presentation/search/search_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  await Hive.initFlutter();
  await setupServiceLocator();
  runApp(const ProviderScope(child: GapsiApp()));
}

class GapsiApp extends StatelessWidget {
  const GapsiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gapsi eCommerce',
      debugShowCheckedModeBanner: false,
      theme: GapsiTheme.light(),
      home: const SearchScreen(),
    );
  }
}
