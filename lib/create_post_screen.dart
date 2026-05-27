import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/app_main_bottom_nav.dart';
import 'homepage.dart';
import 'mood_flow_theme.dart';
import 'services/emotion_board_service.dart';
import 'services/mood_log_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

List<BoxShadow> _createPostNeoShadows() => moodFlowNeoShadows();

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _messageController = TextEditingController();
  String selectedMood = 'Calm';
  String selectedMoodImage = 'assets/CalmIcon.png';
  bool isAnonymous = false;
  bool _isSaving = false;
  bool _isLoadingMood = true;

  @override
  void initState() {
    super.initState();
    _loadMoodFromLog();
  }

  Future<void> _loadMoodFromLog() async {
    try {
      final log = await MoodLogService().getTodayMoodLog();
      if (!mounted) return;
      if (log != null) {
        setState(() {
          selectedMood = (log['mood'] as String?)?.isNotEmpty == true
              ? log['mood'] as String
              : selectedMood;
          selectedMoodImage = (log['mood_image'] as String?)?.isNotEmpty == true
              ? log['mood_image'] as String
              : selectedMoodImage;
        });
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load mood log.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMood = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
              moodFlowGoTo(context, const HomePage());
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
              'New post',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Message',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kMoodCardCreamA, kMoodCardCreamB],
                  ),
                  borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: _createPostNeoShadows(),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add the message…',
                    hintStyle: TextStyle(
                      color: Colors.black.withValues(alpha: 0.35),
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: _createPostNeoShadows(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoadingMood)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: kMoodFlowTealAccent,
                        ),
                      )
                    else ...[
                      const Text(
                        'Mood :',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedMood,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          selectedMoodImage,
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: _createPostNeoShadows(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Anonymous mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    Switch(
                      value: isAnonymous,
                      onChanged: (value) {
                        setState(() {
                          isAnonymous = value;
                        });
                      },
                      activeTrackColor: kMoodMint,
                      inactiveTrackColor: Colors.grey.shade300,
                      activeThumbColor: Colors.black87,
                      inactiveThumbColor: Colors.black87,
                      trackOutlineColor: WidgetStateProperty.all(Colors.black),
                      trackOutlineWidth: WidgetStateProperty.all(2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _isSaving ? const [] : _createPostNeoShadows(),
                ),
                child: Material(
                  color: _isSaving ? Colors.grey.shade300 : kMoodMint,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _isSaving
                        ? null
                        : () async {
                            final message = _messageController.text.trim();
                            if (message.isEmpty) {
                              return;
                            }

                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(context);

                            setState(() {
                              _isSaving = true;
                            });

                            try {
                              final created = await EmotionBoardService().createPost(
                                text: message,
                                moodType: selectedMood,
                                moodImage: selectedMoodImage,
                                isAnonymous: isAnonymous,
                              );

                              if (!mounted) return;
                              nav.pop(created);
                            } on AuthException catch (error) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text(error.message)),
                              );
                            } catch (_) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Unable to create post.')),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isSaving = false;
                                });
                              }
                            }
                          },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: kMoodFlowTealAccent,
                              ),
                            )
                          : const Text(
                              'Post',
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
      ),
      bottomNavigationBar: const AppMainBottomNav(),
    );
  }
}
