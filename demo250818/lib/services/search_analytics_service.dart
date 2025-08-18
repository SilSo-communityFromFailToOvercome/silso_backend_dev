import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/search_analytics_model.dart';

class SearchAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Record a search query
  Future<void> recordSearch(String query) async {
    if (currentUserId == null) return;
    if (query.trim().isEmpty) return;

    final normalizedQuery = query.toLowerCase().trim();
    
    try {
      // Record individual search query
      await _recordIndividualSearch(normalizedQuery);
      
      // Update search analytics
      await _updateSearchAnalytics(normalizedQuery);
    } catch (e) {
      debugPrint('Error recording search: $e');
      // Don't throw error to avoid disrupting user experience
    }
  }

  // Record individual search for audit trail
  Future<void> _recordIndividualSearch(String normalizedQuery) async {
    final searchQuery = SearchQuery(
      queryId: '', // Will be set by Firestore
      query: normalizedQuery,
      userId: currentUserId!,
      searchedAt: DateTime.now(),
    );

    await _firestore
        .collection('search_queries')
        .add(searchQuery.toMap());
  }

  // Update aggregated search analytics
  Future<void> _updateSearchAnalytics(String normalizedQuery) async {
    final analyticsRef = _firestore
        .collection('search_analytics')
        .doc(normalizedQuery);

    await _firestore.runTransaction((transaction) async {
      final analyticsDoc = await transaction.get(analyticsRef);

      if (analyticsDoc.exists) {
        // Update existing analytics
        final currentData = analyticsDoc.data()!;
        final uniqueUsers = List<String>.from(currentData['uniqueUsers'] ?? []);
        
        // Add current user if not already in the list
        if (!uniqueUsers.contains(currentUserId)) {
          uniqueUsers.add(currentUserId!);
        }

        transaction.update(analyticsRef, {
          'searchCount': FieldValue.increment(1),
          'lastSearched': FieldValue.serverTimestamp(),
          'uniqueUsers': uniqueUsers,
          'uniqueUserCount': uniqueUsers.length,
        });
      } else {
        // Create new analytics entry
        final analytics = SearchAnalytics(
          query: normalizedQuery,
          searchCount: 1,
          lastSearched: DateTime.now(),
          uniqueUsers: [currentUserId!],
        );

        transaction.set(analyticsRef, analytics.toMap());
      }
    });
  }

  // Get most popular search query
  Future<PopularSearch?> getMostPopularSearch() async {
    try {
      final snapshot = await _firestore
          .collection('search_analytics')
          .orderBy('searchCount', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final analytics = SearchAnalytics.fromMap(snapshot.docs.first.data());
      return PopularSearch.fromAnalytics(analytics);
    } catch (e) {
      debugPrint('Error getting most popular search: $e');
      return null;
    }
  }

  // Get popular searches (alias for getTopPopularSearches)
  Future<List<PopularSearch>> getPopularSearches({int limit = 10}) async {
    return getTopPopularSearches(limit: limit);
  }

  // Get top popular searches
  Future<List<PopularSearch>> getTopPopularSearches({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('search_analytics')
          .orderBy('searchCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final analytics = SearchAnalytics.fromMap(doc.data());
        return PopularSearch.fromAnalytics(analytics);
      }).toList();
    } catch (e) {
      debugPrint('Error getting top popular searches: $e');
      return [];
    }
  }

  // Get trending searches (popular in last week)
  Future<List<PopularSearch>> getTrendingSearches({int limit = 5}) async {
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final snapshot = await _firestore
          .collection('search_analytics')
          .where('lastSearched', isGreaterThan: Timestamp.fromDate(weekAgo))
          .orderBy('lastSearched', descending: false) // Firebase requires this for compound queries
          .orderBy('searchCount', descending: true)
          .limit(limit)
          .get();

      final searches = snapshot.docs.map((doc) {
        final analytics = SearchAnalytics.fromMap(doc.data());
        return PopularSearch.fromAnalytics(analytics);
      }).toList();

      // Sort by search count in memory since Firestore has limitations
      searches.sort((a, b) => b.searchCount.compareTo(a.searchCount));
      
      return searches.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting trending searches: $e');
      // Fallback to regular popular searches
      return getTopPopularSearches(limit: limit);
    }
  }

  // Get user's search history analytics
  Future<List<SearchQuery>> getUserSearchHistory({int limit = 50}) async {
    if (currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('search_queries')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('searchedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return SearchQuery.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error getting user search history: $e');
      return [];
    }
  }

  // Get search statistics
  Future<Map<String, dynamic>> getSearchStatistics() async {
    try {
      final queriesSnapshot = await _firestore
          .collection('search_queries')
          .count()
          .get();

      final analyticsSnapshot = await _firestore
          .collection('search_analytics')
          .get();

      final uniqueQueries = analyticsSnapshot.docs.length;
      final totalSearches = queriesSnapshot.count;
      
      // Calculate unique users who have searched
      final uniqueUsers = <String>{};
      for (final doc in analyticsSnapshot.docs) {
        final users = List<String>.from(doc.data()['uniqueUsers'] ?? []);
        uniqueUsers.addAll(users);
      }

      return {
        'totalSearches': totalSearches,
        'uniqueQueries': uniqueQueries,
        'uniqueSearchers': uniqueUsers.length,
        'averageSearchesPerQuery': uniqueQueries > 0 ? (totalSearches! / uniqueQueries).round() : 0,
      };
    } catch (e) {
      debugPrint('Error getting search statistics: $e');
      return {
        'totalSearches': 0,
        'uniqueQueries': 0,
        'uniqueSearchers': 0,
        'averageSearchesPerQuery': 0,
      };
    }
  }

  // Clean up old search queries (for maintenance)
  Future<void> cleanupOldQueries({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      final snapshot = await _firestore
          .collection('search_queries')
          .where('searchedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Cleaned up ${snapshot.docs.length} old search queries');
    } catch (e) {
      debugPrint('Error cleaning up old queries: $e');
    }
  }
}