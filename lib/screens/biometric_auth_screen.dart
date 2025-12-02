import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
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
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _authenticate();
  }

  Future<void> _checkBiometrics() async {
    try {
      final bool isSupported = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();

      print('🔐 생체 인식 확인:');
      print('  - isDeviceSupported: $isSupported');
      print('  - canCheckBiometrics: $canCheckBiometrics');
      print('  - availableBiometrics: $availableBiometrics');

      setState(() {
        _isSupported = isSupported && canCheckBiometrics;
        _availableBiometrics = availableBiometrics;
      });

      // 생체 인식이 지원되지 않으면 사용자에게 알리고 건너뛰기 옵션 제공
      if (!_isSupported) {
        setState(() {
          _errorMessage = 'La autenticación biométrica no está disponible en este dispositivo.';
        });
      }
    } catch (e) {
      print('❌ 생체 인식 확인 오류: $e');
      setState(() {
        _isSupported = false;
        _errorMessage = 'Error al verificar la autenticación biométrica: $e';
      });
    }
  }

  Future<void> _authenticate() async {
    if (!_isSupported) {
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Se requiere autenticación biométrica para usar la aplicación',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        _navigateToMain();
      } else {
        setState(() {
          _errorMessage = 'La autenticación fue cancelada';
          _isAuthenticating = false;
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _errorMessage = 'Error durante la autenticación: ${e.message}';
        _isAuthenticating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error desconocido: $e';
        _isAuthenticating = false;
      });
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainConnectionScreen(
          onLanguageChanged: widget.onLanguageChanged,
          currentLocale: widget.currentLocale,
        ),
      ),
    );
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
                  if (_isAuthenticating)
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
                            onPressed: _authenticate,
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
                      onPressed: _authenticate,
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

