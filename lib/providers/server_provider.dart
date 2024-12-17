import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../models/server.dart';

final serversProvider = StreamProvider<List<Server>>((ref) {
  return ref.read(supabaseServiceProvider).getServersStream();
});

final selectedServerProvider = StateProvider<String?>((ref) => null);
