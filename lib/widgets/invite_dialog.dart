import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invite.dart';
import '../services/supabase_service.dart';

class InviteDialog extends ConsumerStatefulWidget {
  final String serverId;

  const InviteDialog({
    super.key,
    required this.serverId,
  });

  @override
  ConsumerState<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<InviteDialog> {
  List<Invite>? _invites;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  Future<void> _loadInvites() async {
    try {
      final invites = await ref.read(supabaseServiceProvider).getServerInvites(widget.serverId);
      if (!mounted) return;
      setState(() {
        _invites = invites;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading invites: $e')),
      );
    }
  }

  Future<void> _createInvite() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateInviteDialog(),
    );

    if (result == null) return;

    try {
      await ref.read(supabaseServiceProvider).createInvite(
            widget.serverId,
            expiry: result['expiry'] as Duration?,
            maxUses: result['maxUses'] as int?,
          );
      _loadInvites();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating invite: $e')),
      );
    }
  }

  Future<void> _deleteInvite(Invite invite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invite'),
        content: const Text('Are you sure you want to delete this invite?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(supabaseServiceProvider).deleteInvite(invite.id);
      _loadInvites();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting invite: $e')),
      );
    }
  }

  Future<void> _copyInviteCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Server Invites',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _createInvite,
                  tooltip: 'Create Invite',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_invites == null || _invites!.isEmpty)
              const Center(
                child: Text(
                  'No invites yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: _invites!.length,
                  itemBuilder: (context, index) {
                    final invite = _invites![index];
                    return Card(
                      child: ListTile(
                        title: Text(invite.code),
                        subtitle: Text(
                          'Uses: ${invite.uses}${invite.maxUses != null ? '/${invite.maxUses}' : ''}\n'
                          'Expires: ${invite.expiresAt?.toString() ?? 'Never'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () => _copyInviteCode(invite.code),
                              tooltip: 'Copy Invite Code',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteInvite(invite),
                              tooltip: 'Delete Invite',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CreateInviteDialog extends StatefulWidget {
  const CreateInviteDialog({super.key});

  @override
  State<CreateInviteDialog> createState() => _CreateInviteDialogState();
}

class _CreateInviteDialogState extends State<CreateInviteDialog> {
  Duration? _expiry;
  int? _maxUses;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Invite',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Duration?>(
              value: _expiry,
              decoration: const InputDecoration(
                labelText: 'Expiry',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('Never'),
                ),
                DropdownMenuItem(
                  value: Duration(hours: 1),
                  child: Text('1 hour'),
                ),
                DropdownMenuItem(
                  value: Duration(days: 1),
                  child: Text('1 day'),
                ),
                DropdownMenuItem(
                  value: Duration(days: 7),
                  child: Text('7 days'),
                ),
              ],
              onChanged: (value) => setState(() => _expiry = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Max Uses (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _maxUses = int.tryParse(value);
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'expiry': _expiry,
                      'maxUses': _maxUses,
                    });
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
