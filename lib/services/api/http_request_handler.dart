import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import '../secure_storage_helper.dart';
import '../../utils/ssl_client_helper.dart';

/// 공통 HTTP 요청 핸들러
class HttpRequestHandler {
  final String serverUrl;
  late final http.Client _httpClient;

  HttpRequestHandler({required this.serverUrl}) {
    // 자체 서명 인증서를 허용하는 커스텀 클라이언트 사용
    _httpClient = SslClientHelper.createUnsafeClient();
  }

  /// HTTP 클라이언트 접근 (내부 클라이언트 재사용을 위해)
  http.Client get httpClient => _httpClient;

  /// 리소스 정리
  void dispose() {
    _httpClient.close();
  }

  /// 저장된 데이터베이스 연결 정보를 읽어와서 헤더로 변환
  Future<Map<String, String>> getDatabaseHeaders() async {
    try {
      final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
      
      // macOS 개발 환경: 모든 데이터를 SharedPreferences에서 읽기
      // 다른 플랫폼: 하이브리드 방식 (일반 데이터는 SharedPreferences, 비밀번호는 SecureStorage)
      final databaseName = await SecureStorageHelper.read('database_name') ?? '';
      final username = await SecureStorageHelper.read('username') ?? '';
      final password = isMacOS
          ? await SecureStorageHelper.read('password') ?? ''  // macOS: SharedPreferences
          : await SecureStorageHelper.readSecure('password') ?? '';  // 다른 플랫폼: SecureStorage

      // 헤더가 비어있으면 경고 출력
      if (databaseName.isEmpty || username.isEmpty || password.isEmpty) {
        print('⚠️ 저장된 데이터베이스 연결 정보가 없거나 불완전합니다.');
        print('   → 데이터베이스에 다시 연결해주세요.');
        throw Exception('Invalid or missing database headers: database_name, username, 또는 password가 저장되지 않았습니다. 데이터베이스에 다시 연결해주세요.');
      }

      final headers = {
        'Content-Type': 'application/json',
        'x-db-name': databaseName,
        'x-db-user': username,
        'x-db-password': password,
        'x-db-ssl': 'false',
        // Keep-Alive 헤더 추가로 연결 재사용 최적화
        'Connection': 'keep-alive',
      };
      
      return headers;
    } catch (e) {
      print('❌ 데이터베이스 헤더 읽기 오류: $e');
      throw Exception('Invalid or missing database headers: ${e.toString()}');
    }
  }

