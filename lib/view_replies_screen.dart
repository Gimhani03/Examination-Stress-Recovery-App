import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/app_main_bottom_nav.dart';
import 'package:flutter_application_1/widgets/profile_avatar_chip.dart';
import 'reply_screen.dart';
import 'homepage.dart';
import 'mood_flow_theme.dart';
import 'services/emotion_board_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewRepliesScreen extends StatefulWidget {
  final String postId;
  final String postName;
  final String postText;
  final Function(int) onReplyAdded;

  /// Seeds from Emotion board so counts match before refresh completes.
  final int? initialLikeCount;
  final int? initialReplyCount;
  final bool? initialIsLiked;
  final String? moodImageAsset;
  final bool? useMintForCard;

  /// Optional: author avatar snapshot for the OP (shown before full post fetch).
  final String? postAvatarPresetId;
  final String? postAvatarUrl;

  const ViewRepliesScreen({
    super.key,
    required this.postId,
    required this.postName,
    required this.postText,
    required this.onReplyAdded,
    this.postAvatarPresetId,
    this.postAvatarUrl,
    this.initialLikeCount,
    this.initialReplyCount,
    this.initialIsLiked,
    this.moodImageAsset,
    this.useMintForCard,
  });

  @override
  State<ViewRepliesScreen> createState() => _ViewRepliesScreenState();
}

class _ViewRepliesScreenState extends State<ViewRepliesScreen> {
  final EmotionBoardService _service = EmotionBoardService();
  static const double _kCardRadius = 22.0;

  String? _avatarString(dynamic v) {
    return v is String && v.trim().isNotEmpty ? v.trim() : null;
  }

  List<Map<String, dynamic>> _replies = [];
  bool _isLoading = true;
  int _likeCount = 0;
  int _replyCount = 0;
  bool _isLiked = false;
  String _moodImage = 'assets/CalmIcon.png';
  bool _useMintAccent = true;
  late String _postText;
  bool _isPostOwner = false;
  String _postTimestamp = '';
  String? _postAvatarPresetId;
  String? _postAvatarUrl;

  @override
  void initState() {
    super.initState();
    _postText = widget.postText;
    _postAvatarPresetId = _avatarString(widget.postAvatarPresetId);
    _postAvatarUrl = _avatarString(widget.postAvatarUrl);
    if (widget.initialLikeCount != null) {
      _likeCount = widget.initialLikeCount!;
    }
    if (widget.initialReplyCount != null) {
      _replyCount = widget.initialReplyCount!;
    }
    if (widget.initialIsLiked != null) {
      _isLiked = widget.initialIsLiked!;
    }
    if (widget.moodImageAsset != null && widget.moodImageAsset!.isNotEmpty) {
      _moodImage = widget.moodImageAsset!;
    }
    if (widget.useMintForCard != null) {
      _useMintAccent = widget.useMintForCard!;
    } else {
      _useMintAccent = widget.postId.hashCode.abs() % 2 == 0;
    }
    _loadPostAndReplies();
  }

