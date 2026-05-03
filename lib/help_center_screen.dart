import 'package:flutter/material.dart';

import 'package:flutter_application_1/utils/help_article_format.dart';

import 'mood_flow_theme.dart';
import 'sos_screen.dart';

const Color _accentPurple = Color(0xFF7C3AED);
const Color _accentCoral = Color(0xFFEA580C);
const Color _cardCreamA = Color(0xFFFFF7ED);
const Color _cardCreamB = Color(0xFFFFFBF5);

/// Left accent colors for help article paragraph cards (rotate by index).
const List<Color> _helpStripeAccents = [
  Color(0xFF7C3AED),
  Color(0xFF0D9488),
  Color(0xFFEA580C),
  Color(0xFF5EEAD4),
  Color(0xFF4F46E5),
];

const Color _disclaimerCardBg = Color(0xFFFFF1F2);
const Color _disclaimerStripe = Color(0xFFE11D48);

class _HelpArticle {
  const _HelpArticle({
    required this.category,
    required this.title,
    required this.body,
    required this.icon,
  });

  final String category;
  final String title;
  final String body;
  final IconData icon;

  bool matchesQuery(String q) {
    if (q.isEmpty) return true;
    final hay = '$category $title $body'.toLowerCase();
    return hay.contains(q);
  }
}

