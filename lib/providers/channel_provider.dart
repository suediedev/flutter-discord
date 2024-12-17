import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../models/channel.dart';

final channelsProvider = StreamProvider.family<List<Channel>, String>((ref, serverId) {
  return ref.read(supabaseServiceProvider).getChannelsStream(serverId);
});

final selectedChannelProvider = StateProvider<String?>((ref) => null);
