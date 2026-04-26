import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'homepage.dart';
import 'profile_avatar_presets.dart';
import 'services/auth_service.dart';
import 'services/emotion_board_service.dart';
import 'services/profile_avatar_service.dart';
import 'widgets/profile_avatar_chip.dart';

const _pageBackground = Color(0xFFEDE9FE);
const _kNeoRadius = 22.0;
const _cardCreamA = Color(0xFFFFF7ED);
const _cardCreamB = Color(0xFFFFFBF5);
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
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;
  String? _remoteAvatarUrl;
  String? _remotePresetId;
  String? _selectedPresetId;
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

    final rawPreset = user.userMetadata?[kAvatarPresetIdKey];
    _remotePresetId = rawPreset is String && rawPreset.trim().isNotEmpty
        ? rawPreset.trim()
        : null;
    _selectedPresetId = _remotePresetId;

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
    return t[0].toUpperCase();
  }

  void _onSelectPreset(String id) {
    setState(() {
      _selectedPresetId = id;
      _stripAvatarOnSave = false;
    });
  }

  void _onRemoveAvatar() {
    setState(() {
      _selectedPresetId = null;
      _stripAvatarOnSave = true;
    });
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
      // Exactly one Auth `updateUser` per save for avatar+touches name, otherwise a second
      // merge rebuilds metadata from stale in-memory maps and restores avatar_preset_id /
      // avatar_url (emotion board stays correct until you change avatar again).
      const avatarRemoveKeys = <String>{
        kAvatarPresetIdKey,
        'avatar_url',
        'avatar_storage_path',
      };

      if (_stripAvatarOnSave) {
        await _avatarService.deleteLegacyUploadedFileIfStored();
        final res = await _authService.mergeUserMetadata(
          {'full_name': name.trim()},
          removeKeys: avatarRemoveKeys,
        );
        await _avatarService.syncEmotionBoardAfterAuth(
          authResponse: res,
          authorAvatarSnapshot: const {
            'author_avatar_preset_id': null,
            'author_avatar_url': null,
          },
        );
        if (mounted) {
          setState(() {
            _stripAvatarOnSave = false;
            _remoteAvatarUrl = null;
            _remotePresetId = null;
            _selectedPresetId = null;
          });
        }
      } else if (_selectedPresetId != null) {
        await _avatarService.deleteLegacyUploadedFileIfStored();
        final res = await _authService.mergeUserMetadata({
          'full_name': name.trim(),
          kAvatarPresetIdKey: _selectedPresetId!,
          'avatar_url': null,
          'avatar_storage_path': null,
        });
        await _avatarService.syncEmotionBoardAfterAuth(
          authResponse: res,
          authorAvatarSnapshot: {
            'author_avatar_preset_id': _selectedPresetId,
            'author_avatar_url': null,
          },
        );
        if (mounted) {
          setState(() {
            _remotePresetId = _selectedPresetId;
            _remoteAvatarUrl = null;
          });
        }
      } else {
        await _authService.updateFullName(name.trim());
      }

      final u = _authService.currentUser;
      if (u != null) {
        try {
          await EmotionBoardService().syncAuthorDisplayName(
            user: u,
            displayName: name.trim(),
          );
        } catch (e, st) {
          debugPrint(
            'Emotion board display_name sync failed (check UPDATE RLS): $e\n$st',
          );
        }
      }

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
        SnackBar(content: Text(e.toString())),
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
        borderSide:
            BorderSide(color: Colors.black.withValues(alpha: 0.35), width: 2),
      ),
    );
  }

  bool get _canRemoveAvatar =>
      !_stripAvatarOnSave &&
      (_selectedPresetId != null ||
          (_remoteAvatarUrl != null && _remoteAvatarUrl!.isNotEmpty));

  /// Shown above the preset grid — legacy uploads only appear here until replaced.
  String? get _previewNetworkUrl {
    if (_stripAvatarOnSave) return null;
    if (_selectedPresetId != null) return null;
    return _remoteAvatarUrl;
  }

  String? get _previewPresetId {
    if (_stripAvatarOnSave) return null;
    return _selectedPresetId;
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
        leading: IconButton(
          iconSize: 26,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            }
          },
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
                    'Your avatar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose an avatar below as your profile picture.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.48),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ProfileAvatarChip(
                      initials: _initialsFromName(),
                      presetId: _previewPresetId,
                      networkUrl: _previewNetworkUrl,
                      size: 104,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_remoteAvatarUrl != null &&
                      _remoteAvatarUrl!.isNotEmpty &&
                      _selectedPresetId == null &&
                      !_stripAvatarOnSave)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Your account still shows an older photo. Choose an avatar above to switch to the new style.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: _PhotoActionButton(
                      label: 'Use initials instead',
                      icon: Icons.hide_image_outlined,
                      destructive: true,
                      onTap: (_isLoading || !_canRemoveAvatar)
                          ? null
                          : _onRemoveAvatar,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Avatar options',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 10.0;
                      final w = constraints.maxWidth;
                      const cols = 4;
                      final cell =
                          (w - spacing * (cols - 1)) / cols;
                      final diameter = cell.clamp(52.0, 72.0);
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        alignment: WrapAlignment.start,
                        children: [
                          for (final p in ProfileAvatarPreset.library)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap:
                                    _isLoading ? null : () => _onSelectPreset(p.id),
                                borderRadius: BorderRadius.circular(999),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: !_stripAvatarOnSave &&
                                              _selectedPresetId == p.id
                                          ? _accentPurple
                                          : Colors.black26,
                                      width: !_stripAvatarOnSave &&
                                              _selectedPresetId == p.id
                                          ? 3
                                          : 1,
                                    ),
                                  ),
                                  child: ProfilePresetAvatarCircle(
                                    preset: p,
                                    size: diameter - 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
                color: const Color(0xFF5EEAD4),
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
                            child:
                                CircularProgressIndicator(strokeWidth: 2.5),
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
            color: destructive ? Colors.red.shade50 : Colors.white,
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
