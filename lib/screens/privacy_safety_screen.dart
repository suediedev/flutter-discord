import 'package:flutter/material.dart';

class PrivacySafetyScreen extends StatefulWidget {
  const PrivacySafetyScreen({super.key});

  @override
  State<PrivacySafetyScreen> createState() => _PrivacySafetyScreenState();
}

class _PrivacySafetyScreenState extends State<PrivacySafetyScreen> {
  bool _dmFromServerMembers = true;
  bool _directMessages = true;
  bool _friendRequests = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF313338),
      appBar: AppBar(
        backgroundColor: const Color(0xFF313338),
        title: const Text('Privacy & Safety'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Safe Direct Messaging'),
          SwitchListTile(
            title: const Text(
              'Keep me safe',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Automatically scan and delete direct messages containing explicit content',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            value: _dmFromServerMembers,
            onChanged: (bool value) {
              setState(() {
                _dmFromServerMembers = value;
              });
            },
          ),
          _buildSectionHeader('Server Privacy Defaults'),
          SwitchListTile(
            title: const Text(
              'Direct messages',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Allow direct messages from server members',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            value: _directMessages,
            onChanged: (bool value) {
              setState(() {
                _directMessages = value;
              });
            },
          ),
          _buildSectionHeader('Who Can Add You As A Friend'),
          SwitchListTile(
            title: const Text(
              'Everyone',
              style: TextStyle(color: Colors.white),
            ),
            value: _friendRequests,
            onChanged: (bool value) {
              setState(() {
                _friendRequests = value;
              });
            },
          ),
          ListTile(
            title: const Text(
              'Data Privacy',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              // Navigate to Data Privacy screen
            },
          ),
          ListTile(
            title: const Text(
              'Advanced',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              // Navigate to Advanced Privacy settings
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
