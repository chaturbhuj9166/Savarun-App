import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/phone_login_screen.dart';
import '../../features/home/home_shell.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/analysis/camera_screen.dart';
import '../../features/analysis/capture_preview_screen.dart';
import '../../features/analysis/analyzing_screen.dart';
import '../../features/analysis/analysis_result_screen.dart';
import '../../features/analysis/style_dna_screen.dart';
import '../../features/analysis/models/outfit_analysis.dart';
import '../../features/wardrobe/add_item_screen.dart';
import '../../features/wardrobe/outfit_combos_screen.dart';
import '../../features/wardrobe/create_outfit_screen.dart';
import '../../features/social/explore_screen.dart';
import '../../features/social/other_profile_screen.dart';
import '../../features/social/chat_list_screen.dart';
import '../../features/social/chat_screen.dart';
import '../../features/profile/outfit_history_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/profile/edit_profile_screen.dart';

/// App route names kept in one place to avoid typos.
class Routes {
  Routes._();
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const home = '/home';
  static const camera = '/camera';
  static const capturePreview = '/capture-preview';
  static const analyzing = '/analyzing';
  static const analysisResult = '/analysis-result';
  static const styleDna = '/style-dna';
  static const addItem = '/add-item';
  static const outfitCombos = '/outfit-combos';
  static const createOutfit = '/create-outfit';
  static const explore = '/explore';
  static const otherProfile = '/user';
  static const chatList = '/chats';
  static const chat = '/chat';
  static const outfitHistory = '/outfit-history';
  static const settings = '/settings';
  static const editProfile = '/edit-profile';
  static const phoneLogin = '/phone-login';
}

/// Locations a logged-out user is allowed to sit on.
const _authLocations = {Routes.login, Routes.onboarding, Routes.phoneLogin};

final appRouter = GoRouter(
  initialLocation: Routes.splash,
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final loc = state.matchedLocation;

    // The splash screen routes itself (onboarding vs login vs home).
    if (loc == Routes.splash) return null;

    if (!loggedIn && !_authLocations.contains(loc)) return Routes.login;
    if (loggedIn && (loc == Routes.login || loc == Routes.phoneLogin)) {
      return Routes.home;
    }
    return null;
  },
  routes: [
    GoRoute(path: Routes.splash, builder: (c, s) => const SplashScreen()),
    GoRoute(path: Routes.onboarding, builder: (c, s) => const OnboardingScreen()),
    GoRoute(path: Routes.login, builder: (c, s) => const LoginScreen()),
    GoRoute(path: Routes.phoneLogin, builder: (c, s) => const PhoneLoginScreen()),
    GoRoute(path: Routes.home, builder: (c, s) => const HomeShell()),
    GoRoute(path: Routes.camera, builder: (c, s) => const CameraScreen()),
    GoRoute(path: Routes.capturePreview, builder: (c, s) => CapturePreviewScreen(file: s.extra as XFile)),
    GoRoute(path: Routes.analyzing, builder: (c, s) => AnalyzingScreen(file: s.extra as XFile)),
    GoRoute(path: Routes.analysisResult, builder: (c, s) => AnalysisResultScreen(analysis: s.extra as OutfitAnalysis)),
    GoRoute(path: Routes.styleDna, builder: (c, s) => StyleDnaScreen(analysis: s.extra as OutfitAnalysis)),
    GoRoute(path: Routes.addItem, builder: (c, s) => const AddItemScreen()),
    GoRoute(path: Routes.outfitCombos, builder: (c, s) => const OutfitCombosScreen()),
    GoRoute(path: Routes.createOutfit, builder: (c, s) => const CreateOutfitScreen()),
    GoRoute(path: Routes.explore, builder: (c, s) => const ExploreScreen()),
    GoRoute(
      path: Routes.otherProfile,
      builder: (c, s) => OtherProfileScreen(uid: s.extra as String),
    ),
    GoRoute(path: Routes.chatList, builder: (c, s) => const ChatListScreen()),
    GoRoute(
      path: Routes.chat,
      builder: (c, s) => ChatScreen(otherUid: s.extra as String),
    ),
    GoRoute(path: Routes.outfitHistory, builder: (c, s) => const OutfitHistoryScreen()),
    GoRoute(path: Routes.settings, builder: (c, s) => const SettingsScreen()),
    GoRoute(path: Routes.editProfile, builder: (c, s) => const EditProfileScreen()),
  ],
);

/// Bridges a Stream (Firebase auth state) to a Listenable so GoRouter
/// re-evaluates its redirect whenever the user signs in or out.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
