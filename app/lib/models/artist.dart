/// Represents a music artist
class Artist {
  final String id;
  final String name;
  final String? imageUrl;
  final String? bio;
  final int? albumCount;
  final int? trackCount;

  Artist({
    required this.id,
    required this.name,
    this.imageUrl,
    this.bio,
    this.albumCount,
    this.trackCount,
  });

  /// Creates an Artist from JSON response
  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Artist',
      imageUrl: json['imageUrl'] ?? json['image'] ?? json['avatarUrl'],
      bio: json['bio'] ?? json['description'],
      albumCount: json['albumCount'],
      trackCount: json['trackCount'],
    );
  }

  /// Converts Artist to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'bio': bio,
      'albumCount': albumCount,
      'trackCount': trackCount,
    };
  }

  Artist copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? bio,
    int? albumCount,
    int? trackCount,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      albumCount: albumCount ?? this.albumCount,
      trackCount: trackCount ?? this.trackCount,
    );
  }
}
