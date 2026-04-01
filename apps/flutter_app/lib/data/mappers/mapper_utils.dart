/// Safe list converter that returns empty list if input is null
List<T> mapList<T>(List<dynamic>? list, T Function(Map<String, dynamic>) mapper) {
  if (list == null || list.isEmpty) return [];
  return list
      .whereType<Map<String, dynamic>>()
      .map(mapper)
      .toList();
}

/// Safe map converter
Map<K, V> mapMap<K, V>(
  Map<dynamic, dynamic>? map,
  MapEntry<K, V> Function(String key, dynamic value) converter,
) {
  if (map == null || map.isEmpty) return {};
  return Map.fromEntries(
    map.entries.map((e) => converter(e.key.toString(), e.value)),
  );
}

/// Safe enum converter
T? mapEnum<T>(String? value, List<T> values, T Function(int) indexer) {
  if (value == null) return null;
  try {
    return values
        .where((e) => e.toString().split('.').last == value.toLowerCase())
        .firstOrNull;
  } catch (_) {
    return null;
  }
}

/// Safe int converter
int mapInt(dynamic value, {int defaultValue = 0}) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Safe double converter
double mapDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Safe bool converter
bool mapBool(dynamic value, {bool defaultValue = false}) {
  if (value is bool) return value;
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return defaultValue;
}

/// Safe string converter
String mapString(dynamic value, {String defaultValue = ''}) {
  if (value is String) return value;
  if (value == null) return defaultValue;
  return value.toString();
}
