import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  CacheEntry({required this.data, required this.timestamp});

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(timestamp) > ttl;
  }
}

class CacheService {
  static final Map<String, CacheEntry<dynamic>> _memoryCache = {};
  static const Duration defaultTTL = Duration(minutes: 5);

  /// Mengambil data dari cache memori (0ms) atau disk SharedPreferences jika memori kosong
  static Future<T?> get<T>(
    String key, {
    Duration ttl = defaultTTL,
    T Function(dynamic json)? fromJson,
  }) async {
    // 1. Cek cache memori (instan 0 milidetik)
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (!entry.isExpired(ttl)) {
        return entry.data as T?;
      }
    }

    // 2. Cek disk lokal jika memori kosong (misal aplikasi baru dibuka)
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('swr_cache_$key');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        final timestampStr = decoded['ts'] as String?;
        final dataJson = decoded['data'];

        if (timestampStr != null) {
          final timestamp = DateTime.parse(timestampStr);
          if (DateTime.now().difference(timestamp) <= ttl) {
            final parsed = fromJson != null ? fromJson(dataJson) : dataJson as T;
            _memoryCache[key] = CacheEntry(data: parsed, timestamp: timestamp);
            return parsed;
          }
        }
      }
    } catch (_) {
      // Abaikan jika parsing disk gagal
    }

    return null;
  }

  /// Menyimpan data baru ke cache memori dan disk
  static Future<void> set<T>(
    String key,
    T data, {
    dynamic Function(T item)? toJson,
  }) async {
    final now = DateTime.now();
    _memoryCache[key] = CacheEntry(data: data, timestamp: now);

    try {
      final prefs = await SharedPreferences.getInstance();
      final dataToStore = toJson != null ? toJson(data) : data;
      final payload = jsonEncode({
        'ts': now.toIso8601String(),
        'data': dataToStore,
      });
      await prefs.setString('swr_cache_$key', payload);
    } catch (_) {
      // Abaikan jika objek tidak bisa di-serialize ke JSON disk
    }
  }

  /// Menghapus cache spesifik
  static Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('swr_cache_$key');
    } catch (_) {}
  }

  /// Membersihkan seluruh cache lokal
  static Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('swr_cache_')).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}

