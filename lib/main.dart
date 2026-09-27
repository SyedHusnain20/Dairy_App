import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'repository/shop_repository.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DairyShopApp());
}

class DairyShopApp extends StatelessWidget {
  const DairyShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ShopRepository>(
      create: (_) => ShopRepository(),
      child: MaterialApp(
        title: 'Dairy Shop',
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
