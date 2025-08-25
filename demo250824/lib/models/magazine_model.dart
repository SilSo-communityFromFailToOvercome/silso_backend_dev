import 'package:cloud_firestore/cloud_firestore.dart';

class MagazinePost {
  final String postId;
  final String? title;
  final String? subtitle;
  final String color; // Hex color as string
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final int order; // Display order
  final bool isActive;

  MagazinePost({
    required this.postId,
    this.title,
    this.subtitle,
    required this.color,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.order,
    this.isActive = true,
  });

  // Create from Firestore document
  factory MagazinePost.fromMap(Map<String, dynamic> data, String documentId) {
    return MagazinePost(
      postId: documentId,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      color: data['color'] ?? '0xFF7C3AED',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'color': color,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'order': order,
      'isActive': isActive,
    };
  }

  // Copy with new values
  MagazinePost copyWith({
    String? postId,
    String? title,
    String? subtitle,
    String? color,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    int? order,
    bool? isActive,
  }) {
    return MagazinePost(
      postId: postId ?? this.postId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      color: color ?? this.color,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }

  // Get primary image (first image or null)
  String? get primaryImageUrl {
    return imageUrls.isNotEmpty ? imageUrls.first : null;
  }

  // Check if post has images
  bool get hasImages {
    return imageUrls.isNotEmpty;
  }

  // Get color as Color object
  int get colorValue {
    try {
      return int.parse(color);
    } catch (e) {
      return 0xFF7C3AED; // Default purple
    }
  }
}

// Request model for creating magazine posts
class CreateMagazinePostRequest {
  final String? title;
  final String? subtitle;
  final String color;
  final int? order;

  CreateMagazinePostRequest({
    this.title,
    this.subtitle,
    this.color = '0xFF7C3AED', // Default color
    this.order,
  });

  Map<String, dynamic> toMap(String userId) {
    return {
      'title': title,
      'subtitle': subtitle,
      'color': color,
      'imageUrls': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': userId,
      'order': order ?? 0,
      'isActive': true,
    };
  }
}

// Request model for updating magazine posts
class UpdateMagazinePostRequest {
  final String? title;
  final String? subtitle;
  final String? color;
  final List<String>? imageUrls;
  final int? order;
  final bool? isActive;

  UpdateMagazinePostRequest({
    this.title,
    this.subtitle,
    this.color,
    this.imageUrls,
    this.order,
    this.isActive,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (title != null) data['title'] = title;
    if (subtitle != null) data['subtitle'] = subtitle;
    if (color != null) data['color'] = color;
    if (imageUrls != null) data['imageUrls'] = imageUrls;
    if (order != null) data['order'] = order;
    if (isActive != null) data['isActive'] = isActive;

    return data;
  }
}