import 'package:flutter/material.dart';
import '../utils/responsive_asset_manager.dart';

/// Responsive Silso Logo widget with SVG/PNG fallback support
class SilsoLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final bool preferSvg;
  final VoidCallback? onTap;
  final String? heroTag;
  
  const SilsoLogo({
    super.key,
    this.width,
    this.height,
    this.color,
    this.preferSvg = true,
    this.onTap,
    this.heroTag,
  });
  
  /// Constructor for responsive sizing
  factory SilsoLogo.responsive({
    Key? key,
    BuildContext? context,
    double baseSize = 120,
    double? maxSize,
    double? minSize,
    Color? color,
    bool preferSvg = true,
    VoidCallback? onTap,
    String? heroTag,
  }) {
    double? size;
    if (context != null) {
      size = AppAssetProvider.getResponsiveLogoSize(
        context,
        baseSize: baseSize,
        maxSize: maxSize ?? baseSize * 1.5,
        minSize: minSize ?? baseSize * 0.7,
      );
    }
    
    return SilsoLogo(
      key: key,
      width: size,
      height: size,
      color: color,
      preferSvg: preferSvg,
      onTap: onTap,
      heroTag: heroTag,
    );
  }
  
  /// Constructor for small size (e.g., app bar)
  factory SilsoLogo.small({
    Key? key,
    Color? color,
    bool preferSvg = true,
    VoidCallback? onTap,
    String? heroTag,
  }) {
    return SilsoLogo(
      key: key,
      width: 32,
      height: 32,
      color: color,
      preferSvg: preferSvg,
      onTap: onTap,
      heroTag: heroTag,
    );
  }
  
  /// Constructor for medium size (e.g., login screen)
  factory SilsoLogo.medium({
    Key? key,
    Color? color,
    bool preferSvg = true,
    VoidCallback? onTap,
    String? heroTag,
  }) {
    return SilsoLogo(
      key: key,
      width: 80,
      height: 80,
      color: color,
      preferSvg: preferSvg,
      onTap: onTap,
      heroTag: heroTag,
    );
  }
  
  /// Constructor for large size (e.g., splash screen)
  factory SilsoLogo.large({
    Key? key,
    Color? color,
    bool preferSvg = true,
    VoidCallback? onTap,
    String? heroTag,
  }) {
    return SilsoLogo(
      key: key,
      width: 150,
      height: 150,
      color: color,
      preferSvg: preferSvg,
      onTap: onTap,
      heroTag: heroTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = width ?? height ?? AppAssetProvider.getResponsiveLogoSize(context);
    
    Widget logoWidget = ResponsiveImage.auto(
      assetPath: AppAssetProvider.getPath(context, AppAsset.silsoLogo),
      width: logoSize,
      height: logoSize,
      color: color,
      preferSvg: preferSvg,
      errorWidget: _buildFallbackLogo(logoSize),
    );
    
    // Wrap with Hero if heroTag is provided
    if (heroTag != null) {
      logoWidget = Hero(
        tag: heroTag!,
        child: logoWidget,
      );
    }
    
    // Wrap with GestureDetector if onTap is provided
    if (onTap != null) {
      logoWidget = GestureDetector(
        onTap: onTap,
        child: logoWidget,
      );
    }
    
    return logoWidget;
  }
  
  /// Build fallback logo when assets fail to load
  Widget _buildFallbackLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF5F37CF), // Silso primary color
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'SILSO',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.2,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Animated Silso Logo with pulse effect
class AnimatedSilsoLogo extends StatefulWidget {
  final double? width;
  final double? height;
  final Color? color;
  final bool preferSvg;
  final VoidCallback? onTap;
  final String? heroTag;
  final Duration animationDuration;
  final bool enablePulse;
  
  const AnimatedSilsoLogo({
    super.key,
    this.width,
    this.height,
    this.color,
    this.preferSvg = true,
    this.onTap,
    this.heroTag,
    this.animationDuration = const Duration(seconds: 2),
    this.enablePulse = true,
  });

  @override
  State<AnimatedSilsoLogo> createState() => _AnimatedSilsoLogoState();
}

class _AnimatedSilsoLogoState extends State<AnimatedSilsoLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.enablePulse) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SilsoLogo(
            width: widget.width,
            height: widget.height,
            color: widget.color,
            preferSvg: widget.preferSvg,
            onTap: widget.onTap,
            heroTag: widget.heroTag,
          ),
        );
      },
    );
  }
}

/// Silso Logo with text underneath
class SilsoLogoWithText extends StatelessWidget {
  final double? logoSize;
  final Color? logoColor;
  final Color? textColor;
  final bool preferSvg;
  final String text;
  final TextStyle? textStyle;
  final double spacing;
  final VoidCallback? onTap;
  final MainAxisAlignment alignment;
  
  const SilsoLogoWithText({
    super.key,
    this.logoSize,
    this.logoColor,
    this.textColor,
    this.preferSvg = true,
    this.text = 'SILSO',
    this.textStyle,
    this.spacing = 12.0,
    this.onTap,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = TextStyle(
      fontSize: (logoSize ?? 80) * 0.2,
      fontWeight: FontWeight.w600,
      color: textColor ?? const Color(0xFF121212),
      letterSpacing: 1.5,
    );

    Widget content = Column(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        SilsoLogo(
          width: logoSize,
          height: logoSize,
          color: logoColor,
          preferSvg: preferSvg,
        ),
        SizedBox(height: spacing),
        Text(
          text,
          style: textStyle ?? defaultTextStyle,
        ),
      ],
    );
    
    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    
    return content;
  }
}