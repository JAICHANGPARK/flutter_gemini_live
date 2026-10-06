import 'package:gemini_live/gemini_live.dart';

/// Result of simulating a function call: the response payload plus an optional
/// scheduling hint for the model.
typedef MockFunctionResult = ({
  Map<String, dynamic> result,
  FunctionResponseScheduling? scheduling,
});

/// Simulates function execution.
/// In production, you would actually call your functions here.
class MockFunctionExecutor {
  const MockFunctionExecutor();

  MockFunctionResult execute(FunctionCall call) {
    Map<String, dynamic> result;
    FunctionResponseScheduling? scheduling;

    switch (call.name) {
      case 'get_weather':
        final location = (call.args?['location'] ?? 'Unknown').toString();
        final requestedUnit = (call.args?['unit'] ?? 'celsius').toString();
        final useFahrenheit = requestedUnit.toLowerCase() == 'fahrenheit';
        final weather = _buildWeather(location, useFahrenheit: useFahrenheit);
        result = weather;
        break;
      case 'get_current_time':
        final timezone = (call.args?['timezone'] ?? 'UTC').toString();
        result = _buildTime(timezone);
        break;
      case 'get_exchange_rate':
        final base = _normalizeCurrency(call.args?['base_currency']);
        final quote = _normalizeCurrency(call.args?['quote_currency']);
        result = _buildExchangeRate(base, quote);
        break;
      case 'convert_currency':
        final amountRaw = call.args?['amount'];
        final amount = amountRaw is num
            ? amountRaw.toDouble()
            : double.tryParse(amountRaw?.toString() ?? '');
        final from = _normalizeCurrency(call.args?['from_currency']);
        final to = _normalizeCurrency(call.args?['to_currency']);
        if (amount == null) {
          result = {'error': 'Invalid amount'};
          break;
        }
        result = _buildCurrencyConversion(amount, from, to);
        break;
      case 'search_places':
        final query = (call.args?['query'] ?? '').toString().trim();
        final city = call.args?['city']?.toString().trim();
        final limitRaw = call.args?['limit'];
        final limit = limitRaw is num
            ? limitRaw.toInt()
            : int.tryParse(limitRaw?.toString() ?? '') ?? 3;
        result = _buildPlaceSearch(query: query, city: city, limit: limit);
        break;
      case 'create_reminder':
        final title = (call.args?['title'] ?? '').toString().trim();
        final datetime = (call.args?['datetime'] ?? '').toString().trim();
        final timezone = (call.args?['timezone'] ?? 'UTC').toString();
        result = {
          'id': 'reminder-${DateTime.now().millisecondsSinceEpoch}',
          'status': 'scheduled',
          'title': title.isEmpty ? 'Untitled reminder' : title,
          'datetime': datetime.isEmpty
              ? DateTime.now().toIso8601String()
              : datetime,
          'timezone': timezone,
        };
        scheduling = FunctionResponseScheduling.WHEN_IDLE;
        break;
      default:
        result = {'error': 'Unknown function: ${call.name}'};
    }

    return (result: result, scheduling: scheduling);
  }

  static const Map<String, double> _currencyPerUsd = {
    'USD': 1.0,
    'KRW': 1320.0,
    'JPY': 150.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'CNY': 7.2,
  };

  String _normalizeCurrency(dynamic raw) {
    final value = raw?.toString().trim().toUpperCase() ?? '';
    return value;
  }

  Map<String, dynamic> _buildExchangeRate(String base, String quote) {
    final baseRate = _currencyPerUsd[base];
    final quoteRate = _currencyPerUsd[quote];
    if (baseRate == null || quoteRate == null) {
      return {
        'error': 'Unsupported currency pair',
        'supported_currencies': _currencyPerUsd.keys.toList(),
      };
    }

    final rate = quoteRate / baseRate;
    return {
      'base_currency': base,
      'quote_currency': quote,
      'rate': double.parse(rate.toStringAsFixed(6)),
      'as_of': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _buildCurrencyConversion(
    double amount,
    String from,
    String to,
  ) {
    final pair = _buildExchangeRate(from, to);
    if (pair['error'] != null) return pair;
    final rate = (pair['rate'] as num).toDouble();
    final converted = amount * rate;
    return {
      'amount': amount,
      'from_currency': from,
      'to_currency': to,
      'rate': rate,
      'converted_amount': double.parse(converted.toStringAsFixed(2)),
      'as_of': pair['as_of'],
    };
  }

  Map<String, dynamic> _buildTime(String timezone) {
    const offsets = {
      'UTC': 0,
      'Asia/Seoul': 9,
      'Asia/Tokyo': 9,
      'Europe/London': 0,
      'America/New_York': -5,
      'America/Los_Angeles': -8,
    };

    final offset = offsets[timezone] ?? 0;
    final nowUtc = DateTime.now().toUtc();
    final local = nowUtc.add(Duration(hours: offset));
    return {
      'timezone': timezone,
      'datetime': local.toIso8601String(),
      'utc_offset_hours': offset,
      'weekday': local.weekday,
    };
  }

  Map<String, dynamic> _buildWeather(
    String location, {
    required bool useFahrenheit,
  }) {
    final hash = location.codeUnits.fold<int>(0, (a, b) => a + b);
    const conditions = ['sunny', 'cloudy', 'rainy', 'windy', 'foggy'];
    final baseTempC = 14 + (hash % 16);
    final humidity = 35 + (hash % 50);
    final windKph = 2 + (hash % 20);
    final temp = useFahrenheit
        ? (baseTempC * 9 / 5) + 32
        : baseTempC.toDouble();

    return {
      'location': location,
      'temperature': double.parse(temp.toStringAsFixed(1)),
      'unit': useFahrenheit ? 'fahrenheit' : 'celsius',
      'condition': conditions[hash % conditions.length],
      'humidity': humidity,
      'wind_kph': windKph,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _buildPlaceSearch({
    required String query,
    String? city,
    required int limit,
  }) {
    if (query.isEmpty) {
      return {'error': 'query is required'};
    }
    final safeLimit = limit.clamp(1, 5);
    final location = (city == null || city.isEmpty) ? 'Unknown city' : city;
    final results = List.generate(safeLimit, (i) {
      final rank = i + 1;
      return {
        'name': '$query Spot $rank',
        'city': location,
        'rating': double.parse((4.8 - (i * 0.2)).toStringAsFixed(1)),
        'open_now': i.isEven,
      };
    });

    return {
      'query': query,
      'city': city,
      'count': results.length,
      'results': results,
    };
  }
}
