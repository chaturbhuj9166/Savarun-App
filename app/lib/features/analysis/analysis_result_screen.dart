import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import 'models/outfit_analysis.dart';
import 'widgets/score_blob.dart';
import 'widgets/style_dna_view.dart';

/// The analysis result, laid out as the design's three swipeable pages:
/// Fit Score → Style DNA → AI Feedback.
class AnalysisResultScreen extends StatefulWidget {
  const AnalysisResultScreen({super.key, required this.analysis});
  final OutfitAnalysis analysis;

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    final hasDna = a.styleDna.isNotEmpty;

    final pages = <Widget>[
      _FitScorePage(analysis: a),
      if (hasDna) StyleDnaView(analysis: a),
      _FeedbackPage(analysis: a),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView(controller: _controller, children: pages),
            ),
            const SizedBox(height: 12),
            SmoothPageIndicator(
              controller: _controller,
              count: pages.length,
              effect: const ExpandingDotsEffect(
                activeDotColor: AppColors.ink,
                dotColor: AppColors.line,
                dotHeight: 6,
                dotWidth: 6,
                expansionFactor: 3,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Page 1 — the headline Fit Score.
class _FitScorePage extends StatelessWidget {
  const _FitScorePage({required this.analysis});
  final OutfitAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final a = analysis;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Text(
            'Your Fit Score',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          ScoreBlob(score: a.fitScore),
          const Spacer(),
          Text(
            _headline(a.fitScore),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          if (a.summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              a.summary,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.inkMuted,
              ),
            ),
          ],
          const Spacer(),
          ElevatedButton(
            onPressed: () => context.push(Routes.fullReport, extra: a),
            child: const Text('See Full Report'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _headline(int s) {
    if (s == 0) return "Couldn't read this outfit";
    if (s >= 85) return 'Excellent Fit! ✨';
    if (s >= 70) return 'Great Outfit! 🔥';
    if (s >= 50) return 'Solid, with room to grow';
    return "Let's refine this fit";
  }
}

/// Page 3 — the design's "What's Working" / "Suggestions" cards.
class _FeedbackPage extends StatelessWidget {
  const _FeedbackPage({required this.analysis});
  final OutfitAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final working =
        analysis.suggestions.where((s) => s.type == 'keep').toList();
    final ideas = analysis.suggestions.where((s) => s.type != 'keep').toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      children: [
        const Center(
          child: Text(
            'AI Feedback',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (working.isNotEmpty)
          _FeedbackCard(title: "What's Working", items: working),
        if (working.isNotEmpty && ideas.isNotEmpty) const SizedBox(height: 16),
        if (ideas.isNotEmpty)
          _FeedbackCard(title: 'Suggestions', items: ideas),
        if (working.isEmpty && ideas.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Text(
              'No feedback for this photo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
            ),
          ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.title, required this.items});
  final String title;
  final List<Suggestion> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          for (final s in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.auto_awesome_rounded,
                        size: 15, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.text,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
