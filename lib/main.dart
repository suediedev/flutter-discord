import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/platform_theme.dart';
import 'screens/auth_wrapper.dart';
import 'widgets/server_list.dart';
import 'widgets/channel_list.dart';
import 'widgets/chat_view.dart';
import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sbowbcufssefxablcjej.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNib3diY3Vmc3NlZnhhYmxjamVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ0NjY4NTgsImV4cCI6MjA1MDA0Mjg1OH0.WWWoF_CvlKaHQgnnxjAxhYuV42FHkxnwO3DbTWXCGNY',
  );
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discord Native',
      theme: PlatformTheme.getMaterialTheme(true),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeRealtime();
  }

  Future<void> _initializeRealtime() async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentSession != null) {
      await ref.read(supabaseServiceProvider).initializeRealtime();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session == null) {
      return const AuthWrapper();
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = PlatformTheme.isMobile(context);
          
          return Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                // Home/Chat view with server list
                Row(
                  children: [
                    // Server list
                    Container(
                      width: 72,
                      color: const Color(0xFF1E1F22),
                      child: const ServerList(),
                    ),
                    // Main content area
                    Expanded(
                      child: Row(
                        children: [
                          // Channel list
                          Container(
                            width: 240,
                            color: const Color(0xFF2B2D31),
                            child: Column(
                              children: [
                                Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2B2D31),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.black.withOpacity(0.2),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Channels',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Expanded(
                                  child: ChannelList(),
                                ),
                              ],
                            ),
                          ),
                          // Chat area
                          Expanded(
                            child: Container(
                              color: const Color(0xFF313338),
                              child: Column(
                                children: [
                                  // Channel header
                                  Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF313338),
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.black.withOpacity(0.2),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.tag, color: Colors.white70),
                                        const SizedBox(width: 8),
                                        Text(
                                          'general',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Chat messages
                                  const Expanded(
                                    child: ChatView(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Notifications view (full width)
                Container(
                  color: const Color(0xFF313338),
                  child: const NotificationsScreen(),
                ),
                // Profile view (full width)
                Container(
                  color: const Color(0xFF313338),
                  child: const ProfileScreen(),
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              backgroundColor: const Color(0xFF2B2D31),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications),
                  label: 'Notifications',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person),
                  label: 'You',
                ),
              ],
            ),
            appBar: AppBar(
              title: const Text('Discord Native'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1; // Switch to notifications tab
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MobileLayout extends StatefulWidget {
  const MobileLayout({super.key});

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home/Chat view
          Scaffold(
            appBar: AppBar(
              title: const Text('Discord Native'),
            ),
            body: const Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        flex: 1,
                        child: ServerList(),
                      ),
                      VerticalDivider(width: 1),
                      Flexible(
                        flex: 2,
                        child: ChannelList(),
                      ),
                      VerticalDivider(width: 1),
                      Expanded(
                        flex: 5,
                        child: ChatView(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Notifications view
          const NotificationsScreen(),
          // Profile view
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'You',
          ),
        ],
      ),
    );
  }
}
