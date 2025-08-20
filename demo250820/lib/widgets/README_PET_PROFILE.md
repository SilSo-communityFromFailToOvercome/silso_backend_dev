# Pet Profile Picture Usage Guide

This guide explains how to use the selected Shilpet as profile pictures across the app.

## Available Widgets

### 1. PetProfilePicture (Dynamic)
Automatically loads the user's selected pet from Firestore. Updates in real-time when user changes pet.

```dart
import '../../widgets/pet_profile_picture.dart';

// For current user (loads from Firestore)
PetProfilePicture(
  size: 40,
)

// For specific user (loads their pet from Firestore)
PetProfilePicture(
  size: 40,
  userId: 'specific_user_id',
)
```

### 2. StaticPetProfilePicture (Static)
Uses a specific pet ID without loading from Firestore. Faster when you already know the pet ID.

```dart
import '../../widgets/pet_profile_picture.dart';

StaticPetProfilePicture(
  size: 40,
  petId: 'pet5',
)
```

## Usage Examples

### In Posts/Comments
```dart
// Post author avatar
PetProfilePicture(
  size: 40,
  userId: post.userId,
)

// Comment author avatar  
PetProfilePicture(
  size: 28,
  userId: comment.userId,
)

// Current user avatar
PetProfilePicture(size: 40)
```

### Different Sizes
- **Large profile**: 80-120px (profile pages)
- **Medium posts**: 40px (post headers)
- **Small comments**: 28px (comment threads)
- **Mini indicators**: 20px (user lists)

### Anonymous Users
For anonymous posts/comments, continue using CircleAvatar with initials:

```dart
widget.post.anonymous
    ? CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFF5F37CF),
        child: Text('익명'),
      )
    : PetProfilePicture(
        size: 40,
        userId: widget.post.userId,
      )
```

## Pet Service

Use `PetService` for advanced pet management:

```dart
import '../../services/pet_service.dart';

final petService = PetService();

// Get current user's pet ID
String petId = await petService.getCurrentUserPetId();

// Get specific user's pet ID  
String userPetId = await petService.getUserPetId(userId);

// Update current user's pet
await petService.updateCurrentUserPet('pet3');
```

## Implementation Status

✅ **Completed:**
- My Page posts (social media style)
- Post detail screen (author avatar)
- Comment avatars in post detail screen
- Reusable widget components
- Pet service for caching

🔄 **To Implement:**
- Community post list screens
- Other comment sections
- Profile pages
- User lists/search results
- Chat/messaging (if exists)

## Features

- **Real-time updates**: Changes when user selects new pet
- **Caching**: Reduces Firestore calls for better performance  
- **Error handling**: Falls back to default avatar on load failure
- **Circular crop**: Uses `BoxFit.cover` to show full pet body in circle
- **Responsive**: Scales with provided size parameter
- **Anonymous support**: Maintains existing anonymous user UI

## Notes

- Uses full pet body image (not just face) due to asset constraints
- Images are automatically cropped to circular shape
- Falls back to gray person icon if pet image fails to load
- Cache is automatically managed by PetService
- All existing anonymous post/comment logic is preserved