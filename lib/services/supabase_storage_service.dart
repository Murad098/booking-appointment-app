import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class SupabaseStorageService {
  static final SupabaseStorageService _instance = SupabaseStorageService._internal();
  factory SupabaseStorageService() => _instance;
  SupabaseStorageService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _profileBucketName = 'profile-images';
  static const String _serviceBucketName = 'business-services';
  static const String _paymentBucketName = 'payment-screenshots';

  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('[SupabaseStorageService] ❌ No Firebase user logged in');
        return null;
      }

      final userId = user.uid;
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final fileName = '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      print('[SupabaseStorageService] 📤 Uploading profile image: $fileName');

      await _supabase.storage.from(_profileBucketName).upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      final imageUrl = _supabase.storage.from(_profileBucketName).getPublicUrl(fileName);
      print('[SupabaseStorageService] ✅ Profile image URL: $imageUrl');

      return imageUrl;
    } catch (e) {
      print('[SupabaseStorageService] ❌ Profile upload failed: $e');
      return null;
    }
  }

  Future<String?> uploadServiceImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('[SupabaseStorageService] ❌ No Firebase user logged in');
        return null;
      }

      final userId = user.uid;
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${userId}_service_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      print('[SupabaseStorageService] 📤 Uploading service image: $fileName to bucket: $_serviceBucketName');

      await _supabase.storage.from(_serviceBucketName).upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      final imageUrl = _supabase.storage.from(_serviceBucketName).getPublicUrl(fileName);
      print('[SupabaseStorageService] ✅ Service image URL: $imageUrl');

      return imageUrl;
    } catch (e) {
      print('[SupabaseStorageService] ❌ Service image upload failed: $e');
      return null;
    }
  }

  // NEW: Upload payment screenshot
  Future<String?> uploadPaymentScreenshot(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('[SupabaseStorageService] ❌ No Firebase user logged in');
        return null;
      }

      final userId = user.uid;
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final fileName = '$userId/payment_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      print('[SupabaseStorageService] 📤 Uploading payment screenshot: $fileName to bucket: $_paymentBucketName');

      await _supabase.storage.from(_paymentBucketName).upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      final imageUrl = _supabase.storage.from(_paymentBucketName).getPublicUrl(fileName);
      print('[SupabaseStorageService] ✅ Payment screenshot URL: $imageUrl');

      return imageUrl;
    } catch (e) {
      print('[SupabaseStorageService] ❌ Payment screenshot upload failed: $e');
      return null;
    }
  }

  Future<void> deleteOldProfileImage(String oldImageUrl) async {
    try {
      if (oldImageUrl.isEmpty || !oldImageUrl.contains('supabase.co')) return;

      final uri = Uri.parse(oldImageUrl);
      final pathSegments = uri.pathSegments;

      String bucketName;
      if (oldImageUrl.contains(_profileBucketName)) {
        bucketName = _profileBucketName;
      } else if (oldImageUrl.contains(_serviceBucketName)) {
        bucketName = _serviceBucketName;
      } else if (oldImageUrl.contains(_paymentBucketName)) {
        bucketName = _paymentBucketName;
      } else {
        return;
      }

      final bucketIndex = pathSegments.indexOf(bucketName);
      if (bucketIndex == -1 || bucketIndex + 1 >= pathSegments.length) return;

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      print('[SupabaseStorageService] 🗑 Deleting old image: $filePath from bucket: $bucketName');

      await _supabase.storage.from(bucketName).remove([filePath]);
      print('[SupabaseStorageService] ✅ Old image deleted');
    } catch (e) {
      print('[SupabaseStorageService] ⚠️ Failed to delete old image: $e');
    }
  }

  String getProfileImageUrl(String filePath) {
    return _supabase.storage.from(_profileBucketName).getPublicUrl(filePath);
  }
}