/// SQLite 로컬 데이터베이스 사용 예시
/// 
/// 이 파일은 LocalDatabaseService를 어떻게 사용하는지 보여주는 예시입니다.
/// 실제 프로젝트에서는 이 코드를 참고하여 구현하세요.

import '../services/local_database_service.dart';
import '../models/item.dart';

class LocalDatabaseUsageExample {
  final LocalDatabaseService _dbService = LocalDatabaseService();

  /// 예시 1: 단일 아이템 삽입
  Future<void> insertSingleItem() async {
    final item = Item(
      name: '샘플 아이템',
      description: '이것은 샘플 설명입니다',
      data: '{"key": "value"}',
      category: '카테고리1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await _dbService.insertItem(item.toMap());
    print('아이템이 삽입되었습니다. ID: $id');
  }

  /// 예시 2: 배치 삽입 (성능 최적화)
  Future<void> insertMultipleItems() async {
    final items = List.generate(1000, (index) {
      return Item(
        name: '아이템 $index',
        description: '설명 $index',
        data: '{"index": $index}',
        category: '카테고리${index % 10}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap();
    });

    await _dbService.insertItemsBatch(items);
    print('1000개의 아이템이 배치로 삽입되었습니다.');
  }

  /// 예시 3: 모든 아이템 조회
  Future<void> getAllItems() async {
    final items = await _dbService.getAllItems();
    print('총 ${items.length}개의 아이템이 있습니다.');
  }

  /// 예시 4: 카테고리별 조회 (인덱스 활용)
  Future<void> getItemsByCategory() async {
    final items = await _dbService.getItemsByCategory('카테고리1');
    print('카테고리1에 속한 아이템: ${items.length}개');
  }

  /// 예시 5: 검색
  Future<void> searchItems() async {
    final items = await _dbService.searchItems('샘플');
    print('"샘플" 검색 결과: ${items.length}개');
  }

  /// 예시 6: 페이지네이션 (대용량 데이터 처리)
  Future<void> getItemsPaginated() async {
    const page = 1;
    const pageSize = 50;

    final items = await _dbService.getItemsPaginated(
      page: page,
      pageSize: pageSize,
    );

    print('페이지 $page: ${items.length}개의 아이템');
  }

  /// 예시 7: 아이템 업데이트
  Future<void> updateItem(int id) async {
    final updatedData = {
      'name': '업데이트된 이름',
      'description': '업데이트된 설명',
    };

    final rowsAffected = await _dbService.updateItem(id, updatedData);
    print('업데이트된 행 수: $rowsAffected');
  }

  /// 예시 8: 아이템 삭제
  Future<void> deleteItem(int id) async {
    final rowsAffected = await _dbService.deleteItem(id);
    print('삭제된 행 수: $rowsAffected');
  }

  /// 예시 9: 배치 삭제
  Future<void> deleteItemsBatch() async {
    final ids = [1, 2, 3, 4, 5];
    await _dbService.deleteItemsBatch(ids);
    print('${ids.length}개의 아이템이 배치로 삭제되었습니다.');
  }

  /// 예시 10: 트랜잭션 사용 (원자성 보장)
  Future<void> useTransaction() async {
    await _dbService.transaction((txn) async {
      // 여러 작업을 하나의 트랜잭션으로 묶기
      await txn.insert('items', {
        'name': '트랜잭션 아이템 1',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      await txn.insert('items', {
        'name': '트랜잭션 아이템 2',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      // 중간에 오류가 발생하면 모든 작업이 롤백됨
    });
    print('트랜잭션이 완료되었습니다.');
  }

  /// 예시 11: 데이터베이스 크기 확인
  Future<void> checkDatabaseSize() async {
    final sizeMB = await _dbService.getDatabaseSizeMB();
    print('데이터베이스 크기: ${sizeMB.toStringAsFixed(2)} MB');
  }

  /// 예시 12: 아이템 개수 조회
  Future<void> getItemCount() async {
    final totalCount = await _dbService.getItemCount();
    print('전체 아이템 개수: $totalCount');

    final categoryCount = await _dbService.getItemCount(category: '카테고리1');
    print('카테고리1 아이템 개수: $categoryCount');
  }

  /// 예시 13: 커스텀 쿼리 실행
  Future<void> executeCustomQuery() async {
    final results = await _dbService.executeQuery(
      '''
      SELECT category, COUNT(*) as count 
      FROM items 
      GROUP BY category 
      ORDER BY count DESC
      ''',
      null,
    );

    for (var row in results) {
      print('${row['category']}: ${row['count']}개');
    }
  }

  /// 예시 14: 데이터베이스 닫기 (앱 종료 시)
  Future<void> closeDatabase() async {
    await _dbService.close();
    print('데이터베이스가 닫혔습니다.');
  }
}

