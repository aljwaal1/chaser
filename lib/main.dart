import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/store_service.dart';
import 'widgets/ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StoreService.instance.load();
  runApp(const OfflineBarcodeCashierApp());
}

class OfflineBarcodeCashierApp extends StatelessWidget {
  const OfflineBarcodeCashierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كاشير باركود',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: primary), scaffoldBackgroundColor: bg),
      home: const Directionality(textDirection: TextDirection.rtl, child: HomeScreen()),
    );
  }
}
