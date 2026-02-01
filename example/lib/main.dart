import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'live_api_demo.dart';
import 'function_calling_demo.dart';
import 'realtime_media_demo.dart';

const String geminiApiKey = "";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Gemini Live API',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Live API Examples'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader('Basic Examples'),
          _buildDemoCard(
            context: context,
            title: 'Chat Interface',
            subtitle: 'Basic chat with text, image, and audio input',
            icon: Icons.chat,
            color: Colors.blue,
            page: const ChatPage(),
          ),
          const SizedBox(height: 16),

          _buildHeader('New Features'),
          _buildDemoCard(
            context: context,
            title: 'Live API Features',
            subtitle:
                'Demo of all new features: VAD, transcription, session resumption, etc.',
            icon: Icons.auto_awesome,
            color: Colors.purple,
            page: const LiveAPIDemoPage(),
          ),
          const SizedBox(height: 12),
          _buildDemoCard(
            context: context,
            title: 'Function Calling',
            subtitle: 'Tool calling with weather and time functions',
            icon: Icons.functions,
            color: Colors.green,
            page: const FunctionCallingDemoPage(),
          ),
          const SizedBox(height: 12),
          _buildDemoCard(
            context: context,
            title: 'Realtime Media',
            subtitle: 'Realtime audio/video input with activity detection',
            icon: Icons.videocam,
            color: Colors.orange,
            page: const RealtimeMediaDemoPage(),
          ),
          const SizedBox(height: 24),

          _buildHeader('Setup'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API Key Configuration',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please set your Gemini API key in main.dart:\n'
                    'const String geminiApiKey = "YOUR_API_KEY";',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get your API key from: https://aistudio.google.com/app/apikey',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildHeader('New Features Included'),
          _buildFeatureChip('toolCall / LiveServerToolCall'),
          _buildFeatureChip('toolCallCancellation'),
          _buildFeatureChip('goAway / LiveServerGoAway'),
          _buildFeatureChip('sessionResumptionUpdate'),
          _buildFeatureChip('voiceActivityDetection'),
          _buildFeatureChip('realtimeInputConfig'),
          _buildFeatureChip('audioTranscription'),
          _buildFeatureChip('contextWindowCompression'),
          _buildFeatureChip('proactivityConfig'),
          _buildFeatureChip('mediaChunks'),
          _buildFeatureChip('activityStart/End'),
          _buildFeatureChip('sendClientContent()'),
          _buildFeatureChip('sendToolResponse()'),
          _buildFeatureChip('sendRealtimeInput()'),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDemoCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Chip(
        label: Text(feature, style: const TextStyle(fontSize: 11)),
        backgroundColor: Colors.blue.shade50,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
