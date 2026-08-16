import 'package:flutter/material.dart';

import 'models/api_key_entry.dart';
import 'services/key_store.dart';

class KeyEditScreen extends StatefulWidget {
  final ApiKeyEntry? entry;

  const KeyEditScreen({super.key, this.entry});

  @override
  State<KeyEditScreen> createState() => _KeyEditScreenState();
}

class _KeyEditScreenState extends State<KeyEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _keyController;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entry?.name ?? '');
    _keyController = TextEditingController(text: widget.entry?.apiKey ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final key = _keyController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = '请输入昵称');
      return;
    }
    if (key.isEmpty) {
      setState(() => _error = '请输入 API Key');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final store = KeyStore();
    if (_isEditing) {
      await store.updateKey(ApiKeyEntry(
        id: widget.entry!.id,
        name: name,
        apiKey: key,
      ));
    } else {
      final entry = await store.addNewKey(name, key);
      await store.setActive(entry.id);
    }

    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑密钥' : '新增密钥')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.vpn_key, size: 64, color: Colors.deepPurple),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '昵称',
                hintText: '例如：工作号',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
