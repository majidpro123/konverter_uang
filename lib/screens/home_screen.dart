import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/currency_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _amountController = TextEditingController();

  // Fungsi pembantu untuk menampilkan simbol mata uang
  String getCurrencySymbol(String code) {
    const symbols = {
      'IDR': 'Rp', 'USD': '\$', 'EUR': '€', 'JPY': '¥', 'CNY': '¥',
      'KRW': '₩', 'GBP': '£', 'MYR': 'RM', 'SGD': 'S\$', 'AUD': 'A\$',
      'SAR': '﷼', 'THB': '฿', 'INR': '₹',
    };
    return symbols[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    // Memanggil provider untuk mengakses state dan fungsi
    final provider = Provider.of<CurrencyProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Konverter Mata Uang'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : provider.errorMessage.isNotEmpty
              ? Center(
                  child: Text(provider.errorMessage,
                      style: const TextStyle(color: AppColors.danger)))
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- INPUT NOMINAL ---
                        AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Masukkan Nominal',
                              labelStyle: const TextStyle(color: AppColors.textMuted),
                              border: InputBorder.none,
                              prefixText: '${getCurrencySymbol(provider.baseCurrency)} ',
                              prefixStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- PEMILIHAN MATA UANG ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Tombol Base Currency
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.textDark,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: AppColors.primary.withOpacity(0.15)),
                                  ),
                                ),
                                onPressed: () async {
                                  final result = await Navigator.pushNamed(
                                      context, '/select-currency',
                                      arguments: 'base') as String?;
                                  if (result != null) provider.setBaseCurrency(result);
                                },
                                child: Text(provider.baseCurrency,
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w700)),
                              ),
                            ),

                            // Tombol Swap (Tukar Mata Uang)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: GestureDetector(
                                onTap: () => provider.swapCurrencies(),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.swap_horiz,
                                      size: 24, color: Colors.white),
                                ),
                              ),
                            ),

                            // Tombol Target Currency
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.textDark,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: AppColors.primary.withOpacity(0.15)),
                                  ),
                                ),
                                onPressed: () async {
                                  final result = await Navigator.pushNamed(
                                      context, '/select-currency',
                                      arguments: 'target') as String?;
                                  if (result != null) provider.setTargetCurrency(result);
                                },
                                child: Text(provider.targetCurrency,
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // --- TOMBOL KONVERSI ---
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () {
                                if (_amountController.text.isNotEmpty) {
                                  provider.calculateConversion(
                                      double.parse(_amountController.text));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Masukkan nominal terlebih dahulu!')),
                                  );
                                }
                              },
                              child: const Text('KONVERSI',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- KARTU HASIL KONVERSI ---
                        if (provider.conversionResult > 0)
                          GradientCard(
                            child: Column(
                              children: [
                                const Text(
                                  'Hasil Konversi',
                                  style: TextStyle(fontSize: 13, color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${getCurrencySymbol(provider.targetCurrency)} ${provider.conversionResult.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),

                        // --- BAGIAN GRAFIK TREN ---
                        Text(
                          'Tren ${provider.baseCurrency} ke ${provider.targetCurrency} (7 Hari Terakhir)',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark),
                        ),
                        const SizedBox(height: 12),

                        // Memanggil Widget Grafik
                        const CurrencyTrendChart(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// --- WIDGET GRAFIK TREN (MEMBACA DATA DARI PROVIDER) ---
class CurrencyTrendChart extends StatelessWidget {
  const CurrencyTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CurrencyProvider>(context);
    final spots = provider.historicalSpots;

    // Jika data grafik kosong atau base dan target mata uang sama
    if (spots.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: const Text(
          'Data tren tidak tersedia',
          style: TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 24, left: 10, top: 20, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: AppColors.textMuted.withOpacity(0.15), strokeWidth: 1),
            getDrawingVerticalLine: (value) =>
                FlLine(color: AppColors.textMuted.withOpacity(0.15), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  // Menampilkan teks sumbu X (H-6, H-5, dst)
                  int daysAgo = spots.length - 1 - value.toInt();
                  String text = daysAgo == 0 ? 'Hr ini' : 'H-$daysAgo';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(text,
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  // Menampilkan teks sumbu Y (Kurs)
                  return Text(value.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: provider.minY,
          maxY: provider.maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: AppColors.primary,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.25),
                    AppColors.primary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}