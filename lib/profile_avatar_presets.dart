import 'package:flutter/material.dart';

/// Metadata key for the chosen preset avatar (stored via Supabase auth user metadata).
const String kAvatarPresetIdKey = 'avatar_preset_id';

/// Built-in illustration-style avatars (icon + soft background). All clients ship the same
/// set, so we only persist an id — no uploads or external avatar API required.
class ProfileAvatarPreset {
  const ProfileAvatarPreset({
    required this.id,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String id;
  final IconData icon;
  final Color background;
  final Color foreground;

  static const List<ProfileAvatarPreset> library = [
    ProfileAvatarPreset(
      id: 'calm',
      icon: Icons.spa_rounded,
      background: Color(0xFFA7F3D0),
      foreground: Color(0xFF065F46),
    ),
    ProfileAvatarPreset(
      id: 'focus',
      icon: Icons.center_focus_strong_rounded,
      background: Color(0xFFC4B5FD),
      foreground: Color(0xFF4C1D95),
    ),
    ProfileAvatarPreset(
      id: 'sun',
      icon: Icons.wb_sunny_rounded,
      background: Color(0xFFFDE68A),
      foreground: Color(0xFF92400E),
    ),
    ProfileAvatarPreset(
      id: 'moon',
      icon: Icons.nightlight_round_rounded,
      background: Color(0xFFBFDBFE),
      foreground: Color(0xFF1E3A8A),
    ),
    ProfileAvatarPreset(
      id: 'heart',
      icon: Icons.favorite_rounded,
      background: Color(0xFFFBCFE8),
      foreground: Color(0xFF9D174D),
    ),
    ProfileAvatarPreset(
      id: 'leaf',
      icon: Icons.eco_rounded,
      background: Color(0xFFD9F99D),
      foreground: Color(0xFF365314),
    ),
    ProfileAvatarPreset(
      id: 'book',
      icon: Icons.menu_book_rounded,
      background: Color(0xFFE9D5FF),
      foreground: Color(0xFF6B21A8),
    ),
    ProfileAvatarPreset(
      id: 'bolt',
      icon: Icons.bolt_rounded,
      background: Color(0xFFFED7AA),
      foreground: Color(0xFF9A3412),
    ),
    ProfileAvatarPreset(
      id: 'star',
      icon: Icons.star_rounded,
      background: Color(0xFFFEF08A),
      foreground: Color(0xFF854D0E),
    ),
    ProfileAvatarPreset(
      id: 'music',
      icon: Icons.music_note_rounded,
      background: Color(0xFFA5F3FC),
      foreground: Color(0xFF0E7490),
    ),
    ProfileAvatarPreset(
      id: 'coffee',
      icon: Icons.local_cafe_rounded,
      background: Color(0xFFE7E5E4),
      foreground: Color(0xFF44403C),
    ),
    ProfileAvatarPreset(
      id: 'pet',
      icon: Icons.pets_rounded,
      background: Color(0xFFFDE68A),
      foreground: Color(0xFF713F12),
    ),
  ];

  static ProfileAvatarPreset? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final p in library) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// Renders a circular preset avatar at [size].
class ProfilePresetAvatarCircle extends StatelessWidget {
  const ProfilePresetAvatarCircle({
    super.key,
    required this.preset,
    required this.size,
    this.borderWidth = 2,
  });

  final ProfileAvatarPreset preset;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: preset.background,
        border: Border.all(color: Colors.black, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Icon(preset.icon, size: size * 0.48, color: preset.foreground),
    );
  }
}
