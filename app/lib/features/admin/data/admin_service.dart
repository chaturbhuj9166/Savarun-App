import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';

String _admin(String path) => '${AppConfig.backendBaseUrl}/api/admin$path';

/// Whether the signed-in user holds the `admin` custom claim. This is the
/// same gate the backend enforces; the UI uses it to show/hide the dashboard.
final isAdminProvider = FutureProvider.autoDispose<bool>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  final token = await user.getIdTokenResult(true);
  return token.claims?['admin'] == true;
});

/* ── Models ── */

class AdminAnalytics {
  const AdminAnalytics({
    required this.totalUsers,
    required this.dailyActiveUsers,
    required this.trendingStyles,
    required this.topProducts,
  });

  final int totalUsers;
  final int dailyActiveUsers;
  final List<({String category, num weight})> trendingStyles;
  final List<({String name, int clicks})> topProducts;

  factory AdminAnalytics.fromJson(Map<String, dynamic> d) => AdminAnalytics(
        totalUsers: (d['totalUsers'] ?? 0) as int,
        dailyActiveUsers: (d['dailyActiveUsers'] ?? 0) as int,
        trendingStyles: (d['trendingStyles'] as List? ?? [])
            .map((s) => (
                  category: (s['category'] ?? '') as String,
                  weight: (s['weight'] ?? 0) as num,
                ))
            .toList(),
        topProducts: (d['topProducts'] as List? ?? [])
            .map((p) => (
                  name: (p['name'] ?? '') as String,
                  clicks: (p['clicks'] ?? 0) as int,
                ))
            .toList(),
      );
}

class AdminUser {
  const AdminUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoURL,
    required this.status,
  });
  final String uid;
  final String name;
  final String? email;
  final String? photoURL;
  final String status;

  factory AdminUser.fromJson(Map<String, dynamic> d) => AdminUser(
        uid: d['uid'] ?? '',
        name: d['name'] ?? 'Savarun User',
        email: d['email'],
        photoURL: d['photoURL'],
        status: d['status'] ?? 'active',
      );
}

class AdminBrand {
  const AdminBrand({required this.id, required this.name, required this.status});
  final String id;
  final String name;
  final String status;

  factory AdminBrand.fromJson(Map<String, dynamic> d) => AdminBrand(
        id: d['id'] ?? '',
        name: d['name'] ?? '',
        status: d['status'] ?? 'pending',
      );
}

class AdminProduct {
  const AdminProduct({
    required this.id,
    required this.name,
    required this.brandName,
    required this.price,
    required this.approved,
    required this.hidden,
  });
  final String id;
  final String name;
  final String brandName;
  final num price;
  final bool approved;
  final bool hidden;

  factory AdminProduct.fromJson(Map<String, dynamic> d) => AdminProduct(
        id: d['id'] ?? '',
        name: d['name'] ?? '',
        brandName: d['brandName'] ?? '',
        price: (d['price'] ?? 0) as num,
        approved: d['approved'] == true,
        hidden: d['hidden'] == true,
      );
}

/* ── Providers ── */

final adminAnalyticsProvider =
    FutureProvider.autoDispose<AdminAnalytics>((ref) async {
  const client = ApiClient();
  final json = await client.get(_admin('/analytics'));
  return AdminAnalytics.fromJson(json['data'] as Map<String, dynamic>);
});

final adminUsersProvider =
    FutureProvider.autoDispose<List<AdminUser>>((ref) async {
  const client = ApiClient();
  final json = await client.get(_admin('/users'));
  return (json['data'] as List).map((u) => AdminUser.fromJson(u)).toList();
});

final adminBrandsProvider =
    FutureProvider.autoDispose<List<AdminBrand>>((ref) async {
  const client = ApiClient();
  final json = await client.get(_admin('/brands'));
  return (json['data'] as List).map((b) => AdminBrand.fromJson(b)).toList();
});

final adminProductsProvider =
    FutureProvider.autoDispose<List<AdminProduct>>((ref) async {
  const client = ApiClient();
  final json = await client.get(_admin('/products'));
  return (json['data'] as List).map((p) => AdminProduct.fromJson(p)).toList();
});

final adminFitWeightsProvider =
    FutureProvider.autoDispose<Map<String, num>>((ref) async {
  const client = ApiClient();
  final json = await client.get(_admin('/fit-weights'));
  final data = json['data'] as Map<String, dynamic>;
  return data.map((k, v) => MapEntry(k, (v ?? 0) as num));
});

final adminRepoProvider = Provider((ref) => const AdminRepository());

class AdminRepository {
  const AdminRepository();

  Future<void> moderateUser(String uid, String action) =>
      const ApiClient().post(_admin('/users/$uid/moderate'), {'action': action});

  Future<void> decideBrand(String id, bool approve) => const ApiClient()
      .post(_admin('/brands/$id/decision'),
          {'decision': approve ? 'approve' : 'reject'});

  Future<void> setProductApproval(String id, bool approved) => const ApiClient()
      .patch(_admin('/products/$id/approval'), {'approved': approved});

  Future<void> setProductHidden(String id, bool hidden) => const ApiClient()
      .patch(_admin('/products/$id/visibility'), {'hidden': hidden});

  Future<void> saveFitWeights(Map<String, num> weights) =>
      const ApiClient().put(_admin('/fit-weights'), weights);
}
