import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../models/member.dart';
import 'package:discord_native/screens/nitro_screen.dart';
import 'package:discord_native/screens/account_screen.dart';
import 'package:discord_native/screens/privacy_safety_screen.dart';
import 'package:discord_native/screens/appearance_screen.dart';
import 'package:discord_native/screens/voice_video_screen.dart';
import 'package:discord_native/screens/language_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF313338),
      appBar: AppBar(
        backgroundColor: const Color(0xFF313338),
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search settings',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: const Color(0xFF1E1F22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

          // Account Settings section
          _buildSectionHeader('Account Settings'),
          _buildSettingItem(
            context,
            'Account',
            Icons.person_outline,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AccountScreen()),
            ),
          ),
          _buildSettingItem(
            context,
            'Get Nitro',
            Icons.star_outline,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NitroScreen()),
            ),
          ),
          _buildSettingItem(
            context,
            'Privacy & Safety',
            Icons.shield,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacySafetyScreen()),
            ),
          ),
          _buildSettingItem(
            context,
            'Family Center',
            Icons.family_restroom,
            () {},
          ),
          _buildSettingItem(
            context,
            'Authorized Apps',
            Icons.key,
            () {},
          ),
          _buildSettingItem(
            context,
            'Devices',
            Icons.devices,
            () {},
          ),
          _buildSettingItem(
            context,
            'Connections',
            Icons.link,
            () {},
          ),
          _buildSettingItem(
            context,
            'Clips',
            Icons.video_library,
            () {},
          ),
          _buildSettingItem(
            context,
            'Friend Requests',
            Icons.person_add,
            () {},
          ),
          _buildSettingItem(
            context,
            'Scan QR Code',
            Icons.qr_code,
            () {},
          ),

          // Billing Settings section
          _buildSectionHeader('Billing Settings'),
          _buildSettingItem(
            context,
            'Nitro',
            Icons.diamond,
            () {},
          ),
          _buildSettingItem(
            context,
            'Server Boost',
            Icons.card_giftcard,
            () {},
          ),
          _buildSettingItem(
            context,
            'Subscriptions',
            Icons.payments,
            () {},
          ),
          _buildSettingItem(
            context,
            'Gift Inventory',
            Icons.inventory,
            () {},
          ),

          // App Settings section
          _buildSectionHeader('App Settings'),
          _buildSettingItem(
            context,
            'Appearance',
            Icons.brush,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AppearanceScreen()),
            ),
          ),
          _buildSettingItem(
            context,
            'Accessibility',
            Icons.accessibility,
            () {},
          ),
          _buildSettingItem(
            context,
            'Voice & Video',
            Icons.voice_chat,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VoiceVideoScreen()),
            ),
          ),
          _buildSettingItem(
            context,
            'Text & Images',
            Icons.text_fields,
            () {},
          ),
          _buildSettingItem(
            context,
            'Notifications',
            Icons.notifications,
            () {},
          ),
          _buildSettingItem(
            context,
            'Keybinds',
            Icons.keyboard,
            () {},
          ),
          _buildSettingItem(
            context,
            'Language',
            Icons.language,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LanguageScreen()),
            ),
          ),
          _buildSettingItem(
            context,
            'Windows Settings',
            Icons.window,
            () {},
          ),
          _buildSettingItem(
            context,
            'Activity Settings',
            Icons.games,
            () {},
          ),

          // Log Out button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                await ref.read(supabaseServiceProvider).signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Log Out'),
            ),
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

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      onTap: onTap,
    );
  }
}
