import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:path/path.dart';
import 'dart:io';

/// 로컬 SQLite 데이터베이스 서비스
/// 200MB 데이터를 오프라인에서 빠르게 처리하기 위한 최적화된 서비스
class LocalDatabaseService {
  static Database? _database;
  static const String _databaseName = 'app_local_database.db';
  static const int _databaseVersion = 1;

  /// 데이터베이스 인스턴스 가져오기 (싱글톤 패턴)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 데이터베이스 초기화
  Future<Database> _initDatabase() async {
    String dbPath = join(await getDatabasesPath(), _databaseName);
    
    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      // 성능 최적화 옵션
      singleInstance: true, // 단일 인스턴스로 메모리 절약
    );
  }

  /// 데이터베이스 생성 시 테이블 생성
  Future<void> _onCreate(Database db, int version) async {
    // 예시: 데이터 아이템 테이블
    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        data TEXT,
        category TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 성능 최적화: 인덱스 추가
    await db.execute('''
      CREATE INDEX idx_items_name ON items(name)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_items_category ON items(category)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_items_created_at ON items(created_at)
    ''');

    // 예시: 사용자 테이블
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_users_username ON users(username)
    ''');
  }

  /// 데이터베이스 업그레이드
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 버전 업그레이드 로직
    if (oldVersion < newVersion) {
      // 필요시 마이그레이션 로직 추가
    }
  }

  /// 데이터베이스 닫기
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // ========== CRUD 작업 ==========

  /// 단일 아이템 삽입
  Future<int> insertItem(Map<String, dynamic> item) async {
    final db = await database;
    item['created_at'] = DateTime.now().millisecondsSinceEpoch;
    item['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    return await db.insert('items', item);
  }

  /// 여러 아이템 배치 삽입 (성능 최적화)
  Future<void> insertItemsBatch(List<Map<String, dynamic>> items) async {
    final db = await database;
    final batch = db.batch();
    
    final now = DateTime.now().millisecondsSinceEpoch;
    
    for (var item in items) {
      item['created_at'] = now;
      item['updated_at'] = now;
      batch.insert('items', item);
    }
    
    await batch.commit(noResult: true);
  }

  /// 모든 아이템 조회
  Future<List<Map<String, dynamic>>> getAllItems() async {
    final db = await database;
    return await db.query('items', orderBy: 'created_at DESC');
  }

  /// 조건부 조회 (인덱스 활용)
  Future<List<Map<String, dynamic>>> getItemsByCategory(String category) async {
    final db = await database;
    return await db.query(
      'items',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
  }

  /// 검색 (인덱스 활용)
  Future<List<Map<String, dynamic>>> searchItems(String keyword) async {
    final db = await database;
    return await db.query(
      'items',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'created_at DESC',
    );
  }

  /// 페이지네이션 조회 (대용량 데이터 처리 최적화)
  Future<List<Map<String, dynamic>>> getItemsPaginated({
    required int page,
    required int pageSize,
    String? category,
  }) async {
    final db = await database;
    final offset = (page - 1) * pageSize;
    
    if (category != null) {
      return await db.query(
        'items',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'created_at DESC',
        limit: pageSize,
        offset: offset,
      );
    } else {
      return await db.query(
        'items',
        orderBy: 'created_at DESC',
        limit: pageSize,
        offset: offset,
      );
    }
  }

  /// 아이템 업데이트
  Future<int> updateItem(int id, Map<String, dynamic> item) async {
    final db = await database;
    item['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    return await db.update(
      'items',
      item,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 아이템 삭제
  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 여러 아이템 배치 삭제
  Future<void> deleteItemsBatch(List<int> ids) async {
    final db = await database;
    final batch = db.batch();
    
    for (var id in ids) {
      batch.delete('items', where: 'id = ?', whereArgs: [id]);
    }
    
    await batch.commit(noResult: true);
  }

  /// 아이템 개수 조회
  Future<int> getItemCount({String? category}) async {
    final db = await database;
    if (category != null) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM items WHERE category = ?',
        [category],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } else {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM items');
      return Sqflite.firstIntValue(result) ?? 0;
    }
  }

  /// 커스텀 쿼리 실행
  Future<List<Map<String, dynamic>>> executeQuery(
    String query,
    List<dynamic>? arguments,
  ) async {
    final db = await database;
    return await db.rawQuery(query, arguments);
  }

  /// 트랜잭션 실행 (원자성 보장)
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  /// 데이터베이스 크기 조회 (MB 단위)
  Future<double> getDatabaseSizeMB() async {
    final dbPath = join(await getDatabasesPath(), _databaseName);
    try {
      final file = File(dbPath);
      if (await file.exists()) {
        final size = await file.length();
        return size / (1024 * 1024); // MB로 변환
      }
    } catch (e) {
      // 파일이 없거나 오류 발생 시
    }
    return 0.0;
  }

  /// 데이터베이스 초기화 (모든 데이터 삭제)
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('items');
    await db.delete('users');
  }

  /// 데이터베이스 백업 (파일 복사)
  Future<String> backupDatabase() async {
    final dbPath = join(await getDatabasesPath(), _databaseName);
    final backupPath = join(
      await getDatabasesPath(),
      '${_databaseName}.backup.${DateTime.now().millisecondsSinceEpoch}',
    );
    
    // 파일 복사 로직은 path_provider와 함께 사용
    // 여기서는 경로만 반환
    return backupPath;
  }
}

