import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as path;

/// 앱에서 사용하는 애셋 타입을 정의하는 열거형
enum AppAsset {
  kakaoSignin,
  googleSigninLogo,
  googleSigninButton,
  silsoLogo,
}

/// 반응형 애셋 경로 및 크기를 제공하는 중앙 관리 클래스
class AppAssetProvider {
  // Asset 경로의 기본 루트
  static const String _baseImagePath = 'assets/images';

  // 화면 크기 분기점
  static const double _tabletBreakpoint = 1024.0;

  /// [asset] 타입에 맞는 애셋의 전체 경로를 반환합니다.
  ///
  /// 일부 애셋은 [useEnglish] 플래그를 통해 언어별 버전을 선택할 수 있습니다.
  static String getPath(
    BuildContext context,
    AppAsset asset, {
    bool useEnglish = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final density = MediaQuery.of(context).devicePixelRatio;

    switch (asset) {
      case AppAsset.kakaoSignin:
        final suffix = useEnglish ? '_en' : '';
        final size =
            screenWidth >= _tabletBreakpoint ? 'large_wide' : 'medium_wide';
        return '$_baseImagePath/kakao_signin/kakao_login_$size$suffix.png';

      case AppAsset.googleSigninLogo:
        return '$_baseImagePath/google_signin/google_logo.png';

      case AppAsset.googleSigninButton:
        // 화면 밀도(density)와 크기에 따라 가장 적절한 이미지 선택
        if (density >= 3.0 && screenWidth >= _tabletBreakpoint) {
          return '$_baseImagePath/google_signin/web_neutral_sq_ctn@4x.png';
        } else if (density >= 2.0) {
          return '$_baseImagePath/google_signin/web_neutral_sq_ctn@3x.png';
        } else if (density >= 1.5) {
          return '$_baseImagePath/google_signin/web_neutral_sq_ctn@2x.png';
        } else {
          return '$_baseImagePath/google_signin/web_neutral_sq_ctn@1x.png';
        }

      case AppAsset.silsoLogo:
        // SVG를 기본으로 반환하며, ResponsiveImage 위젯이 PNG로 자동 대체 처리합니다.
        return '$_baseImagePath/silso_logo/login_logo_svg.svg';
    }
  }

  /// 화면 너비에 따른 상대적 크기 비율을 계산합니다.
  static double _calculateScale(BuildContext context,
      {double baseWidth = 393.0}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth / baseWidth;
  }

  /// 반응형 버튼 사이즈를 계산합니다.
  static Size getResponsiveButtonSize(
    BuildContext context, {
    Size baseSize = const Size(360, 52),
    double maxScale = 1.2,
    double minScale = 0.8,
  }) {
    final scale = _calculateScale(context).clamp(minScale, maxScale);
    return Size(baseSize.width * scale, baseSize.height * scale);
  }

  /// 반응형 로고 사이즈(지름/너비)를 계산합니다.
  static double getResponsiveLogoSize(
    BuildContext context, {
    double baseSize = 120,
    double maxSize = 200,
    double minSize = 80,
  }) {
    final scale = _calculateScale(context);
    return (baseSize * scale).clamp(minSize, maxSize);
  }
}

/// SVG/PNG 대체를 지원하는 반응형 이미지 위젯
class ResponsiveImage extends StatelessWidget {
  final String? svgPath;
  final String? pngPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final Widget? errorWidget;
  final bool preferSvg;

  const ResponsiveImage({
    super.key,
    this.svgPath,
    this.pngPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.errorWidget,
    this.preferSvg = true,
  });

  /// [assetPath]를 기반으로 SVG와 PNG 경로를 자동으로 설정하는 생성자입니다.
  ///
  /// 예를 들어, 'assets/logo.svg'가 주어지면, svgPath는 'assets/logo.svg'로,
  /// pngPath는 'assets/logo.png'로 자동 설정됩니다.
  factory ResponsiveImage.auto({
    Key? key,
    required String assetPath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
    Widget? errorWidget,
    bool preferSvg = true,
  }) {
    final dir = path.dirname(assetPath);
    final filename = path.basenameWithoutExtension(assetPath);
    final svgPath = path.join(dir, '$filename.svg');
    final pngPath = path.join(dir, '$filename.png');

    return ResponsiveImage(
      key: key,
      svgPath: svgPath,
      pngPath: pngPath,
      width: width,
      height: height,
      fit: fit,
      color: color,
      errorWidget: errorWidget,
      preferSvg: preferSvg,
    );
  }

  @override
  Widget build(BuildContext context) {
    // SVG를 우선적으로 로드 시도
    if (preferSvg && svgPath != null && svgPath!.endsWith('.svg')) {
      return SvgPicture.asset(
        svgPath!,
        width: width,
        height: height,
        fit: fit,
        colorFilter:
            color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
        placeholderBuilder: (context) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  /// SVG 로드 실패 시 또는 PNG가 우선일 경우 PNG 이미지를 로드합니다.
  Widget _buildFallback() {
    if (pngPath != null) {
      return Image.asset(
        pngPath!,
        width: width,
        height: height,
        fit: fit,
        color: color,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        filterQuality: FilterQuality.high,
      );
    }
    return _buildErrorWidget();
  }

  /// 모든 이미지 로드 실패 시 표시될 에러 위젯입니다.
  Widget _buildErrorWidget() {
    if (errorWidget != null) return errorWidget!;

    return Container(
      width: width ?? 50,
      height: height ?? 50,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}

/// 앱 실행 초기에 주요 애셋을 미리 로드하여 성능을 향상시키는 클래스
/// Asset preloader for better performance
class AssetPreloader {
  static final Set<String> _preloadedAssets = {};

  /// Preload commonly used assets
  static Future<void> preloadAssets(BuildContext context) async {
    // 이전 대화에서 AppAssetProvider로 리팩토링한 코드를 기반으로 합니다.
    // 만약 이전 코드를 사용하지 않으신다면 이 부분은 기존 코드에 맞게 수정해주세요.
    final List<String> assetsToPreload = [
      AppAssetProvider.getPath(context, AppAsset.kakaoSignin),
      AppAssetProvider.getPath(context, AppAsset.kakaoSignin, useEnglish: true),
      AppAssetProvider.getPath(context, AppAsset.googleSigninButton),
      // SVG와 PNG 경로를 모두 추가
      AppAssetProvider.getPath(context, AppAsset.silsoLogo), // .svg
      AppAssetProvider.getPath(context, AppAsset.silsoLogo).replaceAll('.svg', '.png'), // .png
    ];

    for (String assetPath in assetsToPreload) {
      if (!_preloadedAssets.contains(assetPath)) {
        try {
          if (assetPath.endsWith('.svg')) {
            // SVG 파일의 경우 flutter_svg가 자체적으로 캐싱을 처리하므로
            // 단순히 성공적으로 표시하고 실제 캐싱은 첫 번째 사용 시 처리
            _preloadedAssets.add(assetPath);
            debugPrint('Marked SVG for preloading: $assetPath');
          } else {
            // 일반 이미지는 precacheImage를 사용합니다.
            await precacheImage(AssetImage(assetPath), context);
            _preloadedAssets.add(assetPath);
            debugPrint('Successfully preloaded image: $assetPath');
          }
        } catch (e) {
          // 에셋이 존재하지 않는 경우 무시하고 계속 진행
          debugPrint('Failed to preload asset: $assetPath. Error: $e');
        }
      }
    }
  }
}