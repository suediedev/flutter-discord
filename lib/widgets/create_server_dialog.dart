import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../providers/server_provider.dart';
import '../theme/platform_theme.dart';

class CreateServerDialog extends ConsumerStatefulWidget {
  const CreateServerDialog({super.key});

  @override
  ConsumerState<CreateServerDialog> createState() => _CreateServerDialogState();
}

class _CreateServerDialogState extends ConsumerState<CreateServerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createServer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final server = await ref.read(supabaseServiceProvider).createServer(
        _nameController.text.trim(),
      );
      
      if (!mounted) return;
      Navigator.of(context).pop(server);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating server: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Server'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Server Name',
                hintText: 'Enter server name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a server name';
                }
                return null;
              },
              enabled: !_isLoading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createServer,
          child: _isLoading
              ? PlatformTheme.adaptiveProgressIndicator()
              : const Text('Create'),
        ),
      ],
    );
  }
}
