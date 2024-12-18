import 'package:flutter/material.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  String _theme = 'dark';
  double _messageScale = 1.0;
  bool _animatedEmoji = true;
  bool _animatedStickers = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF313338),
      appBar: AppBar(
        backgroundColor: const Color(0xFF313338),
        title: const Text('Appearance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Theme'),
          RadioListTile<String>(
            title: const Text('Dark', style: TextStyle(color: Colors.white)),
            value: 'dark',
            groupValue: _theme,
            onChanged: (String? value) {
              setState(() {
                _theme = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Light', style: TextStyle(color: Colors.white)),
            value: 'light',
            groupValue: _theme,
            onChanged: (String? value) {
              setState(() {
                _theme = value!;
              });
            },
          ),
          _buildSectionHeader('Message Display'),
          ListTile(
            title: const Text('Message Text Scale',
                style: TextStyle(color: Colors.white)),
            subtitle: Slider(
              value: _messageScale,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: _messageScale.toString(),
              onChanged: (double value) {
                setState(() {
                  _messageScale = value;
                });
              },
            ),
          ),
          _buildSectionHeader('Emoji & Stickers'),
          SwitchListTile(
            title: const Text('Animated Emoji',
                style: TextStyle(color: Colors.white)),
            value: _animatedEmoji,
            onChanged: (bool value) {
              setState(() {
                _animatedEmoji = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Animated Stickers',
                style: TextStyle(color: Colors.white)),
            value: _animatedStickers,
            onChanged: (bool value) {
              setState(() {
                _animatedStickers = value;
              });
            },
          ),
          _buildSectionHeader('Advanced'),
          ListTile(
            title: const Text('Developer Options',
                style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              // Navigate to Developer Options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
