import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

/// Klien API pusat untuk menangani semua request HTTP menggunakan library Dio.
/// Mengatur konfigurasi dasar seperti Base URL, Interceptor untuk Token JWT, dan penanganan error global.
class ApiClient {
  /// Instance Dio yang dikonfigurasi dengan opsi dasar.
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  ApiClient() {
    // Menambahkan Interceptor untuk menyisipkan Token JWT ke setiap request secara otomatis.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          // Penanganan respons global bisa ditambahkan di sini jika perlu (misal: logging).
          return handler.next(response);
        },
        onRequest: (options, handler) async {
          // Ambil token JWT dari penyimpanan lokal (SharedPreferences).
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');

          if (token != null) {
            // Menyisipkan token ke header Authorization untuk autentikasi di server.
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint(
              '[ApiClient] Request: ${options.path}, Token: ${token.substring(0, 5)}...',
            );
          } else {
            debugPrint('[ApiClient] Request: ${options.path}, Token: KOSONG');
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Log error secara global untuk memudahkan proses debugging.
          debugPrint(
            '[ApiClient] Error pada ${e.requestOptions.path}: ${e.message}',
          );
          return handler.next(e);
        },
      ),
    );
  }

  /// Mengekspos instance Dio yang sudah dikonfigurasi agar bisa digunakan oleh Provider atau Service lain.
  Dio get dio => _dio;
}