List<_HelpArticle> _articles() => const [
      _HelpArticle(
        category: 'Getting started',
        icon: Icons.rocket_launch_outlined,
        title: 'What is this app for?',
        body:
            'The app brings together mood check ins with sleep and goals, a Calendar that lists your saved moods '
            'by day, the mood summary screen for today only right after you save, and notification alerts.\n\n'
            'For relief and focus you have guided breathing, a study '
            'focus timer, Music For You tracks matched to your logged mood, AI recovery tips, and a supportive chat tab.\n\n'
            'Home also includes the emotion board for peers and study challenges.\n\n'
            'Profile covers your progress, reminders, saved motivations, profile edits, the help center, '
            'and crisis helplines.\n\n'
            'This is not therapy or emergency care. If you are unsafe or need urgent help, open Crisis '
            'and helplines from Profile or call your local emergency number.',
      ),
      _HelpArticle(
        category: 'Getting started',
        icon: Icons.explore_outlined,
        title: 'Do I need an account?',
        body:
            'Yes. You need an account to use Examination Stress Recovery. Signing in ties your mood check ins, '
            'calendar, emotion board activity, reminders, saved motivations, and profile to a secure space that '
            'only you can open.\n\n'
            'If you are new, create an account from the login screen. Use the same sign in on another phone or '
            'tablet so your progress and history stay with you.',
      ),
      _HelpArticle(
        category: 'Mood and check in',
        icon: Icons.favorite_outline,
        title: 'How does the daily check in work?',
        body:
            'You need to be signed in so your check in can save to your account. From Home tap Log your mood, or open Profile and use the check in there. Choose how you feel, then add sleep or goals.\n\n'
            'After you save, open the mood summary to review today\'s log. That screen is only for the current day.\n\n'
            'To see an older day, open the Calendar from Home, tap that date on the grid, and read the mood saved for it.',
      ),
      _HelpArticle(
        category: 'Mood and check in',
        icon: Icons.insights_outlined,
        title: 'Where can I see my past moods?',
        body:
            'Past moods are only on the Calendar. While signed in, tap the calendar icon on Home, choose a day on '
            'the month grid, and view the mood you saved for that day.\n\n'
            'The mood summary screen is not for history. It shows today\'s check in after you save, not other dates.',
      ),
      _HelpArticle(
        category: 'Focus and calm tools',
        icon: Icons.air_outlined,
        title: 'Breathing exercise tips',
        body:
            'Find a quiet spot, follow the guided rhythm, and don\'t worry about doing it perfectly.\n\n'
            'Even one short session can lower tension before study or sleep.',
      ),
      _HelpArticle(
        category: 'Focus and calm tools',
        icon: Icons.timer_outlined,
        title: 'Using the focus timer',
        body:
            'Pick a duration that feels doable, start the timer, and give one task your full attention.\n\n'
            'Short Pomodoro style blocks often work well during revision.',
      ),
      _HelpArticle(
        category: 'Focus and calm tools',
        icon: Icons.music_note_outlined,
        title: 'Music recommendations',
        body:
            'Music For You on Home uses the mood you logged today. Recommendations are mood based, not a generic playlist. '
            'The app asks the Jamendo catalog for tracks that match a direction meant to help you move through how you feel.\n\n'
            'Examples from the app logic: tired leans to energetic and upbeat picks so you get lift and motivation, like wake up or cheer up style songs. '
            'Sad leans to happy and uplifting picks. Anxious leans to calm and relaxing picks. Calm leans to positive feel good picks.\n\n'
            
            'Songs stream online. If the list is empty or will not load, check your internet connection and try again. '
            'This is for comfort and study ambience, not medical treatment.',
      ),
      _HelpArticle(
        category: 'Community',
        icon: Icons.forum_outlined,
        title: 'Emotion board basics',
        body:
            'Open Emotion Board from Home under Boards. The feed lists community posts, newest first. '
            'Use the filter at the top to show All posts or only Calm, Anxious, Sad, or Tired. Pull down on the list to refresh. '
            'Keep posts kind and respectful.\n\n'
            'You need to be signed in to create a post, tap the heart to like, or leave a reply. Tap the + button to write a message. '
            'The mood label on your post is taken from today\'s mood check in when you have one; if not it stays on the default Calm pairing. '
            'Turn on Anonymous mode before posting if you want to stay anonymous.\n\n'
            'Tap a post to open the thread. There you can read replies, like the post, and add your own reply. Replies always use your profile name and avatar snapshot. '
            'If you wrote the post, use the menu on the card to edit the post or delete it.',
      ),
      _HelpArticle(
        category: 'Community',
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        body:
            'Open Profile while signed in, tap Notification settings, and switch or schedule mood check in reminders, '
            'study, breathing, recovery tips, challenges, and calendar event reminders.\n\n'
            'Your phone system settings still decide whether the app may show banners and sounds.',
      ),
      _HelpArticle(
        category: 'Account and data',
        icon: Icons.lock_outline,
        title: 'Privacy and your data',
        body:
            'While you are signed in, your mood check ins, mood history on the calendar, focus timer sessions, '
            'profile name and avatar, emotion board posts and replies, likes you tap, and saved motivations are '
            'kept online with your account. Other signed in users can read community '
            'posts on the board, so only share what you are fine with others seeing.\n\n'
            'Reminder on or off choices and reminder times you set in Profile, Notification settings stay on your phone. '
            'Your phone must still allow notifications for this app if you want those nudges. When alerts are on, '
            'you may also get notified about likes or replies on your emotion board posts.\n\n'
            'There is no single in app control yet to download your whole archive or delete the entire account by '
            'yourself. For a data export, account deletion, or formal privacy questions, contact the support team '
            'for this app, the same channel you use when you need your email updated.',
      ),
      _HelpArticle(
        category: 'Account and data',
        icon: Icons.mail_outline,
        title: 'Changing your email',
        body:
            'Your sign in email is the address you used to create your account. The app does not offer a screen to change it because that address is locked to how you authenticate.\n\n'
            'If you need to use a different email, contact the support team for this app.',
      ),
      _HelpArticle(
        category: 'AI features',
        icon: Icons.lightbulb_outline,
        title: 'Recovery Tips',
        body:
            'Open Recovery Tips from the bottom lightbulb tab on the main navigation bar. You can also reach it from Home suggestion cards. '
            'You need to be signed in and connected to the internet so the app can load fresh tips for you.\n\n'
            'The screen uses today\'s mood, sleep, and goals from your mood log when you have checked in, then gives you three short pieces: '
            'a relaxation idea, a recovery tip, and a motivation line. If you have not logged mood today, it may use calm as the default mood until you save a check in.\n\n'
            'You can save a motivation line you like from Profile, Saved motivations and read it again later. '
            'These tips are for everyday study support and wellbeing ideas, not diagnosis or therapy.',
      ),
      _HelpArticle(
        category: 'AI features',
        icon: Icons.chat_bubble_outline,
        title: 'AI chat assistant',
        body:
            'Open Chat from the bottom speech bubble tab on the main navigation bar. You need to be signed in and online.\n\n'
            'Type what is on your mind and the AI assistant replies in a friendly way. It can use today\'s mood log when you have one, and it remembers recent messages in the same chat so the conversation makes sense.\n\n'
            'Past chats stay saved with your account so you can open them again. You can also start a new chat whenever you want. '
            'The assistant is meant to help with exam stress, study habits, and encouragement.\n\n'
            'It can misunderstand you or sound confident when it is wrong. It is not diagnosis, therapy, or emergency care. '
            'If you are unsafe or need urgent help, open Crisis and helplines from Profile instead of waiting on the chat.',
      ),
    ];

