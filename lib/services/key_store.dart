import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_key_entry.dart';

class KeyStore {
  static const _keysKey = 'deepseek_api_keys';
  static const _activeKey = 'active_api_key_id';
  static const _legacyKey = 'deepseek_api_key';

  /// 加载全部密钥；若存在旧版单密钥则自动迁移。
  Future<List<ApiKeyEntry>> loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keysKey);

    if (raw != null && raw.isNotEmpty) {
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => ApiKeyEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // 迁移旧版单密钥
    final legacy = prefs.getString(_legacyKey);
    if (legacy != null && legacy.isNotEmpty) {
      final entry = ApiKeyEntry(id: _genId(), name: '默认', apiKey: legacy);
      await _saveKeys([entry]);
      await _saveActive(entry.id);
      await prefs.remove(_legacyKey);
      return [entry];
    }

    return [];
  }

  Future<String?> loadActiveId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeKey);
  }

  Future<void> addKey(ApiKeyEntry entry) async {
    final keys = await loadKeys();
    keys.add(entry);
    await _saveKeys(keys);
  }

  /// 生成新密钥并写入，返回带服务端分配 ID 的实体。
  Future<ApiKeyEntry> addNewKey(String name, String apiKey) async {
    final entry = ApiKeyEntry(id: _genId(), name: name, apiKey: apiKey);
    await addKey(entry);
    return entry;
  }

  Future<void> updateKey(ApiKeyEntry entry) async {
    final keys = await loadKeys();
    final index = keys.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      keys[index] = entry;
      await _saveKeys(keys);
    }
  }

  Future<void> deleteKey(String id) async {
    final keys = await loadKeys();
    keys.removeWhere((e) => e.id == id);
    await _saveKeys(keys);
  }

  Future<void> setActive(String id) async {
    await _saveActive(id);
  }

  Future<void> _saveKeys(List<ApiKeyEntry> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(keys.map((e) => e.toJson()).toList());
    await prefs.setString(_keysKey, raw);
  }

  Future<void> _saveActive(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_activeKey);
    } else {
      await prefs.setString(_activeKey, id);
    }
  }

  String _genId() {
    final random = Random();
    return '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(0xFFFFFF)}';
  }
}
