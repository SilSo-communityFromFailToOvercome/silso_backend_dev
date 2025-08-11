import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 화면 비율에 따라 배경 이미지를 반응형으로 표시하는 위젯
class ResponsiveBackground extends StatelessWidget {
  final Widget child;
  final String? backgroundAssetPath;
  final Color? overlayColor;
  final BlendMode? blendMode;
  final BoxFit? fit;

  const ResponsiveBackground({
    super.key,
    required this.child,
    this.backgroundAssetPath = 'assets/background/background.svg',
    this.overlayColor,
    this.blendMode = BlendMode.darken,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final aspectRatio = screenSize.width / screenSize.height;
    
    // 화면 비율에 따른 배경 이미지 설정
    final backgroundFit = _getOptimalFit(aspectRatio);
    final overlayColorWithRatio = _getOverlayColor(aspectRatio);

    return Stack(
      children: [
        // SVG 배경 이미지
        Positioned.fill(
          child: backgroundAssetPath != null
              ? SvgPicture.asset(
                  backgroundAssetPath!,
                  fit: fit ?? backgroundFit,
                  colorFilter: overlayColorWithRatio != null
                      ? ColorFilter.mode(
                          overlayColorWithRatio,
                          blendMode ?? BlendMode.darken,
                        )
                      : null,
                  placeholderBuilder: (context) => Container(
                    color: const Color(0xFF3F3329), // 기본 배경색
                  ),
                )
              : Container(
                  color: const Color(0xFF3F3329), // SVG 없을 때 기본 배경
                ),
        ),
        // 콘텐츠
        child,
      ],
    );
  }

  // 화면 비율에 따른 최적 BoxFit 결정
  BoxFit _getOptimalFit(double aspectRatio) {
    if (aspectRatio > 1.8) {
      // 매우 넓은 화면 (태블릿 가로모드 등)
      return BoxFit.fitHeight;
    } else if (aspectRatio > 1.2) {
      // 넓은 화면 (태블릿, 데스크탑)
      return BoxFit.cover;
    } else if (aspectRatio > 0.8) {
      // 일반적인 태블릿 비율
      return BoxFit.cover;
    } else if (aspectRatio > 0.5) {
      // 일반적인 스마트폰 비율
      return BoxFit.cover;
    } else {
      // 매우 좁은 화면 (세로로 긴 폰)
      return BoxFit.fitWidth;
    }
  }

  // 화면 비율에 따른 오버레이 색상 강도 조정
  Color? _getOverlayColor(double aspectRatio) {
    if (overlayColor != null) {
      return overlayColor;
    }

    // 기본 오버레이 색상 (검은색)
    const baseColor = Colors.black;
    
    if (aspectRatio > 1.5) {
      // 넓은 화면: 약간 어둡게
      return baseColor.withValues(alpha: 0.2);
    } else if (aspectRatio > 0.8) {
      // 일반 화면: 중간 정도
      return baseColor.withValues(alpha: 0.3);
    } else {
      // 좁은 화면: 조금 더 어둡게
      return baseColor.withValues(alpha: 0.4);
    }
  }
}

// 화면 크기별 배경 이미지 관리 유틸리티
class BackgroundImageUtils {
  // 화면 크기 카테고리 분류
  static ScreenSizeCategory getScreenCategory(Size screenSize) {
    final aspectRatio = screenSize.width / screenSize.height;
    final diagonal = math.sqrt(screenSize.width * screenSize.width + 
                                  screenSize.height * screenSize.height);

    if (diagonal > 1000) {
      return ScreenSizeCategory.desktop;
    } else if (diagonal > 700) {
      return ScreenSizeCategory.tablet;
    } else if (aspectRatio > 1.0) {
      return ScreenSizeCategory.phoneLandscape;
    } else {
      return ScreenSizeCategory.phonePortrait;
    }
  }

  // 화면 카테고리별 최적 설정 반환
  static BackgroundConfig getOptimalConfig(ScreenSizeCategory category) {
    switch (category) {
      case ScreenSizeCategory.desktop:
        return const BackgroundConfig(
          fit: BoxFit.cover,
          overlayOpacity: 0.2,
          alignment: Alignment.center,
        );
      case ScreenSizeCategory.tablet:
        return const BackgroundConfig(
          fit: BoxFit.cover,
          overlayOpacity: 0.25,
          alignment: Alignment.center,
        );
      case ScreenSizeCategory.phoneLandscape:
        return const BackgroundConfig(
          fit: BoxFit.fitHeight,
          overlayOpacity: 0.3,
          alignment: Alignment.center,
        );
      case ScreenSizeCategory.phonePortrait:
        return const BackgroundConfig(
          fit: BoxFit.cover,
          overlayOpacity: 0.35,
          alignment: Alignment.center,
        );
    }
  }

  // 배경 이미지 최적화 정보
  static String getOptimizationInfo(Size screenSize) {
    final category = getScreenCategory(screenSize);
    final aspectRatio = screenSize.width / screenSize.height;
    
    return '''
Screen: ${screenSize.width.toInt()}x${screenSize.height.toInt()}
Aspect Ratio: ${aspectRatio.toStringAsFixed(2)}
Category: ${category.name}
Optimal Fit: ${getOptimalConfig(category).fit.toString()}
''';
  }
}

// 화면 크기 카테고리
enum ScreenSizeCategory {
  phonePortrait,
  phoneLandscape,
  tablet,
  desktop,
}

// 배경 설정 정보
class BackgroundConfig {
  final BoxFit fit;
  final double overlayOpacity;
  final Alignment alignment;

  const BackgroundConfig({
    required this.fit,
    required this.overlayOpacity,
    required this.alignment,
  });
}