import 'package:flutter/material.dart';
import 'platform_utils.dart';

/// 모바일 화면 구성 헬퍼 클래스
/// 핸드폰의 수직(portrait) 및 수평(landscape) 화면 구성을 집중적으로 처리
/// 대형 화면(태블릿, 데스크톱)에는 영향을 미치지 않도록 설계됨
class MobileLayoutHelper {
  /// 대형 화면 기준 너비 (픽셀)
  /// 이 값 이상이면 대형 화면으로 간주하여 모바일 전용 로직을 적용하지 않음
  static const double _largeScreenThreshold = 800.0;
  
  /// 태블릿 최소 크기 (shortestSide 기준)
  /// 이 값 이상이면 태블릿으로 간주
  static const double _tabletThreshold = 600.0;

  /// 모바일 화면 구성 정보를 담는 클래스
  /// 화면 방향, 플랫폼 타입, 모바일 폰 여부 등을 포함
  static MobileLayoutInfo getLayoutInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final orientation = mediaQuery.orientation;
    final platformType = PlatformUtils.getPlatformType(context);
    
    // 대형 화면 여부 확인 (너비 기준)
    // 주의: 대형 화면에는 모바일 전용 로직을 적용하지 않음
    final isLargeScreen = size.width >= _largeScreenThreshold;
    
    // 태블릿 여부 확인
    // iPad 또는 Android 태블릿 (shortestSide >= 600)
    final isTablet = PlatformUtils.isIPad(context) || 
                     (platformType == PlatformType.mobile && size.shortestSide >= _tabletThreshold);
    
    // 모바일 플랫폼 여부 (Android, iOS)
    final isMobilePlatform = platformType == PlatformType.mobile;
    
    // 모바일 폰 여부 (태블릿 제외한 모바일 기기)
    // 핸드폰만을 대상으로 하는 로직에 사용
    final isMobilePhone = isMobilePlatform && !isTablet;
    
    // 핸드폰 수직 모드 (세로 모드)
    // 조건: 모바일 폰이면서 대형 화면이 아니고 세로 방향
    final isMobilePhonePortrait = isMobilePhone && 
                                   !isLargeScreen && 
                                   orientation == Orientation.portrait;
    
    // 핸드폰 수평 모드 (가로 모드)
    // 조건: 모바일 폰이면서 가로 방향
    final isMobilePhoneLandscape = isMobilePhone && 
                                    orientation == Orientation.landscape;
    
