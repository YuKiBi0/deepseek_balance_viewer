class ApiKeyEntry {
  final String id;
  final String name;
  final String apiKey;

  ApiKeyEntry({
    required this.id,
    required this.name,
    required this.apiKey,
  });

  /// 脱敏展示密钥，如 `sk-...abc123`
  String get maskedKey {
    if (apiKey.length <= 8) return apiKey;
    return '${apiKey.substring(0, 3)}...${apiKey.substring(apiKey.length - 4)}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'key': apiKey,
      };

  factory ApiKeyEntry.fromJson(Map<String, dynamic> json) => ApiKeyEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        apiKey: json['key'] as String,
      );
}
