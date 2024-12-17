import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../models/server.dart';
import '../models/member.dart';

// Stream of all servers the user is a member of
final serversStreamProvider = StreamProvider<List<Server>>((ref) {
  return ref.read(supabaseServiceProvider).getServersStream();
});

// Currently selected server
final selectedServerProvider = StateProvider<Server?>((ref) => null);

// Get a specific server by ID
final serverProvider = Provider.family<Server?, String>((ref, serverId) {
  final servers = ref.watch(serversStreamProvider).value ?? [];
  try {
    return servers.firstWhere((s) => s.id == serverId);
  } catch (e) {
    return null;
  }
});

// Members provider
final membersProvider = StreamProvider.family<List<Member>, String>((ref, serverId) {
  return ref.read(supabaseServiceProvider).getServerMembers(serverId);
});
