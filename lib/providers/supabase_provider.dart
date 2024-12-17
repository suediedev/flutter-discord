import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final messagesProvider = StreamProvider.family<List<Message>, String>((ref, channelId) {
  return ref.watch(supabaseServiceProvider).getMessagesStream(channelId);
});
