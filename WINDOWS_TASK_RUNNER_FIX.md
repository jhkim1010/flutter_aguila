# Windows: "Failed to post message to main thread" 오류 해결

## 증상
ventas 자료를 가져오는 중에 **왼쪽 메뉴(드로어)**를 열면 콘솔에 다음 오류가 반복해서 출력됩니다.

```
[ERROR:flutter/shell/platform/windows/task_runner_window.cc(106)] Failed to post message to main thread.
```

## 원인
- Windows 플랫폼에서 Flutter는 **메인 스레드**로 메시지를 보내 UI(예: Drawer 열기)를 처리합니다.
- **ventas 로딩 중**에는 `setState`와 큰 테이블 빌드로 메인 스레드가 바쁩니다.
- 이때 사용자가 메뉴를 눌러 `openDrawer()`를 호출하면, 플랫폼이 메인 스레드로 메시지를 보내려다 실패하면서 위 오류가 반복됩니다.

## 적용한 해결 방법
**Drawer를 여는 동작을 “다음 프레임”으로 미룹니다.**

- `resumen_del_dia_screen.dart`에서 메뉴 버튼의 `onMenuPressed` 콜백을 수정했습니다.
- `Scaffold.of(context).openDrawer()`를 **즉시** 호출하지 않고,  
  `SchedulerBinding.instance.addPostFrameCallback`으로 **한 프레임 뒤**에 실행하도록 했습니다.
- 이렇게 하면 ventas 로딩으로 바쁜 프레임이 끝난 뒤에 Drawer 열기가 실행되어, Windows 메시지 전달 실패가 발생하지 않습니다.

## 추가로 해볼 수 있는 것
- 오류가 계속되면 **Flutter / Windows 빌드 업데이트** 후 다시 실행해 보세요.  
  (`flutter upgrade`, `flutter clean` 후 `flutter pub get` 및 재실행)
- 가능하면 ventas 로딩이 끝난 뒤에 메뉴를 여는 것도 도움이 됩니다.
