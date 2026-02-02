import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Layanan untuk mengelola penyimpanan foto secara lokal (Foto Profil & Foto Goal).
/// Foto disimpan secara fisik di direktori dokumen aplikasi, dan lokasinya (path) dicatat di [SharedPreferences].
class PhotoStorageService {
  /// Instance ImagePicker untuk memilih gambar dari Galeri atau Kamera.
  static final ImagePicker _picker = ImagePicker();

  /// Mengambil foto profil dari galeri ponsel dan menyimpannya ke folder lokal internal aplikasi.
  static Future<String?> pickAndSaveProfilePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality:
            85, // Kompresi sedikit agar ukuran file tidak terlalu besar
      );

      if (image == null) return null;

      // Mendapatkan direktori penyimpanan dokumen internal aplikasi.
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_photo.jpg';
      final savedPath = '${appDir.path}/$fileName';

      // Menyalin (copy) file gambar yang dipilih ke direktori internal aplikasi.
      await File(image.path).copy(savedPath);

      // Mencatat path file ke SharedPreferences agar bisa dimuat kembali saat aplikasi dibuka lagi.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_path', savedPath);

      return savedPath;
    } catch (e) {
      throw Exception('Gagal menyimpan foto profil: $e');
    }
  }

  /// Mengambil path foto profil yang sebelumnya tersimpan di SharedPreferences.
  static Future<String?> getProfilePhotoPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('profile_photo_path');
    } catch (e) {
      throw Exception('Gagal mendapatkan path foto profil: $e');
    }
  }

  /// Menghapus file foto profil dari penyimpanan ponsel dan menghapus catatannya di SharedPreferences.
  static Future<void> deleteProfilePhoto() async {
    try {
      final photoPath = await getProfilePhotoPath();
      if (photoPath != null) {
        final file = File(photoPath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_photo_path');
    } catch (e) {
      throw Exception('Gagal menghapus foto profil: $e');
    }
  }

  /// Memilih foto untuk tujuan menabung (Goal) tertentu dan menyimpannya secara lokal.
  static Future<String?> pickAndSaveGoalPhoto(int goalId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'goal_$goalId.jpg';
      final savedPath = '${appDir.path}/$fileName';

      await File(image.path).copy(savedPath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('goal_image_$goalId', savedPath);

      return savedPath;
    } catch (e) {
      throw Exception('Gagal menyimpan foto goal: $e');
    }
  }

  /// Mengambil path foto goal berdasarkan ID goal yang diberikan.
  static Future<String?> getGoalPhotoPath(int goalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('goal_image_$goalId');
    } catch (e) {
      throw Exception('Gagal mendapatkan path foto goal: $e');
    }
  }

  /// Menghapus file foto goal tertentu dari penyimpanan lokal.
  static Future<void> deleteGoalPhoto(int goalId) async {
    try {
      final photoPath = await getGoalPhotoPath(goalId);
      if (photoPath != null) {
        final file = File(photoPath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('goal_image_$goalId');
    } catch (e) {
      throw Exception('Gagal menghapus foto goal: $e');
    }
  }

  /// Memindahkan file foto goal dari ID sementara ke ID permanen (digunakan saat sinkronisasi backend).
  static Future<void> moveGoalPhoto(int oldGoalId, int newGoalId) async {
    try {
      final oldPhotoPath = await getGoalPhotoPath(oldGoalId);
      debugPrint(
        '[PhotoService] Memindahkan foto dari goal_$oldGoalId ke goal_$newGoalId',
      );

      if (oldPhotoPath != null && File(oldPhotoPath).existsSync()) {
        final appDir = await getApplicationDocumentsDirectory();
        final newFileName = 'goal_$newGoalId.jpg';
        final newPath = '${appDir.path}/$newFileName';

        // Salin ke lokasi baru dan hapus lokasi lama
        await File(oldPhotoPath).copy(newPath);
        await File(oldPhotoPath).delete();

        // Update catatan di SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('goal_image_$oldGoalId');
        await prefs.setString('goal_image_$newGoalId', newPath);

        debugPrint(
          '[PhotoService] Berhasil memindahkan foto ke path baru: $newPath',
        );
      }
    } catch (e) {
      debugPrint('[PhotoService] Error saat memindahkan foto goal: $e');
      rethrow;
    }
  }

  /// Mengecek apakah file foto profil benar-benar ada di penyimpanan fisik ponsel.
  static Future<bool> profilePhotoExists() async {
    try {
      final photoPath = await getProfilePhotoPath();
      if (photoPath == null) return false;
      return await File(photoPath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Mengecek apakah file foto goal tertentu benar-benar ada di penyimpanan fisik ponsel.
  static Future<bool> goalPhotoExists(int goalId) async {
    try {
      final photoPath = await getGoalPhotoPath(goalId);
      if (photoPath == null) return false;
      return await File(photoPath).exists();
    } catch (e) {
      return false;
    }
  }
}
