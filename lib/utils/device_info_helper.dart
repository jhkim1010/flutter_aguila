import 'dart:io';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// 기기 정보 유틸리티 클래스
class DeviceInfoHelper {
  static final NetworkInfo _networkInfo = NetworkInfo();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// 플랫폼 정보 가져오기 (mac, windows, android, iphone, ipad)
  static Future<String> getPlatform() async {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return 'mac';
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'windows';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS의 경우 iPhone과 iPad 구분
      try {
        final iosInfo = await _deviceInfo.iosInfo;
        // iPad인지 확인 (모델명에 iPad가 포함되어 있거나, utsname.machine에 iPad가 포함)
        if (iosInfo.model.toLowerCase().contains('ipad') ||
            iosInfo.name.toLowerCase().contains('ipad')) {
          return 'ipad';
        }
        return 'iphone';
      } catch (e) {
        print('⚠️ iOS 기기 정보 가져오기 실패: $e');
        // 실패 시 기본값으로 iphone 반환
        return 'iphone';
      }
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      return 'linux';
    } else {
      return 'unknown';
    }
  }

  /// MAC 주소 가져오기
  static Future<String?> getMacAddress() async {
    try {
      // 플랫폼별로 MAC 주소 가져오기
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        // 데스크톱 플랫폼: 활성 네트워크 인터페이스의 MAC 주소 가져오기
        final wifiIP = await _networkInfo.getWifiIP();
        if (wifiIP != null) {
          // WiFi IP가 있으면 WiFi MAC 주소 가져오기 시도
          try {
            final wifiBSSID = await _networkInfo.getWifiBSSID();
            if (wifiBSSID != null && wifiBSSID.isNotEmpty) {
              return wifiBSSID;
            }
          } catch (e) {
            print('⚠️ WiFi BSSID 가져오기 실패: $e');
          }
        }
        
        // WiFi MAC이 없으면 일반 네트워크 인터페이스 MAC 가져오기
        // macOS의 경우 시스템 명령어 사용
        if (Platform.isMacOS) {
          try {
            final result = await Process.run('ifconfig', []);
            final output = result.stdout.toString();
            // en0 또는 en1 인터페이스의 MAC 주소 찾기
            final regex = RegExp(r'ether\s+([0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2})');
            final match = regex.firstMatch(output);
            if (match != null) {
              return match.group(1)?.toUpperCase();
            }
          } catch (e) {
            print('⚠️ macOS MAC 주소 가져오기 실패: $e');
          }
        }
        
        // Windows의 경우
        if (Platform.isWindows) {
          try {
            final result = await Process.run('getmac', ['/fo', 'csv', '/nh']);
            final output = result.stdout.toString();
            if (output.isNotEmpty) {
              final lines = output.split('\n');
              for (var line in lines) {
                if (line.contains('Ethernet') || line.contains('Wi-Fi')) {
                  final parts = line.split(',');
                  if (parts.length > 1) {
                    final mac = parts[0].replaceAll('-', ':').trim();
                    if (mac.isNotEmpty) {
                      return mac.toUpperCase();
                    }
                  }
                }
              }
            }
          } catch (e) {
            print('⚠️ Windows MAC 주소 가져오기 실패: $e');
          }
        }
        
        // Linux의 경우
        if (Platform.isLinux) {
          try {
            final result = await Process.run('cat', ['/sys/class/net/eth0/address']);
            final mac = result.stdout.toString().trim();
            if (mac.isNotEmpty) {
              return mac.toUpperCase();
            }
          } catch (e) {
            print('⚠️ Linux MAC 주소 가져오기 실패: $e');
          }
        }
      } else if (Platform.isAndroid) {
        // Android: WiFi MAC 주소 가져오기
        try {
          final wifiBSSID = await _networkInfo.getWifiBSSID();
          if (wifiBSSID != null && wifiBSSID.isNotEmpty) {
            return wifiBSSID.toUpperCase();
          }
        } catch (e) {
          print('⚠️ Android MAC 주소 가져오기 실패: $e');
        }
      } else if (Platform.isIOS) {
        // iOS: WiFi MAC 주소 가져오기 (iOS 14+에서는 제한적)
        try {
          final wifiBSSID = await _networkInfo.getWifiBSSID();
          if (wifiBSSID != null && wifiBSSID.isNotEmpty) {
            return wifiBSSID.toUpperCase();
          }
        } catch (e) {
          print('⚠️ iOS MAC 주소 가져오기 실패: $e');
        }
      }
      
      print('⚠️ MAC 주소를 가져올 수 없습니다.');
      return null;
    } catch (e) {
      print('❌ MAC 주소 가져오기 오류: $e');
      return null;
    }
  }
}

