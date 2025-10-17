import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:raxvor/app/app_routes.dart';
import 'package:raxvor/features/chatroom/chatroom_screen.dart';
import 'package:raxvor/features/home_screen.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/splash_screen.dart';
import 'providers/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(authStateProvider);
  final authNotifier = ValueNotifier<bool>(ref.read(authStateProvider));

  ref.listen<bool>(authStateProvider, (previous, next) {
    authNotifier.value = next;
  });

  ref.onDispose(() {
    authNotifier.dispose();
  });

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authNotifier,
    /* redirect: (context, state) {
      if (state.matchedLocation == AppRoutes.splash) return null;

      final loggedIn = authNotifier.value;
      final loggingIn = state.matchedLocation == AppRoutes.login;

      if (!loggedIn && !loggingIn) return AppRoutes.login;
      if (loggedIn && loggingIn) return AppRoutes.home;
      return null;
    },*/
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) {
          return SignupScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) {
          return HomeScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.chatroom,
        builder: (context, state) {
          Map<String, String> data = state.extra as Map<String, String>;
          return ChatRoomScreen(
            uId: data['uId']!,
            userName: data['username']!,
            profileImage: data['profile_image']!,
          );
        },
      ),
    ],
  );
});
