class FamilyMember {
  final int? id;
  final String name;
  final String relationship;
  final String? photoUrl;

  FamilyMember({
    this.id,
    required this.name,
    required this.relationship,
    this.photoUrl,
  });

  FamilyMember copyWith({
    int? id,
    String? name,
    String? relationship,
    String? photoUrl,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'photoUrl': photoUrl,
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'],
      name: map['name'],
      relationship: map['relationship'],
      photoUrl: map['photoUrl'],
    );
  }
} 