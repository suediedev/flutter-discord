import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/platform_theme.dart';
import 'screens/auth_wrapper.dart';
import 'widgets/server_list.dart';
import 'widgets/channel_list.dart';
import 'widgets/chat_view.dart';

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

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

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
          
          if (isMobile) {
            return const MobileLayout();
          }
          
          return const Row(
            children: [
              ServerList(),
              ChannelList(),
              Expanded(
                child: ChatView(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MobileLayout extends StatelessWidget {
  const MobileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(
          child: ChatView(),
        ),
        SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: ServerList(isBottomBar: true)),
                Expanded(child: ChannelList(isBottomBar: true)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
