class ConversionHistory {
  final int userId;
  final String fromCurrency;
  final String toCurrency;
  final double amount;
  final double result;
  final String date;

  ConversionHistory({
    required this.userId,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    required this.result,
    required this.date,
  });

  // Saat Flutter MENGIRIM data ke Java
  Map<String, dynamic> toMap() {
    return {
      'user': {'id': userId}, // <-- Format objek bersarang khusus untuk relasi @ManyToOne Java
      'baseCurrency': fromCurrency, // Disesuaikan dengan Java
      'targetCurrency': toCurrency, // Disesuaikan dengan Java
      'amount': amount,
      'result': result,
      'conversionDate': date, // Disesuaikan dengan Java
    };
  }

  // Saat Flutter MENERIMA data dari Java
  factory ConversionHistory.fromMap(Map<String, dynamic> map) {
    return ConversionHistory(
      // Mengambil ID dari dalam objek user yang dikirim Spring Boot
      userId: map['user'] != null ? map['user']['id'] : 0, 
      fromCurrency: map['baseCurrency'] ?? '',
      toCurrency: map['targetCurrency'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      result: (map['result'] ?? 0).toDouble(),
      date: map['conversionDate'] ?? '',
    );
  }
}