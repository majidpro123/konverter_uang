import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- IMPORT PROVIDER ---
import 'providers/currency_provider.dart';

// --- IMPORT TEMA ---
import 'theme/app_theme.dart';

// --- IMPORT SCREENS ---
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/currency_selection_screen.dart'; 

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Menginisialisasi Provider dan langsung menarik data kurs awal
        ChangeNotifierProvider(create: (_) => CurrencyProvider()..fetchRates()),
      ],
      child: const KonverterApp(),
    ),
  );
}

class KonverterApp extends StatelessWidget {
  const KonverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Konverter Mata Uang',
      debugShowCheckedModeBanner: false, // Menghilangkan pita debug merah di pojok
      
      // --- MENGGUNAKAN TEMA DESAIN YANG BARU DIBUAT ---
      theme: AppTheme.light, 
      
      // --- ROUTING HALAMAN UTAMA ---
      initialRoute: '/welcome', // Halaman pembuka untuk cek sesi 1 jam
      routes: {
        '/welcome': (context) => const WelcomeScreen(), 
        '/login': (context) => const LoginScreen(), 
        '/': (context) => const MainScreen(),       
        '/select-currency': (context) => const CurrencySelectionScreen(),
      },
    );
  }
}