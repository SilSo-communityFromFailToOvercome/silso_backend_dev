# Firebase Blocking System Implementation

This document explains how the blocking system works and how to integrate it throughout the app.

## Architecture Overview

### Database Structure
```
users/{userId}
├── username
├── email
├── profileImage
└── blockedUsers/{blockedUserId}
    ├── blockedAt
    ├── blockedUserUsername
    └── blockedUserProfileImage

posts/{postId}
├── authorId
├── content
├── createdAt
└── ...

comments/{commentId}
├── postId
├── authorId
├── content
└── ...
```

## Core Services

### 1. UserService
**Location:** `lib/services/user_service.dart`

**Key Methods:**
- `blockUser(String userIdToBlock)` - Block a user
- `unblockUser(String userIdToUnblock)` - Unblock a user
- `getBlockedUsers()` - Get list of blocked users
- `getBlockedUserIds()` - Get list of blocked user IDs (cached)
- `isUserBlocked(String userId)` - Check if specific user is blocked

**Features:**
- **Caching**: Blocked user IDs are cached for 5 minutes to improve performance
- **Bidirectional blocking**: Can optionally include users who blocked you
- **Error handling**: Graceful error handling with meaningful messages

### 2. PostsService
**Location:** `lib/services/posts_service.dart`

**Key Methods:**
- `getPosts()` - Get posts with automatic blocking filter
- `getPostsStream()` - Real-time posts stream with blocking filter
- `getComments(String postId)` - Get comments with blocking filter
- `getCommentsStream(String postId)` - Real-time comments with blocking filter

**Features:**
- **Automatic filtering**: All methods automatically exclude blocked users
- **Real-time updates**: Streams update when users are blocked/unblocked
- **Optional inclusion**: Can include blocked users with `includeBlockedUsers: true`

## Data Models

### BlockedUser
**Location:** `lib/models/blocked_user.dart`
```dart
class BlockedUser {
  final String id;
  final String username;
  final String profileImage;
  final DateTime? blockedAt;
}
```

### Post & Comment
**Location:** `lib/models/post.dart`, `lib/models/comment.dart`
- Includes author information for filtering
- Firestore integration with timestamps
- Support for likes, comments, and nested replies

## Integration Examples

### 1. Block User from Profile/Post
```dart
// From any widget with user interaction
final userService = UserService();

try {
  await userService.blockUser(userIdToBlock);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('사용자를 차단했습니다.')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('차단에 실패했습니다: $e')),
  );
}
```

### 2. Get Filtered Posts for Feed
```dart
final postsService = PostsService();

// Get posts (blocked users automatically excluded)
final posts = await postsService.getPosts(limit: 20);

// Or use stream for real-time updates
Stream<List<Post>> postsStream = postsService.getPostsStream();
```

### 3. Get Filtered Comments
```dart
// Get comments for a post (blocked users excluded)
final comments = await postsService.getComments(postId);

// Or use stream for real-time updates
Stream<List<Comment>> commentsStream = postsService.getCommentsStream(postId);
```

### 4. Check if User is Blocked
```dart
final isBlocked = await userService.isUserBlocked(userId);
if (!isBlocked) {
  // Show user content
}
```

## UI Components

### BlockedUsersPage
**Location:** `lib/screens/my_page/settings/blocked_users.dart`

**Features:**
- Lists all blocked users
- Unblock functionality with confirmation dialog
- Loading, error, and empty states
- Real-time updates
- Responsive design

**States:**
- **Loading**: Shows spinner while fetching data
- **Error**: Shows error message with retry button
- **Empty**: Shows message when no blocked users
- **Loaded**: Shows list of blocked users with unblock buttons

## Performance Optimizations

### 1. Caching
- Blocked user IDs are cached for 5 minutes
- Cache is cleared when blocking/unblocking users
- Reduces Firestore reads for better performance

### 2. Batch Operations
- Post/comment filtering done client-side to reduce queries
- Could be optimized with Cloud Functions for large datasets

### 3. Streams
- Real-time updates automatically reflect blocking changes
- Efficient for live feeds and comment sections

## Security Considerations

### 1. Firestore Security Rules
```javascript
// Users can only read/write their own blocked users
match /users/{userId}/blockedUsers/{blockedUserId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}

// Posts and comments are readable by authenticated users
match /posts/{postId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == resource.data.authorId;
}
```

### 2. Client-Side Validation
- Users cannot block themselves
- Authentication required for all operations
- Proper error handling prevents crashes

## Advanced Features

### 1. Bidirectional Blocking
Use `getAllBlockingRelationships()` to also hide content from users who blocked you:

```dart
// This includes both users you blocked AND users who blocked you
final allBlocked = await userService.getAllBlockingRelationships();
```

### 2. Block from Content
Add block buttons to posts and comments:

```dart
PopupMenuButton<String>(
  onSelected: (value) async {
    if (value == 'block') {
      await userService.blockUser(authorId);
      // Refresh content
    }
  },
  itemBuilder: (context) => [
    const PopupMenuItem(
      value: 'block',
      child: Row(
        children: [
          Icon(Icons.block, color: Colors.red),
          SizedBox(width: 8),
          Text('사용자 차단'),
        ],
      ),
    ),
  ],
)
```

### 3. Undo Block Action
Add undo functionality to SnackBars:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('$username님을 차단했습니다.'),
    action: SnackBarAction(
      label: '실행취소',
      onPressed: () async {
        await userService.unblockUser(userId);
        // Show confirmation
      },
    ),
  ),
);
```

## Testing the Implementation

### 1. Manual Testing
1. Create test users in Firebase Authentication
2. Test blocking/unblocking through the UI
3. Verify posts/comments are filtered correctly
4. Test real-time updates with multiple devices

### 2. Error Scenarios
- Test with no internet connection
- Test with invalid user IDs
- Test blocking already blocked users
- Test unblocking non-blocked users

## Future Enhancements

### 1. Reporting System
- Add reporting functionality alongside blocking
- Store reported content for moderation

### 2. Temporary Blocks
- Add option for temporary blocks (e.g., 24 hours)
- Automatic unblocking after time period

### 3. Block Categories
- Different types of blocks (posts only, comments only, etc.)
- More granular control over what gets blocked

### 4. Admin Controls
- Admin interface to view blocking relationships
- Ability to unblock users for moderation purposes

## Troubleshooting

### Common Issues

1. **Cache not updating**: Call `userService.refreshCache()` after blocking operations
2. **Stream not updating**: Ensure streams are properly disposed and recreated
3. **Performance issues**: Consider pagination and limit concurrent operations
4. **Security rules**: Ensure Firestore rules match your authentication setup

### Debug Tips

1. Check Firebase console for rule denials
2. Monitor Firestore usage for unexpected reads
3. Use Flutter DevTools to track stream subscriptions
4. Log blocking operations for debugging

## Dependencies Required

Make sure these are in your `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.3
```

This blocking system provides a robust foundation for user content filtering while maintaining good performance and user experience.