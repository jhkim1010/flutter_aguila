# Flutter Database Connection App

안드로이드와 iOS에서 동작하는 Flutter 앱으로, Node.js 서버를 통해 데이터베이스에 연결하는 기능을 제공합니다.

## 기능

- 데이터베이스 연결 정보 입력 (이름, 사용자명, 암호, 포트)
- Node.js 서버를 통한 데이터베이스 연결
- 연결 성공 시 폭죽 애니메이션과 환영 메시지 표시

## 시작하기

### 필수 요구사항

- Flutter SDK (3.0.0 이상)
- Dart SDK
- Android Studio / Xcode (모바일 개발용)

### 설치

1. 의존성 설치:
```bash
flutter pub get
```

2. 앱 실행:
```bash
flutter run
```

## Node.js 서버 설정

앱이 연결할 Node.js 서버는 다음 엔드포인트를 제공해야 합니다:

**POST** `/api/connect`

**Request Body:**
```json
{
  "databaseName": "your_database",
  "username": "your_username",
  "password": "your_password",
  "port": 3306
}
```

**Response:**
- 성공: HTTP 200
- 실패: HTTP 4xx/5xx

## 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점
├── screens/
│   ├── connection_screen.dart  # 연결 정보 입력 화면
│   └── celebration_screen.dart # 성공 화면 (폭죽 애니메이션)
└── services/
    └── database_service.dart    # 서버 연결 서비스
```

## 사용 방법

1. 앱을 실행하면 데이터베이스 연결 화면이 표시됩니다.
2. 서버 URL, 데이터베이스 이름, 사용자 이름, 암호, 포트 번호를 입력합니다.
3. "연결하기" 버튼을 누릅니다.
4. 연결이 성공하면 폭죽 애니메이션과 함께 "환영합니다" 메시지가 표시됩니다.

