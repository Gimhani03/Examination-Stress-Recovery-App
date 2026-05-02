import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/app_main_bottom_nav.dart';
import 'package:flutter_application_1/widgets/profile_avatar_chip.dart';
import 'create_post_screen.dart';
import 'view_replies_screen.dart';
import 'homepage.dart';
import 'services/emotion_board_service.dart';
import 'mood_flow_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const double _kBoardNeoRadius = 22;

List<BoxShadow> _boardNeoShadows() => moodFlowNeoShadows();

/// Avatar columns stored on each post for non-anonymous authors (matches profile presets).
(String?, String?) _authorAvatarForPostRow(Map<String, dynamic> post) {
  if (post['is_anonymous'] == true) return (null, null);
  final rawP = post['author_avatar_preset_id'];
  final preset =
      rawP is String && rawP.trim().isNotEmpty ? rawP.trim() : null;
  final rawU = post['author_avatar_url'];
  final url = rawU is String && rawU.trim().isNotEmpty ? rawU.trim() : null;
  return (preset, url);
}

ThemeData _emotionBoardPopupMenuTheme(BuildContext context) {
  return Theme.of(context).copyWith(
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: Colors.black87,
      ),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
    ),
  );
}

class EmotionBoardScreen extends StatefulWidget {
  const EmotionBoardScreen({super.key});

  @override
  State<EmotionBoardScreen> createState() => _EmotionBoardScreenState();
}

class _EmotionBoardScreenState extends State<EmotionBoardScreen> {
  String selectedFilter = 'All';
  final EmotionBoardService _service = EmotionBoardService();
  List<Map<String, dynamic>> _posts = [];
  Set<String> _likedPostIds = {};
  bool _isLoading = true;
  
