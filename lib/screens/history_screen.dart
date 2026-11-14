import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../widgets/history_card.dart'; // Memanggil custom widget yang baru dibuat
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CurrencyProvider>(context);
    final history = provider.historyList;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Konversi'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history_toggle_off,
                        size: 56, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  const Text('Belum ada riwayat konversi.',
                      style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                // Sekarang kita cukup memanggil widget HistoryCard, kodingan jadi lebih bersih!
                return HistoryCard(item: history[index]);
              },
            ),
    );
  }
}