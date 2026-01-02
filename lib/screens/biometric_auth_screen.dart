import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, debugPrint;
import 'main_connection_screen.dart';

class BiometricAuthScreen extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const BiometricAuthScreen({
    super.key,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _errorMessage = '';
  bool _isSupported = false;
  bool _isInitializing = true; // 초기화 중 플래그 추가
  List<BiometricType> _availableBiometrics = [];
  bool _hasCalledAuthenticate = false; // _authenticate 호출 여부 추적
  bool _isAuthDialogShowing = false; // _localAuth.authenticate 다이얼로그 표시 중 플래그
  Completer<bool>? _authCompleter; // _localAuth.authenticate 호출을 보호하는 Completer
  bool _isInitializingBiometrics = false; // _initializeBiometrics 실행 중 플래그

  @override
  void initState() {
    super.initState();
    _initializeBiometrics();
  }

  Future<void> _initializeBiometrics() async {
    debugPrint('🔍 [지문인식] _initializeBiometrics 시작');
    // 중복 호출 방지: 이미 초기화 중이면 중단
    if (_isInitializingBiometrics) {
      debugPrint('🔍 [지문인식] 이미 초기화 중이므로 중단');
      return;
    }
    
    // 초기화 시작 플래그 설정
    _isInitializingBiometrics = true;
    debugPrint('🔍 [지문인식] 초기화 플래그 설정 완료');
    
    try {
      debugPrint('🔍 [지문인식] _checkBiometrics 호출 시작');
      await _checkBiometrics();
      debugPrint('🔍 [지문인식] _checkBiometrics 완료, _isSupported: $_isSupported');
      
      // 초기화 완료 표시
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        debugPrint('🔍 [지문인식] 초기화 완료 상태로 변경');
      }
      
      // 생체 인식이 지원되지 않으면 자동으로 다음 화면으로 이동
      if (!_isSupported) {
        debugPrint('🔍 [지문인식] 생체 인식 미지원, 500ms 후 메인 화면으로 이동');
        // 약간의 지연 후 자동으로 다음 화면으로 이동
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          debugPrint('🔍 [지문인식] 메인 화면으로 이동 시작');
          _navigateToMain();
        }
        return;
      }
      
      // 생체 인식이 지원되면 인증 시도
      debugPrint('🔍 [지문인식] 생체 인식 지원됨, _authenticate 호출 시작');
      await _authenticate();
      debugPrint('🔍 [지문인식] _authenticate 완료');
    } catch (e, stackTrace) {
      debugPrint('❌ [지문인식] _initializeBiometrics 에러: $e');
      debugPrint('❌ [지문인식] 스택 트레이스: $stackTrace');
    } finally {
      // 초기화 완료 플래그 해제 (에러가 발생해도 항상 해제)
      _isInitializingBiometrics = false;
      debugPrint('🔍 [지문인식] 초기화 플래그 해제 완료');
    }
  }

  Future<void> _checkBiometrics() async {
    debugPrint('🔍 [지문인식] _checkBiometrics 시작');
    try {
      debugPrint('🔍 [지문인식] isDeviceSupported 호출 중...');
      final bool isSupported = await _localAuth.isDeviceSupported();
      debugPrint('🔍 [지문인식] isDeviceSupported 결과: $isSupported');
      
      debugPrint('🔍 [지문인식] canCheckBiometrics 호출 중...');
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      debugPrint('🔍 [지문인식] canCheckBiometrics 결과: $canCheckBiometrics');
      
      debugPrint('🔍 [지문인식] getAvailableBiometrics 호출 중...');
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();
      debugPrint('🔍 [지문인식] getAvailableBiometrics 결과: $availableBiometrics');

      // 사용 가능한 생체 인식이 있는지 확인
      final bool hasAvailableBiometrics = availableBiometrics.isNotEmpty;
      debugPrint('🔍 [지문인식] hasAvailableBiometrics: $hasAvailableBiometrics');
      
      final bool finalIsSupported = isSupported && canCheckBiometrics && hasAvailableBiometrics;
      debugPrint('🔍 [지문인식] finalIsSupported: $finalIsSupported');

      setState(() {
        _isSupported = finalIsSupported;
        _availableBiometrics = availableBiometrics;
      });

      // 생체 인식이 지원되지 않으면 사용자에게 알리고 건너뛰기 옵션 제공
      if (!finalIsSupported) {
        debugPrint('🔍 [지문인식] 생체 인식 미지원, 에러 메시지 설정');
        setState(() {
          _errorMessage = 'La autenticación biométrica no está disponible en este dispositivo.';
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [지문인식] _checkBiometrics 에러: $e');
      debugPrint('❌ [지문인식] 스택 트레이스: $stackTrace');
      setState(() {
        _isSupported = false;
        _errorMessage = 'Error al verificar la autenticación biométrica: $e';
      });
    }
  }

  Future<void> _authenticate() async {
    debugPrint('🔍 [지문인식] _authenticate 시작, _isSupported: $_isSupported');
    if (!_isSupported) {
      debugPrint('🔍 [지문인식] 생체 인식 미지원, _authenticate 종료');
      return;
    }
    
    // 가장 강력한 중복 호출 방지: 이미 인증이 호출되었거나 진행 중이면 무조건 차단
    if (_hasCalledAuthenticate || _isAuthDialogShowing || _isAuthenticating || _authCompleter != null) {
      debugPrint('🔍 [지문인식] 중복 호출 방지: _hasCalledAuthenticate=$_hasCalledAuthenticate, _isAuthDialogShowing=$_isAuthDialogShowing, _isAuthenticating=$_isAuthenticating, _authCompleter!=null=${_authCompleter != null}');
      return;
    }

    // setState 호출 전에 플래그 설정하여 재빌드 중 중복 호출 방지
    _hasCalledAuthenticate = true; // 호출 표시
    _isAuthenticating = true; // 인증 중 플래그 설정
    debugPrint('🔍 [지문인식] 플래그 설정: _hasCalledAuthenticate=true, _isAuthenticating=true');
    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      // _localAuth.authenticate 호출 직전에 다시 한 번 중복 호출 체크
      // (비동기 실행 중 위젯이 재빌드되면서 다시 호출될 수 있음)
      if (_isAuthDialogShowing || !_isAuthenticating) {
        debugPrint('🔍 [지문인식] 중복 호출 체크 실패, 종료');
        return;
      }
      
      // Completer가 이미 있으면 기존 인증 프로세스가 진행 중이므로 대기
      if (_authCompleter != null) {
        debugPrint('🔍 [지문인식] 기존 Completer 대기 중...');
        try {
          final bool didAuthenticate = await _authCompleter!.future;
          debugPrint('🔍 [지문인식] 기존 Completer 결과: $didAuthenticate');
          // 기존 프로세스의 결과를 사용하여 처리
          if (didAuthenticate) {
            _navigateToMain();
          } else {
            _isAuthDialogShowing = false;
            setState(() {
              _errorMessage = 'La autenticación fue cancelada';
              _isAuthenticating = false;
            });
          }
        } catch (e) {
          debugPrint('❌ [지문인식] 기존 Completer 에러: $e');
          _isAuthDialogShowing = false;
          setState(() {
            _errorMessage = 'Error durante la autenticación: $e';
            _isAuthenticating = false;
          });
        }
        return;
      }
      
      // macOS에서는 biometricOnly를 true로 설정하여 시스템이 자동으로 다시 요청하는 것을 방지
      final bool isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
      debugPrint('🔍 [지문인식] 플랫폼 확인: isMacOS=$isMacOS');
      
      // _localAuth.authenticate 호출 전 최종 체크 (플래그 설정 전에 체크)
      // 함수 시작 부분에서 이미 체크했지만, 동시 호출 방지를 위해 한 번 더 확인
      if (_isAuthDialogShowing || _authCompleter != null) {
        debugPrint('🔍 [지문인식] 최종 체크 실패, 종료');
        _isAuthenticating = false;
        return;
      }
      
      // 다이얼로그 표시 중 플래그 설정 (_localAuth.authenticate 호출 직전에만 설정)
      _isAuthDialogShowing = true;
      debugPrint('🔍 [지문인식] _isAuthDialogShowing=true 설정');
      
      // 플래그 설정 직후 다시 한 번 체크 (동시 호출 방지)
      if (!_isAuthenticating) {
        debugPrint('🔍 [지문인식] _isAuthenticating=false, 종료');
        _isAuthDialogShowing = false;
        return;
      }
      
      // Completer 생성하여 인증 프로세스 보호
      _authCompleter = Completer<bool>();
      debugPrint('🔍 [지문인식] Completer 생성 완료');
      
      // macOS에서는 biometricOnly: true로 설정하여 시스템이 자동으로 다시 요청하는 것을 방지
      final bool biometricOnly = isMacOS ? true : false;
      debugPrint('🔍 [지문인식] biometricOnly=$biometricOnly, authenticate 호출 시작...');
      
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Se requiere autenticación biométrica para usar la aplicación',
        options: AuthenticationOptions(
          biometricOnly: biometricOnly, // macOS에서는 true로 설정하여 중복 다이얼로그 방지
          stickyAuth: false, // stickyAuth를 false로 설정하여 중복 다이얼로그 방지
        ),
      );
      
      debugPrint('🔍 [지문인식] authenticate 완료, 결과: $didAuthenticate');
      
      // Completer 완료
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.complete(didAuthenticate);
        debugPrint('🔍 [지문인식] Completer 완료');
      }
      
      // 다이얼로그 닫힘 플래그 해제
      _isAuthDialogShowing = false;
      _authCompleter = null; // Completer 초기화
      debugPrint('🔍 [지문인식] 플래그 해제 완료');
      
      if (didAuthenticate) {
        debugPrint('🔍 [지문인식] 인증 성공, 메인 화면으로 이동');
        if (mounted) {
          _navigateToMain();
        }
      } else {
        debugPrint('🔍 [지문인식] 인증 취소');
        _isAuthDialogShowing = false; // 인증 취소 시 플래그 해제
        setState(() {
          _errorMessage = 'La autenticación fue cancelada';
          _isAuthenticating = false;
        });
      }
    } on PlatformException catch (e) {
      debugPrint('❌ [지문인식] PlatformException: ${e.message}');
      _isAuthDialogShowing = false; // 에러 발생 시 플래그 해제
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.completeError(e);
      }
      _authCompleter = null; // Completer 초기화
      setState(() {
        _errorMessage = 'Error durante la autenticación: ${e.message}';
        _isAuthenticating = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [지문인식] 일반 에러: $e');
      debugPrint('❌ [지문인식] 스택 트레이스: $stackTrace');
      _isAuthDialogShowing = false; // 에러 발생 시 플래그 해제
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.completeError(e);
      }
      _authCompleter = null; // Completer 초기화
      setState(() {
        _errorMessage = 'Ocurrió un error desconocido: $e';
        _isAuthenticating = false;
      });
    }
  }

  void _navigateToMain() {
    debugPrint('🔍 [지문인식] _navigateToMain 호출됨');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainConnectionScreen(
          onLanguageChanged: widget.onLanguageChanged,
          currentLocale: widget.currentLocale,
        ),
      ),
    );
    debugPrint('🔍 [지문인식] _navigateToMain 완료');
  }

  String _getBiometricTypeName() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Reconocimiento Facial';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Reconocimiento de Huella';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Reconocimiento de Iris';
    } else if (_availableBiometrics.contains(BiometricType.strong)) {
      return 'Autenticación Biométrica Fuerte';
    } else if (_availableBiometrics.contains(BiometricType.weak)) {
      return 'Autenticación Biométrica Débil';
    }
    return 'Autenticación Biométrica';
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return Icons.remove_red_eye;
    }
    return Icons.security;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getBiometricIcon(),
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isSupported ? _getBiometricTypeName() : 'Autenticación Biométrica',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isInitializing || _isAuthenticating)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  else if (_errorMessage.isNotEmpty)
                    Column(
                      children: [
                        Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (_isSupported)
                          ElevatedButton(
                            onPressed: () {
                              _authenticate();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            child: const Text('Intentar de Nuevo'),
                          )
                        else
                          ElevatedButton(
                            onPressed: _navigateToMain,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            child: const Text('Continuar sin Autenticación'),
                          ),
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        _authenticate();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Autenticar'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

