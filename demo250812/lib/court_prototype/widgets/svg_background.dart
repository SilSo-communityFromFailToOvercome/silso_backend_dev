import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG background image widget covering full screen
/// Includes error handling and fallback mechanisms
class SvgBackground extends StatefulWidget {
  final Widget child;
  final String svgAssetPath;
  final Color? fallbackColor;
  final Color? overlayColor;
  final BoxFit fit;
  final bool enableOverlay;
  final VoidCallback? onSvgLoadError;

  const SvgBackground({
    super.key,
    required this.child,
    this.svgAssetPath = 'assets/background/background.svg',
    this.fallbackColor = const Color(0xFF3F3329),
    this.overlayColor,
    this.fit = BoxFit.cover,
    this.enableOverlay = true,
    this.onSvgLoadError,
  });

  @override
  State<SvgBackground> createState() => _SvgBackgroundState();
}

class _SvgBackgroundState extends State<SvgBackground> {
  bool _svgLoadFailed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  Future<void> _loadSvg() async {
    try {
      // SVG 로딩 미리 테스트
      await _validateSvgAsset();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _svgLoadFailed = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _svgLoadFailed = true;
        });
        widget.onSvgLoadError?.call();
      }
    }
  }

  Future<void> _validateSvgAsset() async {
    // SVG 파일 존재성과 로딩 가능성 확인
    try {
      final svgLoader = SvgAssetLoader(widget.svgAssetPath);
      await svgLoader.loadBytes(null);
    } catch (e) {
      throw Exception('SVG validation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return SizedBox(
      width: screenSize.width,
      height: screenSize.height,
      child: Stack(
        children: [
          // Background layer
          _buildBackgroundLayer(screenSize),
          
          // Overlay layer (optional)
          if (widget.enableOverlay) _buildOverlayLayer(),
          
          // Content layer
          widget.child,
        ],
      ),
    );
  }

  Widget _buildBackgroundLayer(Size screenSize) {
    if (_isLoading) {
      return _buildLoadingBackground();
    }
    
    if (_svgLoadFailed) {
      return _buildFallbackBackground();
    }
    
    return _buildSvgBackground(screenSize);
  }

  Widget _buildLoadingBackground() {
    return Container(
      color: widget.fallbackColor,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
        ),
      ),
    );
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.fallbackColor!,
            widget.fallbackColor!.withValues(alpha: 0.8),
            widget.fallbackColor!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildSvgBackground(Size screenSize) {
    return SizedBox(
      width: screenSize.width,
      height: screenSize.height,
      child: SvgPicture.asset(
        widget.svgAssetPath,
        fit: widget.fit,
        width: screenSize.width,
        height: screenSize.height,
        placeholderBuilder: (context) => _buildLoadingBackground(),
        semanticsLabel: 'Background image',
      ),
    );
  }

  Widget _buildOverlayLayer() {
    final overlayColor = widget.overlayColor ?? 
        Colors.black.withValues(alpha: 0.3);
    
    return Container(
      decoration: BoxDecoration(
        color: overlayColor,
      ),
    );
  }
}

/// SVG 배경을 위한 유틸리티 클래스
class SvgBackgroundUtils {
  /// 화면 비율에 따른 최적의 BoxFit 결정
  static BoxFit getOptimalFit(Size screenSize) {
    final aspectRatio = screenSize.width / screenSize.height;
    
    // SVG 원본 비율 (393/852 ≈ 0.46)
    const svgAspectRatio = 393.0 / 852.0;
    
    if ((aspectRatio - svgAspectRatio).abs() < 0.1) {
      return BoxFit.fill;
    } else if (aspectRatio > svgAspectRatio) {
      return BoxFit.cover; // 넓은 화면
    } else {
      return BoxFit.cover; // 긴 화면
    }
  }

  /// 디바이스 타입에 따른 오버레이 불투명도 결정
  static double getOptimalOverlayOpacity(Size screenSize) {
    final diagonal = _calculateDiagonal(screenSize);
    
    if (diagonal < 600) {
      return 0.35; // 폰 - 더 진한 오버레이
    } else if (diagonal < 1000) {
      return 0.25; // 태블릿 - 중간 오버레이
    } else {
      return 0.2; // 데스크톱 - 연한 오버레이
    }
  }

  static double _calculateDiagonal(Size size) {
    return math.sqrt(size.width * size.width + size.height * size.height);
  }

  /// 성능 정보 제공
  static String getPerformanceInfo(Size screenSize) {
    final fit = getOptimalFit(screenSize);
    final opacity = getOptimalOverlayOpacity(screenSize);
    
    return '''
Screen: ${screenSize.width.toInt()}x${screenSize.height.toInt()}
Optimal Fit: $fit
Overlay Opacity: ${(opacity * 100).toInt()}%
SVG Size: 8.5MB (Large)
Recommendation: Consider using compressed version for production
''';
  }
}

/// Simple color background widget (final fallback)
class SimpleBackground extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color? overlayColor;

  const SimpleBackground({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFF3F3329),
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor,
            backgroundColor.withValues(alpha: 0.8),
            backgroundColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: overlayColor != null
          ? Stack(
              children: [
                Container(
                  decoration: BoxDecoration(color: overlayColor),
                ),
                child,
              ],
            )
          : child,
    );
  }
}