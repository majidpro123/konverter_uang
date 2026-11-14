import 'package:flutter/material.dart';
import '../models/history_model.dart';

class HistoryCard extends StatelessWidget {
  final ConversionHistory item;

  const HistoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.compare_arrows, color: Colors.white),
        ),
        title: Text(
          '${item.amount} ${item.fromCurrency} = ${item.result.toStringAsFixed(2)} ${item.toCurrency}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Tanggal: ${item.date}'),
      ),
    );
  }
}