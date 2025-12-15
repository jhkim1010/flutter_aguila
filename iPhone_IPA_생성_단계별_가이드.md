# iPhone용 IPA 파일 생성 단계별 가이드

## 현재 상태

✅ **Archive 파일이 생성되었습니다!**
- 위치: `build/ios/archive/Runner.xcarchive`
- 크기: 165.9MB
- Bundle ID: com.coolsistema.becoolaguila

## Xcode Organizer에서 IPA Export하기

### 1단계: Xcode Organizer 열기

다음 명령어로 Archive를 엽니다:
```bash
open build/ios/archive/Runner.xcarchive
```

또는 Xcode에서:
- Xcode 메뉴: **Window > Organizer**
- **Archives** 탭 선택
- 최신 Archive (Runner) 선택

### 2단계: Distribute App 클릭

Archive 선택 후:
- **"Distribute App"** 버튼 클릭

### 3단계: 배포 방법 선택

다음 중 하나를 선택:

#### 옵션 A: Ad Hoc (다른 iPhone에 설치)
- ✅ 특정 iPhone에 직접 설치 가능
- ✅ 최대 100대의 기기
- ⚠️ 각 iPhone의 UDID가 Apple Developer에 등록되어 있어야 함

#### 옵션 B: Development (개발용)
- ✅ Mac에 연결된 iPhone에만 설치 가능
- ✅ 개발자 인증서로 서명

#### 옵션 C: Enterprise (엔터프라이즈)
- ✅ 제한 없이 설치 가능
- ⚠️ Enterprise 인증서 필요

### 4단계: Export 설정

**Ad Hoc 선택 시:**
1. "Automatically manage signing" 선택 (권장)
2. 또는 기존 프로비저닝 프로파일 선택
3. Next 클릭

### 5단계: IPA 파일 저장

1. Export 위치 선택 (예: Desktop 또는 Dropbox 폴더)
2. **Export** 버튼 클릭
3. IPA 파일이 생성됨

## 생성된 IPA 파일을 다른 iPhone에 설치하기

### 방법 1: Finder를 통한 설치 (가장 쉬움)

1. **iPhone을 Mac에 USB 케이블로 연결**
2. **Finder 열기** (macOS Catalina 이상)
3. **왼쪽 사이드바에서 iPhone 선택**
4. **IPA 파일을 Finder 창으로 드래그 앤 드롭**
5. **iPhone에서 신뢰 설정:**
   - 설정 > 일반 > VPN 및 기기 관리
   - "개발자 앱" 섹션에서 앱 선택
   - "신뢰" 버튼 클릭

### 방법 2: AirDrop 사용

1. **Mac과 iPhone에서 AirDrop 활성화**
   - Mac: Finder > AirDrop
   - iPhone: 설정 > 일반 > AirDrop
2. **IPA 파일을 AirDrop으로 전송**
3. **iPhone에서 파일 받기**
4. **설치 후 신뢰 설정**

### 방법 3: 이메일/클라우드 저장소

1. **IPA 파일을 이메일이나 클라우드에 업로드**
   - Dropbox, iCloud, Google Drive 등
2. **iPhone에서 다운로드**
3. **파일 앱에서 IPA 파일 열기**
4. **설치 후 신뢰 설정**

## iPhone UDID 확인 방법

Ad-Hoc 배포를 위해서는 iPhone의 UDID가 필요합니다.

### iPhone에서 확인:
1. 설정 > 일반 > 정보
2. UDID를 길게 눌러 복사

### Mac에서 확인 (iPhone 연결 시):
1. Finder에서 iPhone 선택
2. 일반 탭에서 UDID 확인

### 터미널에서:
```bash
# iPhone이 연결되어 있을 때
system_profiler SPUSBDataType | grep -A 11 iPhone
```

## 문제 해결

### "신뢰할 수 없는 개발자" 오류
- **해결**: 설정 > 일반 > VPN 및 기기 관리에서 개발자 앱 신뢰

### "앱을 설치할 수 없음" 오류
- **원인**: iPhone의 UDID가 Apple Developer에 등록되지 않음
- **해결**: Apple Developer 포털에서 UDID 등록

### "프로비저닝 프로파일이 없음" 오류
- **원인**: Ad-Hoc 프로비저닝 프로파일이 생성되지 않음
- **해결**: Xcode에서 "Automatically manage signing" 선택

## 현재 프로젝트 정보

- **앱 이름**: Be COOL
- **Bundle ID**: com.coolsistema.becoolaguila
- **버전**: 1.0.0 (Build 1)
- **팀 ID**: W93P494PLH
- **Archive 위치**: `build/ios/archive/Runner.xcarchive`

## 빠른 참조

### Archive 열기:
```bash
open build/ios/archive/Runner.xcarchive
```

### IPA 생성 후 Dropbox에 복사:
```bash
# IPA 파일이 Desktop에 있다고 가정
cp ~/Desktop/*.ipa ~/Dropbox/ACE_3_uversion/
```

## 다음 단계

1. ✅ Archive 생성 완료
2. ⏳ Xcode Organizer에서 IPA Export
3. ⏳ Dropbox에 IPA 파일 복사
4. ⏳ 다른 iPhone에 전송 및 설치

---

**도움이 필요하면**: `IPHONE_설치_가이드.md` 파일을 참고하세요.

