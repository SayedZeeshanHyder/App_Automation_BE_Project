class NotificationEntity {
  final String id;
  final String message;
  final DateTime createdAt;
  final String category;
  final Map<String, dynamic> data;

  NotificationEntity({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.category,
    required this.data,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'] ?? '',
      message: json['message'] ?? 'No message content.',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      category: json['category'] ?? 'general',
      data: json['data'] is Map<String, dynamic> ? json['data'] : {},
    );
  }

  // Add this method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'data': data,
    };
  }
}