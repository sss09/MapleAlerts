import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/tokens/maple_colors.dart';
import '../../core/design/widgets/aurora_background.dart';
import '../../core/design/widgets/maple_surface.dart';
import '../../core/design/widgets/stroke_icon.dart';
import '../../features/money/presentation/money_topic.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/enabled_topics_provider.dart';
import '../../providers/settings_provider.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _PageData {
  final String icon;
  final String title;
  final String description;

  const _PageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

const List<_PageData> _kPages = [
  _PageData(
    icon: 'leaf',
    title: 'Welcome to Maple Alerts',
    description:
        'Know your deadlines. Find your money. The Canadian-specific stuff '
        'no other app gets.',
  ),
  _PageData(
    icon: 'calendar',
    title: 'Your day, handled',
    description:
        'RRSP, TFSA, tax, benefits, renewals — calm nudges that tell you '
        'what to do, never panic.',
  ),
  _PageData(
    icon: 'leaf',
    title: 'Free, private, yours',
    description:
        'No account, no email, no sign-up. Your data stays on your phone.',
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// Info pages plus the final interactive "what should we track?" page.
  int get _pageCount => _kPages.length + 1;

  Future<void> _complete() async {
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (mounted) context.go('/');
  }

  void _skip() {
    ref.read(analyticsProvider).track('onboarding_skip', {'at_page': '$_currentPage'});
    _complete();
  }

  void _finish() {
    final topics = ref.read(enabledTopicsProvider).map((t) => t.name).toList()..sort();
    ref.read(analyticsProvider)
        .track('onboarding_complete', {'topics_enabled': topics.join(',')});
    _complete();
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void initState() {
    super.initState();
    // onPageChanged never fires for the initial page — emit page 0 here so
    // the funnel's first step is counted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(analyticsProvider).track('onboarding_page_view', {'index': '0'});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>() ??
        MapleColors.fog;
    final isLast = _currentPage == _pageCount - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Aurora atmosphere ─────────────────────────────────────────────
          const Positioned.fill(child: AuroraBackground(motion: true)),

          // ── Page content ──────────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _pageCount,
            onPageChanged: (i) {
              ref.read(analyticsProvider).track('onboarding_page_view', {'index': '$i'});
              setState(() => _currentPage = i);
            },
            itemBuilder: (context, index) => index < _kPages.length
                ? _OnboardingPageView(page: _kPages[index], colors: colors)
                : _TopicsPage(colors: colors),
          ),

          // ── Skip button (top-right) ───────────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: AnimatedOpacity(
                  opacity: isLast ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: isLast,
                    child: TextButton(
                      onPressed: _skip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: colors.muted,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom controls ───────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pageCount, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active ? colors.accent : colors.faint,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    // Primary CTA button
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF62D2A8), Color(0xFF3CA07E)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: const Color(0xFF06231C),
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isLast ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF06231C),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single page view
// ---------------------------------------------------------------------------

class _OnboardingPageView extends StatelessWidget {
  final _PageData page;
  final MapleColors colors;

  const _OnboardingPageView({required this.page, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon: use the real app icon on the first page, stroke icon elsewhere
          if (page.icon == 'leaf') ...[
            // Page 1 — show the real maple leaf app icon for brand impact
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.35),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/icon/icon.png',
                  width: 128,
                  height: 128,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ] else ...[
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.accent.withValues(alpha: 0.22),
                    colors.accent.withValues(alpha: 0.0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.30),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: StrokeIcon(
                  name: page.icon,
                  size: 64,
                  color: colors.accent,
                  strokeWidth: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 36),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.text,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.muted,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Interactive "what should we track?" page
// ---------------------------------------------------------------------------

class _TopicsPage extends ConsumerWidget {
  const _TopicsPage({required this.colors});

  final MapleColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(enabledTopicsProvider);

    // Scrollable: six topic cards exceed short viewports (small phones,
    // landscape) — the list scrolls under the bottom controls.
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 100, 28, 140),
      children: [
        Text(
          'What should we track?',
          style: TextStyle(
            color: colors.text,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Pick what applies to you. You can change this anytime.',
          style: TextStyle(color: colors.muted, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 24),
        for (final topic in MoneyTopic.values) ...[
          _TopicToggle(
            topic: topic,
            selected: enabled.contains(topic),
            colors: colors,
            onTap: () =>
                ref.read(enabledTopicsProvider.notifier).toggle(topic),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TopicToggle extends StatelessWidget {
  const _TopicToggle({
    required this.topic,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final MoneyTopic topic;
  final bool selected;
  final MapleColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: MapleSurface(
        level: MapleSurfaceLevel.minimal,
        status: 'upcoming',
        active: selected,
        radius: 18,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            StrokeIcon(name: topic.icon, size: 20, color: colors.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    topic.blurb,
                    style: TextStyle(fontSize: 12.5, color: colors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? colors.accent : Colors.transparent,
                border: Border.all(
                  color: selected ? colors.accent : colors.lineStrong,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Color(0xFF06231C))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
