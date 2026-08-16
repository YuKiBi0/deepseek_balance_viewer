import 'package:flutter/material.dart';

import 'api_key_screen.dart';
import 'deepseek_service.dart';
import 'key_edit_screen.dart';
import 'models/api_key_entry.dart';
import 'services/key_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = KeyStore();

  List<ApiKeyEntry> _keys = [];
  String? _activeId;
  int _currentIndex = 0;

  final Map<String, Map<String, dynamic>> _balances = {};
  final Map<String, String> _errors = {};
  final Set<String> _loading = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadKeys();
    if (!mounted) return;
    if (_keys.isEmpty) {
      _goToAddKey();
      return;
    }
    _currentIndex = _activeIndex();
    setState(() {});
    _fetchBalance(_keys[_currentIndex]);
  }

  Future<void> _loadKeys() async {
    _keys = await _store.loadKeys();
    _activeId = await _store.loadActiveId();
  }

  void _goToAddKey() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const KeyEditScreen()),
    );
  }

  int _activeIndex() {
    if (_keys.isEmpty) return 0;
    final index = _keys.indexWhere((e) => e.id == _activeId);
    return index == -1 ? 0 : index;
  }

  void _onIndexChanged(int index) {
    if (index < 0 || index >= _keys.length) return;
    _currentIndex = index;
    final key = _keys[index];
    if (key.id != _activeId) {
      _activeId = key.id;
      _store.setActive(key.id);
    }
    _ensureLoaded(key);
  }

  void _ensureLoaded(ApiKeyEntry key) {
    if (_balances.containsKey(key.id) ||
        _errors.containsKey(key.id) ||
        _loading.contains(key.id)) {
      return;
    }
    _fetchBalance(key);
  }

  Future<void> _fetchBalance(ApiKeyEntry key) async {
    if (_loading.contains(key.id)) return;
    setState(() {
      _loading.add(key.id);
      _errors.remove(key.id);
    });

    try {
      final data = await DeepSeekService.fetchBalance(key.apiKey);
      if (!mounted) return;
      setState(() {
        _balances[key.id] = data;
        _loading.remove(key.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errors[key.id] = e.toString().replaceFirst('Exception: ', '');
        _loading.remove(key.id);
      });
    }
  }

  Future<void> _refresh() async {
    if (_keys.isEmpty) return;
    final key = _keys[_currentIndex];
    setState(() {
      _balances.remove(key.id);
      _errors.remove(key.id);
    });
    await _fetchBalance(key);
  }

  Future<void> _openManage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ApiKeyScreen()),
    );
    if (!mounted) return;

    await _loadKeys();
    if (!mounted) return;
    if (_keys.isEmpty) {
      _goToAddKey();
      return;
    }

    _currentIndex = _activeIndex();
    final ids = _keys.map((e) => e.id).toSet();
    _balances.removeWhere((id, _) => !ids.contains(id));
    _errors.removeWhere((id, _) => !ids.contains(id));
    _loading.removeWhere((id) => !ids.contains(id));

    setState(() {});
    _fetchBalance(_keys[_currentIndex]);
  }

  @override
  Widget build(BuildContext context) {
    if (_keys.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DeepSeek 余额'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '密钥管理',
            onPressed: _openManage,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _refresh,
          ),
        ],
      ),
      body: _KeyTabsView(
        key: ValueKey(_keys.map((e) => e.id).join('|')),
        keys: _keys,
        initialIndex: _currentIndex,
        onIndexChanged: _onIndexChanged,
        itemBuilder: _buildKeyView,
      ),
    );
  }

  Widget _buildKeyView(ApiKeyEntry key) {
    if (_loading.contains(key.id)) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _errors[key.id];
    if (error != null) {
      return _buildError(key, error);
    }

    final data = _balances[key.id];
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildBalanceContent(data);
  }

  Widget _buildError(ApiKeyEntry key, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchBalance(key),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceContent(Map<String, dynamic> data) {
    final isAvailable = data['is_available'] as bool? ?? false;
    final balanceInfos = data['balance_infos'] as List<dynamic>? ?? [];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAvailable ? Icons.check_circle : Icons.cancel,
              size: 64,
              color: isAvailable ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              isAvailable ? '账户可用' : '账户不可用',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isAvailable ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            if (balanceInfos.isNotEmpty)
              ...balanceInfos.map((info) {
                final currency = info['currency'] ?? '—';
                final total = info['total_balance'] ?? '—';
                final toppedUp = info['topped_up_balance'] ?? '—';
                final granted = info['granted_balance'] ?? '—';
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '总余额',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$total $currency',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 32),
                        _infoRow('充值余额', '$toppedUp $currency'),
                        _infoRow('赠送余额', '$granted $currency'),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// 负责持有 [TabController]，通过 key 变化触发整棵子树重建，避免原地销毁/重建
/// 控制器导致 TabBar/TabBarView 引用已销毁控制器的异常。
class _KeyTabsView extends StatefulWidget {
  final List<ApiKeyEntry> keys;
  final int initialIndex;
  final ValueChanged<int> onIndexChanged;
  final Widget Function(ApiKeyEntry) itemBuilder;

  const _KeyTabsView({
    super.key,
    required this.keys,
    required this.initialIndex,
    required this.onIndexChanged,
    required this.itemBuilder,
  });

  @override
  State<_KeyTabsView> createState() => _KeyTabsViewState();
}

class _KeyTabsViewState extends State<_KeyTabsView>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  int _lastIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: widget.keys.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _lastIndex = _controller.index;
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final index = _controller.index;
    if (index != _lastIndex) {
      _lastIndex = index;
      widget.onIndexChanged(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _controller,
          isScrollable: true,
          tabs: widget.keys.map((e) => Tab(text: e.name)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: widget.keys.map(widget.itemBuilder).toList(),
          ),
        ),
      ],
    );
  }
}
