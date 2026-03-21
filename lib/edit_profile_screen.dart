import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'homepage.dart';
import 'services/auth_service.dart';
import 'services/profile_avatar_service.dart';

const _pageBackground = Color(0xFFEDE9FE);
const _kNeoRadius = 22.0;
const _cardCreamA = Color(0xFFFFF7ED);
const _cardCreamB = Color(0xFFFFFBF5);
const _mint = Color(0xFF5EEAD4);
const _accentPurple = Color(0xFF7C3AED);

List<BoxShadow> _editProfileNeoShadows() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        offset: const Offset(4, 4),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _authService = AuthService();
  final _avatarService = ProfileAvatarService();
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;
  String? _remoteAvatarUrl;
  Uint8List? _previewBytes;
  XFile? _pickedFile;
  bool _stripAvatarOnSave = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final user = _authService.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to edit your profile.')),
        );
        Navigator.of(context).pop();
      });
      return;
    }

    final metaName = user.userMetadata?['full_name'];
    final metaNameString = metaName is String
        ? metaName.trim()
        : metaName?.toString().trim();
    final initial = (metaNameString?.isNotEmpty == true)
        ? metaNameString!
        : (user.email?.split('@').first ?? '');
    _nameController.text = initial;

    final rawUrl = user.userMetadata?['avatar_url'];
    _remoteAvatarUrl = rawUrl is String && rawUrl.trim().isNotEmpty
        ? rawUrl.trim()
        : null;

    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _initialsFromName() {
    final t = _nameController.text.trim();
    if (t.isEmpty) return '?';
    return t.characters.first.toUpperCase();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1536,
        maxHeight: 1536,
        imageQuality: 88,
      );
      if (x == null || !mounted) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedFile = x;
        _previewBytes = bytes;
        _stripAvatarOnSave = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open image picker: $e')),
      );
    }
  }

  void _onRemovePhoto() {
    setState(() {
      _pickedFile = null;
      _previewBytes = null;
      _stripAvatarOnSave = true;
    });
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cardCreamB,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.black, width: 2),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text(
                    'Choose from gallery',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text(
                    'Take a photo',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_stripAvatarOnSave) {
        await _avatarService.removeAvatar();
        if (mounted) {
          setState(() {
            _stripAvatarOnSave = false;
            _remoteAvatarUrl = null;
          });
        }
      } else if (_pickedFile != null) {
        await _avatarService.uploadAndSaveAvatar(_pickedFile!);
        if (mounted) {
          final u = _authService.currentUser;
          final raw = u?.userMetadata?['avatar_url'];
          setState(() {
            _pickedFile = null;
            _previewBytes = null;
            _remoteAvatarUrl = raw is String && raw.trim().isNotEmpty
                ? raw.trim()
                : _remoteAvatarUrl;
          });
        }
      }

      await _authService.updateFullName(name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Bucket not found')
                ? 'Photo upload failed. Create a public Storage bucket named "avatars" in Supabase, or check permissions.'
                : e.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: Colors.black.withValues(alpha: 0.55),
      ),
      hintStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.black.withValues(alpha: 0.35),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accentPurple, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.35), width: 2),
      ),
    );
  }

  bool get _hasPhotoToShow {
    if (_previewBytes != null) return true;
    if (_stripAvatarOnSave) return false;
    return _remoteAvatarUrl != null && _remoteAvatarUrl!.isNotEmpty;
  }

  bool get _canRemovePhoto {
    return _previewBytes != null ||
        (_remoteAvatarUrl != null &&
            _remoteAvatarUrl!.isNotEmpty &&
            !_stripAvatarOnSave);
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final email = user?.email ?? '';

    if (!_initialized && user == null) {
      return Scaffold(
        backgroundColor: _pageBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        elevation: 0,
        leadingWidth: 56,
        leading: Center(
          child: PhysicalModel(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 4,
            shadowColor: Colors.black38,
            child: GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                }
              },
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
              ),
            ),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              'How you appear in the app',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.38),
                letterSpacing: 0.15,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_cardCreamA, _cardCreamB],
                ),
                borderRadius: BorderRadius.circular(_kNeoRadius),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: _editProfileNeoShadows(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile photo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add, replace, or remove your picture. Changes apply when you save.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.48),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _mint,
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            offset: const Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _hasPhotoToShow
                          ? (_previewBytes != null
                              ? Image.memory(
                                  _previewBytes!,
                                  fit: BoxFit.cover,
                                  width: 104,
                                  height: 104,
                                )
                              : Image.network(
                                  _remoteAvatarUrl!,
                                  fit: BoxFit.cover,
                                  width: 104,
                                  height: 104,
                                  loadingBuilder: (_, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(strokeWidth: 2.5),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      _initialsFromName(),
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ))
                          : Center(
                              child: Text(
                                _initialsFromName(),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                  height: 1,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _PhotoActionButton(
                          label: 'Change',
                          icon: Icons.add_photo_alternate_outlined,
                          onTap: _isLoading ? null : _showPhotoOptions,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PhotoActionButton(
                          label: 'Remove',
                          icon: Icons.delete_outline_rounded,
                          destructive: true,
                          onTap: (_isLoading || !_canRemovePhoto) ? null : _onRemovePhoto,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Display name',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Shown on your profile and wherever your name appears.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.48),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    decoration: _fieldDecoration('Name'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Email is tied to your account. Contact support to change it.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.48),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signed-in email',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email.isEmpty ? '—' : email,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: _editProfileNeoShadows(),
              ),
              child: Material(
                color: _mint,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _isLoading ? null : _save,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text(
                            'Save changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoActionButton extends StatelessWidget {
  const _PhotoActionButton({
    required this.label,
    required this.icon,
    this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: destructive
                ? Colors.red.shade50
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      offset: const Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: enabled
                      ? (destructive ? Colors.red.shade800 : Colors.black87)
                      : Colors.black26,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: enabled
                        ? (destructive ? Colors.red.shade800 : Colors.black87)
                        : Colors.black26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
