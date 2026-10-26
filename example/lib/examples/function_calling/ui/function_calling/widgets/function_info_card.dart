import 'package:flutter/material.dart';

import '../function_calling_i18n.dart';

class FunctionInfoCard extends StatelessWidget {
  const FunctionInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = FunctionCallingI18n.current;
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.availableFunctionsTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildFunctionInfo('get_weather', t.descGetWeather),
            _buildFunctionInfo('get_current_time', t.descGetCurrentTime),
            _buildFunctionInfo('get_exchange_rate', t.descGetExchangeRate),
            _buildFunctionInfo('convert_currency', t.descConvertCurrency),
            _buildFunctionInfo('search_places', t.descSearchPlaces),
            _buildFunctionInfo('create_reminder', t.descCreateReminder),
            const SizedBox(height: 8),
            Text(
              t.tryHint,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionInfo(String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.functions, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
