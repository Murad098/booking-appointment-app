import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class BusinessRatingController extends GetxController {
  final ratingsCache = <String, Map<String, dynamic>>{}.obs; // businessId -> { avg, count, dist }

  Future<Map<String, dynamic>> getBusinessRatings(String businessId) async {
    // Return cached data if available
    if (ratingsCache.containsKey(businessId)) {
      return ratingsCache[businessId]!;
    }

    try {
      // 1. Get all services for this business
      final businessDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .get();

      if (!businessDoc.exists) {
        final emptyResult = {'average': 0.0, 'count': 0, 'distribution': {}};
        ratingsCache[businessId] = emptyResult;
        return emptyResult;
      }

      final data = businessDoc.data() as Map<String, dynamic>;
      final servicesList = data['services'] as List<dynamic>? ?? [];
      final List<String> serviceIds = servicesList.map((s) => s['id'] as String).toList();

      if (serviceIds.isEmpty) {
        final emptyResult = {'average': 0.0, 'count': 0, 'distribution': {}};
        ratingsCache[businessId] = emptyResult;
        return emptyResult;
      }

      // 2. Fetch all reviews for these services (handle Firestore 'in' query limit of 10)
      List<QueryDocumentSnapshot> allReviews = [];
      for (int i = 0; i < serviceIds.length; i += 10) {
        final end = (i + 10) < serviceIds.length ? i + 10 : serviceIds.length;
        final batchIds = serviceIds.sublist(i, end);
        final querySnapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .where('serviceId', whereIn: batchIds)
            .get();
        allReviews.addAll(querySnapshot.docs);
      }

      if (allReviews.isEmpty) {
        final emptyResult = {'average': 0.0, 'count': 0, 'distribution': {}};
        ratingsCache[businessId] = emptyResult;
        return emptyResult;
      }

      // 3. Calculate stats
      int sumRatings = 0;
      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final doc in allReviews) {
        final rating = doc['rating'] as int? ?? 0;
        if (rating >= 1 && rating <= 5) {
          sumRatings += rating;
          distribution[rating] = (distribution[rating] ?? 0) + 1;
        }
      }

      final double avgRating = sumRatings / allReviews.length;
      final result = {
        'average': avgRating,
        'count': allReviews.length,
        'distribution': distribution,
      };

      ratingsCache[businessId] = result;
      return result;

    } catch (e) {
      print('Error fetching ratings for $businessId: $e');
      final emptyResult = {'average': 0.0, 'count': 0, 'distribution': {}};
      ratingsCache[businessId] = emptyResult;
      return emptyResult;
    }
  }

  void clearCache() {
    ratingsCache.clear();
  }
}