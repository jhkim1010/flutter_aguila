/// 보고서 뷰가 공통 AppBar의 공유 버튼에 등록할 콜백 타입
/// 각 타입별 뷰에서 데이터 로드 후 registerShare(() => _shareReport()) 호출
typedef RegisterShareCallback = void Function(void Function() shareFn);
