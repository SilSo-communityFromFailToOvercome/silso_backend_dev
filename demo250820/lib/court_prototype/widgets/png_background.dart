import 'package:flutter/material.dart';

/// PNG background image widget - full screen cover
/// Simple and stable PNG image background implementation
class PngBackground extends StatelessWidget {
  final Widget child;
  final String imageAssetPath;
  final BoxFit fit;
  final Color? overlayColor;
  final bool enableOverlay;
  final Color fallbackColor;

  const PngBackground({
    super.key,
    required this.child,
    this.imageAssetPath = 'assets/background/background.png',
    this.fit = BoxFit.cover,
    this.overlayColor,
    this.enableOverlay = true,
    this.fallbackColor = const Color(0xFF3F3329),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imageAssetPath),
          fit: fit,
          onError: (exception, stackTrace) {
            // Log when image loading fails
            debugPrint('PNG background loading failed: $exception');
          },
        ),
      ),
      child: enableOverlay
          ? Stack(
              children: [
                // Overlay layer
                Container(
                  decoration: BoxDecoration(
                    color: overlayColor ?? Colors.black.withValues(alpha: 0.3),
                  ),
                ),
                // Content
                child,
              ],
            )
          : child,
    );
  }
}

/// 에러 핸들링이 강화된 PNG 배경 위젯
class SafePngBackground extends StatefulWidget {
  final Widget child;
  final String imageAssetPath;
  final BoxFit fit;
  final Color? overlayColor;
  final bool enableOverlay;
  final Color fallbackColor;

  const SafePngBackground({
    super.key,
    required this.child,
    this.imageAssetPath = 'assets/background/background.png',
    this.fit = BoxFit.cover,
    this.overlayColor,
    this.enableOverlay = true,
    this.fallbackColor = const Color(0xFF3F3329),
  });

  @override
  State<SafePngBackground> createState() => _SafePngBackgroundState();
}

class _SafePngBackgroundState extends State<SafePngBackground> {
  bool _imageLoadFailed = false;

  @override
  Widget build(BuildContext context) {
    if (_imageLoadFailed) {
      return _buildFallbackBackground();
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(widget.imageAssetPath),
          fit: widget.fit,
          onError: (exception, stackTrace) {
            debugPrint('PNG background loading failed: $exception');
            if (mounted) {
              setState(() {
                _imageLoadFailed = true;
              });
            }
          },
        ),
      ),
      child: widget.enableOverlay
          ? Stack(
              children: [
                // Overlay layer
                Container(
                  decoration: BoxDecoration(
                    color: widget.overlayColor ?? 
                        Colors.black.withValues(alpha: 0.3),
                  ),
                ),
                // Content
                widget.child,
              ],
            )
          : widget.child,
    );
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.fallbackColor,
            widget.fallbackColor.withValues(alpha: 0.8),
            widget.fallbackColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: widget.enableOverlay
          ? Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: widget.overlayColor ?? 
                        Colors.black.withValues(alpha: 0.3),
                  ),
                ),
                widget.child,
              ],
            )
          : widget.child,
    );
  }
}

/// PNG 배경을 위한 유틸리티 클래스
class PngBackgroundUtils {
  /// 화면 크기에 따른 최적의 BoxFit 결정
  static BoxFit getOptimalFit(Size screenSize) {
    final aspectRatio = screenSize.width / screenSize.height;
    
    // 일반적인 모바일 비율 처리
    if (aspectRatio < 0.7) {
      return BoxFit.cover; // 세로가 긴 화면
    } else if (aspectRatio > 1.5) {
      return BoxFit.cover; // 가로가 긴 화면
    } else {
      return BoxFit.cover; // 표준 비율
    }
  }

  /// 화면 크기에 따른 최적의 오버레이 불투명도
  static double getOptimalOverlayOpacity(Size screenSize) {
    final area = screenSize.width * screenSize.height;
    
    if (area < 300000) { // 작은 화면 (폰)
      return 0.35;
    } else if (area < 800000) { // 중간 화면 (태블릿)
      return 0.25;
    } else { // 큰 화면 (데스크톱)
      return 0.2;
    }
  }

  /// 성능 정보 제공
  static String getPerformanceInfo(Size screenSize, String assetPath) {
    final fit = getOptimalFit(screenSize);
    final opacity = getOptimalOverlayOpacity(screenSize);
    
    return '''
Screen: ${screenSize.width.toInt()}x${screenSize.height.toInt()}
Asset: $assetPath
Optimal Fit: $fit
Overlay Opacity: ${(opacity * 100).toInt()}%
Performance: High (PNG optimized)
''';
  }
}