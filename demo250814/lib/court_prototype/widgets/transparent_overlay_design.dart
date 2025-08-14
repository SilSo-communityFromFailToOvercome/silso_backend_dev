import 'package:flutter/material.dart';

/// Transparent overlay design widget
/// Designed to make appbar and bottom input transparent while background covers entire screen
class TransparentOverlayDesign extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomInput;
  final Color? overlayColor;
  final bool enableAppBarTransparency;
  final bool enableBottomTransparency;

  const TransparentOverlayDesign({
    super.key,
    required this.child,
    this.appBar,
    this.bottomInput,
    this.overlayColor,
    this.enableAppBarTransparency = true,
    this.enableBottomTransparency = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Make Scaffold transparent so background covers entire area
      backgroundColor: Colors.transparent,
      // Set AppBar to transparent as well
      appBar: enableAppBarTransparency && appBar != null
          ? TransparentAppBarWrapper(originalAppBar: appBar!)
          : appBar,
      // Use extendBodyBehindAppBar to extend background behind appbar
      extendBodyBehindAppBar: true,
      // Use extendBody to extend background behind bottom area
      extendBody: true,
      body: Stack(
        children: [
          // Main content (including background)
          child,
          // Bottom transparent input field overlay
          if (enableBottomTransparency && bottomInput != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: TransparentBottomWrapper(
                child: bottomInput!,
              ),
            ),
        ],
      ),
    );
  }
}

/// Transparent AppBar wrapper
class TransparentAppBarWrapper extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget originalAppBar;
  final double opacity;

  const TransparentAppBarWrapper({
    super.key,
    required this.originalAppBar,
    this.opacity = 0.0,
  });

  @override
  Size get preferredSize => originalAppBar.preferredSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent, // Completely transparent
      ),
      child: Opacity(
        opacity: opacity,
        child: originalAppBar,
      ),
    );
  }
}

/// Transparent bottom input field wrapper
class TransparentBottomWrapper extends StatelessWidget {
  final Widget child;
  final double opacity;

  const TransparentBottomWrapper({
    super.key,
    required this.child,
    this.opacity = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: child,
    );
  }
}

/// Design utility for full screen background extension
class FullScreenBackgroundDesign {
  /// Scaffold settings for full screen background coverage
  static Widget createFullScreenBackground({
    required Widget backgroundWidget,
    required Widget content,
    PreferredSizeWidget? transparentAppBar,
    Widget? transparentBottomInput,
  }) {
    return Stack(
      children: [
        // Use Positioned.fill for background to cover entire screen
        Positioned.fill(
          child: backgroundWidget,
        ),
        // Transparent overlay and content
        TransparentOverlayDesign(
          appBar: transparentAppBar,
          bottomInput: transparentBottomInput,
          child: content,
        ),
      ],
    );
  }

  /// Full screen size calculation using MediaQuery
  static Size getFullScreenSize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Size(
      mediaQuery.size.width,
      mediaQuery.size.height + mediaQuery.padding.top + mediaQuery.padding.bottom,
    );
  }

  /// Actual screen size including status bar and navigation bar
  static EdgeInsets getScreenInsets(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
    );
  }
}

/// UI elements with adjustable transparency
class TransparencyController {
  /// AppBar transparency setting (0.0 = completely transparent, 1.0 = completely opaque)
  static const double appBarOpacity = 0.0;
  
  /// Bottom Input transparency setting (0.0 = completely transparent, 1.0 = completely opaque)
  static const double bottomInputOpacity = 0.0;
  
  /// Background overlay transparency (dark overlay over background image)
  static const double backgroundOverlayOpacity = 0.3;

  /// Development/test transparency setting (used for debugging)
  static const double debugOpacity = 0.3; // Used for visibility during development
}

/// Design guidelines for transparent elements for user experience
class TransparentUXGuidelines {
  /// Guidelines for clarifying touchable areas even in transparent elements
  static const EdgeInsets minTouchTargetPadding = EdgeInsets.all(8.0);
  
  /// Minimum size for important action buttons in transparent state
  static const Size minActionButtonSize = Size(44, 44);
  
  /// Minimum contrast ratio for accessibility of transparent elements
  static const double minContrastRatio = 3.0;

  /// Hint to indicate areas where users can interact in transparent state
  static Widget createInteractionHint({
    required Widget child,
    bool showHint = false,
  }) {
    if (!showHint) return child;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}