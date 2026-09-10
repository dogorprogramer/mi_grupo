import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/products/presentation/product_detail_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

GoRouter createAppRouter({
  required AsyncValue<AuthState> Function() authStateReader,
  required Listenable refreshListenable,
}) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = authStateReader();
      return _resolveRedirect(authState, state.matchedLocation);
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/', builder: (context, state) => const ProductsScreen()),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    ],
  );
}

String? _resolveRedirect(AsyncValue<AuthState> auth, String location) {
  final state = auth.value;
  if (state == null) {
    return location == '/splash' ? null : '/splash';
  }
  if (state is AuthAuthenticated) {
    return (location == '/login' || location == '/splash') ? '/' : null;
  }
  return location == '/login' ? null : '/login';
}
