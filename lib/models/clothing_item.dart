
class ClothingItem {
  final String id;
  final String name;
  final String category;
  final String subtype;
  final List<String> colors;
  final List<String> occasions;
  final String fabric;
  final String season;
  final String originalImagePath;
  final String? cleanImagePath;
  final DateTime dateAdded;
  final int wearCount;
  final DateTime? lastWorn;
  final double? rating;

  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    this.subtype = '',
    this.colors = const [],
    this.occasions = const [],
    this.fabric = '',
    this.season = '',
    required this.originalImagePath,
    this.cleanImagePath,
    required this.dateAdded,
    this.wearCount = 0,
    this.lastWorn,
    this.rating,
  });

  ClothingItem copyWith({
    String? name,
    String? category,
    String? subtype,
    List<String>? colors,
    List<String>? occasions,
    String? fabric,
    String? season,
    String? cleanImagePath,
    int? wearCount,
    DateTime? lastWorn,
    double? rating,
    bool clearCleanImagePath = false,
    bool clearLastWorn = false,
    bool clearRating = false,
  }) {
    return ClothingItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      subtype: subtype ?? this.subtype,
      colors: colors ?? this.colors,
      occasions: occasions ?? this.occasions,
      fabric: fabric ?? this.fabric,
      season: season ?? this.season,
      originalImagePath: originalImagePath,
      cleanImagePath: clearCleanImagePath
          ? null
          : cleanImagePath ?? this.cleanImagePath,
      dateAdded: dateAdded,
      wearCount: wearCount ?? this.wearCount,
      lastWorn: clearLastWorn ? null : lastWorn ?? this.lastWorn,
      rating: clearRating ? null : rating ?? this.rating,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'subtype': subtype,
        'colors': colors,
        'occasions': occasions,
        'fabric': fabric,
        'season': season,
        'originalImagePath': originalImagePath,
        'cleanImagePath': cleanImagePath,
        'dateAdded': dateAdded.toIso8601String(),
        'wearCount': wearCount,
        'lastWorn': lastWorn?.toIso8601String(),
        'rating': rating,
      };

  factory ClothingItem.fromMap(Map<dynamic, dynamic> map) {
    return ClothingItem(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      subtype: map['subtype'] as String? ?? '',
      colors: List<String>.from(map['colors'] ?? []),
      occasions: List<String>.from(map['occasions'] ?? []),
      fabric: map['fabric'] as String? ?? '',
      season: map['season'] as String? ?? '',
      originalImagePath: map['originalImagePath'] as String,
      cleanImagePath: map['cleanImagePath'] as String?,
      dateAdded: DateTime.parse(map['dateAdded'] as String),
      wearCount: map['wearCount'] as int? ?? 0,
      lastWorn: map['lastWorn'] == null
          ? null
          : DateTime.parse(map['lastWorn'] as String),
      rating: (map['rating'] as num?)?.toDouble(),
    );
  }
}
