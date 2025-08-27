class Organisation {
  final String id;
  final String name;
  final String description;
  final String ownerName;
  final DateTime createdAt;

  Organisation({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerName,
    required this.createdAt,
  });

  factory Organisation.fromJson(Map<String, dynamic> json) {
    return Organisation(
      id: json['id'] ?? '',
      name: json['organisationName'] ?? 'No Name',
      description: json['organisationDescription'] ?? 'No Description',
      ownerName: json['owner']?['userName'] ?? 'Unknown Owner',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}