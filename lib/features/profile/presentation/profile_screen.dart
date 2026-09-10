import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/user.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/current_user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: user == null
          ? const Center(child: Text('No hay sesión activa.'))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(child: _ProfileAvatar(user: user)),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '${user.firstName} ${user.lastName}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    user.email,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Usuario'),
                  subtitle: Text(user.username),
                ),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Rol'),
                  subtitle: Text(
                    user.role == UserRole.admin ? 'Administrador' : 'Usuario estándar',
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final image = user.image;
    final hasImage = image != null && image.isNotEmpty;

    return CircleAvatar(
      radius: 48,
      foregroundImage: hasImage ? NetworkImage(image) : null,
      onForegroundImageError: hasImage ? (_, _) {} : null,
      child: Text(
        _initials(user),
        style: const TextStyle(fontSize: 28),
      ),
    );
  }

  String _initials(User user) {
    final first = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final last = user.lastName.isNotEmpty ? user.lastName[0] : '';
    final initials = '$first$last'.trim();
    if (initials.isNotEmpty) {
      return initials.toUpperCase();
    }
    return user.username.isNotEmpty ? user.username[0].toUpperCase() : '?';
  }
}