  /// 공통 GET 요청 메서드 (오류 처리 포함)
  Future<Map<String, dynamic>> performGetRequest(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      // 데이터베이스 연결 정보를 헤더로 가져오기
      final headers = await getDatabaseHeaders();
      return await performGetRequestWithHeaders(
        endpoint,
        headers: headers,
        queryParameters: queryParameters,
      );
    } catch (e) {
      print('❌ GET $endpoint 오류: $e');
      return _handleError(e);
    }
  }

  /// 헤더를 직접 지정하는 GET 요청 메서드
  Future<Map<String, dynamic>> performGetRequestWithHeaders(
    String endpoint, {
    required Map<String, String> headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
      // 쿼리 파라미터가 있으면 URL에 추가
      final uri = Uri.parse('$serverUrl$endpoint');
      final uriWithQuery = queryParameters != null && queryParameters.isNotEmpty
          ? uri.replace(queryParameters: queryParameters)
          : uri;
      
      print('=== GET $endpoint 요청 ===');
      print('URL: $uriWithQuery');
      print('Headers: $headers');
      if (queryParameters != null && queryParameters.isNotEmpty) {
        print('Query Parameters: $queryParameters');
      }
      
      final response = await _httpClient.get(
        uriWithQuery,
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('❌ 요청 타임아웃 (10초 초과)');
          throw Exception('요청 타임아웃: 서버 응답이 10초를 초과했습니다. 서버가 실행 중인지 확인하세요.');
        },
      );

      print('=== 응답 정보 ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body Length: ${response.body.length} bytes');
      
      // 응답 본문 로깅 (에러인 경우에만 상세히)
      if (response.statusCode != 200 && response.body.isNotEmpty) {
        final bodyPreview = response.body.length > 500 
            ? '${response.body.substring(0, 500)}... (${response.body.length} bytes total)'
            : response.body;
        print('Response Body: $bodyPreview');
      }
      
      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(response.body);
          int itemCount = 0;
          if (decoded is Map) {
            if (decoded.containsKey('data') && decoded['data'] is List) {
              itemCount = (decoded['data'] as List).length;
            } else if (decoded.containsKey('summary') && decoded['summary'] is Map) {
              itemCount = decoded['summary']['total_items'] ?? 0;
            } else {
              itemCount = decoded.length;
            }
            print('✅ 응답 성공: $itemCount개 항목');
            return decoded as Map<String, dynamic>;
          } else if (decoded is List) {
            itemCount = decoded.length;
            print('✅ 응답 성공: $itemCount개 항목');
            return {'data': decoded};
          } else {
            print('✅ 응답 성공');
            return {'result': decoded};
          }
        } catch (e) {
          print('❌ JSON 파싱 오류: $e');
          print('❌ 응답 본문: ${response.body}');
          throw Exception('JSON 파싱 오류: 서버 응답을 파싱할 수 없습니다.');
        }
      } else {
        // 에러 응답 처리
        String errorMessage = _extractErrorMessage(response);
        print('❌ HTTP 오류 (${response.statusCode}): $errorMessage');
        
        // 에러 메시지가 이미 상태 코드를 포함하고 있으면 중복으로 감싸지 않음
        final alreadyHasStatusCode = errorMessage.contains('(${response.statusCode})') ||
                                     errorMessage.contains('HTTP ${response.statusCode}') ||
                                     errorMessage.contains('${response.statusCode} 오류');
        
        if (alreadyHasStatusCode) {
          // 이미 완전한 메시지이므로 그대로 사용
          throw Exception(errorMessage);
        }
        
        // 클라이언트 측 에러 (4xx)와 서버 측 에러 (5xx) 구분
        if (response.statusCode >= 400 && response.statusCode < 500) {
          throw Exception('요청 오류 (${response.statusCode}): $errorMessage');
        } else {
          throw Exception('서버 오류 (${response.statusCode}): $errorMessage');
        }
      }
    } catch (e) {
      print('❌ GET $endpoint 오류: $e');
      return _handleError(e);
    }
  }

  /// 공통 POST 요청 메서드 (오류 처리 포함)
  Future<Map<String, dynamic>> performPostRequest(
    String endpoint,
    Map<String, dynamic> body, {
    int timeoutSeconds = 10,
  }) async {
    try {
      final headers = await getDatabaseHeaders();
      
      print('=== POST $endpoint 요청 ===');
      print('URL: $serverUrl$endpoint');
      print('Headers: $headers');
      print('Timeout: $timeoutSeconds초');
      print('Request Body Length: ${json.encode(body).length} bytes');
      
      final requestStartTime = DateTime.now();
      http.Response response;
      try {
        response = await _httpClient.post(
          Uri.parse('$serverUrl$endpoint'),
          headers: headers,
          body: json.encode(body),
        ).timeout(
          Duration(seconds: timeoutSeconds),
          onTimeout: () {
            final elapsed = DateTime.now().difference(requestStartTime);
            print('❌ 요청 타임아웃 ($timeoutSeconds초 초과, 실제 경과: ${elapsed.inSeconds}초)');
            throw Exception('요청 타임아웃: 서버 응답이 $timeoutSeconds초를 초과했습니다. 서버가 실행 중인지 확인하세요.');
          },
        );
        final elapsed = DateTime.now().difference(requestStartTime);
        print('⏱️ 요청 완료 시간: ${elapsed.inMilliseconds}ms');
      } catch (e) {
        final elapsed = DateTime.now().difference(requestStartTime);
        print('❌ POST 요청 중 예외 발생 (경과: ${elapsed.inMilliseconds}ms): $e');
        rethrow;
      }

      print('=== 응답 정보 ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body Length: ${response.body.length} bytes');
      
      // 응답 본문 로깅 (너무 길면 일부만)
      if (response.body.isNotEmpty) {
        final bodyPreview = response.body.length > 500 
            ? '${response.body.substring(0, 500)}... (${response.body.length} bytes total)'
            : response.body;
        print('Response Body: $bodyPreview');
      } else {
        print('Response Body: (empty)');
      }

      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(response.body);
          
          // resumen_del_dia 엔드포인트인 경우 원본 데이터 로깅
          if (endpoint.contains('resumen_del_dia')) {
            print('📋 resumen_del_dia 원본 응답 데이터:');
            if (decoded is Map) {
              decoded.forEach((key, value) {
                if (value is List) {
                  print('  - $key: List (${value.length}개 항목)');
                } else if (value is Map) {
                  print('  - $key: Map (${value.keys.toList()})');
                } else {
                  print('  - $key: ${value.runtimeType} = $value');
                }
              });
            }
          }
          
          // 서버 로그 메시지가 포함되어 있는지 확인하고 필터링
          if (decoded is Map) {
            // 서버 로그 메시지 필드 제거 (사용자에게 표시하지 않음)
            final filteredDecoded = Map<String, dynamic>.from(decoded);
            final removedKeys = <String>[];
            filteredDecoded.removeWhere((key, value) {
              final keyLower = key.toLowerCase();
              final valueStr = value.toString().toLowerCase();
              
              // PostgreSQL 연결 정보나 서버 로그 메시지 필터링
              final shouldRemove = keyLower.contains('postgresql') ||
                     keyLower.contains('연결') ||
                     keyLower.contains('connection') ||
                     valueStr.contains('postgresql 연결') ||
                     valueStr.contains('ventas 보고서 오류') ||
                     (valueStr.contains('함수') && valueStr.contains('fallback')) ||
                     // 에러 메시지 필드도 필터링 (하지만 실제 데이터 키는 제외)
                     (keyLower.contains('error') && !keyLower.contains('vcodes') && !keyLower.contains('gastos')) ||
                     (keyLower.contains('오류') && !keyLower.contains('vcodes') && !keyLower.contains('gastos')) ||
                     valueStr.contains('게이트웨이 오류') ||
                     valueStr.contains('bad gateway') ||
                     valueStr.contains('서버 오류');
              
              if (shouldRemove) {
                removedKeys.add(key);
              }
              return shouldRemove;
            });
            
            // 필터링된 키 로깅
            if (removedKeys.isNotEmpty && endpoint.contains('resumen_del_dia')) {
              print('⚠️ 필터링된 키: $removedKeys');
            }
            
            // 응답 데이터에 에러 메시지가 포함되어 있는지 확인
            // 만약 에러 메시지만 있고 실제 데이터가 없으면 예외 발생
            if (filteredDecoded.isEmpty && decoded.isNotEmpty) {
              // 모든 필드가 필터링되었지만 원본에는 데이터가 있었음
              // 에러 메시지만 포함된 경우
              final hasOnlyErrorMessages = decoded.values.every((value) {
                final valueStr = value.toString().toLowerCase();
                return valueStr.contains('오류') ||
                       valueStr.contains('error') ||
                       valueStr.contains('게이트웨이') ||
                       valueStr.contains('bad gateway') ||
                       valueStr.contains('서버');
              });
              
              if (hasOnlyErrorMessages) {
                // 에러 메시지만 있는 경우 예외 발생
                final errorMsg = decoded.values.first.toString();
                throw Exception(errorMsg);
              }
            }
            
            int itemCount = 0;
            if (filteredDecoded.containsKey('data') && filteredDecoded['data'] is List) {
              itemCount = (filteredDecoded['data'] as List).length;
            } else if (filteredDecoded.containsKey('summary') && filteredDecoded['summary'] is Map) {
              itemCount = filteredDecoded['summary']['total_items'] ?? 0;
            } else {
              itemCount = filteredDecoded.length;
            }
            print('✅ 응답 성공: $itemCount개 항목');
            return filteredDecoded;
          } else if (decoded is List) {
            int itemCount = decoded.length;
            print('✅ 응답 성공: $itemCount개 항목');
            return {'data': decoded};
          } else {
            print('✅ 응답 성공');
            return {'result': decoded};
          }
        } catch (e) {
          print('❌ JSON 파싱 오류: $e');
          print('❌ 응답 본문: ${response.body}');
          throw Exception('JSON 파싱 오류: 서버 응답을 파싱할 수 없습니다.');
        }
      } else {
        // 502 Bad Gateway 에러인 경우 재시도 (일시적인 서버 문제일 수 있음)
        if (response.statusCode == 502) {
          print('⚠️ 502 Bad Gateway 에러 발생, 재시도 시도...');
          
          // 최대 3번 재시도 (총 4번 시도), 간격을 늘려서 서버 복구 시간 제공
          for (int retry = 1; retry <= 3; retry++) {
            final delaySeconds = retry; // 1초, 2초, 3초
            print('🔄 재시도 $retry/3... ($delaySeconds초 대기 후)');
            await Future.delayed(Duration(seconds: delaySeconds));
            
            try {
              final retryResponse = await _httpClient.post(
                Uri.parse('$serverUrl$endpoint'),
                headers: headers,
                body: json.encode(body),
              ).timeout(
                Duration(seconds: timeoutSeconds),
              );
              
              print('=== 재시도 응답 정보 ===');
              print('Status Code: ${retryResponse.statusCode}');
              
              if (retryResponse.statusCode == 200) {
                print('✅ 재시도 성공!');
                // 성공 응답 처리 (위의 200 처리 로직과 동일)
                try {
                  final decoded = json.decode(retryResponse.body);
                  if (decoded is Map) {
                    final filteredDecoded = Map<String, dynamic>.from(decoded);
                    filteredDecoded.removeWhere((key, value) {
                      final keyLower = key.toLowerCase();
                      final valueStr = value.toString().toLowerCase();
                      return keyLower.contains('postgresql') ||
                             keyLower.contains('연결') ||
                             keyLower.contains('connection') ||
                             valueStr.contains('postgresql 연결') ||
                             valueStr.contains('ventas 보고서 오류') ||
                             (valueStr.contains('함수') && valueStr.contains('fallback')) ||
                             keyLower.contains('error') ||
                             keyLower.contains('오류') ||
                             valueStr.contains('게이트웨이 오류') ||
                             valueStr.contains('bad gateway') ||
                             valueStr.contains('서버 오류');
                    });
                    int itemCount = 0;
                    if (filteredDecoded.containsKey('data') && filteredDecoded['data'] is List) {
                      itemCount = (filteredDecoded['data'] as List).length;
                    } else if (filteredDecoded.containsKey('summary') && filteredDecoded['summary'] is Map) {
                      itemCount = filteredDecoded['summary']['total_items'] ?? 0;
                    } else {
                      itemCount = filteredDecoded.length;
                    }
                    print('✅ 응답 성공: $itemCount개 항목');
                    return filteredDecoded;
                  } else if (decoded is List) {
                    print('✅ 응답 성공: ${decoded.length}개 항목');
                    return {'data': decoded};
                  } else {
                    print('✅ 응답 성공');
                    return {'result': decoded};
                  }
                } catch (e) {
                  print('❌ JSON 파싱 오류: $e');
                  throw Exception('JSON 파싱 오류: 서버 응답을 파싱할 수 없습니다.');
                }
              } else if (retryResponse.statusCode != 502 || retry == 3) {
                // 다른 에러이거나 마지막 재시도인 경우
                response = retryResponse;
                break;
              }
              // 502 에러이고 재시도 횟수가 남아있으면 계속
            } catch (e) {
              print('❌ 재시도 $retry 실패: $e');
              if (retry == 3) {
                // 마지막 재시도 실패 - 원래 응답으로 처리
                break;
              }
            }
          }
        }
        
        // 에러 응답 처리
        String errorMessage = _extractErrorMessage(response);
        print('❌ HTTP 오류 (${response.statusCode}): $errorMessage');
        
        // 에러 메시지가 이미 상태 코드를 포함하고 있으면 중복으로 감싸지 않음
        final alreadyHasStatusCode = errorMessage.contains('(${response.statusCode})') ||
                                     errorMessage.contains('HTTP ${response.statusCode}') ||
                                     errorMessage.contains('${response.statusCode} 오류');
        
        if (alreadyHasStatusCode) {
          // 이미 완전한 메시지이므로 그대로 사용
          throw Exception(errorMessage);
        }
        
        // 클라이언트 측 에러 (4xx)와 서버 측 에러 (5xx) 구분
        if (response.statusCode >= 400 && response.statusCode < 500) {
          throw Exception('요청 오류 (${response.statusCode}): $errorMessage');
        } else {
          throw Exception('서버 오류 (${response.statusCode}): $errorMessage');
        }
      }
    } catch (e) {
      print('❌ POST $endpoint 오류: $e');
      return _handleError(e);
    }
  }

  /// 공통 PUT 요청 메서드 (오류 처리 포함)
  Future<Map<String, dynamic>> performPutRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final headers = await getDatabaseHeaders();
      
      print('=== PUT $endpoint 요청 ===');
      print('URL: $serverUrl$endpoint');
      
      final response = await _httpClient.put(
        Uri.parse('$serverUrl$endpoint'),
        headers: headers,
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('❌ 요청 타임아웃 (10초 초과)');
          throw Exception('요청 타임아웃: 서버 응답이 10초를 초과했습니다. 서버가 실행 중인지 확인하세요.');
        },
      );

      print('=== 응답 정보 ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body Length: ${response.body.length} bytes');
      
      // 응답 본문 로깅 (에러인 경우에만 상세히)
      if (response.statusCode != 200 && response.statusCode != 204 && response.body.isNotEmpty) {
        final bodyPreview = response.body.length > 500 
            ? '${response.body.substring(0, 500)}... (${response.body.length} bytes total)'
            : response.body;
        print('Response Body: $bodyPreview');
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        try {
          if (response.body.isEmpty) {
            print('✅ 응답 성공 (빈 응답)');
            return {'success': true};
          }
          final decoded = json.decode(response.body);
          int itemCount = 0;
          if (decoded is Map) {
            if (decoded.containsKey('data') && decoded['data'] is List) {
              itemCount = (decoded['data'] as List).length;
            } else {
              itemCount = decoded.length;
            }
            print('✅ 응답 성공: $itemCount개 항목');
            return decoded as Map<String, dynamic>;
          } else if (decoded is List) {
            itemCount = decoded.length;
            print('✅ 응답 성공: $itemCount개 항목');
            return {'data': decoded};
          } else {
            print('✅ 응답 성공');
            return {'result': decoded};
          }
        } catch (e) {
          print('❌ JSON 파싱 오류: $e');
          print('❌ 응답 본문: ${response.body}');
          throw Exception('JSON 파싱 오류: 서버 응답을 파싱할 수 없습니다.');
        }
      } else {
        // 에러 응답 처리
        String errorMessage = _extractErrorMessage(response);
        print('❌ HTTP 오류 (${response.statusCode}): $errorMessage');
        
        // 에러 메시지가 이미 상태 코드를 포함하고 있으면 중복으로 감싸지 않음
        final alreadyHasStatusCode = errorMessage.contains('(${response.statusCode})') ||
                                     errorMessage.contains('HTTP ${response.statusCode}') ||
                                     errorMessage.contains('${response.statusCode} 오류');
        
        if (alreadyHasStatusCode) {
          // 이미 완전한 메시지이므로 그대로 사용
          throw Exception(errorMessage);
        }
        
        // 클라이언트 측 에러 (4xx)와 서버 측 에러 (5xx) 구분
        if (response.statusCode >= 400 && response.statusCode < 500) {
          throw Exception('요청 오류 (${response.statusCode}): $errorMessage');
        } else {
          throw Exception('서버 오류 (${response.statusCode}): $errorMessage');
        }
      }
    } catch (e) {
      print('❌ PUT $endpoint 오류: $e');
      return _handleError(e);
    }
  }

  /// 공통 DELETE 요청 메서드 (오류 처리 포함)
  Future<Map<String, dynamic>> performDeleteRequest(
    String endpoint,
  ) async {
    try {
      final headers = await getDatabaseHeaders();
      
      print('=== DELETE $endpoint 요청 ===');
      print('URL: $serverUrl$endpoint');
      
      final response = await _httpClient.delete(
        Uri.parse('$serverUrl$endpoint'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('❌ 요청 타임아웃 (10초 초과)');
          throw Exception('요청 타임아웃: 서버 응답이 10초를 초과했습니다. 서버가 실행 중인지 확인하세요.');
        },
      );

      print('=== 응답 정보 ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body Length: ${response.body.length} bytes');
      
      // 응답 본문 로깅 (에러인 경우에만 상세히)
      if (response.statusCode != 200 && response.statusCode != 204 && response.body.isNotEmpty) {
        final bodyPreview = response.body.length > 500 
            ? '${response.body.substring(0, 500)}... (${response.body.length} bytes total)'
            : response.body;
        print('Response Body: $bodyPreview');
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 성공 응답 처리
        if (response.body.isEmpty) {
          return {'success': true};
        }
        
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          print('⚠️ JSON 파싱 실패: $e');
          throw Exception('JSON 파싱 오류: 서버 응답을 파싱할 수 없습니다.');
        }
      } else {
        // 에러 응답 처리
        String errorMessage = _extractErrorMessage(response);
        print('❌ HTTP 오류 (${response.statusCode}): $errorMessage');
        
        // 에러 메시지가 이미 상태 코드를 포함하고 있으면 중복으로 감싸지 않음
        final alreadyHasStatusCode = errorMessage.contains('(${response.statusCode})') ||
                                     errorMessage.contains('HTTP ${response.statusCode}') ||
                                     errorMessage.contains('${response.statusCode} 오류');
        
        if (alreadyHasStatusCode) {
          // 이미 완전한 메시지이므로 그대로 사용
          throw Exception(errorMessage);
        }
        
        // 클라이언트 측 에러 (4xx)와 서버 측 에러 (5xx) 구분
        if (response.statusCode >= 400 && response.statusCode < 500) {
          throw Exception('요청 오류 (${response.statusCode}): $errorMessage');
        } else {
          throw Exception('서버 오류 (${response.statusCode}): $errorMessage');
        }
      }
    } catch (e) {
      print('❌ DELETE $endpoint 오류: $e');
      return _handleError(e);
    }
  }

  /// 에러 메시지 추출
  String _extractErrorMessage(http.Response response) {
    // HTTP 상태 코드에 따른 기본 메시지
    String errorMessage = _getDefaultErrorMessage(response.statusCode);
    
    // 응답 본문이 비어있으면 기본 메시지 반환
    if (response.body.isEmpty) {
      print('⚠️ 에러 응답 본문이 비어있습니다.');
      return errorMessage;
    }
    
    // HTML 응답인지 먼저 확인 (시작 부분뿐만 아니라 내용도 확인)
    final bodyTrimmed = response.body.trim();
    final bodyLower = bodyTrimmed.toLowerCase();
    if (bodyLower.startsWith('<html') || 
        bodyLower.startsWith('<!doctype') ||
        bodyLower.contains('</html>') ||
        bodyLower.contains('<html>') ||
        bodyLower.contains('<head>') ||
        bodyLower.contains('<body>')) {
      print('⚠️ HTML 응답 감지: ${bodyTrimmed.length} bytes');
      print('   HTML 내용 미리보기: ${bodyTrimmed.length > 200 ? "${bodyTrimmed.substring(0, 200)}..." : bodyTrimmed}');
      return _extractMessageFromHtml(bodyTrimmed, response.statusCode);
    }
    
    try {
      // JSON 응답인지 확인
      final errorBody = json.decode(response.body);
      
      // JSON 응답 구조 로깅 (디버깅용)
      if (errorBody is Map) {
        print('📋 에러 응답 JSON 구조:');
        errorBody.forEach((key, value) {
          if (value is String && value.length > 100) {
            print('  $key: ${value.substring(0, 100)}... (${value.length} chars)');
          } else {
            print('  $key: $value');
          }
        });
      }
      
      // 다양한 에러 필드명 확인 (우선순위 순)
      if (errorBody is Map) {
        if (errorBody.containsKey('message')) {
          errorMessage = errorBody['message'].toString();
        } else if (errorBody.containsKey('error')) {
          errorMessage = errorBody['error'].toString();
        } else if (errorBody.containsKey('detail')) {
          errorMessage = errorBody['detail'].toString();
        } else if (errorBody.containsKey('errors')) {
          // errors가 배열인 경우
          if (errorBody['errors'] is List && (errorBody['errors'] as List).isNotEmpty) {
            errorMessage = (errorBody['errors'] as List).first.toString();
          } else if (errorBody['errors'] is Map) {
            errorMessage = errorBody['errors'].toString();
          }
        } else if (errorBody.containsKey('msg')) {
          errorMessage = errorBody['msg'].toString();
        } else if (errorBody.containsKey('errorMessage')) {
          errorMessage = errorBody['errorMessage'].toString();
        }
      }
      
      // 서버 로그 메시지 필터링 (성공 응답에 포함된 경우 무시)
      if (response.statusCode == 200) {
        // 성공 응답에 서버 로그가 포함되어 있어도 무시
        if (errorMessage.contains('PostgreSQL 연결') ||
            errorMessage.contains('Ventas 보고서 오류') ||
            errorMessage.contains('함수') && errorMessage.contains('fallback') ||
            errorMessage.contains('함수가 존재하지 않아 직접 쿼리로 fallback')) {
          // 서버가 성공적으로 fallback 처리했다면 에러가 아님
          return errorMessage; // 원본 메시지 반환 (하지만 에러로 처리되지 않음)
        }
      }
      
      // 데이터베이스 함수 관련 에러 감지 (에러 응답인 경우에만)
      if (errorMessage.toLowerCase().contains('function') && 
          errorMessage.toLowerCase().contains('does not exist')) {
        // fallback 성공 메시지가 포함되어 있으면 무시
        if (errorMessage.toLowerCase().contains('fallback') ||
            errorMessage.toLowerCase().contains('대체 방법')) {
          // 서버가 성공적으로 처리했다는 의미이므로 에러가 아님
          return errorMessage;
        }
        
        final functionMatch = RegExp(r'function\s+(\w+)\s*\(').firstMatch(errorMessage.toLowerCase());
        if (functionMatch != null) {
          final functionName = functionMatch.group(1);
          return '데이터베이스 함수 오류: 함수 "$functionName"이(가) 존재하지 않습니다. 서버 관리자에게 문의하세요. (서버가 대체 방법으로 처리할 수 있습니다)';
        }
      }
      
      // DatabaseError 감지
      if (errorBody is Map) {
        final errorType = errorBody['Error type']?.toString() ?? 
                         errorBody['error_type']?.toString() ?? 
                         errorBody['type']?.toString();
        if (errorType != null && errorType.toLowerCase().contains('database')) {
          final originalError = errorBody['Original error']?.toString() ?? 
                               errorBody['original_error']?.toString() ?? 
                               errorBody['message']?.toString();
          if (originalError != null) {
            // 함수 존재하지 않음
            if (originalError.toLowerCase().contains('function') &&
                originalError.toLowerCase().contains('does not exist')) {
              return '데이터베이스 함수 오류: 요청한 함수가 존재하지 않습니다. 서버가 대체 방법으로 처리할 수 있습니다.';
            }
            // 제약 조건 위반
            if (originalError.toLowerCase().contains('unique constraint') ||
                originalError.toLowerCase().contains('constraint violation')) {
              return '데이터 중복 오류: 이미 존재하는 데이터입니다.';
            }
          }
        }
        
        // Validation error 감지
        final problemSource = errorBody['Problem Source']?.toString() ?? 
                              errorBody['problem_source']?.toString();
        if (problemSource != null && 
            problemSource.toLowerCase().contains('constraint')) {
          return '데이터 제약 조건 위반: 입력한 데이터가 데이터베이스 규칙을 위반했습니다.';
        }
        
        // CLIENT_DATA validation error 감지
        if (errorMessage.toLowerCase().contains('validation error') &&
            errorBody.containsKey('Problem Source')) {
          final problemSource = errorBody['Problem Source']?.toString() ?? '';
          if (problemSource.toLowerCase().contains('constraint')) {
            return '데이터 제약 조건 위반: 입력한 데이터가 데이터베이스 규칙을 위반했습니다.';
          }
          return '데이터 검증 오류: 입력한 데이터가 유효하지 않습니다.';
        }
      }
    } catch (e) {
      // JSON 파싱 실패 시 HTML 또는 일반 텍스트 응답 처리
      if (response.body.isNotEmpty) {
        final body = response.body.trim();
        
        // HTML 응답인지 확인
        if (body.toLowerCase().contains('<html>') || 
            body.toLowerCase().contains('<!doctype')) {
          errorMessage = _extractMessageFromHtml(body, response.statusCode);
        } else {
          // 일반 텍스트 응답
          errorMessage = body;
        }
      }
    }
    
    return errorMessage;
  }

  /// HTTP 상태 코드에 따른 기본 에러 메시지 반환
  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return '잘못된 요청입니다. 요청 데이터 형식이나 필수 필드를 확인해주세요.';
      case 401:
        return '인증이 필요합니다. 로그인 정보를 확인해주세요.';
      case 403:
        return '접근 권한이 없습니다.';
      case 404:
        return '요청한 리소스를 찾을 수 없습니다.';
      case 409:
        return '데이터 충돌: 이미 존재하는 데이터이거나 충돌이 발생했습니다.';
      case 422:
        return '요청 데이터 검증 실패: 입력한 데이터가 유효하지 않습니다.';
      case 500:
        return '서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      case 502:
        return '게이트웨이 오류: 백엔드 서버에 연결할 수 없습니다. 서버 관리자에게 문의하거나 잠시 후 다시 시도해주세요.';
      case 503:
        return '서비스를 일시적으로 사용할 수 없습니다. 잠시 후 다시 시도해주세요.';
      case 504:
        return '게이트웨이 타임아웃: 서버 응답 시간이 초과되었습니다.';
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return '요청 오류 (HTTP $statusCode): 클라이언트 측 문제가 발생했습니다.';
        } else if (statusCode >= 500) {
          return '서버 오류 (HTTP $statusCode): 서버 측 문제가 발생했습니다.';
        }
        return 'HTTP $statusCode 오류가 발생했습니다.';
    }
  }

  /// HTML 응답에서 메시지 추출
  String _extractMessageFromHtml(String htmlBody, int statusCode) {
    // 502 Bad Gateway HTML 응답 처리
    // 상태 코드를 포함하지 않고 반환 (호출하는 쪽에서 추가하므로 중복 방지)
    if (statusCode == 502) {
      if (htmlBody.toLowerCase().contains('502 bad gateway') ||
          htmlBody.toLowerCase().contains('bad gateway')) {
        return '백엔드 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인하거나 서버 관리자에게 문의해주세요.';
      }
    }
    
    // HTML 태그 제거 시도
    String cleaned = htmlBody
        .replaceAll(RegExp(r'<[^>]*>', multiLine: true), '')
        .replaceAll(RegExp(r'\s+', multiLine: true), ' ')
        .trim();
    
    // 의미 있는 텍스트가 있으면 사용, 없으면 기본 메시지
    if (cleaned.length > 10 && cleaned.length < 500) {
      return cleaned;
    }
    
    return _getDefaultErrorMessage(statusCode);
  }

  /// 에러 처리
  Map<String, dynamic> _handleError(dynamic e) {
    String errorMessage = e.toString();
    
    // HTML 응답이 포함되어 있는지 확인하고 정제
    if (errorMessage.toLowerCase().contains('<html>') || 
        errorMessage.toLowerCase().contains('<!doctype')) {
      errorMessage = _cleanErrorMessage(errorMessage);
    }
    
    // HTTP 상태 코드 추출 (502, 503 등)
    int? statusCode = _extractStatusCode(errorMessage);
    
    if (errorMessage.contains('SocketException') || 
        errorMessage.contains('Failed host lookup')) {
      throw Exception('네트워크 오류: 서버에 연결할 수 없습니다. 서버 URL과 인터넷 연결을 확인하세요.');
    } else if (errorMessage.contains('timeout')) {
      throw Exception('요청 타임아웃: 서버가 응답하지 않습니다. 서버가 실행 중인지 확인하세요.');
    } else if (errorMessage.contains('CERTIFICATE_VERIFY_FAILED') ||
               errorMessage.contains('HandshakeException') ||
               errorMessage.contains('self signed certificate')) {
      throw Exception('SSL 인증서 오류: 자체 서명 인증서가 감지되었습니다. SSL 클라이언트 설정을 확인하세요.');
    } else if (statusCode != null) {
      // HTTP 상태 코드가 있으면 해당하는 메시지 사용
      throw Exception(_getDefaultErrorMessage(statusCode));
    } else {
      // HTML 태그와 불필요한 정보 제거
      String cleanedMessage = _cleanErrorMessage(errorMessage);
      
      // 서버 로그 메시지가 필터링되어 빈 문자열이 된 경우
      if (cleanedMessage.isEmpty) {
        // 서버가 성공적으로 처리했다는 의미이므로 에러가 아님
        // 하지만 _handleError는 에러를 던져야 하므로 기본 메시지 사용
        throw Exception('요청이 처리되었습니다.');
      }
      
      throw Exception(cleanedMessage);
    }
  }

  /// 에러 메시지에서 HTTP 상태 코드 추출
  int? _extractStatusCode(String errorMessage) {
    // "서버 오류 (502):" 또는 "HTTP 502" 패턴 찾기
    final statusCodeMatch = RegExp(r'(?:서버 오류|HTTP|오류)\s*\(?(\d{3})\)?').firstMatch(errorMessage);
    if (statusCodeMatch != null && statusCodeMatch.group(1) != null) {
      return int.tryParse(statusCodeMatch.group(1)!);
    }
    
    // "502 Bad Gateway" 패턴 찾기
    final badGatewayMatch = RegExp(r'(\d{3})\s+Bad Gateway').firstMatch(errorMessage);
    if (badGatewayMatch != null && badGatewayMatch.group(1) != null) {
      return int.tryParse(badGatewayMatch.group(1)!);
    }
    
    return null;
  }

  /// 에러 메시지 정제 (HTML 태그 제거 및 불필요한 정보 제거)
  String _cleanErrorMessage(String errorMessage) {
    // "Exception: " 제거
    String cleaned = errorMessage.replaceAll(RegExp(r'Exception:\s*'), '');
    
    // "요청 실패: " 제거 (중복 방지)
    cleaned = cleaned.replaceAll(RegExp(r'요청 실패:\s*'), '');
    
    // "서버 오류 (502): " 같은 패턴에서 상태 코드만 남기고 메시지 정제
    cleaned = cleaned.replaceAll(RegExp(r'서버 오류\s*\(\d{3}\):\s*'), '');
    
    // 서버 로그 메시지 필터링 (사용자에게 표시하지 않음)
    if (cleaned.contains('PostgreSQL 연결') ||
        cleaned.contains('Ventas 보고서 오류') ||
        (cleaned.contains('함수') && cleaned.contains('fallback')) ||
        cleaned.contains('함수가 존재하지 않아 직접 쿼리로 fallback')) {
      // 서버 로그 메시지는 무시 (서버가 성공적으로 처리했다는 의미)
      // 빈 문자열 대신 기본 성공 메시지 반환하지 않음 (에러가 아니므로)
      return ''; // 빈 문자열은 호출하는 쪽에서 처리됨
    }
    
    // 데이터베이스 함수 관련 에러 감지 및 처리
    if (cleaned.toLowerCase().contains('function') && 
        cleaned.toLowerCase().contains('does not exist')) {
      // 데이터베이스 함수가 존재하지 않는 경우
      final functionMatch = RegExp(r'function\s+(\w+)\s*\(').firstMatch(cleaned.toLowerCase());
      if (functionMatch != null) {
        final functionName = functionMatch.group(1);
        return '데이터베이스 함수 오류: 함수 "$functionName"이(가) 존재하지 않습니다. 서버 관리자에게 문의하세요. (서버가 대체 방법으로 처리할 수 있습니다)';
      }
      return '데이터베이스 함수 오류: 요청한 함수가 존재하지 않습니다. 서버 관리자에게 문의하세요.';
    }
    
    // Validation error 감지
    if (cleaned.toLowerCase().contains('validation error')) {
      // 제약 조건 위반 정보 추출 시도
      if (cleaned.toLowerCase().contains('unique constraint')) {
        final constraintMatch = RegExp(r'unique constraint\s*\(([^)]+)\)').firstMatch(cleaned.toLowerCase());
        if (constraintMatch != null) {
          final constraintName = constraintMatch.group(1);
          return '데이터 중복 오류: 이미 존재하는 데이터입니다. (제약 조건: $constraintName)';
        }
        return '데이터 중복 오류: 이미 존재하는 데이터입니다.';
      }
      if (cleaned.toLowerCase().contains('constraint violation')) {
        return '데이터 제약 조건 위반: 입력한 데이터가 데이터베이스 규칙을 위반했습니다.';
      }
      return '데이터 검증 오류: 입력한 데이터가 유효하지 않습니다.';
    }
    
    // Database constraint violation 감지
    if (cleaned.toLowerCase().contains('constraint violation') ||
        cleaned.toLowerCase().contains('constraint') && cleaned.toLowerCase().contains('violation')) {
      if (cleaned.toLowerCase().contains('unique')) {
        return '데이터 중복 오류: 이미 존재하는 데이터입니다.';
      }
      return '데이터 제약 조건 위반: 입력한 데이터가 데이터베이스 규칙을 위반했습니다.';
    }
    
    // Unique constraint 감지
    if (cleaned.toLowerCase().contains('unique constraint')) {
      final constraintMatch = RegExp(r'unique constraint\s*\(([^)]+)\)').firstMatch(cleaned.toLowerCase());
      if (constraintMatch != null) {
        final constraintName = constraintMatch.group(1);
        return '데이터 중복 오류: 이미 존재하는 데이터입니다. (제약 조건: $constraintName)';
      }
      return '데이터 중복 오류: 이미 존재하는 데이터입니다.';
    }
    
    // INSERT/UPDATE 실패 감지
    if ((cleaned.toLowerCase().contains('insert') || cleaned.toLowerCase().contains('update')) &&
        cleaned.toLowerCase().contains('failed')) {
      if (cleaned.toLowerCase().contains('validation')) {
        return '데이터 저장 실패: 입력한 데이터가 유효하지 않습니다.';
      }
      if (cleaned.toLowerCase().contains('constraint')) {
        return '데이터 저장 실패: 데이터 제약 조건을 위반했습니다.';
      }
      return '데이터 저장 실패: 데이터를 저장하는 중 문제가 발생했습니다.';
    }
    
    // DatabaseError 감지
    if (cleaned.toLowerCase().contains('databaseerror') ||
        cleaned.toLowerCase().contains('database error')) {
      // 데이터베이스 에러 코드 추출 시도
      final errorCodeMatch = RegExp(r'code:\s*(\d+)').firstMatch(cleaned.toLowerCase());
      if (errorCodeMatch != null) {
        final errorCode = errorCodeMatch.group(1);
        return '데이터베이스 오류 (코드: $errorCode): 데이터베이스 작업 중 문제가 발생했습니다. 서버 관리자에게 문의하세요.';
      }
      return '데이터베이스 오류: 데이터베이스 작업 중 문제가 발생했습니다. 서버 관리자에게 문의하세요.';
    }
    
    // HTML 태그 제거
    if (cleaned.toLowerCase().contains('<html>') || 
        cleaned.toLowerCase().contains('<!doctype')) {
      cleaned = cleaned
          .replaceAll(RegExp(r'<[^>]*>', multiLine: true), '')
          .replaceAll(RegExp(r'\s+', multiLine: true), ' ')
          .trim();
    }
    
    // 502 Bad Gateway 감지
    if (cleaned.toLowerCase().contains('502') && 
        cleaned.toLowerCase().contains('bad gateway')) {
      return '게이트웨이 오류 (502): 백엔드 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인하거나 서버 관리자에게 문의해주세요.';
    }
    
    // 의미 있는 메시지만 남기기 (너무 길면 잘라내기)
    if (cleaned.length > 200) {
      cleaned = '${cleaned.substring(0, 200)}...';
    }
    
    return cleaned.trim();
  }
}
