import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../models/channel.dart';
import '../providers/server_provider.dart';

// Stream of channels for a specific server
final channelsProvider = StreamProvider.family<List<Channel>, String>((ref, serverId) {
  return ref.read(supabaseServiceProvider).getChannelsStream(serverId);
});

// Currently selected channel
final selectedChannelProvider = StateProvider<String?>((ref) => null);

// Get a specific channel by ID
final channelProvider = Provider.family<Channel?, String>((ref, channelId) {
  final serverId = ref.watch(selectedServerProvider)?.id;
  if (serverId == null) return null;
  
  final channels = ref.watch(channelsProvider(serverId)).value ?? [];
  try {
    return channels.firstWhere((c) => c.id == channelId);
  } catch (e) {
    return null;
  }
});