/// FAQs, guides, and crisis signposting; matches the neo UI used on other screens.
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Map<String, List<_HelpArticle>> _groupedMatches() {
    final q = _search.text.trim().toLowerCase();
    final map = <String, List<_HelpArticle>>{};
    for (final a in _articles()) {
      if (!a.matchesQuery(q)) continue;
      map.putIfAbsent(a.category, () => []).add(a);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedMatches();
    final categories = grouped.keys.toList();

    return Scaffold(
      backgroundColor: kMoodFlowBg,
      appBar: AppBar(
        backgroundColor: kMoodFlowBg,
        elevation: 0,
        leading: IconButton(
          iconSize: 26,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Help center',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              'FAQs and guides',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.38),
                letterSpacing: 0.12,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _CrisisShortcutCard(
              onOpen: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const SosScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _SearchField(
              controller: _search,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: moodFlowNeoShadows(),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _disclaimerStripe.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      size: 20,
                      color: _disclaimerStripe.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This app supports everyday stress, not emergencies. If you might hurt yourself or '
                      'someone else, call local emergency services or open Crisis and helplines.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                        color: Colors.black.withValues(alpha: 0.52),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (categories.isEmpty)
              _EmptySearchState(
                onClear: () {
                  _search.clear();
                  setState(() {});
                },
              )
            else
              ...categories.expand((cat) {
                final items = grouped[cat]!;
                return [
                  _SectionHeading(title: stripHelpHtmlEntities(cat)),
                  const SizedBox(height: 8),
                  _ArticleCard(
                    articles: items,
                    onOpen: (article) {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => _HelpArticleRoute(article: article),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                ];
              }),
          ],
        ),
      ),
    );
  }
}

class _CrisisShortcutCard extends StatelessWidget {
  const _CrisisShortcutCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        boxShadow: moodFlowNeoShadows(),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _accentCoral,
                  _accentCoral.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Icon(Icons.emergency_outlined, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Need help right now?',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Crisis numbers & helplines',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.9), size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: moodFlowNeoShadows(),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Search questions…',
          hintStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.35),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.black.withValues(alpha: 0.42), size: 26),
          suffixIcon: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              if (controller.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Clear',
                icon: Icon(Icons.close_rounded, color: Colors.black.withValues(alpha: 0.45)),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Colors.black87,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.articles,
    required this.onOpen,
  });

  final List<_HelpArticle> articles;
  final ValueChanged<_HelpArticle> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: moodFlowNeoShadows(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < articles.length; i++) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onOpen(articles[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _cardCreamA,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              offset: const Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(articles[i].icon, color: _accentPurple, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stripHelpHtmlEntities(articles[i].title),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              helpArticlePreviewLine(articles[i].body),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withValues(alpha: 0.45),
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.black.withValues(alpha: 0.35),
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (i < articles.length - 1) Container(height: 2, color: Colors.black),
          ],
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardCreamA, _cardCreamB],
        ),
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: moodFlowNeoShadows(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.search_off_rounded, size: 36, color: Colors.black.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text(
            'No matching questions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different words, or clear the search to see every topic.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: Colors.black.withValues(alpha: 0.48),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: moodFlowNeoShadows(),
              ),
              child: Material(
                color: kMoodMint,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Text(
                      'Clear search',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpArticleRoute extends StatelessWidget {
  const _HelpArticleRoute({required this.article});

  final _HelpArticle article;

  @override
  Widget build(BuildContext context) {
    final title = stripHelpHtmlEntities(article.title);
    final category = stripHelpHtmlEntities(article.category);
    final body = stripHelpHtmlEntities(article.body);
    final paragraphs = helpArticleParagraphs(body);

    return Scaffold(
      backgroundColor: kMoodFlowBg,
      appBar: AppBar(
        backgroundColor: kMoodFlowBg,
        elevation: 0,
        leading: IconButton(
          iconSize: 26,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Help',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.black.withValues(alpha: 0.55),
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
          children: [
            _HelpArticleHero(
              title: title,
              category: category,
              icon: article.icon,
            ),
            const SizedBox(height: 20),
            Text(
              'Details',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.black.withValues(alpha: 0.38),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            ...List<Widget>.generate(paragraphs.length, (i) {
              final p = paragraphs[i];
              final disclaimer = isHelpDisclaimerParagraph(p);
              final stripe = disclaimer
                  ? _disclaimerStripe
                  : _helpStripeAccents[i % _helpStripeAccents.length];
              return Padding(
                padding: EdgeInsets.only(bottom: i < paragraphs.length - 1 ? 12 : 0),
                child: _HelpParagraphCard(
                  text: p,
                  stripeColor: stripe,
                  paragraphIndex: i + 1,
                  totalParagraphs: paragraphs.length,
                  isDisclaimer: disclaimer,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _HelpArticleHero extends StatelessWidget {
  const _HelpArticleHero({
    required this.title,
    required this.category,
    required this.icon,
  });

  final String title;
  final String category;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            _cardCreamB,
          ],
        ),
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: moodFlowNeoShadows(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentPurple.withValues(alpha: 0.12),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(icon, color: _accentPurple, size: 32),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: kMoodMint,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Text(
              category.toUpperCase(),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              height: 1.2,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpParagraphCard extends StatelessWidget {
  const _HelpParagraphCard({
    required this.text,
    required this.stripeColor,
    required this.paragraphIndex,
    required this.totalParagraphs,
    required this.isDisclaimer,
  });

  final String text;
  final Color stripeColor;
  final int paragraphIndex;
  final int totalParagraphs;
  final bool isDisclaimer;

  @override
  Widget build(BuildContext context) {
    final bg = isDisclaimer
        ? _disclaimerCardBg
        : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: moodFlowNeoShadows(),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              color: stripeColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (totalParagraphs > 1 || isDisclaimer) ...[
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDisclaimer
                                  ? _disclaimerStripe.withValues(alpha: 0.15)
                                  : stripeColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.85),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '$paragraphIndex',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: isDisclaimer ? _disclaimerStripe : Colors.black87,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isDisclaimer
                                  ? 'Important'
                                  : 'Part $paragraphIndex of $totalParagraphs',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.black.withValues(alpha: 0.42),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    SelectableText(
                      text,
                      style: TextStyle(
                        fontSize: isDisclaimer ? 14.5 : 15,
                        fontWeight: FontWeight.w600,
                        height: 1.52,
                        color: Colors.black.withValues(alpha: isDisclaimer ? 0.88 : 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
