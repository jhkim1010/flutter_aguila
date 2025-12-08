import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'ko': {
      // Connection List Screen
      'delete_connection': '연결 삭제',
      'delete_connection_confirm': '{name} 연결을 삭제하시겠습니까?',
      'cancel': '취소',
      'delete': '삭제',
      'connection_deleted': '연결이 삭제되었습니다.',
      'connection_saved': '연결이 저장되었습니다.',
      'connection_edited': '연결이 수정되었습니다.',
      'save_failed': '저장에 실패했습니다',
      'connection_failed': '연결에 실패했습니다.',
      'error': '오류: {error}',
      'database_connection_list': '데이터베이스 연결 목록',
      'no_saved_connections': '저장된 연결이 없습니다',
      'add_new_connection': '아래 버튼을 눌러 새 연결을 추가하세요',
      'server': '서버: {url}',
      'db': 'DB: {name}',
      'port': '포트: {port}',
      'edit': '수정',
      'add_connection': '연결 추가하기',
      
      // Resumen del Dia Screen
      'loading_data': '데이터를 불러오는 중...',
      'retry': '다시 시도',
      'go_back_to_connection': '다시 접속 화면으로 이동',
      'no_data': '데이터가 없습니다.',
      
      // Additional Connections Screen
      'additional_connections': '추가 연결 관리',
      'no_additional_connections': '추가 연결이 없습니다',
      'add_from_main_screen': '메인 화면에서 "연결 추가하기" 버튼을\n눌러 새 연결을 추가하세요',
      
      // Main Connection Screen
      'profile_name': '프로필 이름',
      'database_name': '데이터베이스 이름',
      'username': '사용자 이름',
      'password': '비밀번호',
      'server_type': '서버 유형',
      'hostinger_principal': 'Hostinger Principal Server',
      'local_ip': 'Local IP',
      'local_ip_address': 'Local IP 주소',
      'save_and_connect': '저장하고 연결하기',
      'connecting': '연결 중...',
      'connection_success': '연결 성공!',
      'connection_error': '연결 오류',
      'please_fill_all_fields': '모든 필드를 입력해주세요.',
      'invalid_server_url': '올바른 서버 URL을 입력해주세요.',
      'connection_failed_title': '연결 실패',
      'connection_failed_message': '연결에 실패했습니다. 다음 정보를 확인하세요:',
      'check_items': '확인 사항:',
      'ok': '확인',
      'database_connection': '데이터베이스 연결',
      
      // Connection Screen
      'connection_name': '연결 이름',
      'connection_name_hint': '예: 프로덕션 DB, 개발 DB',
      'connection_name_required': '연결 이름을 입력해주세요',
      'edit_connection': '연결 수정',
      'new_connection': '새 연결 추가',
      'database_connection': '데이터베이스 연결',
      'new_connection_description': '새로운 데이터베이스 연결을 설정합니다',
      'server_label': '서버',
      'db_label': 'DB',
      'server_url': '서버 URL',
      'server_type': '서버 타입',
      'hostinger_principal': 'Hostinger Principal',
      'local_ip': 'Local IP',
      'local_ip_address': '로컬 IP 주소',
      'local_ip_hint': '예: 192.168.1.100',
      'local_ip_required': '로컬 IP 주소를 입력해주세요',
      'database_name_required': '데이터베이스 이름을 입력해주세요',
      'username_required': '사용자 이름을 입력해주세요',
      'password_required': '암호를 입력해주세요',
      'alphanumeric_only': '영어와 숫자만 입력 가능합니다',
      'save': '저장',
      'connect': '연결',
      'save_and_connect': '저장하고 연결하기',
      'edit_and_connect': '수정하고 연결하기',
      'save_only': '저장만 하기',
      'edit_only': '수정만 하기',
      'password': '암호',
      
      // Resumen del Dia - Sections
      'sales_statistics': '📊 판매 통계',
      'expense_statistics': '💸 지출 통계',
      'discount_statistics': '🎁 할인 통계',
      'mercado_pago_statistics': '💳 MercadoPago 결제 통계',
      'script_results': '⚙️ 스크립트 실행 결과',
      'error_occurred': '오류 발생',
      'calendar': '달력',
      'other_database': '다른 데이터 베이스',
      'branch_comparison': '지점별 비교',
      'item': '항목',
    },
    'en': {
      // Connection List Screen
      'delete_connection': 'Delete Connection',
      'delete_connection_confirm': 'Do you want to delete the connection {name}?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'connection_deleted': 'Connection deleted.',
      'connection_saved': 'Connection saved.',
      'connection_edited': 'Connection edited.',
      'save_failed': 'Save failed',
      'connection_failed': 'Connection failed.',
      'error': 'Error: {error}',
      'database_connection_list': 'Database Connection List',
      'no_saved_connections': 'No saved connections',
      'add_new_connection': 'Press the button below to add a new connection',
      'server': 'Server: {url}',
      'db': 'DB: {name}',
      'port': 'Port: {port}',
      'edit': 'Edit',
      'add_connection': 'Add Connection',
      
      // Resumen del Dia Screen
      'loading_data': 'Loading data...',
      'retry': 'Retry',
      'go_back_to_connection': 'Go back to connection screen',
      'no_data': 'No data available.',
      
      // Additional Connections Screen
      'additional_connections': 'Additional Connections',
      'no_additional_connections': 'No additional connections',
      'add_from_main_screen': 'Press the "Add Connection" button on the main screen\nto add a new connection',
      
      // Main Connection Screen
      'profile_name': 'Profile Name',
      'database_name': 'Database Name',
      'username': 'Username',
      'password': 'Password',
      'server_type': 'Server Type',
      'hostinger_principal': 'Hostinger Principal Server',
      'local_ip': 'Local IP',
      'local_ip_address': 'Local IP Address',
      'save_and_connect': 'Save and Connect',
      'connecting': 'Connecting...',
      'connection_success': 'Connection Successful!',
      'connection_error': 'Connection Error',
      'please_fill_all_fields': 'Please fill in all fields.',
      'invalid_server_url': 'Please enter a valid server URL.',
      'connection_failed_title': 'Connection Failed',
      'connection_failed_message': 'Connection failed. Please check the following information:',
      'check_items': 'Check Items:',
      'ok': 'OK',
      'database_connection': 'Database Connection',
      
      // Connection Screen
      'connection_name': 'Connection Name',
      'connection_name_hint': 'e.g., Production DB, Development DB',
      'connection_name_required': 'Please enter a connection name',
      'edit_connection': 'Edit Connection',
      'new_connection': 'Add New Connection',
      'database_connection': 'Database Connection',
      'new_connection_description': 'Set up a new database connection',
      'server_label': 'Server',
      'db_label': 'DB',
      'server_url': 'Server URL',
      'server_type': 'Server Type',
      'hostinger_principal': 'Hostinger Principal',
      'local_ip': 'Local IP',
      'local_ip_address': 'Local IP Address',
      'local_ip_hint': 'e.g., 192.168.1.100',
      'local_ip_required': 'Please enter a local IP address',
      'database_name_required': 'Please enter a database name',
      'username_required': 'Please enter a username',
      'password_required': 'Please enter a password',
      'alphanumeric_only': 'Only letters and numbers are allowed',
      'save': 'Save',
      'connect': 'Connect',
      'save_and_connect': 'Save and Connect',
      'edit_and_connect': 'Edit and Connect',
      'save_only': 'Save Only',
      'edit_only': 'Edit Only',
      'password': 'Password',
      
      // Resumen del Dia - Sections
      'sales_statistics': '📊 Sales Statistics',
      'expense_statistics': '💸 Expense Statistics',
      'discount_statistics': '🎁 Discount Statistics',
      'mercado_pago_statistics': '💳 MercadoPago Payment Statistics',
      'script_results': '⚙️ Script Execution Results',
      'error_occurred': 'Error Occurred',
      'calendar': 'Calendar',
      'other_database': 'Other Database',
      'branch_comparison': 'Branch Comparison',
      'item': 'Item',
    },
    'es': {
      // Connection List Screen
      'delete_connection': 'Eliminar Conexión',
      'delete_connection_confirm': '¿Desea eliminar la conexión {name}?',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'connection_deleted': 'Conexión eliminada.',
      'connection_saved': 'Conexión guardada.',
      'connection_edited': 'Conexión editada.',
      'save_failed': 'Error al guardar',
      'connection_failed': 'Error de conexión.',
      'error': 'Error: {error}',
      'database_connection_list': 'Lista de Conexiones de Base de Datos',
      'no_saved_connections': 'No hay conexiones guardadas',
      'add_new_connection': 'Presione el botón a continuación para agregar una nueva conexión',
      'server': 'Servidor: {url}',
      'db': 'DB: {name}',
      'port': 'Puerto: {port}',
      'edit': 'Editar',
      'add_connection': 'Agregar Conexión',
      
      // Resumen del Dia Screen
      'loading_data': 'Cargando datos...',
      'retry': 'Reintentar',
      'go_back_to_connection': 'Volver a la pantalla de conexión',
      'no_data': 'No hay datos disponibles.',
      
      // Additional Connections Screen
      'additional_connections': 'Conexiones Adicionales',
      'no_additional_connections': 'No hay conexiones adicionales',
      'add_from_main_screen': 'Presione el botón "Agregar Conexión" en la pantalla principal\npara agregar una nueva conexión',
      
      // Main Connection Screen
      'profile_name': 'Nombre del Perfil',
      'profile_name_hint': 'Ingrese un nombre representativo para esta conexión',
      'database_name': 'Nombre de la Base de Datos',
      'username': 'Nombre de Usuario',
      'password': 'Contraseña',
      'server_type': 'Tipo de Servidor',
      'hostinger_principal': 'Servidor Principal Hostinger',
      'local_ip': 'IP Local',
      'local_ip_address': 'Dirección IP Local',
      'local_ip_required': 'Por favor ingrese una dirección IP local',
      'invalid_ip_address': 'Por favor ingrese una dirección IP válida',
      'saved_connections': 'Conexiones Guardadas',
      'connect_with_this_connection': 'Conectar con esta conexión',
      'switch_to_another_connection': 'Cambiar a Otra Conexión',
      'language': 'Idioma',
      'profile_name_hint': 'Ingrese un nombre representativo para esta conexión',
      'save_and_connect': 'Guardar y Conectar',
      'connecting': 'Conectando...',
      'connection_success': '¡Conexión Exitosa!',
      'connection_error': 'Error de Conexión',
      'please_fill_all_fields': 'Por favor complete todos los campos.',
      'invalid_server_url': 'Por favor ingrese una URL de servidor válida.',
      'connection_failed_title': 'Conexión Fallida',
      'connection_failed_message': 'La conexión falló. Por favor verifique la siguiente información:',
      'check_items': 'Elementos a Verificar:',
      'ok': 'OK',
      'database_connection': 'Conexión de Base de Datos',
      
      // Connection Screen
      'connection_name': 'Nombre de Conexión',
      'connection_name_hint': 'Ej: Base de Datos de Producción, Base de Datos de Desarrollo',
      'connection_name_required': 'Por favor ingrese un nombre de conexión',
      'edit_connection': 'Editar Conexión',
      'new_connection': 'Agregar Nueva Conexión',
      'database_connection': 'Conexión de Base de Datos',
      'new_connection_description': 'Configurar una nueva conexión de base de datos',
      'server_label': 'Servidor',
      'db_label': 'DB',
      'server_url': 'URL del Servidor',
      'server_type': 'Tipo de Servidor',
      'hostinger_principal': 'Hostinger Principal',
      'local_ip': 'IP Local',
      'local_ip_address': 'Dirección IP Local',
      'local_ip_hint': 'Ej: 192.168.1.100',
      'local_ip_required': 'Por favor ingrese una dirección IP local',
      'database_name_required': 'Por favor ingrese un nombre de base de datos',
      'username_required': 'Por favor ingrese un nombre de usuario',
      'password_required': 'Por favor ingrese una contraseña',
      'alphanumeric_only': 'Solo se permiten letras y números',
      'save': 'Guardar',
      'connect': 'Conectar',
      'save_and_connect': 'Guardar y Conectar',
      'edit_and_connect': 'Editar y Conectar',
      'save_only': 'Solo Guardar',
      'edit_only': 'Solo Editar',
      'password': 'Contraseña',
      
      // Resumen del Dia - Sections
      'sales_statistics': '📊 Estadísticas de Ventas',
      'expense_statistics': '💸 Estadísticas de Gastos',
      'discount_statistics': '🎁 Estadísticas de Descuentos',
      'mercado_pago_statistics': '💳 Estadísticas de Pagos MercadoPago',
      'script_results': '⚙️ Resultados de Ejecución de Scripts',
      'error_occurred': 'Error Ocurrido',
      'calendar': 'Calendario',
      'other_database': 'Otra Base de Datos',
      'branch_comparison': 'Comparación por Sucursal',
      'item': 'Artículo',
    },
  };

  String translate(String key, {Map<String, String>? params}) {
    String? value = _localizedValues[locale.languageCode]?[key];
    if (value == null) {
      // Fallback to Spanish if translation not found
      value = _localizedValues['es']?[key] ?? key;
    }
    
    // Replace parameters
    if (params != null && value != null) {
      params.forEach((paramKey, paramValue) {
        value = value!.replaceAll('{$paramKey}', paramValue);
      });
    }
    
    return value ?? key;
  }

  // Getters for convenience
  String get deleteConnection => translate('delete_connection');
  String deleteConnectionConfirm(String name) => translate('delete_connection_confirm', params: {'name': name});
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get connectionDeleted => translate('connection_deleted');
  String get connectionSaved => translate('connection_saved');
  String get connectionEdited => translate('connection_edited');
  String get saveFailed => translate('save_failed');
  String get connectionFailed => translate('connection_failed');
  String error(String error) => translate('error', params: {'error': error});
  String get databaseConnectionList => translate('database_connection_list');
  String get noSavedConnections => translate('no_saved_connections');
  String get addNewConnection => translate('add_new_connection');
  String server(String url) => translate('server', params: {'url': url});
  String db(String name) => translate('db', params: {'name': name});
  String port(String port) => translate('port', params: {'port': port});
  String get edit => translate('edit');
  String get addConnection => translate('add_connection');
  String get loadingData => translate('loading_data');
  String get retry => translate('retry');
  String get goBackToConnection => translate('go_back_to_connection');
  String get noData => translate('no_data');
  String get additionalConnections => translate('additional_connections');
  String get noAdditionalConnections => translate('no_additional_connections');
  String get addFromMainScreen => translate('add_from_main_screen');
  String get profileName => translate('profile_name');
  String get databaseName => translate('database_name');
  String get username => translate('username');
  String get password => translate('password');
  String get serverType => translate('server_type');
  String get hostingerPrincipal => translate('hostinger_principal');
  String get localIp => translate('local_ip');
  String get localIpAddress => translate('local_ip_address');
  String get saveAndConnect => translate('save_and_connect');
  String get connecting => translate('connecting');
  String get connectionSuccess => translate('connection_success');
  String get connectionError => translate('connection_error');
  String get pleaseFillAllFields => translate('please_fill_all_fields');
  String get invalidServerUrl => translate('invalid_server_url');
  String get connectionFailedTitle => translate('connection_failed_title');
  String get connectionFailedMessage => translate('connection_failed_message');
  String get checkItems => translate('check_items');
  String get ok => translate('ok');
  String get databaseConnection => translate('database_connection');
  String get connectionName => translate('connection_name');
  String get connectionNameHint => translate('connection_name_hint');
  String get connectionNameRequired => translate('connection_name_required');
  String get editConnection => translate('edit_connection');
  String get newConnection => translate('new_connection');
  String get serverUrl => translate('server_url');
  String get localIpHint => translate('local_ip_hint');
  String get localIpRequired => translate('local_ip_required');
  String get databaseNameRequired => translate('database_name_required');
  String get usernameRequired => translate('username_required');
  String get passwordRequired => translate('password_required');
  String get alphanumericOnly => translate('alphanumeric_only');
  String get save => translate('save');
  String get connect => translate('connect');
  String get editAndConnect => translate('edit_and_connect');
  String get saveOnly => translate('save_only');
  String get editOnly => translate('edit_only');
  String get newConnectionDescription => translate('new_connection_description');
  String get serverLabel => translate('server_label');
  String get dbLabel => translate('db_label');
  String get salesStatistics => translate('sales_statistics');
  String get expenseStatistics => translate('expense_statistics');
  String get discountStatistics => translate('discount_statistics');
  String get mercadoPagoStatistics => translate('mercado_pago_statistics');
  String get scriptResults => translate('script_results');
  String get errorOccurred => translate('error_occurred');
  String get calendar => translate('calendar');
  String get otherDatabase => translate('other_database');
  String get branchComparison => translate('branch_comparison');
  String get item => translate('item');
  String get savedConnections => translate('saved_connections');
  String get connectWithThisConnection => translate('connect_with_this_connection');
  String get switchToAnotherConnection => translate('switch_to_another_connection');
  String get language => translate('language');
  String get profileNameHint => translate('profile_name_hint');
  String get invalidIpAddress => translate('invalid_ip_address');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ko', 'en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

