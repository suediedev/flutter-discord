import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/server.dart';
import '../models/channel.dart';
import '../models/member.dart';
import '../models/message.dart';
import '../models/invite.dart';

final supabaseServiceProvider = Provider((ref) => SupabaseService());

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, Timer> _pollingTimers = {};
  final Map<String, StreamController> _streamControllers = {};

  void dispose() {
    for (final timer in _pollingTimers.values) {
      timer.cancel();
    }
    _pollingTimers.clear();
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }

  // Initialize realtime subscriptions
  Future<void> initializeRealtime() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        debugPrint('No session available for realtime connection');
        return;
      }

      // Create a new RealtimeChannel
      final channel = _supabase.channel('public:messages');
      
      // Subscribe to the channel
      channel
        .on(RealtimeListenTypes.postgresChanges,
          ChannelFilter(event: '*', schema: 'public', table: 'messages'),
          (payload, [ref]) {
            debugPrint('Message change received: $payload');
          })
        .subscribe();

      debugPrint('Realtime channel initialized');
    } catch (e) {
      debugPrint('Error initializing realtime: $e');
    }
  }

  // Servers
  Stream<List<Server>> getServersStream() {
    final controller = StreamController<List<Server>>();
    _streamControllers['servers'] = controller;
    
    // Initial fetch
    fetchAndAddServers(controller);
    
    // Set up polling
    final timer = Timer.periodic(const Duration(seconds: 2), (_) {
      fetchAndAddServers(controller);
    });
    
    _pollingTimers['servers'] = timer;
    
    // Clean up
    controller.onCancel = () {
      timer.cancel();
      _pollingTimers.remove('servers');
      _streamControllers.remove('servers');
      controller.close();
    };
    
    return controller.stream;
  }
  
  Future<void> fetchAndAddServers(StreamController<List<Server>> controller) async {
    if (controller.isClosed) return;
    
    try {
      final servers = await getServers();
      if (!controller.isClosed) {
        controller.add(servers);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  Future<List<Server>> getServers() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      final response = await _supabase
          .from('servers')
          .select<List<Map<String, dynamic>>>('*, server_members!inner(*)')
          .eq('server_members.user_id', user.id)
          .order('name');

      return response.map((json) => Server.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching servers: $e');
      rethrow;
    }
  }

  Future<Server> createServer(String name, {String? iconUrl}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      final response = await _supabase
          .rpc('create_server_with_defaults', params: {
            'server_name': name,
            'server_icon_url': iconUrl,
            'owner_id': user.id,
          });

      final serverResponse = await _supabase
          .from('servers')
          .select<Map<String, dynamic>>()
          .eq('id', response)
          .single();

      // Trigger immediate update for servers
      final controller = _streamControllers['servers'] as StreamController<List<Server>>?;
      if (controller != null && !controller.isClosed) {
        fetchAndAddServers(controller);
      }

      return Server.fromJson(serverResponse);
    } catch (e) {
      debugPrint('Error creating server: $e');
      rethrow;
    }
  }

  Future<void> deleteServer(String serverId) async {
    try {
      await _supabase
          .from('servers')
          .delete()
          .eq('id', serverId);

      // Trigger immediate update for servers
      final controller = _streamControllers['servers'] as StreamController<List<Server>>?;
      if (controller != null && !controller.isClosed) {
        fetchAndAddServers(controller);
      }
    } catch (e) {
      debugPrint('Error deleting server: $e');
      rethrow;
    }
  }

  // Channels
  Stream<List<Channel>> getChannelsStream(String serverId) {
    final streamKey = 'channels_$serverId';
    final controller = StreamController<List<Channel>>();
    _streamControllers[streamKey] = controller;
    
    // Initial fetch
    fetchAndAddChannels(serverId, controller);
    
    // Set up polling
    final timer = Timer.periodic(const Duration(seconds: 2), (_) {
      fetchAndAddChannels(serverId, controller);
    });
    
    _pollingTimers[streamKey] = timer;
    
    // Clean up
    controller.onCancel = () {
      timer.cancel();
      _pollingTimers.remove(streamKey);
      _streamControllers.remove(streamKey);
      controller.close();
    };
    
    return controller.stream;
  }
  
  Future<void> fetchAndAddChannels(String serverId, StreamController<List<Channel>> controller) async {
    if (controller.isClosed) return;
    
    try {
      final channels = await getChannels(serverId);
      if (!controller.isClosed) {
        controller.add(channels);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  Future<List<Channel>> getChannels(String serverId) async {
    try {
      final response = await _supabase
          .from('channels')
          .select<List<Map<String, dynamic>>>()
          .eq('server_id', serverId)
          .order('position');
      
      return response.map((json) => Channel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching channels: $e');
      rethrow;
    }
  }

  Future<Channel> createChannel(String serverId, String name) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      final response = await _supabase
          .from('channels')
          .insert({
            'server_id': serverId,
            'name': name,
            'created_by': user.id,
          })
          .select<Map<String, dynamic>>()
          .single();

      // Trigger immediate update for channels
      final streamKey = 'channels_$serverId';
      final controller = _streamControllers[streamKey] as StreamController<List<Channel>>?;
      if (controller != null && !controller.isClosed) {
        fetchAndAddChannels(serverId, controller);
      }

      return Channel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating channel: $e');
      rethrow;
    }
  }

  Future<void> deleteChannel(String serverId, String channelId) async {
    try {
      await _supabase
          .from('channels')
          .delete()
          .eq('id', channelId);

      // Trigger immediate update for channels
      final streamKey = 'channels_$serverId';
      final controller = _streamControllers[streamKey] as StreamController<List<Channel>>?;
      if (controller != null && !controller.isClosed) {
        fetchAndAddChannels(serverId, controller);
      }
    } catch (e) {
      debugPrint('Error deleting channel: $e');
      rethrow;
    }
  }

  // Members
  Stream<List<Member>> getServerMembers(String serverId) {
    return _supabase
        .from('server_members')
        .stream(primaryKey: ['id'])
        .eq('server_id', serverId)
        .map((rows) => rows.map((row) => Member.fromJson(row)).toList());
  }

  Future<void> joinServer(String serverId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('server_members').insert({
      'server_id': serverId,
      'user_id': userId,
      'role': 'member',
    });
  }

  // Update member status
  Future<void> updateMemberStatus(String memberId, MemberStatus status) async {
    await _supabase.from('server_members').update({
      'status': status.toString().split('.').last,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', memberId);
  }

  // Messages
  Stream<List<Message>> getMessagesStream(String channelId) {
    final streamKey = 'messages_$channelId';
    final controller = StreamController<List<Message>>();
    _streamControllers[streamKey] = controller;
    
    // Initial fetch
    fetchAndAddMessages(channelId, controller);
    
    // Set up polling
    final timer = Timer.periodic(const Duration(seconds: 1), (_) {
      fetchAndAddMessages(channelId, controller);
    });
    
    _pollingTimers[streamKey] = timer;
    
    // Clean up
    controller.onCancel = () {
      timer.cancel();
      _pollingTimers.remove(streamKey);
      _streamControllers.remove(streamKey);
      controller.close();
    };
    
    return controller.stream;
  }
  
  Future<void> fetchAndAddMessages(String channelId, StreamController<List<Message>> controller) async {
    if (controller.isClosed) return;
    
    try {
      final messages = await getMessages(channelId);
      if (!controller.isClosed) {
        controller.add(messages);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  Future<List<Message>> getMessages(String channelId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select<List<Map<String, dynamic>>>('*, user_display_name')
          .eq('channel_id', channelId)
          .order('created_at', ascending: false)
          .limit(50);
      
      return response.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      rethrow;
    }
  }

  Future<Message> sendMessage(String channelId, String content) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      final displayName = user.email?.split('@')[0] ?? 'Unknown User';
      
      final response = await _supabase
          .from('messages')
          .insert({
            'channel_id': channelId,
            'content': content,
            'user_id': user.id,
            'user_display_name': displayName,
          })
          .select<Map<String, dynamic>>()
          .single();

      // Trigger immediate update for messages
      final streamKey = 'messages_$channelId';
      final controller = _streamControllers[streamKey] as StreamController<List<Message>>?;
      if (controller != null && !controller.isClosed) {
        fetchAndAddMessages(channelId, controller);
      }

      return Message.fromJson(response);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> deleteMessage(String channelId, String messageId) async {
    try {
      await _supabase
          .from('messages')
          .delete()
          .eq('id', messageId);

      // Trigger immediate update for messages
      final streamKey = 'messages_$channelId';
      final controller = _streamControllers[streamKey] as StreamController<List<Message>>?;
      if (controller != null && !controller.isClosed) {
        fetchAndAddMessages(channelId, controller);
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  // Server Invites
  Future<Invite> createInvite(String serverId, {
    Duration? expiry,
    int? maxUses,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Generate a unique 8-character invite code
    final code = DateTime.now().millisecondsSinceEpoch.toRadixString(36).substring(0, 8);

    try {
      final response = await _supabase
          .from('server_invites')
          .insert({
            'server_id': serverId,
            'code': code,
            'created_by': user.id,
            'expires_at': expiry != null
                ? DateTime.now().add(expiry).toIso8601String()
                : null,
            'max_uses': maxUses,
            'uses': 0,
          })
          .select()
          .single();

      return Invite.fromJson(response);
    } catch (e) {
      debugPrint('Error creating invite: $e');
      rethrow;
    }
  }

  Future<Invite?> getInvite(String code) async {
    try {
      final response = await _supabase
          .from('server_invites')
          .select()
          .eq('code', code)
          .single();

      final invite = Invite.fromJson(response);
      
      // Check if invite is valid
      if (!invite.isValid) {
        return null;
      }

      return invite;
    } catch (e) {
      debugPrint('Error getting invite: $e');
      return null;
    }
  }

  Future<bool> useInvite(String code) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // Get the invite
      final invite = await getInvite(code);
      if (invite == null) return false;

      // Start a transaction
      await _supabase.rpc('use_invite', params: {
        'invite_code': code,
        'user_id': user.id,
      });

      return true;
    } catch (e) {
      debugPrint('Error using invite: $e');
      return false;
    }
  }

  Future<List<Invite>> getServerInvites(String serverId) async {
    try {
      final response = await _supabase
          .from('server_invites')
          .select<List<Map<String, dynamic>>>()
          .eq('server_id', serverId);
      
      return response.map((json) => Invite.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting server invites: $e');
      rethrow;
    }
  }

  Future<void> deleteInvite(String inviteId) async {
    try {
      await _supabase
          .from('server_invites')
          .delete()
          .eq('id', inviteId);
    } catch (e) {
      debugPrint('Error deleting invite: $e');
      rethrow;
    }
  }

  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Authentication
  Future<void> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw 'Login failed. Please try again.';
      }
    } catch (e) {
      throw 'Login failed: ${e.toString()}';
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      
      if (response.user == null) {
        throw 'Sign up failed. Please try again.';
      }
    } catch (e) {
      throw 'Sign up failed: ${e.toString()}';
    }
  }

  // Track online presence
  void trackPresence(String serverId) {
    final channel = _supabase.channel('online_users:$serverId');
    
    channel.on(RealtimeListenTypes.presence, ChannelFilter(event: 'sync'), (payload, [ref]) {
      print('Presence sync: $payload');
    }).on(RealtimeListenTypes.presence, ChannelFilter(event: 'join'), (payload, [ref]) {
      print('User joined: $payload');
    }).on(RealtimeListenTypes.presence, ChannelFilter(event: 'leave'), (payload, [ref]) {
      print('User left: $payload');
    });

    channel.subscribe((status, [_]) async {
      if (status == 'SUBSCRIBED') {
        await channel.track({'user_id': _supabase.auth.currentUser?.id, 'online_at': DateTime.now().toIso8601String()});
      }
    });
  }

  Future<void> stopTrackingPresence(String serverId) async {
    await _supabase.channel('online_users:$serverId').unsubscribe();
  }

  Future<bool> validateSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return false;
      
      // Check if session is expired
      if (session.expiresAt != null && 
          DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000).isBefore(DateTime.now())) {
        return false;
      }
      
      // Verify the session is still valid by making a test request
      await _supabase.from('servers').select('id').limit(1).maybeSingle();
      return true;
    } catch (e) {
      // If any error occurs (network, auth, etc), consider the session invalid
      // but don't try to sign out as the token might be invalid
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Ignore sign out errors as we just want to clear the session
    }
  }
}
