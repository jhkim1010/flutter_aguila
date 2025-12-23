import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// 플랫폼 타입
enum PlatformType {
  mobile,    // Android, iOS (핸드폰)
  tablet,    // iPad, Android Tablet
  desktop,   // macOS, Windows, Linux
}

/// 플랫폼 유틸리티 클래스
class PlatformUtils {
  /// 현재 플랫폼 타입 반환
  static PlatformType getPlatformType(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    
    // 데스크톱 플랫폼 확인
    if (isDesktop()) {
      return PlatformType.desktop;
    }
    
    // 태블릿 확인 (iPad, Android Tablet)
    // iPad는 일반적으로 600 이상의 shortestSide를 가짐
    if (shortestSide >= 600) {
      return PlatformType.tablet;
    }
    
    // 모바일 (핸드폰)
    return PlatformType.mobile;
  }
  
  /// 데스크톱 플랫폼인지 확인
  static bool isDesktop() {
    return [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ].contains(defaultTargetPlatform);
  }
  
  /// 모바일 플랫폼인지 확인
  static bool isMobile() {
    return [
      TargetPlatform.android,
      TargetPlatform.iOS,
    ].contains(defaultTargetPlatform);
  }
  
  /// iPad인지 확인
  static bool isIPad(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    final size = MediaQuery.of(context).size;
    return size.shortestSide >= 600;
  }
  
  /// 화면 크기가 데스크톱 크기인지 확인 (800x600 이상)
  static bool isDesktopSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= 800 && size.height >= 600;
  }
  
  /// 화면 크기가 태블릿 크기인지 확인
  static bool isTabletSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    return shortestSide >= 600 && shortestSide < 800;
  }
  
  /// 화면 크기가 모바일 크기인지 확인
  static bool isMobileSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width < 800 || size.height < 600;
  }
  
  /// Windows, Mac, 또는 iPad인지 확인 (왼쪽 메뉴가 항상 표시되는 플랫폼)
  static bool hasPersistentMenu(BuildContext context) {
    // Windows 또는 Mac
    if (isDesktop()) {
      return true;
    }
    // iPad
    if (isIPad(context)) {
      return true;
    }
    return false;
  }
  
  /// 플랫폼별 최대 너비 반환
  static double getMaxWidth(BuildContext context, {
    double? mobileMaxWidth,
    double? tabletMaxWidth,
    double? desktopMaxWidth,
  }) {
    final platformType = getPlatformType(context);
    
    switch (platformType) {
      case PlatformType.mobile:
        return mobileMaxWidth ?? double.infinity;
      case PlatformType.tablet:
        return tabletMaxWidth ?? 1200;
      case PlatformType.desktop:
        return desktopMaxWidth ?? double.infinity;
    }
  }
  
  /// 플랫폼별 패딩 반환
  static EdgeInsets getPadding(BuildContext context, {
    EdgeInsets? mobilePadding,
    EdgeInsets? tabletPadding,
    EdgeInsets? desktopPadding,
  }) {
    final platformType = getPlatformType(context);
    
    switch (platformType) {
      case PlatformType.mobile:
        return mobilePadding ?? const EdgeInsets.all(16);
      case PlatformType.tablet:
        return tabletPadding ?? const EdgeInsets.all(24);
      case PlatformType.desktop:
        return desktopPadding ?? const EdgeInsets.all(32);
    }
  }
  
  /// 플랫폼별 그리드 열 개수 반환
  static int getGridColumns(BuildContext context, {
    int? mobileColumns,
    int? tabletColumns,
    int? desktopColumns,
  }) {
    final platformType = getPlatformType(context);
    
    switch (platformType) {
      case PlatformType.mobile:
        return mobileColumns ?? 1;
      case PlatformType.tablet:
        return tabletColumns ?? 2;
      case PlatformType.desktop:
        return desktopColumns ?? 3;
    }
  }
}

