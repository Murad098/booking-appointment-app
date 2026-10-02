import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles saving user data to Firestore
class UserService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'users';
  static const String _businessCollection = 'businesses';

  /// Saves user's name and email to Firestore
  /// Uses the user's UID as the document ID for better security
  static Future<bool> saveUserData(String uid, String name, String email) async {
    try {
      await _db.collection(_collection).doc(uid).set({
        'name': name.trim(),
        'email': email.toLowerCase().trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('[UserService] ✅ User data saved: $uid - $name - $email');
      return true;
    } catch (e) {
      print('[UserService] ❌ saveUserData failed for $uid: $e');
      return false;
    }
  }

  /// Saves user's account type/role to Firestore
  static Future<bool> saveUserRole(String uid, String role) async {
    try {
      await _db.collection(_collection).doc(uid).set({
        'role': role.toLowerCase().trim(),
        'roleUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('[UserService] ✅ User role saved: $uid - $role');
      return true;
    } catch (e) {
      print('[UserService] ❌ saveUserRole failed for $uid: $e');
      return false;
    }
  }

  /// Retrieves user's role/account type from Firestore.
  /// If not found in 'users', checks if the user is a branch manager (via 'branches' collection).
  static Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _db.collection(_collection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final role = doc.data()?['role'] as String?;
        if (role != null && role.isNotEmpty) {
          print('[UserService] ✅ User role fetched: $uid - $role');
          return role;
        }
      }
    } catch (e) {
      print('[UserService] ❌ getUserRole failed for $uid: $e');
    }

    // Fallback: check if the user is a branch manager
    try {
      final query = await _db
          .collection('branches')
          .where('branchManagerId', isEqualTo: uid)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        print('[UserService] ✅ User is branch manager, returning role: business');
        return 'business';
      }
    } catch (e) {
      print('[UserService] ❌ getUserRole (branches) failed for $uid: $e');
    }

    return null;
  }

  /// Saves business profile data to Firestore in 'businesses' collection
  static Future<bool> saveBusinessProfile(String userId, Map<String, dynamic> businessData) async {
    try {
      // Create a unique business ID or use user ID as document ID
      final businessId = userId;

      await _db.collection(_businessCollection).doc(businessId).set({
        'userId': userId,
        'businessName': businessData['basicInfo']['businessName'],
        'category': businessData['basicInfo']['category'],
        'description': businessData['basicInfo']['description'],
        'email': businessData['basicInfo']['email'],
        'phoneNumber': businessData['basicInfo']['phoneNumber'],
        'address': businessData['basicInfo']['address'],
        'city': businessData['basicInfo']['city'], // Added city field
        'operatingHours': businessData['operatingHours'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));

      // Also update user document to mark business profile as completed
      await _db.collection(_collection).doc(userId).set({
        'businessProfileCompleted': true,
        'businessProfileUpdatedAt': FieldValue.serverTimestamp(),
        'businessId': businessId,
      }, SetOptions(merge: true));

      print('[UserService] ✅ Business profile saved for user: $userId in businesses collection');
      return true;
    } catch (e) {
      print('[UserService] ❌ saveBusinessProfile failed for $userId: $e');
      return false;
    }
  }

  /// Checks if business profile is completed
  static Future<bool> isBusinessProfileCompleted(String uid) async {
    try {
      final doc = await _db.collection(_collection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final isCompleted = doc.data()?['businessProfileCompleted'] as bool? ?? false;
        print('[UserService] ✅ Business profile completion check: $uid - $isCompleted');
        return isCompleted;
      }
    } catch (e) {
      print('[UserService] ❌ isBusinessProfileCompleted failed for $uid: $e');
    }
    return false;
  }

  /// Retrieves business profile data from 'businesses' collection
  static Future<Map<String, dynamic>?> getBusinessProfile(String userId) async {
    try {
      final doc = await _db.collection(_businessCollection).doc(userId).get();
      if (doc.exists && doc.data() != null) {
        print('[UserService] ✅ Business profile fetched for user: $userId');
        // Get the currently signed-in user
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // `true` forces a refresh, ensuring you get a valid, non-expired token
          final idToken = await user.getIdToken(true);
          print('✅ FIREBASE ID TOKEN: $idToken');
        } else {
          print('No user is signed in.');
        }
        return doc.data();
      }
    } catch (e) {
      print('[UserService] ❌ getBusinessProfile failed for $userId: $e');
    }
    return null;
  }

  /// Checks if user has a role set
  static Future<bool> hasUserRole(String uid) async {
    final role = await getUserRole(uid);
    return role != null && role.isNotEmpty;
  }

  /// Updates existing user data (if needed in future)
  static Future<bool> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection(_collection).doc(uid).update(data);
      print('[UserService] ✅ User data updated: $uid');
      return true;
    } catch (e) {
      print('[UserService] ❌ updateUserData failed for $uid: $e');
      return false;
    }
  }

  /// Updates user profile with image URL
  static Future<bool> updateProfileImage(String uid, String imageUrl) async {
    try {
      await _db.collection(_collection).doc(uid).set({
        'profileImage': imageUrl,
        'profileImageUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('[UserService] ✅ Profile image updated for: $uid');
      return true;
    } catch (e) {
      print('[UserService] ❌ updateProfileImage failed for $uid: $e');
      return false;
    }
  }

  /// Retrieves user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _db.collection(_collection).doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print('[UserService] ❌ getUserData failed for $uid: $e');
    }
    return null;
  }

  /// Updates profile image directly in the businesses collection
  static Future<bool> updateBusinessProfileImage(String userId, String imageUrl) async {
    try {
      await _db.collection(_businessCollection).doc(userId).set({
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('[UserService] ✅ Business profile image updated for: $userId');
      return true;
    } catch (e) {
      print('[UserService] ❌ updateBusinessProfileImage failed for $userId: $e');
      return false;
    }
  }

  /// Get user's push notification preference
  static Future<bool> getPushNotificationPreference(String uid) async {
    try {
      final doc = await _db.collection(_collection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final enabled = doc.data()?['pushNotificationsEnabled'] as bool?;
        return enabled ?? true; // Default to enabled if not set
      }
      return true;
    } catch (e) {
      print('[UserService] ❌ getPushNotificationPreference failed for $uid: $e');
      return true;
    }
  }

  /// Update user's push notification preference
  static Future<bool> updatePushNotificationPreference(String uid, bool enabled) async {
    try {
      await _db.collection(_collection).doc(uid).set({
        'pushNotificationsEnabled': enabled,
        'pushNotificationsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('[UserService] ✅ Push notification preference updated: $uid - enabled: $enabled');
      return true;
    } catch (e) {
      print('[UserService] ❌ updatePushNotificationPreference failed for $uid: $e');
      return false;
    }
  }

  /// Updates business services in the businesses collection
  static Future<bool> updateBusinessServices(String userId, List<dynamic> services) async {
    try {
      await _db.collection(_businessCollection).doc(userId).set({
        'services': services,
        'servicesUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('[UserService] ✅ Business services updated for: $userId');
      return true;
    } catch (e) {
      print('[UserService] ❌ updateBusinessServices failed for $userId: $e');
      return false;
    }
  }

  /// Updates business payment methods in the businesses collection
  static Future<bool> updateBusinessPaymentMethods(String userId, List<dynamic> paymentMethods) async {
    try {
      await _db.collection(_businessCollection).doc(userId).set({
        'paymentMethods': paymentMethods,
        'paymentMethodsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('[UserService] ✅ Business payment methods updated for: $userId');
      print('[UserService] Payment methods count: ${paymentMethods.length}');
      return true;
    } catch (e) {
      print('[UserService] ❌ updateBusinessPaymentMethods failed for $userId: $e');
      return false;
    }
  }

  /// Updates business Stripe account ID
  static Future<bool> updateBusinessStripeAccount(String businessId, String stripeAccountId) async {
    try {
      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .update({
        'stripeAccountId': stripeAccountId,
        'stripeAccountStatus': 'pending',
        'stripeAccountCreatedAt': FieldValue.serverTimestamp(),
      });

      print('[UserService] ✅ Business Stripe account updated: $businessId');
      return true;
    } catch (e) {
      print('[UserService] ❌ updateBusinessStripeAccount failed for $businessId: $e');
      return false;
    }
  }

  /// Updates business Stripe account status
  static Future<bool> updateBusinessStripeAccountStatus(String businessId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .update({
        'stripeAccountStatus': status,
        'stripeAccountStatusUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('[UserService] ✅ Business Stripe account status updated: $businessId -> $status');
      return true;
    } catch (e) {
      print('[UserService] ❌ updateBusinessStripeAccountStatus failed for $businessId: $e');
      return false;
    }
  }
// Add to UserService class
  static Future<void> updateBusinessStripeCountry(String businessId, String country) async {
    try {
      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .update({'stripeCountry': country});
    } catch (e) {
      print('Error updating Stripe country: $e');
      rethrow;
    }
  }

  /// Gets Stripe account status for a business
  static Future<Map<String, dynamic>?> getStripeAccountStatus(String businessId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .get();

      if (doc.exists) {
        return {
          'stripeAccountId': doc.data()?['stripeAccountId'],
          'stripeAccountStatus': doc.data()?['stripeAccountStatus'],
          'stripeChargesEnabled': doc.data()?['stripeChargesEnabled'] ?? false,
          'stripePayoutsEnabled': doc.data()?['stripePayoutsEnabled'] ?? false,
          'stripeDetailsSubmitted': doc.data()?['stripeDetailsSubmitted'] ?? false,
        };
      }
      return null;
    } catch (e) {
      print('[UserService] ❌ getStripeAccountStatus failed for $businessId: $e');
      return null;
    }
  }

  /// Checks if business has Stripe connected and enabled
  static Future<bool> hasStripeConnected(String businessId) async {
    final status = await getStripeAccountStatus(businessId);
    return status != null &&
        status['stripeAccountStatus'] == 'enabled' &&
        status['stripeChargesEnabled'] == true;
  }

  /// Sets the branch flag for a user (true = branch manager)
  static Future<bool> setBranchStatus(String uid, bool isBranch) async {
    try {
      await _db.collection(_collection).doc(uid).set({
        'branch': isBranch,
        'branchUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('[UserService] ✅ Branch status set: $uid -> $isBranch');
      return true;
    } catch (e) {
      print('[UserService] ❌ setBranchStatus failed: $e');
      return false;
    }
  }

  /// Checks if a user is a branch manager.
  /// First checks 'users' collection for explicit 'branch' flag,
  /// then falls back to checking 'branches' collection.
  static Future<bool> isBranchUser(String uid) async {
    // 1. Check users collection
    try {
      final doc = await _db.collection(_collection).doc(uid).get();
      if (doc.exists) {
        final isBranch = doc.data()?['branch'] as bool? ?? false;
        if (isBranch) return true;
      }
    } catch (e) {
      print('[UserService] ❌ isBranchUser (users) failed: $e');
    }

    // 2. Check branches collection
    try {
      final query = await _db
          .collection('branches')
          .where('branchManagerId', isEqualTo: uid)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        print('[UserService] ✅ isBranchUser found in branches: $uid');
        return true;
      }
    } catch (e) {
      print('[UserService] ❌ isBranchUser (branches) failed: $e');
    }
    return false;
  }


  // Add these methods to your UserService class

// Update business country
  static Future<void> updateBusinessCountry(String businessId, String country) async {
    try {
      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .update({'country': country});
    } catch (e) {
      print('Error updating business country: $e');
      rethrow;
    }
  }

// Update Stripe charges enabled
  static Future<void> updateBusinessStripeChargesEnabled(String businessId, bool enabled) async {
    try {
      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .update({'stripeChargesEnabled': enabled});
    } catch (e) {
      print('Error updating Stripe charges enabled: $e');
      rethrow;
    }
  }

// Update Stripe payouts enabled
  static Future<void> updateBusinessStripePayoutsEnabled(String businessId, bool enabled) async {
    try {
      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .update({'stripePayoutsEnabled': enabled});
    } catch (e) {
      print('Error updating Stripe payouts enabled: $e');
      rethrow;
    }
  }

// Update Stripe details submitted
  static Future<void> updateBusinessStripeDetailsSubmitted(String businessId, bool submitted) async {
    try {
      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .update({'stripeDetailsSubmitted': submitted});
    } catch (e) {
      print('Error updating Stripe details submitted: $e');
      rethrow;
    }
  }
}