import 'package:cloud_firestore/cloud_firestore.dart';

/// A saved outfit combination — a named set of wardrobe item ids.
class OutfitSet {
  const OutfitSet({
    required this.id,
    required this.name,
    required this.itemIds,
  });

  final String id;
  final String name;
  final List<String> itemIds;

  factory OutfitSet.fromDoc(String id, Map<String, dynamic> d) {
    return OutfitSet(
      id: id,
      name: d['name'] ?? 'Outfit',
      itemIds: List<String>.from(d['itemIds'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'itemIds': itemIds,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
