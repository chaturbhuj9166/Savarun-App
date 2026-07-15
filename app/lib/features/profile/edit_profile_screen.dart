import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'data/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  String _style = kStyles.first;

  bool _initialised = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _prefill(UserProfile p) {
    if (_initialised) return;
    _initialised = true;
    _nameController.text = p.name;
    _usernameController.text = p.username ?? '';
    _bioController.text = p.bio;
    if (p.style != null && kStyles.contains(p.style)) _style = p.style!;
  }

  Future<void> _save(String uid) async {
    if (_nameController.text.trim().isEmpty) return _toast('Name cannot be empty');
    final username = _usernameController.text.trim();
    if (username.isEmpty) return _toast('Pick a username');
    if (!RegExp(r'^[a-zA-Z0-9_.]{3,20}$').hasMatch(username)) {
      return _toast('Username: 3–20 letters, numbers, _ or .');
    }

    setState(() => _saving = true);
    try {
      await ref.read(profileRepoProvider).updateProfile(
            uid,
            name: _nameController.text,
            bio: _bioController.text,
            username: username,
            style: _style,
          );
      if (!mounted) return;
      _toast('Profile updated ✨');
      context.pop();
    } catch (e) {
      _toast('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, title: const Text('Edit Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (profile) {
          if (profile == null) return const Center(child: Text('Not signed in'));
          _prefill(profile);

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _label('Name'),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Your name'),
                  ),
                  const SizedBox(height: 18),
                  _label('Username'),
                  TextField(
                    controller: _usernameController,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_.]'))],
                    decoration: const InputDecoration(hintText: 'e.g. chaturbhuj', prefixText: '@ '),
                  ),
                  const SizedBox(height: 18),
                  _label('Bio'),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    maxLength: 120,
                    decoration: const InputDecoration(hintText: 'Tell people about your style'),
                  ),
                  const SizedBox(height: 8),
                  _label('Style'),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kStyles.map((s) {
                      final selected = s == _style;
                      return ChoiceChip(
                        label: Text(s),
                        selected: selected,
                        onSelected: (_) => setState(() => _style = s),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
                        backgroundColor: AppColors.white,
                        side: const BorderSide(color: AppColors.line),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _saving ? null : () => _save(profile.uid),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
              if (_saving)
                const ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.inkMuted, fontSize: 13)),
      );
}
