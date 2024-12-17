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
  final _iconUrlController = TextEditingController();
  bool _isLoading = false;
  String? _iconError;
  bool _isValidatingIcon = false;

  @override
  void dispose() {
    _nameController.dispose();
    _iconUrlController.dispose();
    super.dispose();
  }

  Future<void> _validateIconUrl(String url) async {
    if (url.isEmpty) {
      setState(() => _iconError = null);
      return;
    }

    setState(() => _isValidatingIcon = true);

    try {
      final image = NetworkImage(url);
      await precacheImage(image, context);
      if (!mounted) return;
      setState(() {
        _iconError = null;
        _isValidatingIcon = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _iconError = 'Invalid image URL';
        _isValidatingIcon = false;
      });
    }
  }

  void _createServer() {
    if (!_formKey.currentState!.validate() || _iconError != null || _isValidatingIcon) return;

    final iconUrl = _iconUrlController.text.trim();
    final result = {
      'name': _nameController.text.trim(),
      if (iconUrl.isNotEmpty) 'iconUrl': iconUrl,
    };
    
    Navigator.of(context).pop(result);
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
            if (_iconUrlController.text.isNotEmpty && _iconError == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(_iconUrlController.text),
                      onBackgroundImageError: (_, __) {
                        setState(() => _iconError = 'Failed to load image');
                      },
                    ),
                    if (_isValidatingIcon)
                      const Positioned.fill(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Server Name',
                hintText: 'Enter server name',
                prefixIcon: Icon(Icons.group),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a server name';
                }
                if (value.trim().length < 3) {
                  return 'Server name must be at least 3 characters';
                }
                return null;
              },
              enabled: !_isLoading,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _iconUrlController,
              decoration: InputDecoration(
                labelText: 'Server Icon URL (optional)',
                hintText: 'Enter icon URL',
                prefixIcon: const Icon(Icons.image),
                errorText: _iconError,
                suffixIcon: _isValidatingIcon
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              enabled: !_isLoading,
              onChanged: _validateIconUrl,
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
          onPressed: _isLoading || _isValidatingIcon ? null : _createServer,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
