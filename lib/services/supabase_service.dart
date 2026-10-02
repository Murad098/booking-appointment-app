import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String projectUrl = 'https://xzwglkpjazvzajzlamlf.supabase.co';
  static const String anonKey = 'sb_publishable_Xkoq6bNysg3df-GUa_vAJg_Exnx5if_';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: projectUrl,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}