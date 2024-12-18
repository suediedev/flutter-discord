import 'package:flutter/material.dart';

class VoiceVideoScreen extends StatefulWidget {
  const VoiceVideoScreen({super.key});

  @override
  State<VoiceVideoScreen> createState() => _VoiceVideoScreenState();
}

class _VoiceVideoScreenState extends State<VoiceVideoScreen> {
  double _inputVolume = 0.8;
  double _outputVolume = 0.8;
  String _inputDevice = 'Default';
  String _outputDevice = 'Default';
  bool _noiseReduction = true;
  bool _echoCancellation = true;
  bool _automaticGainControl = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF313338),
      appBar: AppBar(
        backgroundColor: const Color(0xFF313338),
        title: const Text('Voice & Video'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Input Device'),
          ListTile(
            title: const Text('Input Device',
                style: TextStyle(color: Colors.white)),
            subtitle: DropdownButton<String>(
              value: _inputDevice,
              dropdownColor: const Color(0xFF1E1F22),
              style: const TextStyle(color: Colors.white),
              onChanged: (String? newValue) {
                setState(() {
                  _inputDevice = newValue!;
                });
              },
              items: <String>['Default', 'Microphone 1', 'Microphone 2']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: const Text('Input Volume',
                style: TextStyle(color: Colors.white)),
            subtitle: Slider(
              value: _inputVolume,
              min: 0,
              max: 1,
              divisions: 20,
              label: (_inputVolume * 100).round().toString() + '%',
              onChanged: (double value) {
                setState(() {
                  _inputVolume = value;
                });
              },
            ),
          ),
          _buildSectionHeader('Output Device'),
          ListTile(
            title: const Text('Output Device',
                style: TextStyle(color: Colors.white)),
            subtitle: DropdownButton<String>(
              value: _outputDevice,
              dropdownColor: const Color(0xFF1E1F22),
              style: const TextStyle(color: Colors.white),
              onChanged: (String? newValue) {
                setState(() {
                  _outputDevice = newValue!;
                });
              },
              items: <String>['Default', 'Speakers', 'Headphones']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: const Text('Output Volume',
                style: TextStyle(color: Colors.white)),
            subtitle: Slider(
              value: _outputVolume,
              min: 0,
              max: 1,
              divisions: 20,
              label: (_outputVolume * 100).round().toString() + '%',
              onChanged: (double value) {
                setState(() {
                  _outputVolume = value;
                });
              },
            ),
          ),
          _buildSectionHeader('Voice Processing'),
          SwitchListTile(
            title: const Text('Noise Reduction',
                style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'Reduces background noise in your microphone',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            value: _noiseReduction,
            onChanged: (bool value) {
              setState(() {
                _noiseReduction = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Echo Cancellation',
                style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'Prevents echo from speakers',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            value: _echoCancellation,
            onChanged: (bool value) {
              setState(() {
                _echoCancellation = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Automatic Gain Control',
                style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'Automatically adjusts microphone volume',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            value: _automaticGainControl,
            onChanged: (bool value) {
              setState(() {
                _automaticGainControl = value;
              });
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
