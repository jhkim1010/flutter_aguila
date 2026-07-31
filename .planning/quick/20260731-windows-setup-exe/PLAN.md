---
slug: windows-setup-exe
created: 2026-07-31
mode: quick
---

# Windows 단일 setup.exe 설치 파일 만들기

## 문제

현재 Windows 배포물이 두 갈래인데 둘 다 사용자 부담이 있다.

- MSIX: 설치 전에 PC 마다 관리자 권한으로 `.cer` 를 `LocalMachine\TrustedPeople`
  에 등록해야 한다. 파일도 3개(`.msix`, `.cer`, 안내문)를 같이 전달해야 한다.
- 포터블 ZIP: 압축을 풀어야 하고 시작 메뉴 등록·제거 기능이 없다.

요구사항은 "파일 하나, 더블클릭 설치" 다.

## 접근

Inno Setup 으로 자체 압축 설치 프로그램(setup.exe)을 만든다. Windows 는 EXE
설치 프로그램에 인증서를 요구하지 않으므로 사전 등록 단계가 사라진다.

`PrivilegesRequired=lowest` 로 사용자 단위 설치를 한다. `%LOCALAPPDATA%\Programs`
에 설치되므로 UAC 승격 창조차 뜨지 않는다. 사내 PC 에서 관리자 계정이 아닌
직원도 그대로 설치할 수 있다.

## 작업

1. `windows/installer/Be_Cool.iss` 추가
   - `build\windows\x64\runner\Release\*` 전체를 재귀 포함
   - 아이콘: `windows/runner/resources/app_icon.ico`
   - 시작 메뉴 등록, 바탕화면 아이콘 선택 옵션, 제거 프로그램 등록
   - 버전은 컴파일 시 `/DAppVersion=` 로 주입 (pubspec 과 어긋나지 않게)

2. `.github/workflows/windows-build.yml` 에 스텝 추가
   - `choco install innosetup` (GitHub Windows 러너에 choco 는 기본 탑재)
   - `iscc` 로 컴파일, 결과를 `dist\` 로
   - 아티팩트 업로드

3. 산출물을 `BeCool instaladores` 에 배치

## 검증

- 워크플로 성공, `Be_Cool_Setup_v1.0.0.exe` 아티팩트 생성
- EXE 안에 `Be_Cool.exe` 와 `data\` 디렉터리(Flutter 에셋)가 포함됐는지 확인

## 알려진 한계 (범위 밖)

- 서명이 없으므로 첫 실행 시 SmartScreen 이 "알 수 없는 게시자" 경고를 띄운다.
  사용자가 "추가 정보" -> "실행"을 눌러야 한다. 이건 상용 코드 서명 인증서로만
  없앨 수 있고, 자체 서명으로는 해결되지 않는다.
- MSIX 와 ZIP 은 남겨둔다. 이미 동작하며 상황에 따라 쓸 수 있다.