    return MobileLayoutInfo(
      isLargeScreen: isLargeScreen,
      isTablet: isTablet,
      isMobilePlatform: isMobilePlatform,
      isMobilePhone: isMobilePhone,
      isMobilePhonePortrait: isMobilePhonePortrait,
      isMobilePhoneLandscape: isMobilePhoneLandscape,
      orientation: orientation,
      platformType: platformType,
      screenSize: size,
    );
  }
  
  /// 대형 화면인지 확인
  /// 대형 화면에는 모바일 전용 로직을 적용하지 않아야 함
  static bool isLargeScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= _largeScreenThreshold;
  }
  
  /// 태블릿인지 확인
  static bool isTablet(BuildContext context) {
    final platformType = PlatformUtils.getPlatformType(context);
    final size = MediaQuery.of(context).size;
    return PlatformUtils.isIPad(context) || 
           (platformType == PlatformType.mobile && size.shortestSide >= _tabletThreshold);
  }
  
  /// 모바일 폰인지 확인 (태블릿 제외)
  static bool isMobilePhone(BuildContext context) {
    final platformType = PlatformUtils.getPlatformType(context);
    if (platformType != PlatformType.mobile) {
      return false;
    }
    return !isTablet(context);
  }
  
  /// 핸드폰 수직 모드인지 확인
  /// 주의: 대형 화면에는 false를 반환하여 모바일 전용 로직이 적용되지 않도록 함
  static bool isMobilePhonePortrait(BuildContext context) {
    final info = getLayoutInfo(context);
    return info.isMobilePhonePortrait;
  }
  
  /// 핸드폰 수평 모드인지 확인
  static bool isMobilePhoneLandscape(BuildContext context) {
    final info = getLayoutInfo(context);
    return info.isMobilePhoneLandscape;
  }
  
  /// 모바일 폰에 대한 패딩 반환
  /// 수직 모드와 수평 모드에 따라 다른 패딩 적용 가능
  static EdgeInsets getMobilePhonePadding(
    BuildContext context, {
    EdgeInsets? portraitPadding,
    EdgeInsets? landscapePadding,
  }) {
    final info = getLayoutInfo(context);
    
    // 대형 화면이나 태블릿이면 기본값 반환 (모바일 전용 로직 미적용)
    if (!info.isMobilePhone) {
      return const EdgeInsets.all(16);
    }
    
    // 수직 모드와 수평 모드에 따라 다른 패딩 적용
    if (info.isMobilePhonePortrait) {
      return portraitPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    } else if (info.isMobilePhoneLandscape) {
      return landscapePadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    }
    
    return const EdgeInsets.all(16);
  }
  
  /// 모바일 폰에 대한 폰트 크기 반환
  /// 수직 모드와 수평 모드에 따라 다른 크기 적용 가능
  static double getMobilePhoneFontSize(
    BuildContext context, {
    double? portraitSize,
    double? landscapeSize,
    double defaultSize = 14.0,
  }) {
    final info = getLayoutInfo(context);
    
    // 대형 화면이나 태블릿이면 기본값 반환 (모바일 전용 로직 미적용)
    if (!info.isMobilePhone) {
      return defaultSize;
    }
    
    // 수직 모드와 수평 모드에 따라 다른 폰트 크기 적용
    if (info.isMobilePhonePortrait) {
      return portraitSize ?? defaultSize;
    } else if (info.isMobilePhoneLandscape) {
      return landscapeSize ?? defaultSize;
    }
    
    return defaultSize;
  }
  
  /// 모바일 폰에 대한 아이콘 크기 반환
  static double getMobilePhoneIconSize(
    BuildContext context, {
    double? portraitSize,
    double? landscapeSize,
    double defaultSize = 24.0,
  }) {
    final info = getLayoutInfo(context);
    
    // 대형 화면이나 태블릿이면 기본값 반환
    if (!info.isMobilePhone) {
      return defaultSize;
    }
    
    if (info.isMobilePhonePortrait) {
      return portraitSize ?? defaultSize;
    } else if (info.isMobilePhoneLandscape) {
      return landscapeSize ?? defaultSize;
    }
    
    return defaultSize;
  }
  
  /// 디버그 정보 출력
  /// 문제 발생 시 원인 분석을 위한 상세 정보 출력
  static void debugPrintLayoutInfo(BuildContext context, {String? tag}) {
    final info = getLayoutInfo(context);
    final prefix = tag != null ? '[$tag] ' : '';
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('${prefix}📱 [모바일 화면 구성 정보]');
    debugPrint('   → 파일: mobile_layout_helper.dart');
    debugPrint('   → isLargeScreen: ${info.isLargeScreen} (기준: $_largeScreenThreshold)');
    debugPrint('   → isTablet: ${info.isTablet}');
    debugPrint('   → isMobilePlatform: ${info.isMobilePlatform}');
    debugPrint('   → isMobilePhone: ${info.isMobilePhone}');
    debugPrint('   → isMobilePhonePortrait: ${info.isMobilePhonePortrait}');
    debugPrint('   → isMobilePhoneLandscape: ${info.isMobilePhoneLandscape}');
    debugPrint('   → orientation: ${info.orientation}');
    debugPrint('   → platformType: ${info.platformType}');
    debugPrint('   → screenSize: ${info.screenSize}');
    debugPrint('   → screenWidth: ${info.screenSize.width}');
    debugPrint('   → screenHeight: ${info.screenSize.height}');
    debugPrint('   → shortestSide: ${info.screenSize.shortestSide}');
    debugPrint('═══════════════════════════════════════════════════════');
  }
}

/// 모바일 화면 구성 정보를 담는 클래스
class MobileLayoutInfo {
  /// 대형 화면 여부 (너비 >= 800)
  final bool isLargeScreen;
  
  /// 태블릿 여부 (iPad 또는 Android 태블릿)
  final bool isTablet;
  
  /// 모바일 플랫폼 여부 (Android, iOS)
  final bool isMobilePlatform;
  
  /// 모바일 폰 여부 (태블릿 제외)
  final bool isMobilePhone;
  
  /// 핸드폰 수직 모드 (세로 모드)
  final bool isMobilePhonePortrait;
  
  /// 핸드폰 수평 모드 (가로 모드)
  final bool isMobilePhoneLandscape;
  
  /// 화면 방향
  final Orientation orientation;
  
  /// 플랫폼 타입
  final PlatformType platformType;
  
  /// 화면 크기
  final Size screenSize;
  
  const MobileLayoutInfo({
    required this.isLargeScreen,
    required this.isTablet,
    required this.isMobilePlatform,
    required this.isMobilePhone,
    required this.isMobilePhonePortrait,
    required this.isMobilePhoneLandscape,
    required this.orientation,
    required this.platformType,
    required this.screenSize,
  });
  
  @override
  String toString() {
    return 'MobileLayoutInfo('
        'isLargeScreen: $isLargeScreen, '
        'isTablet: $isTablet, '
        'isMobilePhone: $isMobilePhone, '
        'isMobilePhonePortrait: $isMobilePhonePortrait, '
        'isMobilePhoneLandscape: $isMobilePhoneLandscape, '
        'orientation: $orientation)';
  }
}
