import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// A single clothing item in the user's digital wardrobe.
/// Fields mirror the spec: category, color (hex), fabric, season, formality.
class WardrobeItem {
  const WardrobeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.colorHex,
    required this.fabric,
    required this.season,
    required this.formality,
    required this.photoURL,
  });

  final String id;
  final String name;
  final String category;
  final String colorHex; // e.g. "#1A1A2E"
  final String fabric;
  final String season;
  final String formality;
  final String? photoURL;

  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    final value = int.tryParse('FF$hex', radix: 16) ?? 0xFF9E9E9E;
    return Color(value);
  }

  factory WardrobeItem.fromDoc(String id, Map<String, dynamic> d) {
    return WardrobeItem(
      id: id,
      name: d['name'] ?? 'Item',
      category: d['category'] ?? 'Tops',
      colorHex: d['colorHex'] ?? '#9E9E9E',
      fabric: d['fabric'] ?? 'Cotton',
      season: d['season'] ?? 'All-season',
      formality: d['formality'] ?? 'Casual',
      photoURL: d['photoURL'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'colorHex': colorHex,
        'fabric': fabric,
        'season': season,
        'formality': formality,
        'photoURL': photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

/// Allowed option lists (used by the Add-Item form dropdowns).
class WardrobeOptions {
  WardrobeOptions._();

  static const categories = ['Tops', 'Bottoms', 'Footwear', 'Outerwear', 'Accessories'];
  static const fabrics = ['Cotton', 'Denim', 'Linen', 'Silk', 'Wool', 'Polyester', 'Leather', 'Other'];
  static const seasons = ['Summer', 'Winter', 'All-season'];
  static const formalities = ['Casual', 'Smart Casual', 'Formal'];

  /// Common clothing colours with names + hex, shown as swatches.
  static const colors = <({String name, String hex})>[
    (name: 'Black', hex: '#1A1A2E'),
    (name: 'White', hex: '#F5F5F5'),
    (name: 'Grey', hex: '#9E9E9E'),
    (name: 'Navy', hex: '#2A3A6E'),
    (name: 'Blue', hex: '#3D5AFE'),
    (name: 'Indigo', hex: '#5546C9'),
    (name: 'Red', hex: '#E74C3C'),
    (name: 'Pink', hex: '#FF7AC6'),
    (name: 'Green', hex: '#2ECC71'),
    (name: 'Olive', hex: '#808000'),
    (name: 'Beige', hex: '#C8A165'),
    (name: 'Brown', hex: '#5A3A22'),
    (name: 'Yellow', hex: '#F6A700'),
    (name: 'Purple', hex: '#8E44AD'),
  ];
}
