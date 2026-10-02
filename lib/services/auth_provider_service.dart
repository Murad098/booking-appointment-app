import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Stores and retrieves the auth provider used to create each account.
///
/// Collection: `user_providers`
/// Document ID: the user's email address (lowercased)
/// Fields:
///   - provider: 'password' | 'google'
class AuthProviderService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'user_providers';

  /// Saves the provider for an email.
  /// Returns true if saved successfully, false if Firestore was unreachable.
  /// Never throws — the calling flow must never be broken by this.
  static Future<bool> saveProvider(String email, String provider) async {
    try {
      await _db
          .collection(_collection)
          .doc(email.toLowerCase().trim())
          .set({'provider': provider}, SetOptions(merge: true)); // Use merge to be safe
      print('[AuthProviderService] ✅ Provider saved: $email → $provider');
      return true;
    } catch (e) {
      // Print the full error so you can see the exact Firestore issue
      // in your debug console (e.g. missing google-services.json config,
      // Firestore not initialized, etc.)
      print('[AuthProviderService] ❌ saveProvider failed for $email: $e');
      return false;
    }
  }

  /// Returns the stored provider ('password' or 'google'), or null if
  /// no record exists (truly new user) or Firestore is unreachable.
  ///
  /// Fallback: if Firestore has no record, checks the currently
  /// signed-in Firebase Auth user's providerData — handles the case
  /// where a previous saveProvider call failed silently.
  static Future<String?> getProvider(String email) async {
    // ── Step 1: Try Firestore first ──
    try {
      final doc = await _db
          .collection(_collection)
          .doc(email.toLowerCase().trim())
          .get();

      if (doc.exists) {
        final provider = doc.data()?['provider'] as String?;
        print('[AuthProviderService] ✅ Provider fetched: $email → $provider');
        return provider;
      } else {
        print('[AuthProviderService] ℹ️ No Firestore record for: $email');
      }
    } catch (e) {
      print('[AuthProviderService] ❌ getProvider Firestore failed for $email: $e');
    }

    // ── Step 2: Firestore had no record — fall back to Firebase Auth providerData ──
    // This handles accounts whose saveProvider call failed previously.
    // NOTE: This only works if the user is CURRENTLY signed in.
    // For pre-checks during login/signup, the user might not be signed in yet,
    // so this fallback might return null even if the account exists in Auth.
    // This is acceptable because if they are not signed in, we can't check providerData easily
    // without signing them in first (which creates a chicken-and-egg problem).
    // So for pre-checks, we rely primarily on Firestore.

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null &&
          currentUser.email?.toLowerCase().trim() == email.toLowerCase().trim()) {
        final providerIds =
        currentUser.providerData.map((p) => p.providerId).toList();
        print('[AuthProviderService] ℹ️ Auth providerData for $email: $providerIds');

        String? detectedProvider;
        if (providerIds.contains('password')) {
          detectedProvider = 'password';
        } else if (providerIds.contains('google.com')) {
          detectedProvider = 'google';
        }

        if (detectedProvider != null) {
          // Heal the missing Firestore record for next time (fire-and-forget)
          await saveProvider(email, detectedProvider);
          return detectedProvider;
        }
      }
    } catch (e) {
      print('[AuthProviderService] ❌ Auth fallback failed for $email: $e');
    }

    return null;
  }
}