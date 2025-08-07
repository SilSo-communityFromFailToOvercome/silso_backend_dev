# Responsive Asset Integration Guide

A comprehensive system for managing responsive images with SVG/PNG fallback support for login buttons and logos.

## Overview

The responsive asset system provides:
- ✅ **Responsive sizing** based on screen dimensions
- ✅ **SVG/PNG fallback** support with automatic switching
- ✅ **Asset preloading** for better performance
- ✅ **Multiple button variants** (Kakao, Google)
- ✅ **Logo components** with animations and sizing options
- ✅ **Error handling** with fallback UI elements

## Available Assets

### 📁 Kakao Signin Assets
```
assets/images/kakao_signin/
├── kakao_login_large_wide.png       # Large button (Korean)
├── kakao_login_medium_wide.png      # Medium button (Korean)
├── kakao_login_large_wide_en.png    # Large button (English)
└── kakao_login_medium_wide_en.png   # Medium button (English)
```

### 📁 Google Signin Assets
```
assets/images/google_signin/
├── web_neutral_sq_ctn.svg           # SVG full button
├── web_neutral_sq_ctn@1x.png       # 1x density button
├── web_neutral_sq_ctn@2x.png       # 2x density button
├── web_neutral_sq_ctn@3x.png       # 3x density button
├── web_neutral_sq_ctn@4x.png       # 4x density button
└── google_logo.png                 # Google logo only
```

### 📁 Silso Logo Assets
```
assets/images/silso_logo/
├── login_logo_svg.svg              # SVG logo (preferred)
└── login_logo.png                  # PNG logo (fallback)
```

## Core Components

### 1. ResponsiveAssetManager

Central utility class for asset management:

```dart
// Get responsive Kakao signin asset
String asset = ResponsiveAssetManager.getKakaoSigninAsset(
  context,
  useEnglish: false, // or true for English
);

// Get responsive Google signin asset
String asset = ResponsiveAssetManager.getGoogleSigninAsset(
  context,
  useFullButton: true, // Full button vs logo only
);

// Get Silso logo asset with SVG/PNG fallback
String asset = ResponsiveAssetManager.getSilsoLogoAsset(
  context,
  preferSvg: true, // Prefer SVG, fallback to PNG
);

// Calculate responsive button size
Size buttonSize = ResponsiveAssetManager.getResponsiveButtonSize(
  context,
  baseSize: Size(360, 52),
  maxScale: 1.2,
  minScale: 0.8,
);

// Calculate responsive logo size
double logoSize = ResponsiveAssetManager.getResponsiveLogoSize(
  context,
  baseSize: 120,
  maxSize: 200,
  minSize: 80,
);
```

### 2. ResponsiveImage Widget

Universal image widget with SVG/PNG fallback:

```dart
// Automatic SVG/PNG selection
ResponsiveImage.auto(
  assetPath: 'assets/images/logo',
  width: 100,
  height: 100,
  preferSvg: true,           // Try SVG first
  fit: BoxFit.contain,
  color: Colors.blue,        // Tint color
  errorWidget: fallbackWidget,
)

// Manual SVG/PNG specification  
ResponsiveImage(
  svgPath: 'assets/images/logo.svg',
  pngPath: 'assets/images/logo.png',
  width: 100,
  height: 100,
  preferSvg: true,
)
```

### 3. Kakao Login Button

Multiple variants with responsive asset support:

```dart
// Basic Kakao button with assets
KakaoLoginButton(
  useAssetImage: true,       // Use asset images
  useEnglish: false,         // Korean vs English
  onSuccess: () => print('Success!'),
  onError: (error) => print('Error: $error'),
)

// Korean variant (enhanced styling)
KakaoLoginButtonKorean(
  useAssetImage: true,
  onSuccess: onSuccess,
  onError: onError,
)

// Simple variant (outlined button)
KakaoLoginButtonSimple(
  onSuccess: onSuccess,
  onError: onError,
)
```

### 4. Google Sign-In Button

Responsive Google signin with multiple modes:

```dart
// Custom button with Google logo asset
GoogleSignInButton(
  useAssetImage: true,       // Use Google logo asset
  useFullButton: false,      // Logo only
  onSuccess: () => navigateToHome(),
  onError: (error) => showError(error),
)

// Full Google signin button asset
GoogleSignInButton(
  useAssetImage: true,
  useFullButton: true,       // Full button asset
  onSuccess: onSuccess,
  onError: onError,
)

// Basic button with fallback icon
GoogleSignInButton(
  useAssetImage: false,      // Use fallback icons
  onSuccess: onSuccess,
  onError: onError,
)
```

### 5. Silso Logo Components

Comprehensive logo system with multiple variants:

```dart
// Basic responsive logo
SilsoLogo.responsive(
  context: context,
  baseSize: 120,
  maxSize: 200,
  minSize: 80,
  preferSvg: true,
  onTap: () => navigateToHome(),
)

// Predefined sizes
SilsoLogo.small()          // 32x32px
SilsoLogo.medium()         // 80x80px  
SilsoLogo.large()          // 150x150px

// Animated logo with pulse effect
AnimatedSilsoLogo(
  width: 100,
  height: 100,
  enablePulse: true,
  animationDuration: Duration(seconds: 2),
  onTap: onLogoTap,
)

// Logo with text underneath
SilsoLogoWithText(
  logoSize: 80,
  text: 'SILSO Platform',
  textColor: Colors.black87,
  spacing: 12,
  onTap: onTap,
)

// Hero animation support
SilsoLogo.medium(
  heroTag: 'main-logo',     // For hero animations
  onTap: navigateWithHero,
)
```

## Screen Size Breakpoints

The system uses these breakpoints for responsive behavior:

