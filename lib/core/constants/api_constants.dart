import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  /// Daftar IP kandidat laptop:
  /// 1. 192.168.137.1 -> Windows Mobile Hotspot (laptop sebagai pemancar hotspot)
  /// 2. 10.30.93.147 -> Samsung USB Tethering (HP Samsung sebagai pemancar tethering)
  static final List<String> candidateHosts = [
    '192.168.137.1',
    '10.30.93.147',
  ];

  /// Host IP default aktif
  static String hostIp = '192.168.137.1';
  static const String port = '8000';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:$port';
    } else if (Platform.isAndroid) {
      return 'http://$hostIp:$port';
    } else {
      return 'http://127.0.0.1:$port';
    }
  }

  static String get loginUrl => '$baseUrl/api/v1/auth/login';
  static String get registerUrl => '$baseUrl/api/v1/auth/register';
  static String get logoutUrl => '$baseUrl/api/v1/auth/logout';
  static String get meUrl => '$baseUrl/api/v1/auth/me';
  static String get schoolsUrl => '$baseUrl/api/schools';

  static void setWorkingHost(String host) {
    if (candidateHosts.contains(host)) {
      hostIp = host;
    }
  }
}
