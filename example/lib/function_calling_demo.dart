import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';
import 'api_key_store.dart';

/// Demo page for function calling (tool calling) feature
class FunctionCallingDemoPage extends StatefulWidget {
  const FunctionCallingDemoPage({super.key});

  @override
  State<FunctionCallingDemoPage> createState() =>
      _FunctionCallingDemoPageState();
}

class _FunctionCallingDemoPageState extends State<FunctionCallingDemoPage> {
  late final GoogleGenAI _genAI;
  LiveSession? _session;
  final TextEditingController _inputController = TextEditingController();

  bool _isConnected = false;
  bool _isConnecting = false;

  final List<ChatMessage> _messages = [];
  final List<FunctionCall> _pendingFunctionCalls = [];

  @override
  void initState() {
    super.initState();
    _genAI = GoogleGenAI(apiKey: ApiKeyStore.apiKey);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _session?.close();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_isConnecting) return;
    if (!ApiKeyStore.hasApiKey) {
      _addSystemMessage('❌ API key is not configured. Open Settings first.');
      return;
    }

    setState(() => _isConnecting = true);
    _addSystemMessage('Connecting with function calling enabled...');

    try {
      final session = await _genAI.live.connect(
        LiveConnectParameters(
          model: 'gemini-live-2.5-flash-preview',
          config: GenerationConfig(
            temperature: 0.7,
            responseModalities: [Modality.TEXT],
          ),
          systemInstruction: Content(
            parts: [
              Part(
                text:
                    'You are a helpful assistant with tool access. '
                    'Prefer tool calls for weather, time, exchange rate, currency conversion, place search, and reminders. '
                    'If a user asks for multiple actions, call tools as needed and then summarize clearly.',
              ),
            ],
          ),
          tools: [
            Tool(
              functionDeclarations: [
                FunctionDeclaration(
                  name: 'get_weather',
                  description:
                      'Get weather by location with optional unit (celsius/fahrenheit).',
                  parameters: {
                    'type': 'OBJECT',
                    'properties': {
                      'location': {'type': 'STRING'},
                      'unit': {
                        'type': 'STRING',
                        'enum': ['celsius', 'fahrenheit'],
                      },
                    },
                    'required': ['location'],
                  },
                ),
                FunctionDeclaration(
                  name: 'get_current_time',
                  description: 'Get current time for a timezone.',
                  parameters: {
                    'type': 'OBJECT',
                    'properties': {
                      'timezone': {'type': 'STRING'},
                    },
                  },
                ),
                FunctionDeclaration(
                  name: 'get_exchange_rate',
                  description: 'Get FX rate for a currency pair.',
                  parameters: {
                    'type': 'OBJECT',
                    'properties': {
                      'base_currency': {'type': 'STRING'},
                      'quote_currency': {'type': 'STRING'},
                    },
                    'required': ['base_currency', 'quote_currency'],
                  },
                ),
                FunctionDeclaration(
                  name: 'convert_currency',
                  description: 'Convert money from one currency to another.',
                  parameters: {
                    'type': 'OBJECT',
                    'properties': {
                      'amount': {'type': 'NUMBER'},
                      'from_currency': {'type': 'STRING'},
                      'to_currency': {'type': 'STRING'},
                    },
                    'required': ['amount', 'from_currency', 'to_currency'],
                  },
                ),
                FunctionDeclaration(
                  name: 'search_places',
                  description:
                      'Search places by query and optional city. Returns ranked results.',
                  parameters: {
                    'type': 'OBJECT',
                    'properties': {
                      'query': {'type': 'STRING'},
                      'city': {'type': 'STRING'},
                      'limit': {'type': 'INTEGER'},
                    },
                    'required': ['query'],
                  },
                ),
                FunctionDeclaration(
                  name: 'create_reminder',
                  description:
                      'Create a reminder with title, datetime and timezone.',
                  behavior: Behavior.NON_BLOCKING,
                  parameters: {
                    'type': 'OBJECT',
                    'properties': {
                      'title': {'type': 'STRING'},
                      'datetime': {'type': 'STRING'},
                      'timezone': {'type': 'STRING'},
                    },
                    'required': ['title', 'datetime'],
                  },
                ),
              ],
            ),
          ],
          callbacks: LiveCallbacks(
            onOpen: () {
              _addSystemMessage('✅ Connected with function calling');
              setState(() {
                _isConnected = true;
                _isConnecting = false;
              });
            },
            onMessage: _handleMessage,
            onError: (error, stack) {
              _addSystemMessage('❌ Error: $error');
              setState(() => _isConnecting = false);
            },
            onClose: (code, reason) {
              _addSystemMessage('🔒 Connection closed');
              setState(() {
                _isConnected = false;
                _isConnecting = false;
              });
            },
          ),
        ),
      );

      setState(() => _session = session);
    } catch (e) {
      _addSystemMessage('❌ Connection failed: $e');
      setState(() => _isConnecting = false);
    }
  }

  void _handleMessage(LiveServerMessage message) {
    // Handle text response
    if (message.text != null) {
      _addMessage('model', message.text!);
    }

    // Handle tool calls
    if (message.toolCall != null) {
      final calls = message.toolCall!.functionCalls ?? [];
      for (final call in calls) {
        _handleFunctionCall(call);
      }
    }

    // Handle tool call cancellation
    if (message.toolCallCancellation != null) {
      final ids = message.toolCallCancellation!.ids ?? [];
      _addSystemMessage('❌ Tool calls cancelled: ${ids.join(", ")}');
      setState(() {
        _pendingFunctionCalls.removeWhere((call) => ids.contains(call.id));
      });
    }
  }

  void _handleFunctionCall(FunctionCall call) {
    _addSystemMessage('🔧 Function call: ${call.name} (id: ${call.id})');
    _addSystemMessage('   Args: ${call.args}');

    setState(() => _pendingFunctionCalls.add(call));

    // Simulate function execution
    // In production, you would actually call your functions here
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

    _addSystemMessage('📤 Sending response: $result');

    // Send function response
    if (_session != null && call.id != null && call.name != null) {
      _session!.sendToolResponse(
        functionResponses: [
          FunctionResponse(
            id: call.id!,
            name: call.name!,
            response: result,
            scheduling: scheduling,
          ),
        ],
      );
    }

    setState(() => _pendingFunctionCalls.removeWhere((c) => c.id == call.id));
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

  void _addMessage(String author, String text) {
    setState(() {
      _messages.add(
        ChatMessage(author: author, text: text, timestamp: DateTime.now()),
      );
    });
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(
        ChatMessage(
          author: 'system',
          text: text,
          timestamp: DateTime.now(),
          isSystem: true,
        ),
      );
    });
  }

  void _sendText(String text) {
    if (_session == null || !_isConnected) {
      _addSystemMessage('❌ Not connected');
      return;
    }

    _addMessage('user', text);
    _session!.sendText(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Function Calling Demo'),
        actions: [
          if (_pendingFunctionCalls.isNotEmpty)
            Badge(
              label: Text('${_pendingFunctionCalls.length}'),
              child: const Icon(Icons.pending_actions),
            ),
        ],
      ),
      body: Column(
        children: [
          // Info card
          Card(
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
          ),

          // Connection button
          if (!_isConnected)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _isConnecting ? null : _connect,
                icon: _isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.connect_without_contact),
                label: Text(_isConnecting ? 'Connecting...' : 'Connect'),
              ),
            ),

          // Message list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Input area
          if (_isConnected) _buildInputArea(),
        ],
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

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            msg.text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
      );
    }

    final isUser = msg.author == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Text(msg.text),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickPrompt('Weather in Seoul in celsius'),
                const SizedBox(width: 6),
                _buildQuickPrompt('Convert 120 USD to KRW'),
                const SizedBox(width: 6),
                _buildQuickPrompt('Find 3 ramen places in Tokyo'),
                const SizedBox(width: 6),
                _buildQuickPrompt(
                  'Remind me tomorrow 9am Asia/Seoul to submit weekly report',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: const InputDecoration(
                    hintText:
                        'Ask weather/time/fx conversion/place search/reminder...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _submitInput(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _submitInput,
                icon: const Icon(Icons.send),
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitInput() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _sendText(text);
    _inputController.clear();
  }

  Widget _buildQuickPrompt(String prompt) {
    return ActionChip(
      label: Text(prompt, style: const TextStyle(fontSize: 12)),
      onPressed: () => _sendText(prompt),
    );
  }
}

class ChatMessage {
  final String author;
  final String text;
  final DateTime timestamp;
  final bool isSystem;

  ChatMessage({
    required this.author,
    required this.text,
    required this.timestamp,
    this.isSystem = false,
  });
}