  Future<void> _loadPostAndReplies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final post = await _service.fetchPostById(widget.postId);
      final liked = await _service.fetchLikedPostIds();
      final replies = await _service.fetchReplies(postId: widget.postId);
      if (!mounted) {
        return;
      }
      setState(() {
        _replies = replies;
        _isLiked = liked.contains(widget.postId);
        if (post != null) {
          // Likes: embedded count on post matches emotion_likes rows.
          _likeCount = (post['like_count'] as int?) ?? 0;
          // Replies: always use loaded rows so the number matches the list (avoids stale reply_count column).
          _replyCount = replies.length;
          final uid = Supabase.instance.client.auth.currentUser?.id;
          _isPostOwner = post['user_id'] == uid;
          final body = post['text'] as String?;
          if (body != null) {
            _postText = body;
          }
          if (widget.moodImageAsset == null || widget.moodImageAsset!.isEmpty) {
            _moodImage = (post['mood_image'] as String?)?.isNotEmpty == true
                ? post['mood_image'] as String
                : 'assets/CalmIcon.png';
          }
          if (widget.useMintForCard == null) {
            _useMintAccent = widget.postId.hashCode.abs() % 2 == 0;
          } else {
            _useMintAccent = widget.useMintForCard!;
          }
          _postTimestamp = formatEmotionPostTimestamp(post['created_at']);
          final anon = post['is_anonymous'] == true;
          if (anon) {
            _postAvatarPresetId = null;
            _postAvatarUrl = null;
          } else {
            _postAvatarPresetId =
                _avatarString(post['author_avatar_preset_id']);
            _postAvatarUrl = _avatarString(post['author_avatar_url']);
          }
        } else {
          _replyCount = replies.length;
          _isPostOwner = false;
          _postTimestamp = '';
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load post or replies.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLike() async {
    final wasLiked = _isLiked;
    final currentLikes = _likeCount;
    setState(() {
      if (wasLiked) {
        _isLiked = false;
        _likeCount = currentLikes - 1;
      } else {
        _isLiked = true;
        _likeCount = currentLikes + 1;
      }
    });
    try {
      if (wasLiked) {
        await _service.unlikePost(postId: widget.postId);
      } else {
        await _service.likePost(postId: widget.postId);
      }
      final fresh = await _service.fetchPostById(widget.postId);
      if (!mounted) return;
      if (fresh != null) {
        final n = (fresh['like_count'] as int?) ?? _likeCount;
        setState(() {
          _likeCount = n;
        });
        await _service.updateLikeCount(
          postId: widget.postId,
          likeCount: n,
        );
      } else {
        await _service.updateLikeCount(
          postId: widget.postId,
          likeCount: _likeCount,
        );
      }
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLiked = wasLiked;
        _likeCount = currentLikes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLiked = wasLiked;
        _likeCount = currentLikes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update like. Try again.')),
      );
    }
  }

  void _goTo(Widget screen) {
    moodFlowGoTo(context, screen);
  }

  /// Same chips as [EmotionBoardScreen] post cards: reply count, like count, mood icon.
  Widget _buildPostActionRow() {
    final accent = _useMintAccent
        ? const Color(0xFF0F766E)
        : const Color(0xFF5B21B6);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFDDD6FE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, color: accent, size: 16),
                const SizedBox(width: 5),
                Text(
                  '$_replyCount',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _handleLike,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _isLiked ? const Color(0xFFFEE2E2) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isLiked ? const Color(0xFFDC2626) : Colors.black54,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  '$_likeCount',
                  style: TextStyle(
                    color: _isLiked ? const Color(0xFFB91C1C) : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Mood',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.black.withValues(alpha: 0.38),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Image.asset(
            _moodImage,
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Future<void> _showEditPostDialog() async {
    final controller = TextEditingController(text: _postText);
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: moodFlowNeoShadows(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Edit post',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kMoodCardCreamA, kMoodCardCreamB],
                    ),
                    borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: moodFlowNeoShadows(),
                  ),
                  child: TextField(
                    controller: controller,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Update your post',
                      hintStyle: TextStyle(
                        color: Colors.black.withValues(alpha: 0.35),
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        foregroundColor: kMoodFlowTealNav,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: kMoodMint,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () async {
                          final updatedText = controller.text.trim();
                          if (updatedText.isEmpty) {
                            Navigator.pop(dialogContext);
                            return;
                          }
                          try {
                            await _service.updatePostText(
                              postId: widget.postId,
                              text: updatedText,
                            );
                            if (!mounted) return;
                            setState(() {
                              _postText = updatedText;
                            });
                          } on AuthException catch (error) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                          } catch (_) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Unable to update post.')),
                            );
                          }
                          if (context.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  }

  Future<void> _confirmDeletePost() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: moodFlowNeoShadows(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Delete post?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.62),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: TextButton.styleFrom(
                        foregroundColor: kMoodFlowTealNav,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.pop(dialogContext, true),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldDelete != true) return;
    try {
      await _service.deletePost(postId: widget.postId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete post.')),
      );
    }
  }

  Future<void> _addReply() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReplyScreen(
          postName: widget.postName,
          postText: _postText,
        ),
      ),
    );

    if (result != null && result.toString().isNotEmpty) {
      try {
        await _service.addReply(
          postId: widget.postId,
          text: result.toString(),
        );
        if (!mounted) return;
        await _loadPostAndReplies();
        if (!mounted) return;
        await _service.updateReplyCount(
          postId: widget.postId,
          replyCount: _replies.length,
        );
        widget.onReplyAdded(_replies.length);
      } on AuthException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to add reply.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMoodFlowBg,
      appBar: AppBar(
        backgroundColor: kMoodFlowBg,
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
              _goTo(const HomePage());
            }
          },
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Replies',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                height: 1.1,
              ),
            ),
            Text(
              'Conversation',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.38),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kMoodCardCreamA, kMoodCardCreamB],
                ),
                borderRadius: BorderRadius.circular(_kCardRadius),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: moodFlowNeoShadows(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileAvatarChip(
                        initials: widget.postName.isNotEmpty
                            ? widget.postName[0].toUpperCase()
                            : '?',
                        presetId: _postAvatarPresetId,
                        networkUrl: _postAvatarUrl,
                        size: 36,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.postName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_postTimestamp.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _postTimestamp,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withValues(alpha: 0.45),
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_isPostOwner)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditPostDialog();
                            } else if (value == 'delete') {
                              _confirmDeletePost();
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _postText,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: Colors.black.withValues(alpha: 0.85),
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildPostActionRow(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$_replyCount ${_replyCount == 1 ? 'reply' : 'replies'}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kMoodFlowTealAccent),
                  )
                : _replies.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: moodFlowNeoShadows(),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No replies yet',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Be the first to reply.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black.withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        itemCount: _replies.length,
                        itemBuilder: (context, index) {
                          final reply = _replies[index];
                          final name = reply['display_name'] as String? ?? 'User';
                          final text = reply['text'] as String? ?? '';
                          final preset = _avatarString(reply['author_avatar_preset_id']);
                          final url = _avatarString(reply['author_avatar_url']);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.black, width: 2),
                                boxShadow: moodFlowNeoShadows(),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ProfileAvatarChip(
                                    initials:
                                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                    presetId: preset,
                                    networkUrl: url,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          text,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black.withValues(alpha: 0.82),
                                            height: 1.4,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black, width: 2)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: moodFlowNeoShadows(),
                ),
                child: Material(
                  color: kMoodMint,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _addReply,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_comment_rounded, size: 22, color: Colors.black87),
                          SizedBox(width: 10),
                          Text(
                            'Add reply',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppMainBottomNav(),
    );
  }
}
