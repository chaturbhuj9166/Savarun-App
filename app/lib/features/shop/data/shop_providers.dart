import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';

/// An approved brand product shown in the Shop tab (Module 4).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brandName,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.description,
  });

  final String id;
  final String name;
  final String brandName;
  final num price;
  final String imageUrl;
  final String category;
  final String description;

  factory Product.fromJson(Map<String, dynamic> d) => Product(
        id: d['id'] ?? '',
        name: d['name'] ?? '',
        brandName: d['brandName'] ?? '',
        price: (d['price'] ?? 0) as num,
        imageUrl: d['imageUrl'] ?? '',
        category: d['category'] ?? '',
        description: d['description'] ?? '',
      );
}

/// Products for the Shop grid, optionally filtered by category.
/// Pass an empty string for "All".
final productsProvider =
    FutureProvider.autoDispose.family<List<Product>, String>((ref, category) async {
  const client = ApiClient();
  final url = category.isEmpty
      ? AppConfig.affiliateProductsEndpoint
      : '${AppConfig.affiliateProductsEndpoint}?category=$category';
  final json = await client.get(url);
  return (json['data'] as List).map((p) => Product.fromJson(p)).toList();
});

/// Trending Brands strip on the Shop screen — top products by click count.
final trendingProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  const client = ApiClient();
  final json = await client.get(AppConfig.affiliateTrendingEndpoint);
  return (json['data'] as List).map((p) => Product.fromJson(p)).toList();
});

/// The admin-chosen Featured Brand for the top of Home (Module 4).
class FeaturedBrand {
  const FeaturedBrand({required this.brandName, required this.products});
  final String brandName;
  final List<Product> products;
}

/// Featured brand for Home; null when the admin hasn't set one (or it has no
/// live products) — the Home section then renders nothing.
final featuredBrandProvider =
    FutureProvider.autoDispose<FeaturedBrand?>((ref) async {
  const client = ApiClient();
  final json = await client.get(AppConfig.affiliateFeaturedEndpoint);
  final data = json['data'];
  if (data == null) return null;
  return FeaturedBrand(
    brandName: data['brandName'] ?? '',
    products: (data['products'] as List).map((p) => Product.fromJson(p)).toList(),
  );
});

/// One of the caller's own brand submissions and its review status.
class MyBrand {
  const MyBrand({required this.id, required this.name, required this.status});
  final String id;
  final String name;
  final String status; // pending | approved | rejected

  factory MyBrand.fromJson(Map<String, dynamic> d) => MyBrand(
        id: d['id'] ?? '',
        name: d['name'] ?? '',
        status: d['status'] ?? 'pending',
      );
}

/// The caller's brand submissions.
final myBrandsProvider = FutureProvider.autoDispose<List<MyBrand>>((ref) async {
  const client = ApiClient();
  final json = await client.get(AppConfig.myBrandsEndpoint);
  return (json['data'] as List).map((b) => MyBrand.fromJson(b)).toList();
});

final shopRepoProvider = Provider((ref) => const ShopRepository());

class ShopRepository {
  const ShopRepository();

  /// Records the affiliate click and returns the brand's destination URL.
  Future<String> resolveAffiliateUrl(String productId) async {
    const client = ApiClient();
    final json = await client
        .post(AppConfig.affiliateClickEndpoint, {'productId': productId});
    return (json['data'] as Map<String, dynamic>)['websiteUrl'] as String;
  }

  /// Submit a brand for admin review.
  Future<void> submitBrand({required String name, String? website}) async {
    const client = ApiClient();
    await client.post(AppConfig.brandsEndpoint, {
      'name': name,
      if (website != null && website.isNotEmpty) 'website': website,
    });
  }

  /// List a product under an approved brand.
  Future<void> submitProduct({
    required String brandId,
    required String name,
    required num price,
    required String websiteUrl,
    required String category,
    String description = '',
    String imageUrl = '',
  }) async {
    const client = ApiClient();
    await client.post(AppConfig.brandProductsEndpoint, {
      'brandId': brandId,
      'name': name,
      'price': price,
      'websiteUrl': websiteUrl,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
    });
  }
}
