class Credential {
  final int? id;
  final int? familyMemberId; // Null means it belongs to the user
  final String title;
  final String category;
  final Map<String, String> fields;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  static const String CATEGORY_BANK = "Bank Account";
  static const String CATEGORY_CARD = "Card";
  static const String CATEGORY_WEBSITE = "Website";
  static const String CATEGORY_APP = "App";
  static const String CATEGORY_OTHER = "Other";

  static const List<String> CATEGORIES = [
    CATEGORY_BANK,
    CATEGORY_CARD,
    CATEGORY_WEBSITE,
    CATEGORY_APP,
    CATEGORY_OTHER,
  ];

  Credential({
    this.id,
    this.familyMemberId,
    required this.title,
    required this.category,
    required this.fields,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isFavorite = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Credential copyWith({
    int? id,
    int? familyMemberId,
    String? title,
    String? category,
    Map<String, String>? fields,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return Credential(
      id: id ?? this.id,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      title: title ?? this.title,
      category: category ?? this.category,
      fields: fields ?? this.fields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyMemberId': familyMemberId,
      'title': title,
      'category': category,
      'fields': fields,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory Credential.fromMap(Map<String, dynamic> map) {
    return Credential(
      id: map['id'],
      familyMemberId: map['familyMemberId'],
      title: map['title'],
      category: map['category'],
      fields: Map<String, String>.from(map['fields']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isFavorite: map['isFavorite'] == 1,
    );
  }

  // Get a list of searchable terms from all fields
  List<String> getSearchTerms() {
    List<String> terms = [title, category];
    fields.forEach((key, value) {
      terms.add(key);
      terms.add(value);
    });
    return terms;
  }
} 