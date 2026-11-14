import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkSession(); // Cek sesi auto-login di sini
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('userId') ?? 0;
    final String? loginTimeStr = prefs.getString('loginTime');

    if (userId != 0 && loginTimeStr != null) {
      final DateTime loginTime = DateTime.parse(loginTimeStr);
      final DateTime now = DateTime.now();

      if (now.difference(loginTime).inHours < 1) {
        if (!mounted) return;
        final provider = Provider.of<CurrencyProvider>(context, listen: false);
        provider.resetData();
        provider.loadHistory();

        // Sesi aktif: Langsung lompat ke halaman utama
        Navigator.pushReplacementNamed(context, '/');
        return;
      } else {
        // Sesi kedaluwarsa: Bersihkan memori
        await prefs.clear();
      }
    }

    // Jika tidak ada sesi atau sudah kedaluwarsa, tampilkan tombol Lanjut
    if (mounted) {
      setState(() {
        _isCheckingSession = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Aplikasi (Menggunakan Ikon)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x556C5CE7),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: const Icon(
                Icons.currency_exchange,
                size: 90,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            // Nama Aplikasi
            const Text(
              'Konverter Mata Uang',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),

            // Slogan / Deskripsi
            const Text(
              'Hitung Kurs Lebih Mudah & Cepat',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textMuted,
              ),
            ),

            const SizedBox(height: 60),

            // Indikator Loading (saat cek sesi) ATAU Tombol Lanjut
            _isCheckingSession
                ? const CircularProgressIndicator(color: AppColors.primary)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // Pindah ke halaman Login saat ditekan
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Tombol membulat
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Lanjut',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}