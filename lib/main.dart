import 'package:flutter/material.dart';
import 'features/maps/presentation/screens/map_screen.dart';
import '../../../../core/constants/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meu Mapa',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: AppColors.background, // Cor de fundo geral
      ),
      home: const MapScreen(), // Tela inicial
    );
  }
}