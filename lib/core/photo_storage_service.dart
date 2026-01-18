import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoStorageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick and save profile photo to local storage
  static Future<String?> pickAndSaveProfilePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_photo.jpg';
      final savedPath = '${appDir.path}/$fileName';

      // Copy image to app directory
      await File(image.path).copy(savedPath);

      // Save path to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_path', savedPath);

      return savedPath;
    } catch (e) {
      throw Exception('Gagal menyimpan foto: $e');
    }
  }

  /// Get profile photo path from SharedPreferences
  static Future<String?> getProfilePhotoPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('profile_photo_path');
    } catch (e) {
      throw Exception('Gagal mendapatkan foto: $e');
    }
  }

  /// Delete profile photo
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
      throw Exception('Gagal menghapus foto: $e');
    }
  }

  /// Pick and save goal photo
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

  /// Get goal photo path
  static Future<String?> getGoalPhotoPath(int goalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('goal_image_$goalId');
    } catch (e) {
      throw Exception('Gagal mendapatkan foto goal: $e');
    }
  }

  /// Delete goal photo
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

  /// Move goal photo from old ID to new ID
  static Future<void> moveGoalPhoto(int oldGoalId, int newGoalId) async {
    try {
      final oldPhotoPath = await getGoalPhotoPath(oldGoalId);
      print(
        '[PhotoService] Moving photo from goal_$oldGoalId to goal_$newGoalId',
      );
      print('[PhotoService] Old photo path: $oldPhotoPath');

      if (oldPhotoPath != null && File(oldPhotoPath).existsSync()) {
        final appDir = await getApplicationDocumentsDirectory();
        final newFileName = 'goal_$newGoalId.jpg';
        final newPath = '${appDir.path}/$newFileName';

        print('[PhotoService] Copying from $oldPhotoPath to $newPath');
        await File(oldPhotoPath).copy(newPath);
        print('[PhotoService] Copy successful');

        print('[PhotoService] Deleting old file');
        await File(oldPhotoPath).delete();
        print('[PhotoService] Old file deleted');

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('goal_image_$oldGoalId');
        await prefs.setString('goal_image_$newGoalId', newPath);
        print(
          '[PhotoService] SharedPreferences updated: goal_image_$newGoalId = $newPath',
        );
      } else {
        print('[PhotoService] Old photo not found or path is null');
      }
    } catch (e) {
      print('[PhotoService] Error moving goal photo: $e');
      rethrow;
    }
  }

  /// Check if profile photo exists
  static Future<bool> profilePhotoExists() async {
    try {
      final photoPath = await getProfilePhotoPath();
      if (photoPath == null) return false;
      return await File(photoPath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Check if goal photo exists
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
