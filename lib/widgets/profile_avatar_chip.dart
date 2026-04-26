import 'package:flutter/material.dart';

import '../profile_avatar_presets.dart';

/// Header / edit preview: preset, optional legacy uploaded image, or initials.
class ProfileAvatarChip extends StatelessWidget {
  const ProfileAvatarChip({
    super.key,
    required this.initials,
    this.presetId,
    this.networkUrl,
    this.size = 76,
    this.borderWidth = 2,
  });

  final String initials;
  final String? presetId;
  final String? networkUrl;
  final double size;
  final double borderWidth;

  static const Color _fallbackFill = Color(0xFF5EEAD4);

  @override
  Widget build(BuildContext context) {
    final preset = ProfileAvatarPreset.byId(presetId);
    if (preset != null) {
      return ProfilePresetAvatarCircle(
        preset: preset,
        size: size,
        borderWidth: borderWidth,
      );
    }
    final url = networkUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _fallbackFill,
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
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: size,
          height: size,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: size * 0.35,
                height: size * 0.35,
                child: const CircularProgressIndicator(strokeWidth: 2.5),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _initialsLetter(),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _fallbackFill,
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
      child: _initialsLetter(),
    );
  }

  Widget _initialsLetter() {
    return Center(
      child: Text(
        _firstInitial(initials),
        style: TextStyle(
          fontSize: size * 0.37,
          fontWeight: FontWeight.w900,
          color: Colors.black87,
          height: 1,
        ),
      ),
    );
  }

  static String _firstInitial(String s) {
    final t = s.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }
}
