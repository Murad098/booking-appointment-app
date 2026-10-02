// lib/services/chat_supabase_storage_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';

class ChatSupabaseStorageService {
  static final ChatSupabaseStorageService _instance = ChatSupabaseStorageService._internal();
  factory ChatSupabaseStorageService() => _instance;
  ChatSupabaseStorageService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _chatImagesBucket = 'chat-images';
  static const String _chatVideosBucket = 'chat-videos';
  static const String _chatVoiceBucket = 'chat-voice';
  static const String _chatFilesBucket = 'chat-files'; // Added this

  Future<String?> uploadChatImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await _supabase.storage.from(_chatImagesBucket).upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      return _supabase.storage.from(_chatImagesBucket).getPublicUrl(fileName);
    } catch (e) {
      print('[ChatStorage] Image upload failed: $e');
      return null;
    }
  }

  Future<String?> uploadChatVideo(File videoFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final fileExtension = videoFile.path.split('.').last.toLowerCase();
      final fileName = '${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await _supabase.storage.from(_chatVideosBucket).upload(
        fileName,
        videoFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      return _supabase.storage.from(_chatVideosBucket).getPublicUrl(fileName);
    } catch (e) {
      print('[ChatStorage] Video upload failed: $e');
      return null;
    }
  }

  Future<String?> uploadChatFile(File file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final fileExtension = file.path.split('.').last.toLowerCase();
      final fileName = '${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await _supabase.storage.from(_chatFilesBucket).upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      return _supabase.storage.from(_chatFilesBucket).getPublicUrl(fileName);
    } catch (e) {
      print('[ChatStorage] File upload failed: $e');
      return null;
    }
  }

  Future<String?> uploadVoiceMessage(File voiceFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final fileName = '${user.uid}/${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _supabase.storage.from(_chatVoiceBucket).upload(
        fileName,
        voiceFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      return _supabase.storage.from(_chatVoiceBucket).getPublicUrl(fileName);
    } catch (e) {
      print('[ChatStorage] Voice upload failed: $e');
      return null;
    }
  }

  Future<void> deleteChatFile(String url) async {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      if (segments.length >= 3) {
        final bucket = segments[segments.length - 2];
        final filePath = segments.sublist(segments.length - 1).join('/');

        await _supabase.storage.from(bucket).remove([filePath]);
      }
    } catch (e) {
      print('[ChatStorage] Delete failed: $e');
    }
  }
}