```dart
// Breakpoint definitions
static const double mobileBreakpoint = 600.0;   // < 600px = mobile
static const double tabletBreakpoint = 1024.0;  // 600-1024px = tablet
                                                 // > 1024px = desktop

// Button scaling
- Mobile: 0.8x - 1.2x scale
- Tablet: 1.0x - 1.3x scale  
- Desktop: 1.1x - 1.5x scale

// Logo sizing
- Small screens: 80-120px logos
- Medium screens: 100-150px logos
- Large screens: 120-200px logos
```

## Performance Optimization

### Asset Preloading

Preload assets during app initialization:

```dart
// In main.dart or splash screen
await AssetPreloader.preloadAssets(context);

// Preloaded assets are cached for instant loading
```

### Caching Strategy

```dart
// Assets are automatically cached after first load
// SVG assets use flutter_svg's caching
// PNG assets use Flutter's standard image caching
// Manual cache management available through AssetPreloader
```

## Usage Examples

### Login Screen Integration

```dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Responsive logo with hero animation
              SilsoLogo.responsive(
                context: context,
                baseSize: 120,
                heroTag: 'login-logo',
                onTap: () => Navigator.pushNamed(context, '/about'),
              ),
              
              SizedBox(height: 48),
              
              // Kakao login with Korean assets
              KakaoLoginButton(
                useAssetImage: true,
                useEnglish: false,
                onSuccess: () => handleKakaoSuccess(),
                onError: (error) => showErrorDialog(error),
              ),
              
              SizedBox(height: 16),
              
              // Google login with full button asset
              GoogleSignInButton(
                useAssetImage: true,
                useFullButton: true,
                onSuccess: () => handleGoogleSuccess(),
                onError: (error) => showErrorDialog(error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### App Bar Integration

```dart
AppBar(
  title: Text('My App'),
  actions: [
    // Small logo in app bar
    Padding(
      padding: EdgeInsets.only(right: 16.0),
      child: SilsoLogo.small(
        color: Colors.white,
        onTap: () => Navigator.pushNamed(context, '/home'),
      ),
    ),
  ],
)
```

### Splash Screen Integration

```dart
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5F37CF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large animated logo
            AnimatedSilsoLogo(
              width: 200,
              height: 200,
              preferSvg: true,
              enablePulse: true,
              heroTag: 'splash-logo',
            ),
            
            SizedBox(height: 32),
            
            // Logo with text
            SilsoLogoWithText(
              logoSize: 0, // Hide logo (already shown above)
              text: 'Loading...',
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
```

## Error Handling

The system provides comprehensive error handling:

### Asset Loading Errors
- **SVG fails** → Automatically fallback to PNG
- **PNG fails** → Show custom error widget
- **All assets fail** → Display fallback UI with brand colors

### Network Errors
- **Button interactions** → Show loading states
- **Auth failures** → Trigger error callbacks
- **Connectivity issues** → Graceful degradation

### Fallback UI
```dart
// Custom fallback logo
Widget buildFallbackLogo(double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Color(0xFF5F37CF), // Silso primary color
      borderRadius: BorderRadius.circular(size * 0.2),
    ),
    child: Center(
      child: Text(
        'SILSO',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
```

## Best Practices

### 1. Asset Organization
- ✅ Group assets by component type
- ✅ Use consistent naming conventions
- ✅ Provide multiple densities for PNG assets
- ✅ Include both SVG and PNG versions when possible

### 2. Performance
- ✅ Preload critical assets during app launch
- ✅ Use SVG for scalable graphics
- ✅ Optimize PNG assets for target screen densities
- ✅ Implement proper caching strategies

### 3. Responsive Design
- ✅ Test on multiple screen sizes
- ✅ Use appropriate breakpoints
- ✅ Implement min/max size constraints
- ✅ Consider device pixel ratios

### 4. Accessibility
- ✅ Provide semantic descriptions for logos
- ✅ Ensure sufficient color contrast
- ✅ Support screen readers
- ✅ Implement proper focus handling

### 5. Error Handling
- ✅ Always provide fallback UI
- ✅ Test asset loading failures
- ✅ Implement proper error reporting
- ✅ Graceful degradation strategies

## Testing

Run the demo to test all features:

```dart
// Add to your main.dart or routing
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ResponsiveAssetDemo(),
  ),
);
```

The demo includes:
- 📱 **All logo variants** and sizes
- 🔘 **Interactive controls** for testing different modes
- 📊 **Real-time asset information** display
- 🎯 **Button interaction** testing
- 📏 **Responsive sizing** demonstration

## Dependencies

Required packages in `pubspec.yaml`:

```yaml
dependencies:
  flutter_svg: ^2.2.0          # SVG support
  cupertino_icons: ^1.0.8      # iOS-style icons (fallback)
  
  # Auth packages (if using login functionality)
  firebase_auth: ^5.3.1        # Firebase authentication
  google_sign_in: ^6.3.0       # Google Sign-In
  kakao_flutter_sdk: ^1.9.5     # Kakao login SDK
```

## Troubleshooting

### Common Issues

**Q: Assets not loading**
- Verify asset paths in `pubspec.yaml`
- Check file permissions
- Ensure assets exist in specified directories

**Q: SVG rendering issues**
- Check SVG syntax and compatibility
- Verify flutter_svg package version
- Use PNG fallback for complex SVGs

**Q: Button not responding**
- Check authentication service setup
- Verify callback functions
- Test network connectivity

**Q: Sizing issues on different screens**
- Test breakpoint logic
- Adjust min/max size constraints  
- Check MediaQuery availability

For more examples and advanced usage, see the demo implementation in `lib/examples/responsive_asset_demo.dart`.