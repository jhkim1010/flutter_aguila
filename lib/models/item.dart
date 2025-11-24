/// 데이터 아이템 모델
class Item {
  final int? id;
  final String name;
  final String? description;
  final String? data;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    this.id,
    required this.name,
    this.description,
    this.data,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Map으로 변환 (데이터베이스 저장용)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'data': data,
      'category': category,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Map에서 생성 (데이터베이스 조회용)
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      data: map['data'] as String?,
      category: map['category'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// 복사 생성자
  Item copyWith({
    int? id,
    String? name,
    String? description,
    String? data,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      data: data ?? this.data,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Item(id: $id, name: $name, category: $category)';
  }
}

