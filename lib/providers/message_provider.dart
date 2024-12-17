import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../models/message.dart';

final messagesProvider = StreamProvider.family<List<Message>, String>((ref, channelId) {
  return ref.read(supabaseServiceProvider).getMessagesStream(channelId);
});
