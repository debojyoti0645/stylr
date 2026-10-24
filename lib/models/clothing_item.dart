class ClothingItem {
  final String id;
  final String name;
  final String category;
  final String subtype;
  final List<String> colors;
  final List<String> occasions;
  final String fabric;
  final String season;
  final String pattern;
  final String style;
  final String neckline;
  final String sleeveLength;
  final String garmentLength;
  final String fit;
  final String brand;
  final String size;
  final Map<String, String> measurements;
  final String measurementUnit;
  final double? purchasePrice;
  final DateTime? purchaseDate;
  final String notes;
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
    this.pattern = '',
    this.style = '',
    this.neckline = '',
    this.sleeveLength = '',
    this.garmentLength = '',
    this.fit = '',
    this.brand = '',
    this.size = '',
    this.measurements = const {},
    this.measurementUnit = 'cm',
    this.purchasePrice,
    this.purchaseDate,
    this.notes = '',
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
    String? pattern,
    String? style,
    String? neckline,
    String? sleeveLength,
    String? garmentLength,
    String? fit,
    String? brand,
    String? size,
    Map<String, String>? measurements,
    String? measurementUnit,
    double? purchasePrice,
    bool clearPurchasePrice = false,
    DateTime? purchaseDate,
    bool clearPurchaseDate = false,
    String? notes,
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
      pattern: pattern ?? this.pattern,
      style: style ?? this.style,
      neckline: neckline ?? this.neckline,
      sleeveLength: sleeveLength ?? this.sleeveLength,
      garmentLength: garmentLength ?? this.garmentLength,
      fit: fit ?? this.fit,
      brand: brand ?? this.brand,
      size: size ?? this.size,
      measurements: measurements ?? this.measurements,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      purchasePrice: clearPurchasePrice
          ? null
          : purchasePrice ?? this.purchasePrice,
      purchaseDate: clearPurchaseDate
          ? null
          : purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
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
    'pattern': pattern,
    'style': style,
    'neckline': neckline,
    'sleeveLength': sleeveLength,
    'garmentLength': garmentLength,
    'fit': fit,
    'brand': brand,
    'size': size,
    'measurements': measurements,
    'measurementUnit': measurementUnit,
    'purchasePrice': purchasePrice,
    'purchaseDate': purchaseDate?.toIso8601String(),
    'notes': notes,
    'originalImagePath': originalImagePath,
    'cleanImagePath': cleanImagePath,
    'dateAdded': dateAdded.toIso8601String(),
    'wearCount': wearCount,
    'lastWorn': lastWorn?.toIso8601String(),
    'rating': rating,
  };

  factory ClothingItem.fromMap(Map<dynamic, dynamic> map) {
    return ClothingItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Unclassified',
      subtype: map['subtype'] as String? ?? '',
      colors: List<String>.from(map['colors'] ?? []),
      occasions: List<String>.from(map['occasions'] ?? []),
      fabric: map['fabric'] as String? ?? '',
      season: map['season'] as String? ?? '',
      pattern: map['pattern'] as String? ?? '',
      style: map['style'] as String? ?? '',
      neckline: map['neckline'] as String? ?? '',
      sleeveLength: map['sleeveLength'] as String? ?? '',
      garmentLength: map['garmentLength'] as String? ?? '',
      fit: map['fit'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      size: map['size'] as String? ?? '',
      measurements: Map<String, String>.from(
        (map['measurements'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ) ??
            const {},
      ),
      measurementUnit: map['measurementUnit'] as String? ?? 'cm',
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble(),
      purchaseDate: map['purchaseDate'] == null
          ? null
          : DateTime.parse(map['purchaseDate'] as String),
      notes: map['notes'] as String? ?? '',
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
