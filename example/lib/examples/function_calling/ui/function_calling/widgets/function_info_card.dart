import 'package:flutter/material.dart';

class FunctionInfoCard extends StatelessWidget {
  const FunctionInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Functions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildFunctionInfo(
              'get_weather',
              'Get weather for a location (+ unit)',
            ),
            _buildFunctionInfo(
              'get_current_time',
              'Get current time for a timezone',
            ),
            _buildFunctionInfo(
              'get_exchange_rate',
              'Get FX rate (e.g., USD/KRW)',
            ),
            _buildFunctionInfo(
              'convert_currency',
              'Convert amount across currencies',
            ),
            _buildFunctionInfo(
              'search_places',
              'Search ranked places by query/city',
            ),
            _buildFunctionInfo(
              'create_reminder',
              'Schedule reminder (non-blocking)',
            ),
            const SizedBox(height: 8),
            const Text(
              'Try: weather/time + FX conversion + cafe search + reminders',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
        children: [
          const Icon(Icons.functions, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: Colors.blue,
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
