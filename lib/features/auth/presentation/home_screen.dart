import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_notifier.dart';
import 'auth_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final auth = authState.value;
    final user = auth is AuthAuthenticated ? auth.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MiGrupo'),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user.image != null)
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(user.image!),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    '${user.firstName} ${user.lastName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(user.email),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => ref.read(authStateProvider.notifier).logout(),
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
    );
  }
}
