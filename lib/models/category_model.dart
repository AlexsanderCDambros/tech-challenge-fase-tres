class CategoryModel {
  final String? id;
  final String userId;
  final String name;
  final String type; // 'income' ou 'expense'
  final String color;

  CategoryModel({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'color': color,
    };
  }

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoryModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'expense',
      color: map['color'] ?? '#000000',
    );
  }
}