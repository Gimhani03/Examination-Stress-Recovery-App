import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/chat_message.dart';
import 'package:flutter_application_1/models/chat_thread_summary.dart';
import 'package:flutter_application_1/services/gemini_chat_service.dart';
import 'package:flutter_application_1/homepage.dart';
import 'package:flutter_application_1/emotion_board_screen.dart';
import 'package:flutter_application_1/recovery_tips_screen.dart';
import 'package:flutter_application_1/profile_screen.dart';

const _pageBackground = Color(0xFFEDE9FE);
const _kNeoRadius = 18.0;
const _tealNav = Color(0xFF115E59);
const _tealAccent = Color(0xFF0D9488);
const _userBubbleTop = Color(0xFFCCFBF1);
const _userBubbleBottom = Color(0xFF99F6E4);
const _assistantBubbleTop = Color(0xFFFFF7ED);
const _assistantBubbleBottom = Color(0xFFFFFBF5);
const _inputFill = Color(0xFFFFF7ED);
const _sendFill = Color(0xFF5EEAD4);

List<BoxShadow> _chatNeoShadows() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.26),
        offset: const Offset(3, 3),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GeminiChatService _chatService = GeminiChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  String? _conversationId;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final id = await _chatService.ensureInitialConversationId();
      if (!mounted) return;
      setState(() {
        _conversationId = id;
      });
      await _loadChatHistory();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start chat')),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    final cid = _conversationId;
    if (cid == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final history =
          await _chatService.getChatHistory(conversationId: cid, limit: 50);
      if (!mounted) return;
      setState(() {
        _messages = history.map((item) => ChatMessage.fromMap(item)).toList();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load chat history')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    final cid = _conversationId;
    if (message.isEmpty || _isSending || cid == null) return;

    setState(() {
      _isSending = true;
    });

    // Add user message to UI
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, userMessage);
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(
        userMessage: message,
        conversationId: cid,
      );

      if (!mounted) return;

      // Add AI response to UI
      final aiMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.insert(0, aiMessage);
      });

      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;

      // Add error message
      final errorMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: 'Sorry, I encountered an error. Please try again.',
        timestamp: DateTime.now(),
        isError: true,
      );

      setState(() {
        _messages.insert(0, errorMsg);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kNeoRadius + 4),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        backgroundColor: _assistantBubbleTop,
        title: const Text(
          'Delete this chat?',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
        ),
        content: const Text(
          'This removes only this conversation. Other saved chats stay in your list.',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final cid = _conversationId;
      if (cid == null) return;
      try {
        await _chatService.clearChatHistory(cid);
        if (!mounted) return;
        setState(() {
          _messages.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat deleted')),
          );
        }
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete chat')),
        );
      }
    }
  }

  Future<void> _startNewChat() async {
    if (_isSending) return;
    try {
      final newId = await _chatService.startNewConversation();
      if (!mounted) return;
      setState(() {
        _conversationId = newId;
        _messages = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New chat — messages save automatically')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start a new chat')),
      );
    }
  }

  Future<void> _openChatList() async {
    if (_conversationId == null) return;
    List<ChatThreadSummary> threads = [];
    try {
      threads = await _chatService.listChatThreads();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load saved chats')),
      );
      return;
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _assistantBubbleTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: Colors.black, width: 2),
      ),
      builder: (sheetContext) {
        final sheetHeight = (MediaQuery.sizeOf(sheetContext).height * 0.58)
            .clamp(280.0, 520.0);
        return SizedBox(
          height: sheetHeight,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Saved chats',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: threads.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                          child: Text(
                            'No saved threads yet. Send a message to create your first chat.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                              height: 1.35,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          itemCount: threads.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final t = threads[index];
                            final active = t.id == _conversationId;
                            final time =
                                '${t.updatedAt.year}-${t.updatedAt.month.toString().padLeft(2, '0')}-${t.updatedAt.day.toString().padLeft(2, '0')}';
                            return Material(
                              color: active ? _userBubbleBottom : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () async {
                                  Navigator.pop(sheetContext);
                                  await _chatService.setActiveConversationId(t.id);
                                  if (!mounted) return;
                                  setState(() {
                                    _conversationId = t.id;
                                  });
                                  await _loadChatHistory();
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.black, width: 2),
                                    boxShadow: active ? _chatNeoShadows() : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.preview,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: Colors.black87,
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              time,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black.withValues(alpha: 0.45),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (active)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Icon(Icons.check_circle_rounded,
                                              color: _tealAccent, size: 22),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    final isError = message.isError;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: isError
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isUser
                      ? [_userBubbleTop, _userBubbleBottom]
                      : [_assistantBubbleTop, _assistantBubbleBottom],
                ),
          color: isError ? const Color(0xFFFFE4E6) : null,
          borderRadius: BorderRadius.circular(_kNeoRadius),
          border: Border.all(
            color: isError ? const Color(0xFFDC2626) : Colors.black,
            width: 2,
          ),
          boxShadow: _chatNeoShadows(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: isError ? const Color(0xFF991B1B) : Colors.black87,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _neoAppBarIconButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: _chatNeoShadows(),
              ),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  icon,
                  color: onTap == null
                      ? Colors.black.withValues(alpha: 0.22)
                      : Colors.black87,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goTo(Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              'AI Chat',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              'Your study companion',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.38),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          _neoAppBarIconButton(
            icon: Icons.add_comment_rounded,
            onTap: _isSending ? null : _startNewChat,
          ),
          _neoAppBarIconButton(
            icon: Icons.folder_open_rounded,
            onTap: _conversationId == null ? null : _openChatList,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _neoAppBarIconButton(
              icon: Icons.delete_outline_rounded,
              onTap: _messages.isNotEmpty ? _clearHistory : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _tealAccent),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: _userBubbleBottom,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                  boxShadow: _chatNeoShadows(),
                                ),
                                child: const Icon(Icons.psychology_rounded, size: 44, color: Colors.black87),
                              ),
                              const SizedBox(height: 22),
                              const Text(
                                'Hi — I’m your AI study companion',
                                style: TextStyle(
                                  fontSize: 21,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Exam stress, focus, or a rough day — type what’s on your mind.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withValues(alpha: 0.52),
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 26),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [_assistantBubbleTop, _assistantBubbleBottom],
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: Colors.black, width: 2),
                                  boxShadow: _chatNeoShadows(),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Try asking:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildSuggestion('💪 How can I stay motivated?'),
                                    _buildSuggestion('📚 Tips for better focus'),
                                    _buildSuggestion('😰 I’m feeling stressed'),
                                    _buildSuggestion('⏰ Help with time management'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
          ),

          // Typing Indicator
          if (_isSending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_assistantBubbleTop, _assistantBubbleBottom],
                    ),
                    borderRadius: BorderRadius.circular(_kNeoRadius),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: _chatNeoShadows(),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _tealAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Thinking…',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Input Field
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _inputFill,
                        borderRadius: BorderRadius.circular(_kNeoRadius),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: _chatNeoShadows(),
                      ),
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isSending,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type your message…',
                          hintStyle: TextStyle(
                            color: Colors.black.withValues(alpha: 0.35),
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: _sendFill,
                    shape: const CircleBorder(side: BorderSide(color: Colors.black, width: 2)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _isSending ? null : _sendMessage,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.send_rounded,
                          color: _isSending
                              ? Colors.black.withValues(alpha: 0.25)
                              : Colors.black87,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
              icon: const Icon(Icons.home_outlined, color: _tealNav, size: 28),
              onPressed: () => _goTo(const HomePage()),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: _tealNav, size: 28),
              onPressed: () => _goTo(const EmotionBoardScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.lightbulb_outline_rounded, color: _tealNav, size: 28),
              onPressed: () => _goTo(const RecoveryTipsScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline_rounded, color: _tealNav, size: 28),
              onPressed: () => _goTo(const ProfileScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
