import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Alamat API gratis untuk ambil kurs mata uang terbaru
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest/';

  Future<Map<String, dynamic>> fetchRates(String baseCurrency) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$baseCurrency'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['rates']; 
      } else {
        throw Exception('Gagal memuat data mata uang dari server');
      }
    } catch (e) {
      throw Exception('Error jaringan, pastikan internet aktif: $e');
    }
  }

  Future<Map<String, dynamic>> fetchHistoricalRates(String base, String target) async {
    final today = DateTime.now();
    final pastDate = today.subtract(const Duration(days: 8)); 
    
    final formatDate = (DateTime date) => "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    final startRoute = formatDate(pastDate);
    final endRoute = formatDate(today);

    final url = Uri.parse('https://api.frankfurter.dev/v1/$startRoute..$endRoute?base=$base&symbols=$target');
    
    print("Mencetak URL Tren API: $url"); // Cek URL di Run/Debug Console

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Memastikan data rates benar-benar ada di dalam respons
        if (data['rates'] != null) {
          return data['rates'] as Map<String, dynamic>;
        }
        return {};
      } else {
        print("API Error Status: ${response.statusCode}");
        throw Exception('Gagal memuat data tren historis');
      }
    } catch (e) {
      print("Error fetching trend: $e");
      throw Exception('Gagal mengambil data tren: $e');
    }
  }
}