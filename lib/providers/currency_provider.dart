import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/history_model.dart';

class CurrencyProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  final String _backendUrl = 'http://10.0.2.2:8081/api/history'; 
  
  Map<String, dynamic> _rates = {};
  bool _isLoading = false;
  String _errorMessage = '';
  
  String _baseCurrency = 'USD';
  String _targetCurrency = 'IDR';
  double _conversionResult = 0.0;

  List<ConversionHistory> _historyList = [];

  // --- STATE UNTUK GRAFIK TREN ---
  List<FlSpot> _historicalSpots = [];
  double _minY = 0;
  double _maxY = 0;

  // --- GETTERS ---
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Map<String, dynamic> get rates => _rates;
  String get baseCurrency => _baseCurrency;
  String get targetCurrency => _targetCurrency;
  double get conversionResult => _conversionResult;
  List<ConversionHistory> get historyList => _historyList;
  
  List<FlSpot> get historicalSpots => _historicalSpots;
  double get minY => _minY;
  double get maxY => _maxY;

  CurrencyProvider() {
    loadHistory(); 
    fetchRates(); // Panggil fetch rates di awal
    updateHistoricalData(); 
  }

  // --- AMBIL KURS MATA UANG (DENGAN CACHE OFFLINE) ---
  Future<void> fetchRates() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    try {
      // Ambil data dari API online
      _rates = await _apiService.fetchRates(_baseCurrency);
      
      // JIKA BERHASIL: Simpan data terbaru ke cache lokal berdasarkan baseCurrency
      await prefs.setString('cached_rates_$_baseCurrency', jsonEncode(_rates));
    } catch (e) {
      print('Gagal mengambil data terbaru, mencoba memuat dari cache: $e');
      
      // JIKA GAGAL (OFFLINE): Ambil dari cache lokal
      String? cachedData = prefs.getString('cached_rates_$_baseCurrency');
      if (cachedData != null) {
        _rates = jsonDecode(cachedData);
        _errorMessage = 'Mode Offline: Menampilkan data kurs terakhir.';
      } else {
        _errorMessage = 'Koneksi gagal dan tidak ada data cache tersedia.';
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void setBaseCurrency(String currency) {
    _baseCurrency = currency;
    fetchRates();
    updateHistoricalData(); 
  }

  void setTargetCurrency(String currency) {
    _targetCurrency = currency;
    updateHistoricalData(); 
    notifyListeners();
  }

  void swapCurrencies() {
    String temp = _baseCurrency;
    _baseCurrency = _targetCurrency;
    _targetCurrency = temp;
    fetchRates(); 
    updateHistoricalData(); 
  }

  void calculateConversion(double amount) {
    if (_rates.containsKey(_targetCurrency)) {
      _conversionResult = amount * _rates[_targetCurrency];
      
      final history = ConversionHistory(
        userId: 0, 
        fromCurrency: _baseCurrency,
        toCurrency: _targetCurrency,
        amount: amount,
        result: _conversionResult,
        date: DateTime.now().toIso8601String(),
      );
      
      _saveToHistory(history);
      notifyListeners();
    }
  }

  // --- SIMPAN RIWAYAT (DENGAN UPDATE CACHE LOKAL) ---
  Future<void> _saveToHistory(ConversionHistory history) async {
    final prefs = await SharedPreferences.getInstance();
    final int currentUserId = prefs.getInt('userId') ?? 0;
    
    if (currentUserId == 0) return;

    final historyWithUser = ConversionHistory(
      userId: currentUserId,
      fromCurrency: history.fromCurrency,
      toCurrency: history.toCurrency,
      amount: history.amount,
      result: history.result,
      date: history.date,
    );

    // 1. Tambahkan ke UI lokal dulu agar responsif
    _historyList.insert(0, historyWithUser);
    
    // 2. Perbarui cache offline riwayat lokal saat ada transaksi baru
    List<Map<String, dynamic>> rawList = _historyList.map((item) => item.toMap()).toList();
    await prefs.setString('cached_history_$currentUserId', jsonEncode(rawList));
    notifyListeners();

    // 3. Kirim ke Spring Boot secara asinkronus (jika online)
    try {
      await http.post(
        Uri.parse('$_backendUrl/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(historyWithUser.toMap()),
      ).timeout(const Duration(seconds: 3)); // Batasi waktu tunggu 3 detik
    } catch (e) {
      print('Gagal sinkronisasi ke database MySQL (Aplikasi berjalan offline): $e');
    }
  }

  // --- MUAT RIWAYAT (DENGAN CACHE OFFLINE) ---
  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final int currentUserId = prefs.getInt('userId') ?? 0;
    
    if (currentUserId == 0) {
      _historyList = [];
      notifyListeners();
      return;
    }

    try {
      // Mencoba mengambil data dari backend Spring Boot dengan batasan waktu 4 detik
      final response = await http.get(
        Uri.parse('$_backendUrl/user/$currentUserId'),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        _historyList = data.map((item) => ConversionHistory.fromMap(item)).toList();
        _historyList = _historyList.reversed.toList();

        // JIKA BERHASIL: Amankan data terbaru dari server ke dalam cache offline
        await prefs.setString('cached_history_$currentUserId', response.body);
      } else {
        _loadHistoryFromCache(prefs, currentUserId);
      }
    } catch (e) {
      print('Spring Boot Offline, mengambil riwayat dari cache SharedPreferences...');
      // JIKA OFFLINE: Jalankan fungsi penarik data cache
      _loadHistoryFromCache(prefs, currentUserId);
    }
    
    notifyListeners();
  }

  // Fungsi pembantu untuk membaca data cache riwayat
  void _loadHistoryFromCache(SharedPreferences prefs, int userId) {
    String? cachedData = prefs.getString('cached_history_$userId');
    if (cachedData != null) {
      List<dynamic> data = jsonDecode(cachedData);
      
      // Deteksi struktur map lokal vs raw json server
      if (data.isNotEmpty && data.first.containsKey('user')) {
        _historyList = data.map((item) => ConversionHistory.fromMap(item)).toList();
        _historyList = _historyList.reversed.toList();
      } else {
        // Jika dari struktur simpan lokal yang sudah dibalik
        _historyList = data.map((item) => ConversionHistory.fromMap(item)).toList();
      }
    } else {
      _historyList = [];
    }
  }

  // --- DATA GRAFIK (DENGAN CACHE OFFLINE) ---
  Future<void> updateHistoricalData() async {
    if (_baseCurrency == _targetCurrency) {
      _historicalSpots = [];
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String cacheKey = 'cached_chart_${_baseCurrency}_$_targetCurrency';

    try {
      final historicalData = await _apiService.fetchHistoricalRates(_baseCurrency, _targetCurrency);
      
      // Simpan data grafik ke cache
      await prefs.setString(cacheKey, jsonEncode(historicalData));
      _processChartData(historicalData);
      
    } catch (e) {
      print("Gagal mengambil grafik baru, memuat cache grafik: $e");
      
      String? cachedChart = prefs.getString(cacheKey);
      if (cachedChart != null) {
        final historicalData = jsonDecode(cachedChart);
        _processChartData(historicalData);
      } else {
        _historicalSpots = [];
      }
    } finally {
      notifyListeners();
    }
  }

  // Fungsi pembantu memproses titik koordinat grafik
  void _processChartData(dynamic historicalData) {
    List<FlSpot> spots = [];
    int index = 0;
    List<double> allRates = [];

    historicalData.forEach((date, ratesMap) {
      if (ratesMap.containsKey(_targetCurrency)) {
        final rate = (ratesMap[_targetCurrency] as num).toDouble();
        spots.add(FlSpot(index.toDouble(), rate));
        allRates.add(rate);
        index++;
      }
    });

    _historicalSpots = spots;

    if (allRates.isNotEmpty) {
      allRates.sort();
      _minY = allRates.first * 0.999;
      _maxY = allRates.last * 1.001; 
    }
  }

  void resetData() {
    _conversionResult = 0.0;
    _baseCurrency = 'USD';
    _targetCurrency = 'IDR';
    _historyList = [];
    _historicalSpots = [];
    notifyListeners(); 
  }
}