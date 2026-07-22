import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/blob_art.dart';

/// One onboarding slide: full-bleed brand artwork with the copy from the
/// client's design placed above or below it.
class _Slide {
  const _Slide({
    required this.image,
    this.title,
    this.subtitle,
    this.textAtTop = true,
  });

  final String image;
  final String? title;
  final String? subtitle;
  final bool textAtTop;
}

const _slides = [
  // Slide 1 — the brand mark.
  _Slide(image: AppAssets.logoBackground),
  _Slide(
    image: AppAssets.onboardingStyle,
    title: 'AI that\nunderstands\nyour style',
    subtitle: 'Get smart outfit analysis\nand level up your\nfashion game.',
  ),
  _Slide(
    image: AppAssets.onboardingWardrobe,
    title: 'Your wardrobe,\nDigitized',
    subtitle:
        'Organize, manage and\ncreate amazing outfits\nfrom your own clothes.',
    textAtTop: false,
  ),
  _Slide(
    image: AppAssets.onboardingCommunity,
    title: 'Connect.\nShare.\nInspire.',
    subtitle: 'Join a community of\nfashion lovers and\nshare your looks.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (!mounted) return;
    context.go(Routes.login);
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBrandSlide = _page == 0;

    return Scaffold(
      backgroundColor: AppColors.artCanvas,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
          ),
          // Bottom controls sit above the artwork.
          Positioned(
            left: 28,
            right: 28,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 72,
                child: Row(
                  children: [
                    if (isBrandSlide)
                      SmoothPageIndicator(
                        controller: _controller,
                        count: _slides.length,
                        effect: const ExpandingDotsEffect(
                          activeDotColor: AppColors.ink,
                          dotColor: AppColors.line,
                          dotHeight: 6,
                          dotWidth: 6,
                          expansionFactor: 3,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 40),
                          alignment: Alignment.centerLeft,
                        ),
                        child: const Text('SKIP'),
                      ),
                    const Spacer(),
                    CircleArrowButton(onPressed: _next),
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

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(slide.image, fit: BoxFit.cover),
        if (slide.title == null)
          // Brand slide — logo mark and wordmark, centred.
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AppAssets.logoMark, width: 120),
                const SizedBox(height: 8),
                const Text(
                  'SAVARUN',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'AI FASHION & STYLE\nPLATFORM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.4,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          )
        else
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: slide.textAtTop
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
                children: [
                  Text(
                    slide.title!,
                    style: const TextStyle(
                      fontSize: 27,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    slide.subtitle!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.7,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
