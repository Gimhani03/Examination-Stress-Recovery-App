import 'package:flutter/material.dart';
import 'create_post_screen.dart';
import 'view_replies_screen.dart';
import 'homepage.dart';
import 'profile_screen.dart';
import 'recovery_tips_screen.dart';
import 'services/emotion_board_service.dart';
import 'mood_flow_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const double _kBoardNeoRadius = 22;

List<BoxShadow> _boardNeoShadows() => moodFlowNeoShadows();

String _formatEmotionPostTimestamp(dynamic raw) {
  if (raw == null) return '';
  DateTime? dt;
  if (raw is String) {
    dt = DateTime.tryParse(raw);
  } else if (raw is DateTime) {
    dt = raw;
  }
  if (dt == null) return '';
  final l = dt.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final mon = months[l.month - 1];
  var hour12 = l.hour % 12;
  if (hour12 == 0) hour12 = 12;
  final min = l.minute.toString().padLeft(2, '0');
  final ampm = l.hour < 12 ? 'AM' : 'PM';
  return '$mon ${l.day}, ${l.year} · $hour12:$min $ampm';
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

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

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
      if (mounted) {
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
                  _goTo(const HomePage());
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
                  PopupMenuButton<String>(
                    offset: const Offset(0, 44),
                    onSelected: (String value) {
                      setState(() {
                        selectedFilter = value;
                      });
                    },
                    itemBuilder: (BuildContext context) => const [
                      PopupMenuItem(value: 'All', child: Text('All')),
                      PopupMenuItem(value: 'Calm', child: Text('Calm')),
                      PopupMenuItem(value: 'Anxious', child: Text('Anxious')),
                      PopupMenuItem(value: 'Sad', child: Text('Sad')),
                      PopupMenuItem(value: 'Tired', child: Text('Tired')),
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
                                return _buildPostCard(
                                  name: name,
                                  timestamp:
                                      _formatEmotionPostTimestamp(post['created_at']),
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
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ViewRepliesScreen(
                                          postId: post['id'] as String,
                                          postName: name,
                                          postText: post['text'] ?? '',
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
      bottomNavigationBar: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined, color: kMoodFlowTealNav, size: 28),
              onPressed: () => _goTo(const HomePage()),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: kMoodFlowTealNav, size: 28),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.lightbulb_outline_rounded, color: kMoodFlowTealNav, size: 28),
              onPressed: () => _goTo(const RecoveryTipsScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline_rounded, color: kMoodFlowTealNav, size: 28),
              onPressed: () => _goTo(const ProfileScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditPostDialog(int postIndex) async {
    final controller = TextEditingController(text: _posts[postIndex]['text']);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit post'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: 'Update your post',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
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
                    const SnackBar(content: Text('Unable to update post.')),
                  );
                }
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeletePost(int postIndex) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete post?'),
          content: Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
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
    required String name,
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
    final bg = useMintAccent
        ? const Color(0xFFF0FDFA)
        : const Color(0xFFF5F0FF);
    final avatarBg = useMintAccent
        ? const Color(0xFFCCFBF1)
        : const Color(0xFFEDE4FF);
    final accent = useMintAccent
        ? const Color(0xFF0F766E)
        : const Color(0xFF5B21B6);

    return Container(
      decoration: BoxDecoration(
        color: bg,
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
              CircleAvatar(
                radius: 22,
                backgroundColor: avatarBg,
                child: Icon(
                  Icons.person_rounded,
                  color: accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
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
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
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
                  icon: Icon(Icons.more_vert_rounded,
                      color: Colors.black.withValues(alpha: 0.45)),
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
