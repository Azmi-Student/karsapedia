import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/school_model.dart';
import '../models/user_model.dart';
import 'cache_service.dart';
import 'storage_service.dart';

class AuthService {
  /// Header standar untuk request JSON
  static Map<String, String> _headers([String? token]) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Request HTTP GET dengan pencarian host IP kandidat otomatis (Hotspot vs USB Tethering)
  static Future<http.Response> _getWithCandidateHosts(
    String path, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      final url = Uri.parse('http://127.0.0.1:${ApiConstants.port}$path');
      return await http.get(url, headers: headers).timeout(timeout);
    }

    final hostsToTry = [
      ApiConstants.hostIp,
      ...ApiConstants.candidateHosts.where((h) => h != ApiConstants.hostIp),
    ];

    dynamic lastError;
    for (final host in hostsToTry) {
      try {
        final url = Uri.parse('http://$host:${ApiConstants.port}$path');
        final response = await http.get(url, headers: headers).timeout(timeout);
        ApiConstants.setWorkingHost(host);
        return response;
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('Gagal terhubung ke server backend.');
  }

  /// Request HTTP POST dengan pencarian host IP kandidat otomatis (Hotspot vs USB Tethering)
  static Future<http.Response> _postWithCandidateHosts(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      final url = Uri.parse('http://127.0.0.1:${ApiConstants.port}$path');
      return await http.post(url, headers: headers, body: body).timeout(timeout);
    }

    final hostsToTry = [
      ApiConstants.hostIp,
      ...ApiConstants.candidateHosts.where((h) => h != ApiConstants.hostIp),
    ];

    dynamic lastError;
    for (final host in hostsToTry) {
      try {
        final url = Uri.parse('http://$host:${ApiConstants.port}$path');
        final response = await http.post(url, headers: headers, body: body).timeout(timeout);
        ApiConstants.setWorkingHost(host);
        return response;
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('Gagal terhubung ke server backend.');
  }

  /// Request HTTP PUT dengan pencarian host IP kandidat otomatis (Hotspot vs USB Tethering)
  static Future<http.Response> _putWithCandidateHosts(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      final url = Uri.parse('http://127.0.0.1:${ApiConstants.port}$path');
      return await http.put(url, headers: headers, body: body).timeout(timeout);
    }

    final hostsToTry = [
      ApiConstants.hostIp,
      ...ApiConstants.candidateHosts.where((h) => h != ApiConstants.hostIp),
    ];

    dynamic lastError;
    for (final host in hostsToTry) {
      try {
        final url = Uri.parse('http://$host:${ApiConstants.port}$path');
        final response = await http.put(url, headers: headers, body: body).timeout(timeout);
        ApiConstants.setWorkingHost(host);
        return response;
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('Gagal terhubung ke server backend.');
  }

  /// 1. Login Pengguna (mendukung email atau username)
  static Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    try {
      final response = await _postWithCandidateHosts(
        '/api/v1/auth/login',
        headers: _headers(),
        body: jsonEncode({
          'login': login.trim(),
          'email': login.trim(),
          'password': password,
          'device_name': 'flutter_mobile',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
        final token = data['data']['token'];
        final user = UserModel.fromJson(data['data']['user']);

        await StorageService.saveToken(token);
        await StorageService.saveUser(user);

        return {'success': true, 'user': user};
      } else {
        final message = data['message'] ?? 'Login gagal. Silakan periksa kembali kredensial Anda.';
        return {'success': false, 'message': message};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server backend. Pastikan server aktif (${ApiConstants.baseUrl}).',
      };
    }
  }

  /// 2. Registrasi Pengguna Baru
  static Future<Map<String, dynamic>> register({
    required String name,
    String? username,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? schoolName,
    String? schoolNpsn,
    String? phoneNumber,
  }) async {
    try {
      final response = await _postWithCandidateHosts(
        '/api/v1/auth/register',
        headers: _headers(),
        body: jsonEncode({
          'name': name.trim(),
          'username': username?.trim(),
          'email': email.trim(),
          'password': password,
          'password_confirmation': passwordConfirmation,
          'school_name': schoolName?.trim(),
          'school_npsn': schoolNpsn?.trim(),
          'phone_number': phoneNumber?.trim(),
          'device_name': 'flutter_mobile',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final token = data['data']['token'];
        final user = UserModel.fromJson(data['data']['user']);

        await StorageService.saveToken(token);
        await StorageService.saveUser(user);

        return {'success': true, 'user': user};
      } else {
        String errorMessage = data['message'] ?? 'Registrasi gagal.';
        if (data['errors'] != null && data['errors'] is Map) {
          final firstError = (data['errors'] as Map).values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first.toString();
          }
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server backend. Pastikan server aktif (${ApiConstants.baseUrl}).',
      };
    }
  }

  /// 3. Mendapatkan data profil terkini langsung dari backend
  static Future<UserModel?> getMe() async {
    final token = await StorageService.getToken();
    if (token == null) return null;

    final response = await _getWithCandidateHosts(
      '/api/v1/auth/me',
      headers: _headers(token),
      timeout: const Duration(seconds: 4),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['data']['user']);
      await StorageService.saveUser(user);
      return user;
    } else {
      throw Exception('Gagal memuat profil: HTTP ${response.statusCode}');
    }
  }

  /// 4. Logout Pengguna
  static Future<void> logout() async {
    try {
      final token = await StorageService.getToken();
      if (token != null) {
        await _postWithCandidateHosts(
          '/api/v1/auth/logout',
          headers: _headers(token),
          timeout: const Duration(seconds: 3),
        );
      }
    } catch (_) {
      // Abaikan error jaringan saat logout
    } finally {
      await StorageService.clearAll();
    }
  }

  static final Map<String, List<SchoolModel>> _schoolSearchCache = {};

  /// 5. Pencarian Rekomendasi Sekolah (Dengan In-Memory Memoization Cache)
  static Future<List<SchoolModel>> searchSchools(String query) async {
    final term = query.trim().toLowerCase();
    if (term.length < 3) return [];

    // 1. Cek cache memori lokal terlebih dahulu (instan 0 ms, 0 beban backend)
    if (_schoolSearchCache.containsKey(term)) {
      return _schoolSearchCache[term]!;
    }

    try {
      final response = await _getWithCandidateHosts(
        '/api/schools?search=${Uri.encodeComponent(term)}',
        headers: {'Accept': 'application/json'},
        timeout: const Duration(seconds: 4),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        final list = items.map((i) => SchoolModel.fromJson(i)).toList();

        // Batasi ukuran cache memori maksimal 60 query terbaru
        if (_schoolSearchCache.length > 60) {
          _schoolSearchCache.remove(_schoolSearchCache.keys.first);
        }
        _schoolSearchCache[term] = list;

        return list;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 6. Perbarui Data Profil (Nama, Username, Nomor HP, Sekolah)
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? username,
    String? phoneNumber,
    String? schoolName,
    String? schoolNpsn,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Sesi login tidak valid.'};
      }

      final response = await _putWithCandidateHosts(
        '/api/v1/auth/profile',
        headers: _headers(token),
        body: jsonEncode({
          'name': name.trim(),
          'username': username?.trim(),
          'phone_number': phoneNumber?.trim(),
          'school_name': schoolName?.trim(),
          'school_npsn': schoolNpsn?.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
        final updatedUser = UserModel.fromJson(data['data']['user']);
        await StorageService.saveUser(updatedUser);
        await CacheService.set('current_user_profile', updatedUser);
        return {'success': true, 'user': updatedUser};
      } else {
        String msg = data['message'] ?? 'Gagal memperbarui profil.';
        if (data['errors'] != null && data['errors'] is Map) {
          final first = (data['errors'] as Map).values.first;
          if (first is List && first.isNotEmpty) {
            msg = first.first.toString();
          }
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi saat memperbarui profil.'};
    }
  }

  /// 7. Perbarui Kata Sandi Akun
  static Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Sesi login tidak valid.'};
      }

      final response = await _putWithCandidateHosts(
        '/api/v1/auth/password',
        headers: _headers(token),
        body: jsonEncode({
          'current_password': currentPassword,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Kata sandi berhasil diperbarui.'};
      } else {
        String msg = data['message'] ?? 'Gagal memperbarui kata sandi.';
        if (data['errors'] != null && data['errors'] is Map) {
          final first = (data['errors'] as Map).values.first;
          if (first is List && first.isNotEmpty) {
            msg = first.first.toString();
          }
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi saat memperbarui kata sandi.'};
    }
  }
}
