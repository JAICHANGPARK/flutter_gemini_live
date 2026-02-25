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
                    'You are a helpful assistant with access to weather and time functions. '
                    'Use the get_weather function when asked about weather. '
                    'Use the get_current_time function when asked about time.',
              ),
            ],
          ),
          tools: [
            Tool(
              functionDeclarations: [
                FunctionDeclaration(
                  name: 'get_weather',
                  description: 'Get weather by location',
                  parameters: {
                    'type': 'OBJECT',
                    'properties': {
                      'location': {'type': 'STRING'},
                    },
                    'required': ['location'],
                  },
                ),
                FunctionDeclaration(
                  name: 'get_current_time',
                  description: 'Get current time for a timezone',
                  parameters: {
                    'type': 'OBJECT',
                    'properties': {
                      'timezone': {'type': 'STRING'},
                    },
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

    switch (call.name) {
      case 'get_weather':
        result = {
          'location': call.args?['location'] ?? 'Unknown',
          'temperature': 22,
          'unit': 'celsius',
          'condition': 'sunny',
          'humidity': 65,
        };
        break;
      case 'get_current_time':
        result = {
          'timezone': call.args?['timezone'] ?? 'UTC',
          'datetime': DateTime.now().toIso8601String(),
        };
        break;
      default:
        result = {'error': 'Unknown function: ${call.name}'};
    }

    _addSystemMessage('📤 Sending response: $result');

    // Send function response
    if (_session != null && call.id != null && call.name != null) {
      _session!.sendFunctionResponse(
        id: call.id!,
        name: call.name!,
        response: result,
      );
    }

    setState(() => _pendingFunctionCalls.removeWhere((c) => c.id == call.id));
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
                    'Get weather for a location',
                  ),
                  _buildFunctionInfo(
                    'get_current_time',
                    'Get current time for a timezone',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try asking: "What\'s the weather in Tokyo?" or "What time is it in London?"',
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
    final controller = TextEditingController();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Ask about weather or time...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  _sendText(text);
                  controller.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _sendText(controller.text);
                controller.clear();
              }
            },
            icon: const Icon(Icons.send),
            color: Colors.blue,
          ),
        ],
      ),
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
