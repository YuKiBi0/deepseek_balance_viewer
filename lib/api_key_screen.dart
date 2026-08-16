import 'package:flutter/material.dart';

import 'key_edit_screen.dart';
import 'models/api_key_entry.dart';
import 'services/key_store.dart';

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _store = KeyStore();
  List<ApiKeyEntry> _keys = [];
  String? _activeId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final keys = await _store.loadKeys();
    final activeId = await _store.loadActiveId();
    if (!mounted) return;
    setState(() {
      _keys = keys;
      _activeId = activeId;
      _loading = false;
    });
  }

  Future<void> _openEdit([ApiKeyEntry? entry]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KeyEditScreen(entry: entry)),
    );
    await _load();
  }

  Future<void> _delete(ApiKeyEntry entry) async {
    await _store.deleteKey(entry.id);
    if (_activeId == entry.id) {
      final remaining = _keys.where((e) => e.id != entry.id).toList();
      if (remaining.isNotEmpty) {
        await _store.setActive(remaining.first.id);
      }
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('密钥管理')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _keys.isEmpty
              ? const Center(child: Text('暂无密钥，点击右下角添加'))
              : ListView.builder(
                  itemCount: _keys.length,
                  itemBuilder: (context, index) {
                    final key = _keys[index];
                    final isActive = key.id == _activeId;
                    return ListTile(
                      leading: Icon(
                        isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                      title: Text(key.name),
                      subtitle: Text(key.maskedKey),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: '删除',
                        onPressed: () => _delete(key),
                      ),
                      onTap: () => _openEdit(key),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(),
        tooltip: '添加密钥',
        child: const Icon(Icons.add),
      ),
    );
  }
}
