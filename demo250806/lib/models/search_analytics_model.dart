import 'package:cloud_firestore/cloud_firestore.dart';

class SearchQuery {
  final String queryId;
  final String query;
  final String userId;
  final DateTime searchedAt;
  final String? userAgent;
  final String? ipAddress;

  SearchQuery({
    required this.queryId,
    required this.query,
    required this.userId,
    required this.searchedAt,
    this.userAgent,
    this.ipAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'query': query.toLowerCase().trim(), // Normalize for consistency
      'userId': userId,
      'searchedAt': Timestamp.fromDate(searchedAt),
      'userAgent': userAgent,
      'ipAddress': ipAddress,
    };
  }

  factory SearchQuery.fromMap(Map<String, dynamic> map, String documentId) {
    return SearchQuery(
      queryId: documentId,
      query: map['query'] ?? '',
      userId: map['userId'] ?? '',
      searchedAt: (map['searchedAt'] as Timestamp).toDate(),
      userAgent: map['userAgent'],
      ipAddress: map['ipAddress'],
    );
  }
}

class SearchAnalytics {
  final String query;
  final int searchCount;
  final DateTime lastSearched;
  final List<String> uniqueUsers;

  SearchAnalytics({
    required this.query,
    required this.searchCount,
    required this.lastSearched,
    required this.uniqueUsers,
  });

  Map<String, dynamic> toMap() {
    return {
      'query': query.toLowerCase().trim(),
      'searchCount': searchCount,
      'lastSearched': Timestamp.fromDate(lastSearched),
      'uniqueUsers': uniqueUsers,
      'uniqueUserCount': uniqueUsers.length,
    };
  }

  factory SearchAnalytics.fromMap(Map<String, dynamic> map) {
    return SearchAnalytics(
      query: map['query'] ?? '',
      searchCount: map['searchCount'] ?? 0,
      lastSearched: (map['lastSearched'] as Timestamp).toDate(),
      uniqueUsers: List<String>.from(map['uniqueUsers'] ?? []),
    );
  }
}

class PopularSearch {
  final String query;
  final int searchCount;
  final int uniqueUserCount;
  final DateTime lastSearched;

  PopularSearch({
    required this.query,
    required this.searchCount,
    required this.uniqueUserCount,
    required this.lastSearched,
  });

  factory PopularSearch.fromAnalytics(SearchAnalytics analytics) {
    return PopularSearch(
      query: analytics.query,
      searchCount: analytics.searchCount,
      uniqueUserCount: analytics.uniqueUsers.length,
      lastSearched: analytics.lastSearched,
    );
  }
}