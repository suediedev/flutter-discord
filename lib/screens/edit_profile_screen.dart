import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/supabase_service.dart';
import '../widgets/server_icon.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _pronounsController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  Color _bannerColor = const Color(0xFFB7FF00);
  bool _isSaving = false;
  bool _showServerSelector = false;
  String? _selectedServerId;
  List<Map<String, dynamic>> _servers = [];
  Map<String, dynamic>? _serverProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadUserData();
    _loadServers();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _pronounsController.dispose();
    _aboutMeController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index == 1 && _selectedServerId == null) {
      setState(() => _showServerSelector = true);
    }
  }

  Future<void> _loadServers() async {
    try {
      final servers = await ref.read(supabaseServiceProvider).getUserServers();
      setState(() => _servers = servers);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading servers: $e')),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      if (_tabController.index == 0) {
        final profile = await ref.read(supabaseServiceProvider).getUserProfile();
        if (profile != null) {
          setState(() {
            _displayNameController.text = profile['display_name'] ?? '';
            _pronounsController.text = profile['pronouns'] ?? '';
            _aboutMeController.text = profile['about_me'] ?? '';
            if (profile['banner_color'] != null) {
              _bannerColor = Color(int.parse(profile['banner_color'], radix: 16));
            }
          });
        } else {
          final user = ref.read(supabaseServiceProvider).currentUser;
          if (user?.email != null) {
            _displayNameController.text = user!.email!.split('@')[0];
          }
        }
      } else if (_selectedServerId != null) {
        // Clear previous data
        setState(() {
          _displayNameController.text = '';
          _pronounsController.text = '';
        });

        final profile = await ref.read(supabaseServiceProvider).getServerProfile(_selectedServerId!);
        if (profile != null) {
          setState(() {
            _serverProfile = profile;
            _displayNameController.text = profile['nickname'] ?? '';
            _pronounsController.text = profile['pronouns'] ?? '';
          });
        } else {
          // Set default nickname from user profile
          final userProfile = await ref.read(supabaseServiceProvider).getUserProfile();
          if (userProfile != null) {
            setState(() {
              _displayNameController.text = userProfile['display_name'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  void _selectServer(String serverId) {
    setState(() {
      _selectedServerId = serverId;
      _showServerSelector = false;
    });
    _loadUserData();
  }

  Future<void> _saveProfile() async {
    if (_displayNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_tabController.index == 0) {
        await ref.read(supabaseServiceProvider).updateUserProfile(
          displayName: _displayNameController.text,
          pronouns: _pronounsController.text,
          aboutMe: _aboutMeController.text,
          bannerColor: _bannerColor.value.toRadixString(16).padLeft(8, '0'),
        );
      } else if (_selectedServerId != null) {
        await ref.read(supabaseServiceProvider).updateServerProfile(
          serverId: _selectedServerId!,
          nickname: _displayNameController.text,
          pronouns: _pronounsController.text,
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF313338),
      appBar: AppBar(
        backgroundColor: const Color(0xFF313338),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.blue),
                  ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'User Profile'),
            Tab(text: 'Server Profiles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserProfile(),
          _showServerSelector ? _buildServerSelector() : _buildServerProfile(),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DISPLAY NAME',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _displayNameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFF1E1F22),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'PRONOUNS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pronounsController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E1F22),
              border: const OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              suffixIcon: _pronounsController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () {
                        setState(() => _pronounsController.clear());
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'If left blank, your default pronouns will be used.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ABOUT ME',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _aboutMeController,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFF1E1F22),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROFILE BANNER',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _showColorPicker,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _bannerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showColorPicker,
                      child: Text(
                        '#${_bannerColor.value.toRadixString(16).toUpperCase().substring(2)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white70),
                      onPressed: _showColorPicker,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined, color: Colors.white70),
                    const SizedBox(width: 8),
                    const Text(
                      'Add Banner',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Requires Nitro',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement Nitro subscription
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF248046),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Get Nitro'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerSelector() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFF1E1F22),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              prefixIcon: Icon(Icons.search, color: Colors.white70),
              hintText: 'Search',
              hintStyle: TextStyle(color: Colors.white70),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _servers.length,
            itemBuilder: (context, index) {
              final server = _servers[index]['servers'];
              return ListTile(
                leading: ServerIcon(
                  iconUrl: server['icon_url'],
                  serverName: server['name'],
                  size: 40,
                ),
                title: Text(
                  server['name'],
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: server['id'] == _selectedServerId
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () => _selectServer(server['id']),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServerProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SERVER NICKNAME',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _displayNameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFF1E1F22),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'PRONOUNS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pronounsController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E1F22),
              border: const OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              suffixIcon: _pronounsController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () {
                        setState(() => _pronounsController.clear());
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'If left blank, your default pronouns will be used.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.purple.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Customize your profile for every server!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement Nitro subscription
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF248046),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Get Nitro'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _bannerColor,
              onColorChanged: (Color color) {
                setState(() => _bannerColor = color);
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
