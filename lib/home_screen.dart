import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'deepseek_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _balanceData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('deepseek_api_key');
      if (apiKey == null || apiKey.isEmpty) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/apikey');
        }
        return;
      }

      final data = await DeepSeekService.fetchBalance(apiKey);
      if (mounted) {
        setState(() {
          _balanceData = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _changeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('deepseek_api_key');
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/apikey');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DeepSeek 余额'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _fetchBalance,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchBalance,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _balanceData!;
    final isAvailable = data['is_available'] as bool? ?? false;
    final balanceInfos = data['balance_infos'] as List<dynamic>? ?? [];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 24),
            TextButton(
              onPressed: _changeApiKey,
              child: const Text('更换 API Key'),
            ),
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
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
