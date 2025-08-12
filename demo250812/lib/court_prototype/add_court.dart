import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/court_service.dart';

// Add new court session page
class AddCourtScreen extends StatefulWidget {
  const AddCourtScreen({super.key});

  @override
  State<AddCourtScreen> createState() => _AddCourtScreenState();
}

class _AddCourtScreenState extends State<AddCourtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final CourtService _courtService = CourtService();
  
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive design calculations
    const double baseWidth = 393.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final double widthRatio = screenWidth / baseWidth;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        title: Text(
          'Create Court Session',
          style: TextStyle(
            fontSize: 20 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF121212)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24 * widthRatio),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      Text(
                        'Court Title',
                        style: TextStyle(
                          fontSize: 16 * widthRatio,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF121212),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(height: 8 * widthRatio),
                      TextFormField(
                        controller: _titleController,
                        maxLength: 100,
                        decoration: InputDecoration(
                          hintText: 'Enter the debate topic or question...',
                          hintStyle: TextStyle(
                            fontSize: 16 * widthRatio,
                            color: const Color(0xFF8E8E8E),
                            fontFamily: 'Pretendard',
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * widthRatio),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * widthRatio),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * widthRatio),
                            borderSide: const BorderSide(
                              color: Color(0xFF5F37CF),
                              width: 2,
                            ),
                          ),
                          counterStyle: TextStyle(
                            fontSize: 12 * widthRatio,
                            color: const Color(0xFF8E8E8E),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16 * widthRatio,
                          color: const Color(0xFF121212),
                          fontFamily: 'Pretendard',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a court title';
                          }
                          if (value.trim().length < 5) {
                            return 'Title must be at least 5 characters long';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 24 * widthRatio),
                      
                      // Description field
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16 * widthRatio,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF121212),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(height: 8 * widthRatio),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: 'Provide more details about the topic, context, or specific points to consider...',
                          hintStyle: TextStyle(
                            fontSize: 16 * widthRatio,
                            color: const Color(0xFF8E8E8E),
                            fontFamily: 'Pretendard',
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * widthRatio),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * widthRatio),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12 * widthRatio),
                            borderSide: const BorderSide(
                              color: Color(0xFF5F37CF),
                              width: 2,
                            ),
                          ),
                          counterStyle: TextStyle(
                            fontSize: 12 * widthRatio,
                            color: const Color(0xFF8E8E8E),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16 * widthRatio,
                          color: const Color(0xFF121212),
                          fontFamily: 'Pretendard',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          if (value.trim().length < 10) {
                            return 'Description must be at least 10 characters long';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 32 * widthRatio),
                      
                      // Info card
                      Container(
                        padding: EdgeInsets.all(16 * widthRatio),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5F37CF).withOpacity( 0.1),
                          borderRadius: BorderRadius.circular(12 * widthRatio),
                          border: Border.all(
                            color: const Color(0xFF5F37CF).withOpacity( 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: const Color(0xFF5F37CF),
                                  size: 20 * widthRatio,
                                ),
                                SizedBox(width: 8 * widthRatio),
                                Text(
                                  'Court Session Details',
                                  style: TextStyle(
                                    fontSize: 14 * widthRatio,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF5F37CF),
                                    fontFamily: 'Pretendard',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8 * widthRatio),
                            Text(
                              '• Session duration: 2 hours\n• Participants can vote "Guilty" or "Not Guilty"\n• Results are determined by majority vote\n• Session ends automatically when time expires',
                              style: TextStyle(
                                fontSize: 12 * widthRatio,
                                color: const Color(0xFF5F37CF),
                                fontFamily: 'Pretendard',
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Create button
              Padding(
                padding: EdgeInsets.all(24 * widthRatio),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _createCourtSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F37CF),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16 * widthRatio),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * widthRatio),
                      ),
                      elevation: 2,
                    ),
                    child: _isCreating
                        ? SizedBox(
                            height: 20 * widthRatio,
                            width: 20 * widthRatio,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Create Court Session',
                            style: TextStyle(
                              fontSize: 16 * widthRatio,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Create court session with all database fields
  Future<void> _createCourtSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Create court session using Firestore service
      final courtId = await _courtService.createCourtSession(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: 'General', // Default category, can be enhanced later
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Court session created successfully! ID: ${courtId.substring(0, 8)}...',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Navigate back to court list
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create court session: ${e.toString()}',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

}

// Data model for court session with all database fields
class CourtSessionData {
  final String id;
  final String title;
  final String description;
  final DateTime dateCreated;
  final int currentLiveMembers;
  final int guiltyVotes;
  final int notGuiltyVotes;
  final String? resultWin; // 'guilty', 'not_guilty', or null
  final int sessionDurationMinutes; // Session duration in minutes
  final DateTime? dateEnded;
  final String category;
  final String creatorId;
  final bool isLive;
  final List<String> participants;

  const CourtSessionData({
    required this.id,
    required this.title,
    required this.description,
    required this.dateCreated,
    required this.currentLiveMembers,
    required this.guiltyVotes,
    required this.notGuiltyVotes,
    this.resultWin,
    required this.sessionDurationMinutes,
    this.dateEnded,
    required this.category,
    required this.creatorId,
    required this.isLive,
    required this.participants,
  });

  // Calculate time left dynamically based on current time
  Duration get timeLeft {
    if (!isLive || dateEnded != null) return Duration.zero;
    
    final now = DateTime.now();
    final sessionEnd = dateCreated.add(Duration(minutes: sessionDurationMinutes));
    final remaining = sessionEnd.difference(now);
    
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dateCreated': dateCreated.toIso8601String(),
      'currentLiveMembers': currentLiveMembers,
      'guiltyVotes': guiltyVotes,
      'notGuiltyVotes': notGuiltyVotes,
      'resultWin': resultWin,
      'sessionDurationMinutes': sessionDurationMinutes,
      'dateEnded': dateEnded?.toIso8601String(),
      'category': category,
      'creatorId': creatorId,
      'isLive': isLive,
      'participants': participants,
    };
  }

  // Create from Firestore document
  factory CourtSessionData.fromFirestore(String documentId, Map<String, dynamic> data) {
    return CourtSessionData(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dateCreated: data['dateCreated'] is Timestamp 
          ? (data['dateCreated'] as Timestamp).toDate()
          : DateTime.parse(data['dateCreated'] ?? DateTime.now().toIso8601String()),
      currentLiveMembers: data['currentLiveMembers'] ?? 0,
      guiltyVotes: data['guiltyVotes'] ?? 0,
      notGuiltyVotes: data['notGuiltyVotes'] ?? 0,
      resultWin: data['resultWin'],
      sessionDurationMinutes: data['sessionDurationMinutes'] ?? 2, // Default 2 minutes
      dateEnded: data['dateEnded'] != null 
          ? (data['dateEnded'] is Timestamp 
              ? (data['dateEnded'] as Timestamp).toDate()
              : DateTime.parse(data['dateEnded']))
          : null,
      category: data['category'] ?? 'General',
      creatorId: data['creatorId'] ?? '',
      isLive: data['isLive'] ?? false,
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  // Create from database map (backwards compatibility)
  factory CourtSessionData.fromMap(String documentId, Map<String, dynamic> map) {
    return CourtSessionData(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dateCreated: DateTime.parse(map['dateCreated']),
      currentLiveMembers: map['currentLiveMembers'] ?? 0,
      guiltyVotes: map['guiltyVotes'] ?? 0,
      notGuiltyVotes: map['notGuiltyVotes'] ?? 0,
      resultWin: map['resultWin'],
      sessionDurationMinutes: map['sessionDurationMinutes'] ?? 2,
      dateEnded: map['dateEnded'] != null ? DateTime.parse(map['dateEnded']) : null,
      category: map['category'] ?? 'General',
      creatorId: map['creatorId'] ?? '',
      isLive: map['isLive'] ?? false,
      participants: List<String>.from(map['participants'] ?? []),
    );
  }

  // Copy with method for updates
  CourtSessionData copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateCreated,
    int? currentLiveMembers,
    int? guiltyVotes,
    int? notGuiltyVotes,
    String? resultWin,
    int? sessionDurationMinutes,
    DateTime? dateEnded,
    String? category,
    String? creatorId,
    bool? isLive,
    List<String>? participants,
  }) {
    return CourtSessionData(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateCreated: dateCreated ?? this.dateCreated,
      currentLiveMembers: currentLiveMembers ?? this.currentLiveMembers,
      guiltyVotes: guiltyVotes ?? this.guiltyVotes,
      notGuiltyVotes: notGuiltyVotes ?? this.notGuiltyVotes,
      resultWin: resultWin ?? this.resultWin,
      sessionDurationMinutes: sessionDurationMinutes ?? this.sessionDurationMinutes,
      dateEnded: dateEnded ?? this.dateEnded,
      category: category ?? this.category,
      creatorId: creatorId ?? this.creatorId,
      isLive: isLive ?? this.isLive,
      participants: participants ?? this.participants,
    );
  }
}