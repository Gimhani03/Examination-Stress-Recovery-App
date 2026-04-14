import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// Uploads profile photos to Supabase Storage bucket [bucketName].
///
/// Create a **public** bucket named `avatars` in the Supabase dashboard (or
/// match [bucketName]). Example policies: authenticated users can insert/update/delete
/// only under `avatars/{their_user_id}/`, and `select` is allowed for public read.
class ProfileAvatarService {
  ProfileAvatarService({SupabaseClient? client, AuthService? authService})
      : _client = client ?? Supabase.instance.client,
        _authService = authService ?? AuthService();

  final SupabaseClient _client;
  final AuthService _authService;
  static const String bucketName = 'avatars';

  String _contentTypeForPath(String path, String? mimeType) {
    if (mimeType != null && mimeType.isNotEmpty) {
      return mimeType;
    }
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  String _fileExtension(String path, String contentType) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    if (lower.endsWith('.gif')) return 'gif';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'heic';
    if (contentType.contains('png')) return 'png';
    if (contentType.contains('webp')) return 'webp';
    return 'jpg';
  }

  /// Uploads [file] and updates auth metadata with `avatar_url` and
  /// `avatar_storage_path`. Removes the previous object if paths differ.
  Future<void> uploadAndSaveAvatar(XFile file) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Could not read the image.');
    }

    final contentType = _contentTypeForPath(file.path, file.mimeType);
    final ext = _fileExtension(file.path, contentType);
    final storagePath = '${user.id}/profile.$ext';

    final oldPath = user.userMetadata?['avatar_storage_path'] as String?;
    if (oldPath != null &&
        oldPath.isNotEmpty &&
        oldPath != storagePath) {
      try {
        await _client.storage.from(bucketName).remove([oldPath]);
      } catch (_) {
        // Best-effort cleanup of stale object.
      }
    }

    await _client.storage.from(bucketName).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );

    final dynamic urlResult =
        _client.storage.from(bucketName).getPublicUrl(storagePath);
    final publicUrl = urlResult is String
        ? urlResult
        : urlResult.publicUrl as String;

    await _authService.mergeUserMetadata(
      {
        'avatar_url': publicUrl,
        'avatar_storage_path': storagePath,
      },
    );
  }

  /// Deletes the stored object (if any) and clears avatar metadata.
  Future<void> removeAvatar() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }

    final path = user.userMetadata?['avatar_storage_path'] as String?;
    if (path != null && path.isNotEmpty) {
      try {
        await _client.storage.from(bucketName).remove([path]);
      } catch (_) {
        // Still clear metadata so UI recovers.
      }
    }

    await _authService.mergeUserMetadata(
      {},
      removeKeys: {'avatar_url', 'avatar_storage_path'},
    );
  }
}
