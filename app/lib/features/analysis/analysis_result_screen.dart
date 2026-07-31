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
          const SizedBox(height: 12),
          // Share this look to the home feed (Module 3). Only offer it when
          // the analysis has a stored image to post.
          if ((a.imageUrl ?? '').isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => context.push(
                Routes.shareOutfit,
                extra: (
                  a.imageUrl,
                  a.fitScore,
                  a.styleDna.isNotEmpty ? a.styleDna.first.style : null,
                ),
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Share to Feed'),
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

/// Page 3 — the Fashion Doctor's report: diagnosis, trend pulse, what's working
/// and the prescription (what to add/swap).
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
        // "Fashion Doctor" report header.
        Center(
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_hospital_rounded,
                        size: 14, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'FASHION DOCTOR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Style Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Diagnosis (the overall verdict).
        if (analysis.summary.isNotEmpty)
          _ReportCard(
            icon: Icons.medical_services_outlined,
            title: 'Diagnosis',
            child: Text(
              analysis.summary,
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: AppColors.inkSoft),
            ),
          ),

        // Trend pulse.
        if (analysis.trend.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ReportCard(
            icon: Icons.trending_up_rounded,
            title: 'Trend Pulse',
            child: Text(
              analysis.trend,
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: AppColors.inkSoft),
            ),
          ),
        ],

        // What's working.
        if (working.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ReportCard(
            icon: Icons.check_circle_outline_rounded,
            title: "What's Working",
            child: _Bullets(items: working),
          ),
        ],

        // Prescription (add / swap).
        if (ideas.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ReportCard(
            icon: Icons.medication_outlined,
            title: 'Prescription',
            child: _Bullets(items: ideas),
          ),
        ],

        if (analysis.summary.isEmpty &&
            analysis.trend.isEmpty &&
            working.isEmpty &&
            ideas.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Text(
              'No report for this photo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
            ),
          ),

        // "Suggestions for You" — reveals the AI's personalised styling ideas.
        if (analysis.styleTips.isNotEmpty) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showSuggestions(context, analysis.styleTips),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Suggestions for You'),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  void _showSuggestions(BuildContext context, List<String> tips) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.canvas,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Suggestions for You',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Small tweaks that would take this look further",
              style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 20),
            for (final tip in tips)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.checkroom_rounded,
                          size: 15, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A titled card for one section of the Fashion Doctor report.
class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Bullet list of suggestions.
class _Bullets extends StatelessWidget {
  const _Bullets({required this.items});
  final List<Suggestion> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.arrow_right_rounded,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.text,
                    style: const TextStyle(
                        fontSize: 13.5, height: 1.5, color: AppColors.inkSoft),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