  List<Map<String, dynamic>> get filteredPosts {
    if (selectedFilter == 'All') {
      return _posts;
    }
    return _posts.where((post) => 
      (post['mood_type'] as String?)?.toLowerCase() == selectedFilter.toLowerCase()
    ).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  /// When [showLoading] is true (default), the list shows a loading state.
  /// Set [showLoading] to false to refresh in the background (e.g. after returning
  /// from [ViewRepliesScreen]) so like/reply counts stay in sync without a jarring full-screen loader.
  Future<void> _loadPosts({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final results = await Future.wait([
        _service.fetchPosts(),
        _service.fetchLikedPostIds(),
      ]);
      if (!mounted) return;
      setState(() {
        _posts = results[0] as List<Map<String, dynamic>>;
        _likedPostIds = results[1] as Set<String>;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load posts. Try again.')),
      );
    } finally {
      if (mounted && showLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goTo(Widget screen) {
    moodFlowGoTo(context, screen);
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
              'Emotion Board',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              'Share how you feel',
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
      body: SafeArea(
        child: Column(
          children: [
            // Header with post count and filter
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_posts.length} posts',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Theme(
                    data: _emotionBoardPopupMenuTheme(context),
                    child: PopupMenuButton<String>(
                      offset: const Offset(0, 44),
                      onSelected: (String value) {
                        setState(() {
                          selectedFilter = value;
                        });
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                            value: 'All', child: Text('All')),
                        const PopupMenuItem(
                            value: 'Calm', child: Text('Calm')),
                        const PopupMenuItem(
                            value: 'Anxious', child: Text('Anxious')),
                        const PopupMenuItem(
                            value: 'Sad', child: Text('Sad')),
                        const PopupMenuItem(
                            value: 'Tired', child: Text('Tired')),
                      ],
                      child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: _boardNeoShadows(),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedFilter,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded, size: 22),
                        ],
                      ),
                    ),
                  ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreatePostScreen(),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _posts.insert(0, result as Map<String, dynamic>);
                        });
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5EEAD4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: _boardNeoShadows(),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.black87, size: 26),
                    ),
                  ),
                ],
              ),
            ),
            // Posts List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0D9488),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF0D9488),
                      onRefresh: _loadPosts,
                      child: filteredPosts.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 48),
                              children: [
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          _kBoardNeoRadius),
                                      border: Border.all(
                                          color: Colors.black, width: 2),
                                      boxShadow: _boardNeoShadows(),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.forum_outlined,
                                          size: 44,
                                          color: Colors.black
                                              .withValues(alpha: 0.35),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          selectedFilter == 'All'
                                              ? 'No posts yet'
                                              : 'No $selectedFilter posts',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap + to share how you feel,\nor pull to refresh.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black
                                                .withValues(alpha: 0.45),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
                              itemCount: filteredPosts.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final post = filteredPosts[index];
                                final originalIndex = _posts.indexOf(post);
                                final isEven = index % 2 == 0;
                                final name = (post['is_anonymous'] == true)
                                    ? 'Anonymous User'
                                    : (post['display_name'] as String? ??
                                        'User');
                                final av = _authorAvatarForPostRow(post);
                                return _buildPostCard(
                                  context: context,
                                  name: name,
                                  avatarPresetId: av.$1,
                                  avatarUrl: av.$2,
                                  timestamp:
                                      formatEmotionPostTimestamp(post['created_at']),
                                  useMintAccent: !isEven,
                                  text: post['text'] ?? '',
                                  moodImage: post['mood_image'] ??
                                      'assets/CalmIcon.png',
                                  comments:
                                      (post['reply_count'] as int?) ?? 0,
                                  likes: (post['like_count'] as int?) ?? 0,
                                  isLiked: _likedPostIds
                                      .contains(post['id'] as String? ?? ''),
                                  onLike: () =>
                                      _handleLike(post, originalIndex),
                                  onComment: () async {
                                    await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ViewRepliesScreen(
                                          postId: post['id'] as String,
                                          postName: name,
                                          postText: post['text'] ?? '',
                                          postAvatarPresetId: av.$1,
                                          postAvatarUrl: av.$2,
                                          initialLikeCount:
                                              (post['like_count'] as int?) ?? 0,
                                          initialReplyCount:
                                              (post['reply_count'] as int?) ?? 0,
                                          initialIsLiked: _likedPostIds
                                              .contains(post['id'] as String? ?? ''),
                                          moodImageAsset: post['mood_image'] as String?,
                                          useMintForCard: !isEven,
                                          onReplyAdded: (replyCount) {
                                            setState(() {
                                              _posts[originalIndex]
                                                      ['reply_count'] =
                                                  replyCount;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                    if (!mounted) return;
                                    await _loadPosts(showLoading: false);
                                  },
                                  onEdit: () =>
                                      _showEditPostDialog(originalIndex),
                                  onDelete: () =>
                                      _confirmDeletePost(originalIndex),
                                  isOwner: post['user_id'] ==
                                      Supabase.instance.client.auth
                                          .currentUser?.id,
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppMainBottomNav(),
    );
  }

  Future<void> _showEditPostDialog(int postIndex) async {
    final controller = TextEditingController(text: _posts[postIndex]['text']);
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
                              postId: _posts[postIndex]['id'] as String,
                              text: updatedText,
                            );
                            if (!mounted) return;
                            setState(() {
                              _posts[postIndex]['text'] = updatedText;
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

  Future<void> _confirmDeletePost(int postIndex) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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

    if (shouldDelete == true) {
      try {
        await _service.deletePost(postId: _posts[postIndex]['id'] as String);
        if (!mounted) return;
        setState(() {
          _posts.removeAt(postIndex);
        });
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
  }

  Future<void> _handleLike(Map<String, dynamic> post, int postIndex) async {
    final postId = post['id'] as String;
    final isLiked = _likedPostIds.contains(postId);
    final currentLikes = (post['like_count'] as int?) ?? 0;

    // Optimistic update
    setState(() {
      if (isLiked) {
        _likedPostIds.remove(postId);
        _posts[postIndex]['like_count'] = currentLikes - 1;
      } else {
        _likedPostIds.add(postId);
        _posts[postIndex]['like_count'] = currentLikes + 1;
      }
    });

    try {
      if (isLiked) {
        await _service.unlikePost(postId: postId);
      } else {
        await _service.likePost(postId: postId);
      }
      if (!mounted) return;
      // Replace optimistic count with true aggregate (same as feed query).
      final fresh = await _service.fetchPostById(postId);
      if (!mounted) return;
      if (fresh != null) {
        final n = (fresh['like_count'] as int?) ?? 0;
        setState(() {
          _posts[postIndex]['like_count'] = n;
        });
        await _service.updateLikeCount(postId: postId, likeCount: n);
      }
    } on AuthException catch (error) {
      // Revert optimistic update
      if (!mounted) return;
      setState(() {
        if (isLiked) {
          _likedPostIds.add(postId);
        } else {
          _likedPostIds.remove(postId);
        }
        _posts[postIndex]['like_count'] = currentLikes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (e) {
      // Revert optimistic update
      if (!mounted) return;
      setState(() {
        if (isLiked) {
          _likedPostIds.add(postId);
        } else {
          _likedPostIds.remove(postId);
        }
        _posts[postIndex]['like_count'] = currentLikes;
      });
      debugPrint('Like toggle error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update like. Try again.')),
      );
    }
  }

  Widget _buildPostCard({
    required BuildContext context,
    required String name,
    String? avatarPresetId,
    String? avatarUrl,
    required String timestamp,
    required bool useMintAccent,
    required String text,
    required String moodImage,
    required int comments,
    required int likes,
    bool isLiked = false,
    required VoidCallback onLike,
    required VoidCallback onComment,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    bool isOwner = false,
  }) {
    final accent = useMintAccent
        ? const Color(0xFF0F766E)
        : const Color(0xFF5B21B6);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kMoodCardCreamA, kMoodCardCreamB],
        ),
        borderRadius: BorderRadius.circular(_kBoardNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: _boardNeoShadows(),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatarChip(
                initials: name.isNotEmpty ? name[0].toUpperCase() : '?',
                presetId: avatarPresetId,
                networkUrl: avatarUrl,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (timestamp.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        timestamp,
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
              if (isOwner)
                Theme(
                  data: _emotionBoardPopupMenuTheme(context),
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    icon: Icon(Icons.more_vert_rounded,
                        color: Colors.black.withValues(alpha: 0.45)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              color: Colors.black87,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onComment,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDD6FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          color: accent, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        '$comments',
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
                onTap: onLike,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isLiked
                        ? const Color(0xFFFEE2E2)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isLiked
                            ? const Color(0xFFDC2626)
                            : Colors.black54,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$likes',
                        style: TextStyle(
                          color: isLiked
                              ? const Color(0xFFB91C1C)
                              : Colors.black87,
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
                  moodImage,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
